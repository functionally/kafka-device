{-# LANGUAGE OverloadedStrings #-}


module Main (
  main
) where


import Data.String (IsString(fromString))
import Network.UI.Kafka.Keyboard (keyboardLoop)
import System.Environment (getArgs)


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
              (fromString client)
              (fromString host, toEnum $ read port)
              (fromString topic)
              sensor
          result <- loop
          either print return result
      _ -> putStrLn "USAGE: kafka-device-keyboard client host port topic senosr"
