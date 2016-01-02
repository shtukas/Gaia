{-# LANGUAGE DeriveDataTypeable #-}

module Main where

import Control.Monad    (msum)

import Happstack.Server (dirs, path, nullConf, simpleHTTP, 
                         serveDirectory, Browsing(EnableBrowsing))
import Happstack.Server.Response as R

import Gaia.Types
import qualified Gaia.SearchEngine as GSE

alpha_search :: String -> SEStructure1
alpha_search pattern = SEStructure1 $ GSE.runQuery2 pattern

main :: IO ()
main = simpleHTTP nullConf $
    msum [   dirs "api/v0" $ ok $ toResponse "Use the Force!"
           , dirs "api/v1/search" $ do path ( \pattern -> ok ( toResponse $ alpha_search pattern ) )
           , serveDirectory EnableBrowsing ["index.html"] "/Lucille-E/Applications/Gaia/web-root"
         ]

-- currently runs at http://localhost:8000
-- TODO: remove root directory hardcoding

