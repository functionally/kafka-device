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


import Network.UI.Kafka (ExitAction, LoopAction, Sensor, TopicConnection, producerLoop)
import Network.UI.Kafka.Types (Event(KeyEvent))
import System.IO (BufferMode(NoBuffering), hSetBuffering, hSetEcho, stdin)


-- | Produce keyboard events on a Kafka topic from standard input.
keyboardLoop :: TopicConnection             -- ^ The Kafka topic name and connection information.
             -> Sensor                      -- ^ The name of the sensor producing events.
             -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
keyboardLoop topicConnection sensor =
  do
    hSetBuffering stdin NoBuffering
    hSetEcho stdin False
    producerLoop topicConnection sensor
      $ fmap (: [])
      $ KeyEvent
      <$> getChar
      <*> return Nothing
      <*> return Nothing
      <*> return Nothing
