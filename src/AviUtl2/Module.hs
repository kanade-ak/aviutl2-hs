{-|
Module      : AviUtl2.Module
Description : AviUtl2のスクリプトモジュール向けABIバインディングです。

スクリプトモジュールは、ホストとの間で緩く型付けされた引数や戻り値を
やり取りします。このモジュールでは、引数読取、結果返却、エラー報告のための
コールバック群を、C SDKに近い形で公開しています。

値は整数・浮動小数・文字列・配列・テーブル・バイナリなどに分かれていますが、
すべて低水準ポインタベースのやり取りです。配列長やキー配列の整合性は
呼び出し側で保証してください。
-}
module AviUtl2.Module
  ( SCRIPT_MODULE_PARAM(..)
  , SCRIPT_MODULE_FUNCTION(..)
  , SCRIPT_MODULE_TABLE(..)
  , getParamNum
  , getParamInt
  , getParamDouble
  , getParamString
  , getParamData
  , getParamTableInt
  , getParamTableDouble
  , getParamTableString
  , getParamArrayNum
  , getParamArrayInt
  , getParamArrayDouble
  , getParamArrayString
  , pushResultInt
  , pushResultDouble
  , pushResultString
  , pushResultData
  , pushResultTableInt
  , pushResultTableDouble
  , pushResultTableString
  , pushResultArrayInt
  , pushResultArrayDouble
  , pushResultArrayString
  , setError
  , getParamBoolean
  , pushResultBoolean
  , getParamTableBoolean
  , pushResultArrayBoolean
  , pushResultTableBoolean
  , getScriptModuleEdit
  , pushResultFunction
  , pushResultMetaTable
  , getScriptModuleUserdata
  ) where

import Foreign.C.Types (CInt(..), CDouble(..), CBool(..))
import Foreign.Ptr (Ptr, FunPtr)
import Foreign.Storable (Storable(..))
import AviUtl2.Edit (EDIT_SECTION)
import AviUtl2.Types (LPCWSTR, LPCSTR, BOOL_)

-- | スクリプト引数の読取と戻り値の返却を行う関数テーブルです。
-- |
-- | 各関数は、現在呼び出されているスクリプト関数の実引数列に対して
-- | インデックスやキーを指定して値を取得したり、結果を順次積み上げたりします。
data SCRIPT_MODULE_PARAM = SCRIPT_MODULE_PARAM
  { smpGetParamNum            :: FunPtr (IO CInt)
  , smpGetParamInt            :: FunPtr (CInt -> IO CInt)
  , smpGetParamDouble         :: FunPtr (CInt -> IO CDouble)
  , smpGetParamString         :: FunPtr (CInt -> IO LPCSTR)
  , smpGetParamData           :: FunPtr (CInt -> IO (Ptr ()))
  , smpGetParamTableInt       :: FunPtr (CInt -> LPCSTR -> IO CInt)
  , smpGetParamTableDouble    :: FunPtr (CInt -> LPCSTR -> IO CDouble)
  , smpGetParamTableString    :: FunPtr (CInt -> LPCSTR -> IO LPCSTR)
  , smpGetParamArrayNum       :: FunPtr (CInt -> IO CInt)
  , smpGetParamArrayInt       :: FunPtr (CInt -> CInt -> IO CInt)
  , smpGetParamArrayDouble    :: FunPtr (CInt -> CInt -> IO CDouble)
  , smpGetParamArrayString    :: FunPtr (CInt -> CInt -> IO LPCSTR)
  , smpPushResultInt          :: FunPtr (CInt -> IO ())
  , smpPushResultDouble       :: FunPtr (CDouble -> IO ())
  , smpPushResultString      :: FunPtr (LPCSTR -> IO ())
  , smpPushResultData         :: FunPtr (Ptr () -> IO ())
  , smpPushResultTableInt    :: FunPtr (Ptr LPCSTR -> Ptr CInt -> CInt -> IO ())
  , smpPushResultTableDouble :: FunPtr (Ptr LPCSTR -> Ptr CDouble -> CInt -> IO ())
  , smpPushResultTableString :: FunPtr (Ptr LPCSTR -> Ptr LPCSTR -> CInt -> IO ())
  , smpPushResultArrayInt    :: FunPtr (Ptr CInt -> CInt -> IO ())
  , smpPushResultArrayDouble :: FunPtr (Ptr CDouble -> CInt -> IO ())
  , smpPushResultArrayString :: FunPtr (Ptr LPCSTR -> CInt -> IO ())
  , smpSetError               :: FunPtr (LPCSTR -> IO ())
  , smpGetParamBoolean        :: FunPtr (CInt -> IO BOOL_)
  , smpPushResultBoolean      :: FunPtr (BOOL_ -> IO ())
  , smpGetParamTableBoolean   :: FunPtr (CInt -> LPCSTR -> IO BOOL_)
  , smpPushResultArrayBoolean :: FunPtr (Ptr BOOL_ -> CInt -> IO ())
  , smpPushResultTableBoolean :: FunPtr (Ptr LPCSTR -> Ptr BOOL_ -> CInt -> IO ())
  , smpEdit                   :: Ptr EDIT_SECTION
  , smpPushResultFunction     :: FunPtr (FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> Ptr () -> IO ())
  , smpPushResultMetaTable    :: FunPtr (FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> Ptr () -> IO ())
  , smpUserdata               :: Ptr ()
  }

