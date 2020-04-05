{-|
Module: TurboHaskell.AuthSupport.Authentication
Description: Authentication functions
Copyright: (c) digitally induced GmbH, 2020
-}
module TurboHaskell.AuthSupport.Authentication (verifyPassword, hashPassword, generateAuthenticationToken, Lockable (maxSignInAttemps)) where

import ClassyPrelude
import Data.String.Conversions (cs)
import qualified Crypto.PasswordStore
import qualified Test.RandomStrings
import GHC.Records

class Lockable entity where
    maxSignInAttemps :: entity -> Int

passwordStrength :: Int
passwordStrength = 17

-- | Creates a password hash
-- 
-- __Example:__
-- 
-- > action CreateUserAction = do
-- >     newRecord @NewUser
-- >         |> fill @'["passwordHash"]
-- >         |> validateField nonEmpty #passwordHash
-- >         |> ifValid \case
-- >             Left user -> ..
-- >             Right user -> do
-- >                 user <- get #passwordHash user |> cs |> liftIO . hashPassword
-- >                 user <- createRecord user
-- > 
hashPassword :: ByteString -> IO Text
hashPassword plainText = cs <$> Crypto.PasswordStore.makePassword plainText passwordStrength
{-# INLINE hashPassword #-}


class VerifiyPassword a where
    verifyPassword' :: a -> Text -> Bool

instance VerifiyPassword Text where
    verifyPassword' passwordHash plainText = Crypto.PasswordStore.verifyPassword (cs plainText) (cs passwordHash)

instance VerifiyPassword (Maybe Text) where
    verifyPassword' (Just passwordHash) plainText = verifyPassword' passwordHash plainText
    verifyPassword' Nothing _ = False

-- | Returns @True@ when a given non-hashed password matches the hashed password of the given user.
--
-- >>> user <- query @User |> filterWhere (#email, "hunter2@outlook.com") |> fetchOne
-- >>> verifyPassword user "hunter2"
-- True
verifyPassword :: (HasField "passwordHash" entity passwordField, VerifiyPassword passwordField) => entity -> Text -> Bool
verifyPassword entity plainText = verifyPassword' passwordHash plainText
    where
        passwordHash = getField @"passwordHash" entity
{-# INLINE verifyPassword #-}


-- | Generates a 32 character random string
--
-- >>> token <- generateAuthenticationToken
-- "11D3OAbUfL0P9KNJ09VcUfCO0S9RwI"
generateAuthenticationToken :: IO Text
generateAuthenticationToken = cs <$> Test.RandomStrings.randomWord Test.RandomStrings.randomASCII 32
{-# INLINE generateAuthenticationToken #-}