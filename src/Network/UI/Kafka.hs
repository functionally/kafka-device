{-|
Module      :  Network.UI.Kafka
Copyright   :  (c) 2016 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <consult@brianwbush.info>
Stability   :  Experimental
Portability :  Stable

Produce and consume events on Kafka topics.
-}


module Network.UI.Kafka (
-- * Types
  Sensor
, LoopAction
, ExitAction
-- * Consumption
, ConsumerCallback
, consumerLoop
-- * Production
, ProducerCallback
, producerLoop
) where


import Control.Concurrent (MVar, newEmptyMVar, isEmptyMVar, threadDelay, tryPutMVar)
import Control.Monad (void, when)
import Control.Monad.Except (liftIO)
import Data.Binary (decode, encode)
import Data.ByteString.Char8 (pack, unpack)
import Data.ByteString.Lazy (fromStrict, toStrict)
import Network.UI.Kafka.Types (Event)
import Network.Kafka (KafkaAddress, KafkaClientError, KafkaClientId, KafkaTime(..), TopicAndMessage(..), getLastOffset, mkKafkaState, runKafka, withAddressHandle)
import Network.Kafka.Consumer (fetch', fetchMessages, fetchRequest)
import Network.Kafka.Producer (makeKeyedMessage, produceMessages)
import Network.Kafka.Protocol (FetchResponse(..), KafkaBytes(..), Key(..), Message(..), TopicName, Value(..))


-- | A name for a sensor.
type Sensor = String


-- | Action for iterating to produce or consume events.
type LoopAction = IO (Either KafkaClientError ())


-- | Action for ending iteration.
type ExitAction = IO ()


-- | Callback for consuming events from a sensor.
type ConsumerCallback =  Sensor -- ^ The name of the sensor producing the event.
                      -> Event  -- ^ The event.
                      -> IO ()  -- ^ The action for consuming the event.


-- | Consume events for a Kafka topic.
consumerLoop :: KafkaClientId               -- ^ A Kafka client identifier for the consumer.
             -> KafkaAddress                -- ^ The address of the Kafka broker.
             -> TopicName                   -- ^ The Kafka topic name.
             -> ConsumerCallback            -- ^ The consumer callback.
             -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
consumerLoop clientId address topic consumer =
  do
    exitFlag <- newEmptyMVar :: IO (MVar ())
    let
      fromMessage :: Message -> (Sensor, Event)
      fromMessage message =
        let
          (_, _, _, Key (Just (KBytes k)), Value (Just (KBytes v))) = _messageFields message
        in
          (unpack k, decode $ fromStrict v)
      loop offset =
        do
          result <- withAddressHandle address $ \handle -> fetch' handle =<< fetchRequest offset 0 topic
          let
            (_, [(_, _, offset', _)]) : _ = _fetchResponseFields result
            messages = fromMessage . _tamMessage <$> fetchMessages result
          liftIO
            $ do
              mapM_ (uncurry consumer) messages
              threadDelay 7500 -- FIXME: Is a thread delay really necessary in order not to miss messages?  Why?
          running <- liftIO $ isEmptyMVar exitFlag
          when running
            $ loop offset'
    return
      (
        void $ tryPutMVar exitFlag ()
      , fmap void $ runKafka (mkKafkaState clientId address)
        $ do
          offset <- getLastOffset LatestTime 0 topic
          loop offset
      )


-- | Callback for producing events from a sensor.
type ProducerCallback = IO [Event] -- ^ Action for producing events.


-- | Produce events for a Kafka topic.
producerLoop :: KafkaClientId               -- ^ A Kafka client identifier for the producer.
             -> KafkaAddress                -- ^ The address of the Kafka broker.
             -> TopicName                   -- ^ The Kafka topic name.
             -> Sensor                      -- ^ The name of the sensor producing the event.
             -> ProducerCallback            -- ^ The producer callback.
             -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
producerLoop clientId address topic sensor producer =
  do
    exitFlag <- newEmptyMVar :: IO (MVar ())
    let
      loop =
        do
          events <- liftIO producer
          void
            $ produceMessages
            $ map
              (TopicAndMessage topic . makeKeyedMessage (pack sensor) . toStrict . encode)
              events
          running <- liftIO $ isEmptyMVar exitFlag
          when running
            loop
    return
      (
        void $ tryPutMVar exitFlag ()
      , void <$> runKafka (mkKafkaState clientId address) loop
      )