instance Storable SCRIPT_MODULE_PARAM where
  sizeOf _ = 32 * 8
  alignment _ = 8
  peek ptr = SCRIPT_MODULE_PARAM
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
    <*> peekByteOff ptr 56
    <*> peekByteOff ptr 64
    <*> peekByteOff ptr 72
    <*> peekByteOff ptr 80
    <*> peekByteOff ptr 88
    <*> peekByteOff ptr 96
    <*> peekByteOff ptr 104
    <*> peekByteOff ptr 112
    <*> peekByteOff ptr 120
    <*> peekByteOff ptr 128
    <*> peekByteOff ptr 136
    <*> peekByteOff ptr 144
    <*> peekByteOff ptr 152
    <*> peekByteOff ptr 160
    <*> peekByteOff ptr 168
    <*> peekByteOff ptr 176
    <*> peekByteOff ptr 184
    <*> peekByteOff ptr 192
    <*> peekByteOff ptr 200
    <*> peekByteOff ptr 208
    <*> peekByteOff ptr 216
    <*> peekByteOff ptr 224
    <*> peekByteOff ptr 232
    <*> peekByteOff ptr 240
    <*> peekByteOff ptr 248
  poke ptr v = do
    pokeByteOff ptr 0 (smpGetParamNum v)
    pokeByteOff ptr 8 (smpGetParamInt v)
    pokeByteOff ptr 16 (smpGetParamDouble v)
    pokeByteOff ptr 24 (smpGetParamString v)
    pokeByteOff ptr 32 (smpGetParamData v)
    pokeByteOff ptr 40 (smpGetParamTableInt v)
    pokeByteOff ptr 48 (smpGetParamTableDouble v)
    pokeByteOff ptr 56 (smpGetParamTableString v)
    pokeByteOff ptr 64 (smpGetParamArrayNum v)
    pokeByteOff ptr 72 (smpGetParamArrayInt v)
    pokeByteOff ptr 80 (smpGetParamArrayDouble v)
    pokeByteOff ptr 88 (smpGetParamArrayString v)
    pokeByteOff ptr 96 (smpPushResultInt v)
    pokeByteOff ptr 104 (smpPushResultDouble v)
    pokeByteOff ptr 112 (smpPushResultString v)
    pokeByteOff ptr 120 (smpPushResultData v)
    pokeByteOff ptr 128 (smpPushResultTableInt v)
    pokeByteOff ptr 136 (smpPushResultTableDouble v)
    pokeByteOff ptr 144 (smpPushResultTableString v)
    pokeByteOff ptr 152 (smpPushResultArrayInt v)
    pokeByteOff ptr 160 (smpPushResultArrayDouble v)
    pokeByteOff ptr 168 (smpPushResultArrayString v)
    pokeByteOff ptr 176 (smpSetError v)
    pokeByteOff ptr 184 (smpGetParamBoolean v)
    pokeByteOff ptr 192 (smpPushResultBoolean v)
    pokeByteOff ptr 200 (smpGetParamTableBoolean v)
    pokeByteOff ptr 208 (smpPushResultArrayBoolean v)
    pokeByteOff ptr 216 (smpPushResultTableBoolean v)
    pokeByteOff ptr 224 (smpEdit v)
    pokeByteOff ptr 232 (smpPushResultFunction v)
    pokeByteOff ptr 240 (smpPushResultMetaTable v)
    pokeByteOff ptr 248 (smpUserdata v)

