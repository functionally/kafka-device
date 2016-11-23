{-|
Module      :  Network.UI.Kafka.Types
Copyright   :  (c) 2016 Brian W Bush
License     :  MIT
Maintainer  :  Brian W Bush <consult@brianwbush.info>
Stability   :  Experimental
Portability :  Stable

Event types.
-}


{-# LANGUAGE DeriveGeneric    #-}
{-# LANGUAGE FlexibleContexts #-}


module Network.UI.Kafka.Types (
-- * Types
  Event(..)
, SpecialKey(..)
, Toggle(..)
, Modifiers(..)
, Button(..)
, ButtonState
, Hand(..)
, Finger(..)
) where


import Data.Aeson.Types (FromJSON, ToJSON)
import Data.Binary (Binary)
import Data.Serialize (Serialize)
import GHC.Generics (Generic)


-- | An event.
data Event =
    -- | A character from a keyboard.
    KeyEvent
    {
      key           :: Char                   -- ^ The character.
    , toggle        :: Maybe Toggle           -- ^ The state of the key.
    , modifiers     :: Maybe Modifiers        -- ^ Modifiers for the key.
    , mousePosition :: Maybe (Double, Double) -- ^ The position of the mouse pointer.
    }
  | -- | A special key from a keyboard.
    SpecialKeyEvent
    {
      specialKey    :: SpecialKey             -- ^ The special key.
    , toggle        :: Maybe Toggle           -- ^ The state of the key.
    , modifiers     :: Maybe Modifiers        -- ^ Modifiers for the key.
    , mousePosition :: Maybe (Double, Double) -- ^ The position of the mouse pointer.
    }
  | -- | A button press on a mouse.
    MouseEvent
    {
      button        :: ButtonState            -- ^ The state of the mouse button.
    , modifiers     :: Maybe Modifiers        -- ^ Modifiers on the keyboard.
    , mousePosition :: Maybe (Double, Double) -- ^ The position of the mouse pointer.
    }
  | -- | The press of of a button.
    ButtonEvent
    {
      button :: ButtonState -- ^ The state of the button.
    }
  | -- | The pressing of several buttons.
    ButtonsEvent
    {
      buttons :: [ButtonState] -- ^ The states of the buttons.
    }
  | -- | The movement of a mouse.
    PositionEvent
    {
      mousePosition :: Maybe (Double, Double) -- ^ The position of the mouse pointer.
    }
  | -- | Motion.
    MotionEvent
    {
      motionRightward :: Double -- ^ Motion rightward (+1) to leftward (-1).
    , motionUpward    :: Double -- ^ Motion upward (+1) to downward (-1).
    , motionBackward  :: Double -- ^ Motion backward (+1) to forward (-1).
    }
  | -- | Rotation.
    RotationEvent
    {
      rotationForward   :: Double -- ^ Rotation forward (+1) to backward (-1).
    , rotationClockwise :: Double -- ^ Rotation clockwise (+1) to counterclockwise (-1).
    , rotationRightward :: Double -- ^ Rotation rightward (+1) to leftward (-1).
    }
  | -- | Joystick position.
    JoystickEvent
    {
      joystickRightward :: Double        -- ^ Positioning rigthward (+1) to leftward (-1).
    , joystickForward   :: Double        -- ^ Positioning forward (+1) to backward (-1).
    , joystickUpward    :: Double        -- ^ Positioning upward (+1) to downward (-1).
    , buttons           :: [ButtonState] -- ^ The states of joystick buttons.
    }
  | -- | Moving a finger.
    FingerEvent
    {
      hand            :: Hand                     -- ^ The hand of the finger.
    , finger          :: Finger                   -- ^ The finger.
    , pointerPosition :: (Double, Double, Double) -- ^ The position of the finger.
    }
  | -- | Moving a pointer.
    PointerEvent
    {
      pointerPosition :: (Double, Double, Double) -- ^ The position of the pointer.
    }
  | -- | An analog value.
    AnalogEvent
    {
      axis        :: Int    -- ^ The axis for the value.
    , analogValue :: Double -- ^ The value, betwee +1 and -1.
    }
  | -- | An error.
    EventError
    {
      message :: String -- ^ The error message.
    }
    deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON Event

instance ToJSON Event

instance Binary Event

instance Serialize Event


-- | Keyboard modifiers.
data Modifiers =
  Modifiers
  {
    shiftModifier :: Bool -- ^ Whether the shift key is down.
  , ctrlModifier  :: Bool -- ^ Whether the control key is down.
  , altModifier   :: Bool -- ^ Whether the alt key is down.
  }
    deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON Modifiers

instance ToJSON Modifiers

instance Binary Modifiers

instance Serialize Modifiers


-- | A special key.
data SpecialKey = KeyF1 | KeyF2 | KeyF3 | KeyF4 | KeyF5 | KeyF6 | KeyF7 | KeyF8 | KeyF9 | KeyF10 | KeyF11 | KeyF12 | KeyLeft | KeyUp | KeyRight | KeyDown | KeyPageUp | KeyPageDown | KeyHome | KeyEnd | KeyInsert | KeyNumLock | KeyBegin | KeyDelete | KeyShiftL | KeyShiftR | KeyCtrlL | KeyCtrlR | KeyAltL | KeyAltR | KeyUnknown Int
  deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON SpecialKey

instance ToJSON SpecialKey

instance Binary SpecialKey

instance Serialize SpecialKey


-- | A button and its state.
type ButtonState = (Button, Toggle)


-- | A button.
data Button = LeftButton | MiddleButton | RightButton | WheelUp | WheelDown | IndexButton Int | LetterButton Char
  deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON Button

instance ToJSON Button

instance Binary Button

instance Serialize Button


-- | The state of a button.
data Toggle = Down | Up
  deriving (Bounded, Enum, Eq, Generic, Ord, Read, Show)

instance FromJSON Toggle

instance ToJSON Toggle

instance Binary Toggle

instance Serialize Toggle


-- | A hand.
data Hand = RightHand | LeftHand
  deriving (Bounded, Enum, Eq, Generic, Ord, Read, Show)

instance FromJSON Hand

instance ToJSON Hand

instance Binary Hand

instance Serialize Hand


-- | A finger.
data Finger = Thumb | IndexFinger | MiddleFinger | RingFinger | Pinky
  deriving (Bounded, Enum, Eq, Generic, Ord, Read, Show)

instance FromJSON Finger

instance ToJSON Finger

instance Binary Finger

instance Serialize Finger
