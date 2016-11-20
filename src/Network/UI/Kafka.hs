module Network.UI.Kafka (
  Sensor
, LoopAction
, ExitAction
, ConsumerCallback
, consumerLoop
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


type Sensor = String


type LoopAction = IO (Either KafkaClientError ())


type ExitAction = IO ()


type ConsumerCallback = Sensor -> Event -> IO ()


consumerLoop :: KafkaClientId -> KafkaAddress -> TopicName -> ConsumerCallback -> IO (ExitAction, LoopAction)
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


type ProducerCallback = IO Event


producerLoop :: KafkaClientId -> KafkaAddress -> TopicName -> Sensor -> ProducerCallback -> IO (ExitAction, LoopAction)
producerLoop clientId address topic sensor producer =
  do
    exitFlag <- newEmptyMVar :: IO (MVar ())
    let
      loop =
        do
          event <- liftIO producer
          void
            $ produceMessages
            [
              TopicAndMessage topic
                $ makeKeyedMessage (pack sensor) (toStrict $ encode event)
            ]
          running <- liftIO $ isEmptyMVar exitFlag
          when running
            loop
    return
      (
        void $ tryPutMVar exitFlag ()
      , void <$> runKafka (mkKafkaState clientId address) loop
      )
