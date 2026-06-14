module PluginSupport
  ( requiredVersion
  , newWideString
  , newUtf8String
  ) where

import Foreign.C.String (newCWString)
import GHC.Foreign (newCString)
import GHC.IO.Encoding (utf8)
import AviUtl2.Types (LPCWSTR, LPCSTR, DWORD)

requiredVersion :: DWORD
requiredVersion = 2003300

newWideString :: String -> IO LPCWSTR
newWideString = newCWString

newUtf8String :: String -> IO LPCSTR
newUtf8String = newCString utf8