-- | スクリプトモジュールが公開する1個の関数定義です。
-- |
-- | 名前と実装コールバックの組で構成され、複数個を配列として登録します。
data SCRIPT_MODULE_FUNCTION = SCRIPT_MODULE_FUNCTION
  { smfName :: LPCWSTR
  , smfFunc :: FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ())
  }

instance Storable SCRIPT_MODULE_FUNCTION where
  sizeOf _ = 16
  alignment _ = 8
  peek ptr = SCRIPT_MODULE_FUNCTION
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (smfName v)
    pokeByteOff ptr 8 (smfFunc v)

-- | スクリプトモジュール登録用のテーブルです。
-- |
-- | 説明文と公開関数配列へのポインタを保持します。
data SCRIPT_MODULE_TABLE = SCRIPT_MODULE_TABLE
  { smtInformation :: LPCWSTR
  , smtFunctions   :: Ptr SCRIPT_MODULE_FUNCTION
  }

instance Storable SCRIPT_MODULE_TABLE where
  sizeOf _ = 16
  alignment _ = 8
  peek ptr = SCRIPT_MODULE_TABLE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (smtInformation v)
    pokeByteOff ptr 8 (smtFunctions v)

foreign import ccall "dynamic"
  mkGetParamNum :: FunPtr (IO CInt) -> IO CInt

foreign import ccall "dynamic"
  mkGetParamInt :: FunPtr (CInt -> IO CInt) -> CInt -> IO CInt

foreign import ccall "dynamic"
  mkGetParamDouble :: FunPtr (CInt -> IO CDouble) -> CInt -> IO CDouble

foreign import ccall "dynamic"
  mkGetParamString :: FunPtr (CInt -> IO LPCSTR) -> CInt -> IO LPCSTR

foreign import ccall "dynamic"
  mkGetParamData :: FunPtr (CInt -> IO (Ptr ())) -> CInt -> IO (Ptr ())

foreign import ccall "dynamic"
  mkGetParamTableInt :: FunPtr (CInt -> LPCSTR -> IO CInt) -> CInt -> LPCSTR -> IO CInt

foreign import ccall "dynamic"
  mkGetParamTableDouble :: FunPtr (CInt -> LPCSTR -> IO CDouble) -> CInt -> LPCSTR -> IO CDouble

foreign import ccall "dynamic"
  mkGetParamTableString :: FunPtr (CInt -> LPCSTR -> IO LPCSTR) -> CInt -> LPCSTR -> IO LPCSTR

foreign import ccall "dynamic"
  mkGetParamArrayNum :: FunPtr (CInt -> IO CInt) -> CInt -> IO CInt

foreign import ccall "dynamic"
  mkGetParamArrayInt :: FunPtr (CInt -> CInt -> IO CInt) -> CInt -> CInt -> IO CInt

foreign import ccall "dynamic"
  mkGetParamArrayDouble :: FunPtr (CInt -> CInt -> IO CDouble) -> CInt -> CInt -> IO CDouble

foreign import ccall "dynamic"
  mkGetParamArrayString :: FunPtr (CInt -> CInt -> IO LPCSTR) -> CInt -> CInt -> IO LPCSTR

foreign import ccall "dynamic"
  mkPushResultInt :: FunPtr (CInt -> IO ()) -> CInt -> IO ()

foreign import ccall "dynamic"
  mkPushResultDouble :: FunPtr (CDouble -> IO ()) -> CDouble -> IO ()

foreign import ccall "dynamic"
  mkPushResultString :: FunPtr (LPCSTR -> IO ()) -> LPCSTR -> IO ()

foreign import ccall "dynamic"
  mkPushResultData :: FunPtr (Ptr () -> IO ()) -> Ptr () -> IO ()

foreign import ccall "dynamic"
  mkPushResultTableInt :: FunPtr (Ptr LPCSTR -> Ptr CInt -> CInt -> IO ()) -> Ptr LPCSTR -> Ptr CInt -> CInt -> IO ()

