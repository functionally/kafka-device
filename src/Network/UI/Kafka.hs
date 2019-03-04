{-|
Module      :  $Header$
Copyright   :  (c) 2016-19 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <code@functionally.io>
Stability   :  Production
Portability :  Portable

Produce and consume events on Kafka topics.
-}


{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards  #-}


module Network.UI.Kafka (
-- * Types
  TopicConnection(..)
, Sensor
, LoopAction
, ExitAction
-- * Consumption
, ConsumerCallback
, consumerLoop
, rawConsumerLoop
-- * Production
, ProducerCallback
, producerLoop
, rawProducerLoop
) where


import Control.Arrow ((***))
import Control.Concurrent (MVar, newEmptyMVar, isEmptyMVar, threadDelay, tryPutMVar, yield)
import Control.Monad (void, when)
import Control.Monad.Except (liftIO)
import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Binary (decode, encode)
import Data.ByteString.Char8 (pack, unpack)
import Data.ByteString.Lazy (fromStrict, toStrict)
import Data.String (IsString(fromString))
import GHC.Generics (Generic)
import Network.UI.Kafka.Types (Event)
import Network.Kafka (KafkaClientError, KafkaTime(..), TopicAndMessage(..), getLastOffset, mkKafkaState, runKafka, withAddressHandle)
import Network.Kafka.Consumer (fetch', fetchMessages, fetchRequest)
import Network.Kafka.Producer (makeKeyedMessage, produceMessages)
import Network.Kafka.Protocol (FetchResponse(..), KafkaBytes(..), Key(..), Message(..), Value(..))


-- | Connection information for a Kafka topic.
data TopicConnection =
  TopicConnection
  {
    client  :: String        -- ^ A name for the Kafka client.
  , address :: (String, Int) -- ^ The host name and port for the Kafka broker.
  , topic   :: String        -- ^ The Kafka topic name.
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON TopicConnection

instance ToJSON TopicConnection


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
consumerLoop :: TopicConnection             -- ^ The Kafka topic name and connection information.
             -> ConsumerCallback            -- ^ The consumer callback.
             -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
consumerLoop topicConnection =
  let
    fromMessage :: Message -> (Sensor, Event)
    fromMessage message =
      let
        (_, _, _, Key (Just (KBytes k)), Value (Just (KBytes v))) = _messageFields message
      in
        (unpack k, decode $ fromStrict v)
  in
    rawConsumerLoop topicConnection fromMessage
      . uncurry


-- | Consume messages for a Kafka topic.
rawConsumerLoop :: TopicConnection             -- ^ The Kafka topic name and connection information.
                -> (Message -> a)              -- ^ The decoder.
                -> (a -> IO ())                -- ^ The consumer callback.
                -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
rawConsumerLoop TopicConnection{..} fromMessage consumer =
  do
    exitFlag <- newEmptyMVar :: IO (MVar ())
    let
      topic' = fromString topic
      address' = fromString *** fromIntegral $ address
      loop offset =
        do
          result <- withAddressHandle address' $ \handle -> fetch' handle =<< fetchRequest offset 0 topic'
          let
            (_, [(_, _, offset', _)]) : _ = _fetchResponseFields result
            messages = fromMessage . _tamMessage <$> fetchMessages result
          liftIO
            $ do
              mapM_ consumer messages
              threadDelay 100 -- FIXME: Is a thread delay really necessary in order not to miss messages?  Why?
          running <- liftIO $ isEmptyMVar exitFlag
          when running
            $ loop offset'
    return
      (
        void $ tryPutMVar exitFlag ()
      , fmap void $ runKafka (mkKafkaState (fromString client) address')
        $ do
          offset <- getLastOffset LatestTime 0 topic'
          loop offset
      )


-- | Callback for producing events from a sensor.
type ProducerCallback = IO [Event] -- ^ Action for producing events.


-- | Produce events for a Kafka topic.
producerLoop :: TopicConnection             -- ^ The Kafka topic name and connection information.
             -> Sensor                      -- ^ The name of the sensor producing the event.
             -> ProducerCallback            -- ^ The producer callback.
             -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
producerLoop topicConnection sensor =
  let
    toMessage = makeKeyedMessage (pack sensor) . toStrict . encode
  in
    rawProducerLoop topicConnection toMessage


-- | Produce messages for a Kafka topic.
rawProducerLoop :: TopicConnection             -- ^ The Kafka topic name and connection information.
                -> (a -> Message)              -- ^ The encoder.
                -> IO [a]                      -- ^ The producer callback.
                -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
rawProducerLoop TopicConnection{..} toMessage producer =
  do
    exitFlag <- newEmptyMVar :: IO (MVar ())
    let
      loop =
        do
          events <- liftIO producer
          void
            . produceMessages
            $ map
              (TopicAndMessage (fromString topic) . toMessage)
              events
          running <- liftIO $ isEmptyMVar exitFlag
          when (null events)
            $ liftIO yield
          when running
            loop
    return
      (
        void $ tryPutMVar exitFlag ()
      , void <$> runKafka (mkKafkaState (fromString client) (fromString *** fromIntegral $ address)) loop
      )
