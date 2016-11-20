{-# LANGUAGE OverloadedStrings #-}


module Main (
  main
) where


import Data.String (IsString(fromString))
import Network.UI.Kafka (consumerLoop)
import System.Environment (getArgs)


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
              (fromString client)
              (fromString host, toEnum $ read port)
              (fromString topic)
              $ curry print
          result <- loop
          either print return result
      _ -> putStrLn "USAGE: kafka-keyboard client host port topic"