foreign import ccall "dynamic"
  mkPushResultTableDouble :: FunPtr (Ptr LPCSTR -> Ptr CDouble -> CInt -> IO ()) -> Ptr LPCSTR -> Ptr CDouble -> CInt -> IO ()

foreign import ccall "dynamic"
  mkPushResultTableString :: FunPtr (Ptr LPCSTR -> Ptr LPCSTR -> CInt -> IO ()) -> Ptr LPCSTR -> Ptr LPCSTR -> CInt -> IO ()

foreign import ccall "dynamic"
  mkPushResultArrayInt :: FunPtr (Ptr CInt -> CInt -> IO ()) -> Ptr CInt -> CInt -> IO ()

foreign import ccall "dynamic"
  mkPushResultArrayDouble :: FunPtr (Ptr CDouble -> CInt -> IO ()) -> Ptr CDouble -> CInt -> IO ()

foreign import ccall "dynamic"
  mkPushResultArrayString :: FunPtr (Ptr LPCSTR -> CInt -> IO ()) -> Ptr LPCSTR -> CInt -> IO ()

foreign import ccall "dynamic"
  mkSetError :: FunPtr (LPCSTR -> IO ()) -> LPCSTR -> IO ()

foreign import ccall "dynamic"
  mkGetParamBoolean :: FunPtr (CInt -> IO BOOL_) -> CInt -> IO BOOL_

foreign import ccall "dynamic"
  mkPushResultBoolean :: FunPtr (BOOL_ -> IO ()) -> BOOL_ -> IO ()

foreign import ccall "dynamic"
  mkGetParamTableBoolean :: FunPtr (CInt -> LPCSTR -> IO BOOL_) -> CInt -> LPCSTR -> IO BOOL_

foreign import ccall "dynamic"
  mkPushResultArrayBoolean :: FunPtr (Ptr BOOL_ -> CInt -> IO ()) -> Ptr BOOL_ -> CInt -> IO ()

foreign import ccall "dynamic"
  mkPushResultTableBoolean :: FunPtr (Ptr LPCSTR -> Ptr BOOL_ -> CInt -> IO ()) -> Ptr LPCSTR -> Ptr BOOL_ -> CInt -> IO ()

foreign import ccall "dynamic"
  mkPushResultFunction :: FunPtr (FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> Ptr () -> IO ()) -> FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> Ptr () -> IO ()

foreign import ccall "dynamic"
  mkPushResultMetaTable :: FunPtr (FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> Ptr () -> IO ()) -> FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> Ptr () -> IO ()

-- | 現在の呼び出しで渡された引数個数を取得します。
getParamNum :: Ptr SCRIPT_MODULE_PARAM -> IO CInt
getParamNum ptr = do
  p <- peek ptr
  mkGetParamNum (smpGetParamNum p)

-- | 指定位置の引数を整数として取得します。
getParamInt :: Ptr SCRIPT_MODULE_PARAM -> CInt -> IO CInt
getParamInt ptr idx = do
  p <- peek ptr
  mkGetParamInt (smpGetParamInt p) idx

-- | 指定位置の引数を浮動小数点数として取得します。
getParamDouble :: Ptr SCRIPT_MODULE_PARAM -> CInt -> IO CDouble
getParamDouble ptr idx = do
  p <- peek ptr
  mkGetParamDouble (smpGetParamDouble p) idx

-- | 指定位置の引数を文字列として取得します。
-- |
-- | 戻り値はSDK所有の文字列ポインタです。
getParamString :: Ptr SCRIPT_MODULE_PARAM -> CInt -> IO LPCSTR
getParamString ptr idx = do
  p <- peek ptr
  mkGetParamString (smpGetParamString p) idx

-- | 指定位置の引数を生データポインタとして取得します。
getParamData :: Ptr SCRIPT_MODULE_PARAM -> CInt -> IO (Ptr ())
getParamData ptr idx = do
  p <- peek ptr
  mkGetParamData (smpGetParamData p) idx

-- | テーブル型引数から、指定キーの整数値を取得します。
getParamTableInt :: Ptr SCRIPT_MODULE_PARAM -> CInt -> LPCSTR -> IO CInt
getParamTableInt ptr idx key = do
  p <- peek ptr
  mkGetParamTableInt (smpGetParamTableInt p) idx key

