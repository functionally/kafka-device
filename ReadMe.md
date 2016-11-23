UI device events via a Kafka message broker
===========================================


This package contains functions passive UI device events to topics on a Kafka message broker.


The simple Kafka client that produces events from the keyboard can be run, for example, as follows:
	cabal run kafka-device-keyboard -- keyboard-client localhost 9092 events keyboard

The simple Kafka clietn that consumes events can be run, for example, as follows:
	cabal run kafka-device -- consumer-client localhost 9092 events
