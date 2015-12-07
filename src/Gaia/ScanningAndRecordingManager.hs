{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Gaia.ScanningAndRecordingManager (
    getCurrentMerkleRootForFSScanRoot,
    generalScan
) where

import qualified Data.Aeson as A
    -- JSON library
    -- A.encode :: A.ToJSON a => a -> Char8.ByteString

import qualified Data.Text as T
    -- T.pack :: String -> T.Text

import qualified System.Directory as Dir
    -- doesDirectoryExist :: FilePath -> IO Bool
    -- getDirectoryContents :: FilePath -> IO [FilePath]

import           System.FilePath
    -- takeFileName :: FilePath -> FilePath

import           System.Posix

import qualified Data.ByteString.Lazy.Char8 as Char8
    -- Char8.pack :: [Char] -> Char8.ByteString
    -- Char8.readFile :: FilePath -> IO Char8.ByteString

import qualified Gaia.AesonObjectsUtils as GAOU

import qualified Gaia.FSRootsManagement as FSRM

import qualified PStorageServices.Xcache as X

import qualified Data.Maybe as M

import           Gaia.Types

-- ---------------------------------------------------------------

getLocationName :: LocationPath -> LocationPath
getLocationName = takeFileName

getFileSize :: FilePath -> IO FileOffset
getFileSize filepath = do
    stat <- getFileStatus filepath
    return (fileSize stat)

getFileContents :: FilePath -> IO Char8.ByteString
getFileContents = Char8.readFile

excludeDotFolders :: [FilePath] -> [FilePath]
excludeDotFolders = filter (\filename -> head filename /= '.' )

-- ---------------------------------------------------------------

locationToAesonJSONVAlueRecursivelyComputedaAndStored :: LocationPath -> IO A.Value
locationToAesonJSONVAlueRecursivelyComputedaAndStored location = do
    isFile      <- Dir.doesFileExist location
    isDirectory <- Dir.doesDirectoryExist location
    if isFile
        then filepathToAesonJSONValue ( location :: FilePath )
        else if isDirectory
            then folderpathToAesonJSONValue ( location :: FolderPath )
            else return A.Null

--{
--	"aion-type" : "file"
--	"version"   : 1
--	"name"      : String
--	"size"      : Integer
--	"hash"      : sha1-hash
--}

filepathToAesonJSONValue :: FilePath -> IO A.Value
filepathToAesonJSONValue filepath = do
    filesize <- getFileSize filepath
    filecontents <- getFileContents filepath
    return $ GAOU.makeAesonValueForFile ( getLocationName filepath ) ( fromIntegral filesize ) filecontents

--{
--	"aion-type" : "directory"
--	"version"   : 1
--	"name"      : String
--	"contents"  : [Aion-Hash]
--}

folderpathToAesonJSONValue :: FolderPath -> IO A.Value
folderpathToAesonJSONValue folderpath = do
    directoryContents <- Dir.getDirectoryContents folderpath
    aesonvalues <- mapM (\filename -> locationToAesonJSONVAlueRecursivelyComputedaAndStored $ folderpath ++ "/" ++ filename)
                       (excludeDotFolders directoryContents)
    caskeys <- mapM GAOU.commitAesonValueToCAS aesonvalues
    let aesonvalues2 = map (A.String . T.pack) caskeys
    return $ GAOU.makeAesonValueForDirectory (getLocationName folderpath) aesonvalues2

-- ---------------------------------------------------------------

locationExists :: LocationPath -> IO Bool
locationExists locationpath = do
    exists1 <- Dir.doesDirectoryExist locationpath
    exists2 <- Dir.doesFileExist locationpath
    return $ exists1 || exists2

computeMerkleRootForLocationRecursivelyComputedaAndStored :: LocationPath -> IO ( Maybe String )
computeMerkleRootForLocationRecursivelyComputedaAndStored locationpath = do
    exists <- locationExists locationpath
    if exists
        then do
            value <- locationToAesonJSONVAlueRecursivelyComputedaAndStored locationpath
            string <- GAOU.commitAesonValueToCAS value
            return $ Just string
        else
            return Nothing

commitMerkleRootForFSScanRoot :: String -> String -> IO ()
commitMerkleRootForFSScanRoot fsscanlocationpath merkleroot = do
    X.set (FSRM.xCacheStorageKeyForTheAionMerkleRootOfAFSRootScan fsscanlocationpath) ( Char8.pack merkleroot )

getCurrentMerkleRootForFSScanRoot :: String -> IO ( Maybe String )
getCurrentMerkleRootForFSScanRoot locationpath = do
    bytes <- X.get (FSRM.xCacheStorageKeyForTheAionMerkleRootOfAFSRootScan locationpath)
    case bytes of 
        Nothing     -> return $ Nothing 
        Just bytes' -> return $ Just ( Char8.unpack bytes' )


-- ---------------------------------------------------------------

generalScan :: IO ()
generalScan = do
    scanroots <- FSRM.getFSScanRoots
    _ <- sequence $ map (\scanroot -> 
                            do
                                s1 <- computeMerkleRootForLocationRecursivelyComputedaAndStored scanroot 
                                case s1 of 
                                    Nothing -> return ()
                                    Just s2 -> do
                                        putStrLn $ "location: " ++ scanroot
                                        putStrLn $ "merkle  : " ++ s2 
                                        commitMerkleRootForFSScanRoot scanroot s2
                         ) scanroots
    return ()

