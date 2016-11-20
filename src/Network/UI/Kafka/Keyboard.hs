module Network.UI.Kafka.Keyboard (
  keyboardLoop
) where


import Network.Kafka (KafkaAddress, KafkaClientId)
import Network.Kafka.Protocol (TopicName)
import Network.UI.Kafka (ExitAction, LoopAction, Sensor, producerLoop)
import Network.UI.Kafka.Types (Event(KeyEvent))
import System.IO (BufferMode(NoBuffering), hSetBuffering, hSetEcho, stdin)


keyboardLoop :: KafkaClientId -> KafkaAddress -> TopicName -> Sensor -> IO (ExitAction, LoopAction)
keyboardLoop client address topic sensor =
  do
    hSetBuffering stdin NoBuffering
    hSetEcho stdin False
    producerLoop client address topic sensor
      $ KeyEvent
      <$> getChar
      <*> return Nothing
      <*> return Nothing
      <*> return Nothing
