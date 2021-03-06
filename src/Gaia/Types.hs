module Gaia.Types where

import qualified Data.Aeson as A
import qualified Data.ByteString.Char8 as B1
import qualified Data.ByteString.Lazy.Char8 as Char8
import qualified Data.Text as T
import           Happstack.Server.Response as R
import qualified Text.JSON.Generic as TJG

-- -----------------------------------------------------------------------------
-- General File System

type FolderPath   = String
type LocationPath = String

-- -----------------------------------------------------------------------------
-- Gaia Files

type GaiaFileDirectiveBody = String
data GaiaFileDirectiveTag  = GaiaFileTag        -- | NewTag1 | NewTag2 ...
                     deriving (Eq, Show)

data GaiaFileDirective = GaiaFileDirective GaiaFileDirectiveTag GaiaFileDirectiveBody
                 deriving (Eq)

instance Show GaiaFileDirective where
  show (GaiaFileDirective t b) = show t ++ " -> " ++ "\"" ++ b ++ "\""

-- -----------------------------------------------------------------------------
-- Aion Points, AionPointAbstractionGeneric

{-

    ExtendedJSONString carries a JSON string and its CAS String.

    The motivation is that we want the CAS string to be then carried by Aeson Values
    and then by AionPointAbstractionGenerics
    and then to appear as Search Engine result metadata.

-}

data ExtendedJSONString = ExtendedJSONString String String deriving (Show) -- first is the json string and second is the cas key
data ExtendedAesonValue = ExtendedAesonValue A.Value String deriving (Show) -- string is the cas key

{-
	AionPointAbstractionGeneric are "projections" of Aeson Values.
	They are used to make the code of the search engine independent from Aeson. 
-}

-- See http://stackoverflow.com/questions/24352280/multiple-declarations-of-x
-- for why I use "unnatural" field names.

data AionPointAbstractionFile = AionPointAbstractionFile { name1   :: String
                                                         , size1   :: Integer
                                                         , hash1   :: String 
                                                         --, caskey1 :: String 
                                                         } deriving (Show)

data AionPointAbstractionDirectory = AionPointAbstractionDirectory { name2     :: String
                                                                   , contents2 :: [String]
                                                                   --, caskey2   :: String 
                                                                   } deriving (Show)

data AionPointAbstractionGeneric = AionPointAbstractionGenericFromFile AionPointAbstractionFile 
                                 | AionPointAbstractionGenericFromDirectory AionPointAbstractionDirectory 
                                   deriving (Show)

{-

    ExtendedAionPointAbstractionGeneric also carries the cas key

-}

data ExtendedAionPointAbstractionGeneric = ExtendedAionPointAbstractionGeneric AionPointAbstractionGeneric String deriving (Show) -- string is the cas key 

-- -----------------------------------------------------------------------------
-- FileSystemSearchEngine
{-
	SEStructure1 encapsulates answers from the Search Engine. 
	It is used because we needed to make them instances of Happstack's ToMessage classtype.
-}

newtype SEStructure1 = SEStructure1 [String]

instance R.ToMessage SEStructure1 where
    toContentType _ = B1.pack "application/json"
    toMessage (SEStructure1 x) = (Char8.pack . TJG.encodeJSON) x

-- -----------------------------------------------------------------------------
-- FileSystemSearchEngine

{-
    SEStructure2 is the second version of search engine return set
    A basic element is a location together with its CAS key.
    This because we need to send the aion point cas key to the web client.
-}
data SEAtom = SEAtom String String deriving (Show) -- first is the location and second is the cas key
newtype SEStructure2 = SEStructure2 [SEAtom]

instance A.ToJSON SEAtom where
    toJSON (SEAtom location caskey) = A.object [ (T.pack "location") A..= (A.String $ T.pack location)
                                               , (T.pack "caskey")   A..= (A.String $ T.pack caskey)
                                               ]

instance A.ToJSON SEStructure2 where
    toJSON (SEStructure2 list) = A.toJSON list

instance R.ToMessage SEStructure2 where
    toContentType _ = B1.pack "application/json"
    toMessage (SEStructure2 x) = (A.encode . A.toJSON) x

-- -----------------------------------------------------------------------------
-- DataWE (Data with Extension)
{-
	Data with extension is the what we retrieve from disk when the web client wants to see a AION point
-} 

data DataWE = DataWE Char8.ByteString String -- first argument is the binary data, and second is the file extension

instance R.ToMessage DataWE where
    toContentType _ = B1.pack "application/octet-stream"
    toMessage (DataWE bytestring _) = bytestring

