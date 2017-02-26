{-|
Module      :  $Header$
Copyright   :  (c) 2016-17 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <consult@brianwbush.info>
Stability   :  Experimental
Portability :  Stable

Interpret user-interfaces events on Kafka topics.
-}



{-# LANGUAGE DeriveGeneric        #-}
{-# LANGUAGE OverloadedStrings    #-}
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
data Interpretation a =
  TrackInterpretation
  {
    kafka       :: TopicConnection      -- ^ How to connect to Kafka.
  , sensor      :: Sensor               -- ^ The name of the sensor.
  , path        :: FilePath             -- ^ The path the the device.
  , xAxis       :: AxisInterpretation a -- ^ Interpretation for the x-axis.
  , yAxis       :: AxisInterpretation a -- ^ Interpretation for the y-axis.
  , zAxis       :: AxisInterpretation a -- ^ Interpretation for the z-axis.
  , phiAxis     :: AxisInterpretation a -- ^ Interpretation for the Euler angle about the x-axis.
  , thetaAxis   :: AxisInterpretation a -- ^ Interpretation for the Euler angle about the y-axis.
  , psiAxis     :: AxisInterpretation a -- ^ Interpretation for the Euler angle about the z-axis.
  , location    :: V3 a                 -- ^ The initial location, (x, y, z).
  , orientation :: V3 a                 -- ^ The initial orientation, (phi, theta, psi).
  , flying      :: Bool                 -- ^ Whether to interpret displacements as being relative to the current orientation.
  , resetButton :: Maybe Int            -- ^ The button number for resetting the location and orientation to their initial values.
  }
    deriving (Eq, Generic, Read, Show)

instance FromJSON a => FromJSON (Interpretation a)

instance ToJSON a => ToJSON (Interpretation a)


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
translate :: (Conjugate a, Epsilon a, Num a, Ord a, RealFloat a)
          => MVar (State a)    -- ^ Reference to the current location and orientation.
          -> AnalogHandler a b -- ^ How to handle raw analog events.
          -> ButtonHandler a b -- ^ How to handle raw button events.
          -> Interpretation a  -- ^ The interpretation.
          -> b                 -- ^ A raw event.
          -> IO [Event]        -- ^ The corresponding events for Kafka.
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
      (location1@(V3 x y z), orientation1@(Quaternion q0 (V3 qx qy qz))) =
        case (buttonHandler event, analogHandler event) of
          (Just (number, pressed), _) -> if pressed && Just number == resetButton
                                           then (location, eulerToQuaternion orientation)
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
                                           , eulerToQuaternion euler
                                             * orientation0
                                           )
          (_, _)                      -> (location0, orientation0)
      [x', y', z', q0', qx', qy', qz'] = realToFrac <$> [x, y, z, q0, qx, qy, qz]
    unless (location0 == location1 && orientation0 == orientation1)
      . void
      $ swapMVar state (location1, orientation1)
    return
      . (if location0    /= location1    then (LocationEvent    (     x' , y' , z' ) :) else id)
      . (if orientation0 /= orientation1 then (OrientationEvent (q0', qx', qy', qz') :) else id)
      $ case buttonHandler event of
          Just (number, pressed) -> [ButtonEvent (IndexButton number, if pressed then Down else Up)]
          Nothing                -> []

-- | Convert from Euler angles to a quaternion.
eulerToQuaternion :: (Epsilon a, Num a, RealFloat a) => V3 a -> Quaternion a
eulerToQuaternion (V3 phi theta psi) =
  let
    [ex, ey, ez] = basis
  in
    ez `axisAngle` psi * ey `axisAngle` theta * ex `axisAngle` phi


-- | Location and orientation.
type State a = (V3 a, Quaternion a)


-- | How to handle raw analog events.
type AnalogHandler a b = b -> Maybe (Int, a)


-- | How to handle raw button events.
type ButtonHandler a b = b -> Maybe (Int, Bool)


-- | Repeatedly interpret events.
interpretationLoop :: (Conjugate a, Epsilon a, Num a, Ord a, RealFloat a)
                   => AnalogHandler a b -- ^ How to handle raw analog events.
                   -> ButtonHandler a b -- ^ How to handle raw button events.
                   -> Interpretation a  -- ^ The interpretation.
                   -> IO b              -- ^ Action for getting the next raw event.
                   -> IO (ExitAction, LoopAction) -- ^ Action to create the exit and loop actions.
interpretationLoop analogHandler buttonHandler interpretation@TrackInterpretation{..} action =
  do
    state <- newMVar (location, eulerToQuaternion orientation)
    producerLoop kafka sensor
      $ translate state analogHandler buttonHandler interpretation
      =<< action