-- | テーブル型引数から、指定キーの浮動小数点値を取得します。
getParamTableDouble :: Ptr SCRIPT_MODULE_PARAM -> CInt -> LPCSTR -> IO CDouble
getParamTableDouble ptr idx key = do
  p <- peek ptr
  mkGetParamTableDouble (smpGetParamTableDouble p) idx key

-- | テーブル型引数から、指定キーの文字列値を取得します。
getParamTableString :: Ptr SCRIPT_MODULE_PARAM -> CInt -> LPCSTR -> IO LPCSTR
getParamTableString ptr idx key = do
  p <- peek ptr
  mkGetParamTableString (smpGetParamTableString p) idx key

-- | 配列型引数の要素数を取得します。
getParamArrayNum :: Ptr SCRIPT_MODULE_PARAM -> CInt -> IO CInt
getParamArrayNum ptr idx = do
  p <- peek ptr
  mkGetParamArrayNum (smpGetParamArrayNum p) idx

-- | 配列型引数の指定位置を整数として取得します。
getParamArrayInt :: Ptr SCRIPT_MODULE_PARAM -> CInt -> CInt -> IO CInt
getParamArrayInt ptr idx key = do
  p <- peek ptr
  mkGetParamArrayInt (smpGetParamArrayInt p) idx key

-- | 配列型引数の指定位置を浮動小数点数として取得します。
getParamArrayDouble :: Ptr SCRIPT_MODULE_PARAM -> CInt -> CInt -> IO CDouble
getParamArrayDouble ptr idx key = do
  p <- peek ptr
  mkGetParamArrayDouble (smpGetParamArrayDouble p) idx key

-- | 配列型引数の指定位置を文字列として取得します。
getParamArrayString :: Ptr SCRIPT_MODULE_PARAM -> CInt -> CInt -> IO LPCSTR
getParamArrayString ptr idx key = do
  p <- peek ptr
  mkGetParamArrayString (smpGetParamArrayString p) idx key

-- | 整数値を戻り値として積みます。
-- |
-- | 複数値を返す仕様の関数では、必要に応じて複数回呼び出します。
pushResultInt :: Ptr SCRIPT_MODULE_PARAM -> CInt -> IO ()
pushResultInt ptr val = do
  p <- peek ptr
  mkPushResultInt (smpPushResultInt p) val

-- | 浮動小数点値を戻り値として積みます。
pushResultDouble :: Ptr SCRIPT_MODULE_PARAM -> CDouble -> IO ()
pushResultDouble ptr val = do
  p <- peek ptr
  mkPushResultDouble (smpPushResultDouble p) val

-- | 文字列値を戻り値として積みます。
pushResultString :: Ptr SCRIPT_MODULE_PARAM -> LPCSTR -> IO ()
pushResultString ptr val = do
  p <- peek ptr
  mkPushResultString (smpPushResultString p) val

-- | 生データを戻り値として積みます。
pushResultData :: Ptr SCRIPT_MODULE_PARAM -> Ptr () -> IO ()
pushResultData ptr val = do
  p <- peek ptr
  mkPushResultData (smpPushResultData p) val

-- | テーブル形式の整数結果を返します。
-- |
-- | 'keys' と 'vals' は同じ要素数 'num' を持つ配列である必要があります。
pushResultTableInt :: Ptr SCRIPT_MODULE_PARAM -> Ptr LPCSTR -> Ptr CInt -> CInt -> IO ()
pushResultTableInt ptr keys vals num = do
  p <- peek ptr
  mkPushResultTableInt (smpPushResultTableInt p) keys vals num

-- | テーブル形式の浮動小数点結果を返します。
pushResultTableDouble :: Ptr SCRIPT_MODULE_PARAM -> Ptr LPCSTR -> Ptr CDouble -> CInt -> IO ()
pushResultTableDouble ptr keys vals num = do
  p <- peek ptr
  mkPushResultTableDouble (smpPushResultTableDouble p) keys vals num

-- | テーブル形式の文字列結果を返します。
pushResultTableString :: Ptr SCRIPT_MODULE_PARAM -> Ptr LPCSTR -> Ptr LPCSTR -> CInt -> IO ()
pushResultTableString ptr keys vals num = do
  p <- peek ptr
  mkPushResultTableString (smpPushResultTableString p) keys vals num

