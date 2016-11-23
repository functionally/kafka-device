{-|
Module      :  Main
Copyright   :  (c) 2016 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <consult@brianwbush.info>
Stability   :  Experimental
Portability :  Stable

Simple producver of keyboard events from standard input.
-}


{-# LANGUAGE OverloadedStrings #-}


module Main (
-- * Entry point
  main
) where


import Data.String (IsString(fromString))
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
              (fromString client)
              (fromString host, toEnum $ read port)
              (fromString topic)
              sensor
          result <- loop
          either print return result
      _ -> putStrLn "USAGE: kafka-device-keyboard client host port topic sensor"
