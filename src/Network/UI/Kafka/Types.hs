{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}


module Network.UI.Kafka.Types (
  Event(..)
, SpecialKey(..)
, Toggle(..)
, Modifiers(..)
, Button(..)
) where


import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Binary (Binary)
import Data.Serialize (Serialize)
import GHC.Generics (Generic)


data Event =
    KeyEvent
    {
      key           :: Char
    , toggle        :: Maybe Toggle
    , modifiers     :: Maybe Modifiers
    , mousePosition :: Maybe (Double, Double)
    }
  | SpecialKeyEvent
    {
      specialKey    :: SpecialKey
    , toggle        :: Maybe Toggle
    , modifiers     :: Maybe Modifiers
    , mousePosition :: Maybe (Double, Double)
    }
  | MouseEvent
    {
      button        :: ButtonState
    , mousePosition :: Maybe (Double, Double)
    , modifiers     :: Maybe Modifiers
    }
  | ButtonEvent
    {
      button      :: ButtonState
    }
  | ButtonsEvent
    {
      buttons :: [ButtonState]
    }
  | PositionEvent
    {
      mousePosition :: Maybe (Double, Double)
    }
  | MotionEvent
    {
      motionRightward :: Double
    , motionUpward    :: Double
    , motionBackward  :: Double
    }
  | RotationEvent
    {
      rotationForward   :: Double
    , rotationClockwise :: Double
    , rotationRightward :: Double
    }
  | JoystickEvent
    {
      joystickRightward :: Double
    , joystickForward   :: Double
    , joystickUpward    :: Double
    , buttons           :: [ButtonState]
    }
    deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON Event

instance ToJSON Event

instance Binary Event

instance Serialize Event


data Modifiers =
  Modifiers
  {
    shiftModifier :: Bool
  , ctrlModifier  :: Bool
  , altModifier   :: Bool
  }
    deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON Modifiers

instance ToJSON Modifiers

instance Binary Modifiers

instance Serialize Modifiers


data SpecialKey = KeyF1 | KeyF2 | KeyF3 | KeyF4 | KeyF5 | KeyF6 | KeyF7 | KeyF8 | KeyF9 | KeyF10 | KeyF11 | KeyF12 | KeyLeft | KeyUp | KeyRight | KeyDown | KeyPageUp | KeyPageDown | KeyHome | KeyEnd | KeyInsert | KeyNumLock | KeyBegin | KeyDelete | KeyShiftL | KeyShiftR | KeyCtrlL | KeyCtrlR | KeyAltL | KeyAltR | KeyUnknown Int
  deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON SpecialKey

instance ToJSON SpecialKey

instance Binary SpecialKey

instance Serialize SpecialKey


type ButtonState = (Button, Toggle)


data Button = LeftButton | MiddleButton | RightButton | WheelUp | WheelDown | IndexButton Int | LetterButton Char
  deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON Button

instance ToJSON Button

instance Binary Button

instance Serialize Button


data Toggle = Down | Up
  deriving (Bounded, Enum, Eq, Generic, Ord, Read, Show)

instance FromJSON Toggle

instance ToJSON Toggle

instance Binary Toggle

instance Serialize Toggle