-- | 整数配列を戻り値として返します。
pushResultArrayInt :: Ptr SCRIPT_MODULE_PARAM -> Ptr CInt -> CInt -> IO ()
pushResultArrayInt ptr vals num = do
  p <- peek ptr
  mkPushResultArrayInt (smpPushResultArrayInt p) vals num

-- | 浮動小数点配列を戻り値として返します。
pushResultArrayDouble :: Ptr SCRIPT_MODULE_PARAM -> Ptr CDouble -> CInt -> IO ()
pushResultArrayDouble ptr vals num = do
  p <- peek ptr
  mkPushResultArrayDouble (smpPushResultArrayDouble p) vals num

-- | 文字列配列を戻り値として返します。
pushResultArrayString :: Ptr SCRIPT_MODULE_PARAM -> Ptr LPCSTR -> CInt -> IO ()
pushResultArrayString ptr vals num = do
  p <- peek ptr
  mkPushResultArrayString (smpPushResultArrayString p) vals num

-- | スクリプト側へエラーメッセージを報告します。
-- |
-- | 関数実行を失敗扱いにしたいときの説明文として使います。
setError :: Ptr SCRIPT_MODULE_PARAM -> LPCSTR -> IO ()
setError ptr msg = do
  p <- peek ptr
  mkSetError (smpSetError p) msg

-- | 指定位置の引数を真偽値として取得します。
getParamBoolean :: Ptr SCRIPT_MODULE_PARAM -> CInt -> IO BOOL_
getParamBoolean ptr idx = do
  p <- peek ptr
  mkGetParamBoolean (smpGetParamBoolean p) idx

-- | 真偽値を戻り値として積みます。
pushResultBoolean :: Ptr SCRIPT_MODULE_PARAM -> BOOL_ -> IO ()
pushResultBoolean ptr val = do
  p <- peek ptr
  mkPushResultBoolean (smpPushResultBoolean p) val

-- | テーブル型引数から、指定キーの真偽値を取得します。
getParamTableBoolean :: Ptr SCRIPT_MODULE_PARAM -> CInt -> LPCSTR -> IO BOOL_
getParamTableBoolean ptr idx key = do
  p <- peek ptr
  mkGetParamTableBoolean (smpGetParamTableBoolean p) idx key

-- | 真偽値配列を戻り値として返します。
pushResultArrayBoolean :: Ptr SCRIPT_MODULE_PARAM -> Ptr BOOL_ -> CInt -> IO ()
pushResultArrayBoolean ptr vals num = do
  p <- peek ptr
  mkPushResultArrayBoolean (smpPushResultArrayBoolean p) vals num

-- | テーブル形式の真偽値結果を返します。
pushResultTableBoolean :: Ptr SCRIPT_MODULE_PARAM -> Ptr LPCSTR -> Ptr BOOL_ -> CInt -> IO ()
pushResultTableBoolean ptr keys vals num = do
  p <- peek ptr
  mkPushResultTableBoolean (smpPushResultTableBoolean p) keys vals num

-- | スクリプト処理中に参照できる編集セクションを取得します。
getScriptModuleEdit :: Ptr SCRIPT_MODULE_PARAM -> IO (Ptr EDIT_SECTION)
getScriptModuleEdit ptr = smpEdit <$> peek ptr

-- | スクリプトへ関数値を戻り値として返します。
pushResultFunction :: Ptr SCRIPT_MODULE_PARAM -> FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ()) -> Ptr () -> IO ()
pushResultFunction ptr callback userdata = do
  p <- peek ptr
  mkPushResultFunction (smpPushResultFunction p) callback userdata

-- | スクリプトへメタテーブル値を戻り値として返します。
pushResultMetaTable
  :: Ptr SCRIPT_MODULE_PARAM
  -> FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ())
  -> FunPtr (Ptr SCRIPT_MODULE_PARAM -> IO ())
  -> Ptr ()
  -> IO ()
pushResultMetaTable ptr getter setter userdata = do
  p <- peek ptr
  mkPushResultMetaTable (smpPushResultMetaTable p) getter setter userdata

-- | 関数値やメタテーブル呼び出し時にホストから渡されたユーザーデータです。
getScriptModuleUserdata :: Ptr SCRIPT_MODULE_PARAM -> IO (Ptr ())
getScriptModuleUserdata ptr = smpUserdata <$> peek ptr
