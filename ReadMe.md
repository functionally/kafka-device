UI device events via a Kafka message broker
===========================================


This package contains functions passing UI device events to topics on a [Kafka message broker](https://kafka.apache.org/).


Clients
-------

The simple Kafka client that produces events from the keyboard can be run, for example, as follows:

	cabal run kafka-device-keyboard -- keyboard-client localhost 9092 events keyboard

The simple Kafka client that consumes events can be run, for example, as follows:

	cabal run kafka-device -- consumer-client localhost 9092 events

See also

*   https://hackage.haskell.org/package/kafka-device-joystick/: events from Linux joysticks
*   https://hackage.haskell.org/package/kafka-device-glut/: events from GLUT-compatible devices
*   https://hackage.haskell.org/package/kafka-device-spacenav/: events from SpaceNavigator devices
*   https://hackage.haskell.org/package/kafka-device-leap/: events from Leap Motion devices
