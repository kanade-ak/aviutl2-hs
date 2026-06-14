{-|
Module      : AviUtl2.Logger
Description : AviUtl2本体のログ出力機構にアクセスするためのモジュールです。

汎用プラグインにはホストからログハンドルが渡されます。
このモジュールでは、その関数テーブル定義と、各ログレベルへ書き込むための
小さなラッパーを提供します。

文字列の整形やレベル管理はAviUtl2側が行うため、ここではワイド文字列を
そのまま渡す低水準APIとして設計しています。
-}
module AviUtl2.Logger
  ( LOG_HANDLE(..)
  , logMessage
  , logInfo
  , logWarn
  , logError
  , logVerbose
  ) where

import Foreign.Ptr (Ptr, FunPtr)
import Foreign.Storable (Storable(..))
import AviUtl2.Types (LPCWSTR)

-- | AviUtl2本体のログ出力関数群をまとめたハンドルです。
-- |
-- | 通常ログ、情報、警告、エラー、詳細ログの各出力先が入っています。
data LOG_HANDLE = LOG_HANDLE
  { lhLog     :: FunPtr (Ptr LOG_HANDLE -> LPCWSTR -> IO ())
  , lhInfo    :: FunPtr (Ptr LOG_HANDLE -> LPCWSTR -> IO ())
  , lhWarn    :: FunPtr (Ptr LOG_HANDLE -> LPCWSTR -> IO ())
  , lhError   :: FunPtr (Ptr LOG_HANDLE -> LPCWSTR -> IO ())
  , lhVerbose :: FunPtr (Ptr LOG_HANDLE -> LPCWSTR -> IO ())
  }

instance Storable LOG_HANDLE where
  sizeOf _ = 40
  alignment _ = 8
  peek ptr = LOG_HANDLE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
  poke ptr v = do
    pokeByteOff ptr 0 (lhLog v)
    pokeByteOff ptr 8 (lhInfo v)
    pokeByteOff ptr 16 (lhWarn v)
    pokeByteOff ptr 24 (lhError v)
    pokeByteOff ptr 32 (lhVerbose v)

foreign import ccall "dynamic"
  mkLogFunc :: FunPtr (Ptr LOG_HANDLE -> LPCWSTR -> IO ()) -> Ptr LOG_HANDLE -> LPCWSTR -> IO ()

-- | 通常のプラグインログを出力します。
-- |
-- | 特にレベル分けを行わない一般的なメッセージを記録したいときに使います。
logMessage :: Ptr LOG_HANDLE -> LPCWSTR -> IO ()
logMessage ptr msg = do
  h <- peek ptr
  mkLogFunc (lhLog h) ptr msg

-- | 情報レベルのログを出力します。
logInfo :: Ptr LOG_HANDLE -> LPCWSTR -> IO ()
logInfo ptr msg = do
  h <- peek ptr
  mkLogFunc (lhInfo h) ptr msg

-- | 警告レベルのログを出力します。
-- |
-- | 処理続行は可能だが想定外の状態を検知したときに向いています。
logWarn :: Ptr LOG_HANDLE -> LPCWSTR -> IO ()
logWarn ptr msg = do
  h <- peek ptr
  mkLogFunc (lhWarn h) ptr msg

-- | エラーレベルのログを出力します。
-- |
-- | 処理失敗や継続困難な状態の報告に使います。
logError :: Ptr LOG_HANDLE -> LPCWSTR -> IO ()
logError ptr msg = do
  h <- peek ptr
  mkLogFunc (lhError h) ptr msg

-- | 詳細デバッグ向けの冗長ログを出力します。
-- |
-- | トレース用途の細かな情報を残したい場合に使います。
logVerbose :: Ptr LOG_HANDLE -> LPCWSTR -> IO ()
logVerbose ptr msg = do
  h <- peek ptr
  mkLogFunc (lhVerbose h) ptr msg
