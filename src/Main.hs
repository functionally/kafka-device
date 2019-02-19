{-|
Module      :  $Headers
Copyright   :  (c) 2016-19 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <code@functionally.io>
Stability   :  Production
Portability :  Portable

Simple consumer that echos UI events from a Kafka topic to the console.
-}


module Main (
-- * Entry point
  main
) where


import Network.UI.Kafka (TopicConnection(TopicConnection), consumerLoop)
import System.Environment (getArgs)


-- | The main action.
main :: IO ()
main =
  do
    args <- getArgs
    case args of
      [client, host, port, topic] ->
        do
          putStrLn $ "Kafka client:  " ++ client
          putStrLn $ "Kafka address: (" ++ host ++ "," ++ port ++ ")"
          putStrLn $ "Kafka topic:   " ++ topic
          (_, loop) <-
            consumerLoop
              (TopicConnection client (host, read port) topic)
              $ curry print
          result <- loop
          either print return result
      _ -> putStrLn "USAGE: kafka-device client host port topic"
