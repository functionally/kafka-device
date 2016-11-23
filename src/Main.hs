{-|
Module      :  Main
Copyright   :  (c) 2016 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <consult@brianwbush.info>
Stability   :  Experimental
Portability :  Stable

Simple consumer that echos UI events to the console.
-}


{-# LANGUAGE OverloadedStrings #-}


module Main (
-- * Entry point
  main
) where


import Data.String (IsString(fromString))
import Network.UI.Kafka (consumerLoop)
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
              (fromString client)
              (fromString host, toEnum $ read port)
              (fromString topic)
              $ curry print
          result <- loop
          either print return result
      _ -> putStrLn "USAGE: kafka-keyboard client host port topic"
