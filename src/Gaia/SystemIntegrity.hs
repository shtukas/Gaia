module Gaia.SystemIntegrity where

import qualified Data.Aeson as A
import qualified Gaia.AesonObjectsUtils as GAOU

-- This function checks the Aion Tree below a CAS Key
aionTreeFsckCASKey :: String -> IO Bool
aionTreeFsckCASKey caskey = do
    string' <- GAOU.getAesonJSONStringForCASKey caskey
    case string' of 
        Nothing     -> return False
        Just string -> do
            let aesonValue' = GAOU.convertJSONStringIntoAesonValue string
            case aesonValue' of
                Nothing         -> return False
                Just aesonValue -> aionTreeFsckAesonValue aesonValue
            

-- This function checks the Aion Tree below a Aeson Value
aionTreeFsckAesonValue :: A.Value -> IO Bool
aionTreeFsckAesonValue aesonValue = do
    if GAOU.aesonValueIsFile aesonValue
        then do
            let gaiaProjection = GAOU.aesonValueForFileGaiaProjection aesonValue
            aionTreeFsckFileGaiaProjection gaiaProjection
        else do 
            let gaiaProjection = GAOU.aesonValueForDirectoryGaiaProjection aesonValue
            aionTreeFsckDirectoryGaiaProjection gaiaProjection

-- This function checks the Aion tree below a file trace
aionTreeFsckFileGaiaProjection :: ( String, Integer, String ) -> IO Bool -- ( filename, filesize, sha1-shah ) -> IO Bool
aionTreeFsckFileGaiaProjection gaiaProjection = do
    return True

-- This function checks the Aion tree below 
aionTreeFsckDirectoryGaiaProjection :: ( String, [String] ) -> IO Bool -- ( String, [String] ) -> IO Bool
aionTreeFsckDirectoryGaiaProjection gaiaProjection = do
    let caskeys = snd gaiaProjection
    let bools1 = map (\key -> aionTreeFsckCASKey key ) caskeys -- [ IO Bool ]
    let bools2 = sequence bools1 -- IO [ Bool ]
    bools3 <- bools2 -- [ Bool ]
    return $ all (\b -> b) bools3 -- Funny that it has to be done that way




