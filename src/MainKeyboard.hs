{-|
Module      :  $Headers
Copyright   :  (c) 2016-19 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <code@functionally.io>
Stability   :  Production
Portability :  Portable

Simple producer of keyboard events from standard input to a Kafka topic.
-}


module Main (
-- * Entry point
  main
) where


import Network.UI.Kafka (TopicConnection(TopicConnection))
import Network.UI.Kafka.Keyboard (keyboardLoop)
import System.Environment (getArgs)


-- | The main action.
main :: IO ()
main =
  do
    args <- getArgs
    case args of
      [client, host, port, topic, sensor] ->
        do
          putStrLn $ "Kafka client:  " ++ client
          putStrLn $ "Kafka address: (" ++ host ++ "," ++ port ++ ")"
          putStrLn $ "Kafka topic:   " ++ topic
          putStrLn $ "Sensor name:   " ++ sensor
          (_, loop) <-
            keyboardLoop
              (TopicConnection client (host, read port) topic)
              sensor
          result <- loop
          either print return result
      _ -> putStrLn "USAGE: kafka-device-keyboard client host port topic sensor"
