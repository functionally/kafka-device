{-|
Module      :  $Headers
Copyright   :  (c) 2016-19 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <code@functionally.io>
Stability   :  Production
Portability :  Portable

Interpret user-interfaces events on Kafka topics.
-}


{-# LANGUAGE DeriveGeneric        #-}
{-# LANGUAGE RecordWildCards      #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}


module Network.UI.Kafka.Interpretation (
-- * Types
  Interpretation(..)
, AxisInterpretation(..)
, AnalogHandler
, ButtonHandler
-- * Event handling
, interpretationLoop
) where


import Control.Concurrent.MVar (MVar, newMVar, readMVar, swapMVar)
import Control.Monad (unless, void)
import Data.Aeson.Types (FromJSON, ToJSON)
import GHC.Generics (Generic)
import Linear.Conjugate (Conjugate)
import Linear.Epsilon (Epsilon)
import Linear.Quaternion (Quaternion(..), axisAngle, rotate)
import Linear.V3 (V3(..))
import Linear.Vector ((^+^), basis)
import Network.UI.Kafka (ExitAction, LoopAction, Sensor, TopicConnection, producerLoop)
import Network.UI.Kafka.Types (Button(..), Event(ButtonEvent, LocationEvent, OrientationEvent), Toggle(..))


instance FromJSON a => FromJSON (V3 a)

instance ToJSON a => ToJSON (V3 a)


instance FromJSON a => FromJSON (Quaternion a)

instance ToJSON a => ToJSON (Quaternion a)


-- | Instructions for interpreting user-interface events from Kafka.
data Interpretation a b =
  TrackInterpretation
  {
    kafka       :: TopicConnection      -- ^ How to connect to Kafka.
  , sensor      :: Sensor               -- ^ The name of the sensor.
  , device      :: a                    -- ^ The device.
  , xAxis       :: AxisInterpretation b -- ^ Interpretation for the x-axis.
  , yAxis       :: AxisInterpretation b -- ^ Interpretation for the y-axis.
  , zAxis       :: AxisInterpretation b -- ^ Interpretation for the z-axis.
  , phiAxis     :: AxisInterpretation b -- ^ Interpretation for the Euler angle about the x-axis.
  , thetaAxis   :: AxisInterpretation b -- ^ Interpretation for the Euler angle about the y-axis.
  , psiAxis     :: AxisInterpretation b -- ^ Interpretation for the Euler angle about the z-axis.
  , location    :: V3 b                 -- ^ The initial location, (x, y, z).
  , orientation :: V3 b                 -- ^ The initial orientation, (phi, theta, psi).
  , flying      :: Bool                 -- ^ Whether to interpret displacements as being relative to the current orientation.
  , resetButton :: Maybe Int            -- ^ The button number for resetting the location and orientation to their initial values.
  }
    deriving (Eq, Generic, Read, Show)

instance (FromJSON a, FromJSON b) => FromJSON (Interpretation a b)

instance (ToJSON a, ToJSON b) => ToJSON (Interpretation a b)


-- | Instructions for interpreting an axis.
data AxisInterpretation a =
  AxisInterpretation
  {
    axisNumber :: Int     -- ^ The axis number.
  , threshold  :: Maybe a -- ^ The threshold for forwarding events.
  , increment  :: a       -- ^ How much to increment the axis per unit of change.
  , lowerBound :: Maybe a -- ^ The minimum value for the axis position.
  , upperBound :: Maybe a -- ^ The maximum value for the axis position.
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON a => FromJSON (AxisInterpretation a)

instance ToJSON a => ToJSON (AxisInterpretation a)


-- | Translate a SpaceNavigator event on Linux into events for Kafka.
translate :: (Conjugate b, Epsilon b, Num b, Ord b, RealFloat b)
          => MVar (State b)     -- ^ Reference to the current location and orientation.
          -> AnalogHandler b c  -- ^ How to handle raw analog events.
          -> ButtonHandler b c  -- ^ How to handle raw button events.
          -> Interpretation a b -- ^ The interpretation.
          -> c                  -- ^ A raw event.
          -> IO [Event]         -- ^ The corresponding events for Kafka.
translate state analogHandler buttonHandler TrackInterpretation{..} event =
  do
    (location0, orientation0) <- readMVar state
    let
      adjust number setting AxisInterpretation{..} =
        if number == axisNumber && maybe True (abs setting >) threshold
          then setting * increment
          else 0
      clamp AxisInterpretation{..} =
          maybe id ((maximum .) . (. return) . (:)) lowerBound
        . maybe id ((minimum .) . (. return) . (:)) upperBound
      (location1, orientation1) =
        case (buttonHandler event, analogHandler event) of
          (Just (number, pressed), _) -> if pressed && Just number == resetButton
                                           then (location, fromEuler orientation)
                                           else (location0, orientation0)
          (_, Just (number, setting)) -> let
                                           euler = adjust number setting <$> V3 phiAxis thetaAxis psiAxis
                                           axes = V3 xAxis yAxis zAxis
                                           delta = adjust number setting <$> axes
                                         in
                                           (
                                             clamp
                                               <$> axes
                                               <*> location0
                                               ^+^ (if flying then (orientation0 `rotate`) else id) delta
                                           , fromEuler euler
                                             * orientation0
                                           )
          (_, _)                      -> (location0, orientation0)
    unless (location0 == location1 && orientation0 == orientation1)
      . void
      $ swapMVar state (location1, orientation1)
    return
      . (if location0    /= location1    then (fromV3 location1            :) else id)
      . (if orientation0 /= orientation1 then (fromQuaternion orientation1 :) else id)
      $ case buttonHandler event of
          Just (number, pressed) -> [ButtonEvent (IndexButton number, if pressed then Down else Up)]
          Nothing                -> []

-- | Convert from Euler angles to a quaternion.
fromEuler :: (Epsilon a, Num a, RealFloat a) => V3 a -> Quaternion a
fromEuler (V3 phi theta psi) =
  let
    [ex, ey, ez] = basis
  in
    ez `axisAngle` psi * ey `axisAngle` theta * ex `axisAngle` phi


-- | Convert from 'V3' to 'Event'.
fromV3 :: Real a => V3 a -> Event
fromV3 (V3 x y z) = LocationEvent (realToFrac x, realToFrac y, realToFrac z)


-- | Convert from 'Quaternion' to 'Event'.
fromQuaternion :: Real a => Quaternion a -> Event
fromQuaternion (Quaternion w (V3 x y z)) = OrientationEvent (realToFrac w, realToFrac x, realToFrac y, realToFrac z)


-- | Convert from degrees to radians.
fromDegrees :: (Floating a, Num a) => a -> a
fromDegrees = (* pi) . (/ 180)


-- | Location and orientation.
type State a = (V3 a, Quaternion a)


-- | How to handle raw analog events.
type AnalogHandler a b =  b              -- ^ The raw event.
                       -> Maybe (Int, a) -- ^ The axis number and value.


-- | How to handle raw button events.
type ButtonHandler a b =  b                 -- ^ The raw event.
                       -> Maybe (Int, Bool) -- ^ The button number and whether the button is depressed.


-- | Repeatedly interpret events.
interpretationLoop :: (Conjugate b, Epsilon b, Num b, Ord b, RealFloat b)
                   => AnalogHandler b c           -- ^ How to handle raw analog events.
                   -> ButtonHandler b c           -- ^ How to handle raw button events.
                   -> Interpretation a b          -- ^ The interpretation.
                   -> IO c                        -- ^ Action for getting the next raw event.
                   -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
interpretationLoop analogHandler buttonHandler interpretation@TrackInterpretation{..} action =
  do
    first <- newMVar True
    state <- newMVar (location, fromEuler $ fromDegrees <$> orientation)
    producerLoop kafka sensor
      $ do
        isFirst <- readMVar first
        if isFirst
          then swapMVar first False >> return [fromV3 location, fromQuaternion $ fromEuler $ fromDegrees <$> orientation]
          else action >>= translate state analogHandler buttonHandler interpretation
