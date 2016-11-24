{-|
Module      :  Network.UI.Kafka.Keyboard
Copyright   :  (c) 2016 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <consult@brianwbush.info>
Stability   :  Experimental
Portability :  Stable

Produce events on a Kafka topic from standard input.
-}


module Network.UI.Kafka.Keyboard (
-- * Event handling 
  keyboardLoop
) where


import Network.Kafka (KafkaAddress, KafkaClientId)
import Network.Kafka.Protocol (TopicName)
import Network.UI.Kafka (ExitAction, LoopAction, Sensor, producerLoop)
import Network.UI.Kafka.Types (Event(KeyEvent))
import System.IO (BufferMode(NoBuffering), hSetBuffering, hSetEcho, stdin)


-- | Produce keyboard events on a Kafka topic from standard input.
keyboardLoop :: KafkaClientId               -- ^ A Kafka client identifier for the producer.
             -> KafkaAddress                -- ^ The address of the Kafka broker.
             -> TopicName                   -- ^ The Kafka topic name.
             -> Sensor                      -- ^ The name of the sensor producing events.
             -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
keyboardLoop client address topic sensor =
  do
    hSetBuffering stdin NoBuffering
    hSetEcho stdin False
    producerLoop client address topic sensor
      $ fmap (: [])
      $ KeyEvent
      <$> getChar
      <*> return Nothing
      <*> return Nothing
      <*> return Nothing
