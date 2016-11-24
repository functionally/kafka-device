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
data SpecialKey =
    -- | F1
    KeyF1
  | -- | F2
    KeyF2
  | -- | F3
    KeyF3
  | -- | F4
    KeyF4
  | -- | F5
    KeyF5
  | -- | F6
    KeyF6
  | -- | F7
    KeyF7
  | -- | F8
    KeyF8
  | -- | F9
    KeyF9
  | -- | F10
    KeyF10
  | -- | F11
    KeyF11
  | -- | F12
    KeyF12
  | -- | left arrow
    KeyLeft
  | -- | up arrow
    KeyUp
  | -- | right arrow
    KeyRight
  | -- | down arrow
    KeyDown
  | -- | page up
    KeyPageUp
  | -- | page down
    KeyPageDown
  | -- | home
    KeyHome
  | -- | end
    KeyEnd
  | -- | insert
    KeyInsert
  | -- | number lock
    KeyNumLock
  | -- | begin
    KeyBegin
  | -- | delete
    KeyDelete
  | -- | left shift
    KeyShiftL
  | -- | right shift
    KeyShiftR
  | -- | left control
    KeyCtrlL
  | -- | right control
    KeyCtrlR
  | -- | left alt
    KeyAltL
  | -- | right alt
    KeyAltR
  | -- | unknown, with a specified index
    KeyUnknown Int
  deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON SpecialKey

instance ToJSON SpecialKey

instance Binary SpecialKey

instance Serialize SpecialKey


-- | A button and its state.
type ButtonState = (Button, Toggle)


-- | A button.
data Button =
    -- | left mouse button
    LeftButton
  | -- |  middle mouse button
    MiddleButton
  | -- | right mouse button
    RightButton
  | -- | mouse wheel upward
    WheelUp
  | -- | mouse wheel downward
    WheelDown
  | -- | button specified by an index
    IndexButton Int
  | -- | button specified by a letter
    LetterButton Char
  deriving (Eq, Generic, Ord, Read, Show)

instance FromJSON Button

instance ToJSON Button

instance Binary Button

instance Serialize Button


-- | The state of a button.
data Toggle =
    -- | pressed down
    Down
  | -- | released and up
    Up
  deriving (Bounded, Enum, Eq, Generic, Ord, Read, Show)

instance FromJSON Toggle

instance ToJSON Toggle

instance Binary Toggle

instance Serialize Toggle


-- | A hand.
data Hand =
    -- | right hand
    RightHand
  | -- | left hand
    LeftHand
  deriving (Bounded, Enum, Eq, Generic, Ord, Read, Show)

instance FromJSON Hand

instance ToJSON Hand

instance Binary Hand

instance Serialize Hand


-- | A finger.
data Finger =
    -- | thumb
    Thumb
  | -- | first or index finger
    IndexFinger
  | -- | second or middle finger
    MiddleFinger
  | -- | third of ring finger
    RingFinger
  | -- | fourth finger or pinky
    Pinky
  deriving (Bounded, Enum, Eq, Generic, Ord, Read, Show)

instance FromJSON Finger

instance ToJSON Finger

instance Binary Finger

instance Serialize Finger
