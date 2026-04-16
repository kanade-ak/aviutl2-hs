{-|
Module      : AviUtl2.Config
Description : 翻訳文字列、フォント、配色、レイアウト値を取得する設定APIです。

このモジュールのハンドルは主に汎用プラグインへ渡され、AviUtl2本体の
ローカライズ済み文字列やUIテーマ情報を参照するために使います。

ラッパーは薄く、SDKコールバックをそのまま呼び出す設計です。
戻り値の文字列ポインタや構造体ポインタはホスト所有である前提で扱ってください。
-}
module AviUtl2.Config
  ( FONT_INFO(..)
  , CONFIG_HANDLE(..)
  , translate
  , getLanguageText
  , getFontInfo
  , getColorCode
  , getLayoutSize
  , getColorCodeIndex
  ) where

import Foreign.C.Types (CInt(..), CFloat(..))
import Foreign.Ptr (Ptr, FunPtr)
import Foreign.Storable (Storable(..))
import AviUtl2.Types (LPCWSTR, LPCSTR)

-- | ホストが返すフォント情報です。
-- |
-- | フォント名とサイズをまとめて保持します。UIをAviUtl2本体の見た目に合わせたい場合に
-- | 'getFontInfo' で取得して利用します。
data FONT_INFO = FONT_INFO
  { fiName :: LPCWSTR
  , fiSize :: CFloat
  } deriving (Show)

instance Storable FONT_INFO where
  sizeOf _ = 16
  alignment _ = 8
  peek ptr = FONT_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (fiName v)
    pokeByteOff ptr 8 (fiSize v)

-- | 設定参照用の関数テーブルです。
-- |
-- | アプリケーションデータ保存先のパスに加え、翻訳文字列、フォント、
-- | 色、レイアウト寸法などを取得するためのコールバックが入っています。
data CONFIG_HANDLE = CONFIG_HANDLE
  { chAppDataPath    :: LPCWSTR
  , chTranslate      :: FunPtr (Ptr CONFIG_HANDLE -> LPCWSTR -> IO LPCWSTR)
  , chGetLanguageText :: FunPtr (Ptr CONFIG_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCWSTR)
  , chGetFontInfo    :: FunPtr (Ptr CONFIG_HANDLE -> LPCSTR -> IO (Ptr FONT_INFO))
  , chGetColorCode   :: FunPtr (Ptr CONFIG_HANDLE -> LPCSTR -> IO CInt)
  , chGetLayoutSize  :: FunPtr (Ptr CONFIG_HANDLE -> LPCSTR -> IO CInt)
  , chGetColorCodeIndex :: FunPtr (Ptr CONFIG_HANDLE -> LPCSTR -> CInt -> IO CInt)
  }

instance Storable CONFIG_HANDLE where
  sizeOf _ = 56
  alignment _ = 8
  peek ptr = CONFIG_HANDLE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
  poke ptr v = do
    pokeByteOff ptr 0 (chAppDataPath v)
    pokeByteOff ptr 8 (chTranslate v)
    pokeByteOff ptr 16 (chGetLanguageText v)
    pokeByteOff ptr 24 (chGetFontInfo v)
    pokeByteOff ptr 32 (chGetColorCode v)
    pokeByteOff ptr 40 (chGetLayoutSize v)
    pokeByteOff ptr 48 (chGetColorCodeIndex v)

foreign import ccall "dynamic"
  mkTranslate :: FunPtr (Ptr CONFIG_HANDLE -> LPCWSTR -> IO LPCWSTR)
              -> Ptr CONFIG_HANDLE -> LPCWSTR -> IO LPCWSTR

foreign import ccall "dynamic"
  mkGetLanguageText :: FunPtr (Ptr CONFIG_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCWSTR)
                    -> Ptr CONFIG_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCWSTR

foreign import ccall "dynamic"
  mkGetFontInfo :: FunPtr (Ptr CONFIG_HANDLE -> LPCSTR -> IO (Ptr FONT_INFO))
                -> Ptr CONFIG_HANDLE -> LPCSTR -> IO (Ptr FONT_INFO)

foreign import ccall "dynamic"
  mkGetColorCode :: FunPtr (Ptr CONFIG_HANDLE -> LPCSTR -> IO CInt)
                 -> Ptr CONFIG_HANDLE -> LPCSTR -> IO CInt

foreign import ccall "dynamic"
  mkGetLayoutSize :: FunPtr (Ptr CONFIG_HANDLE -> LPCSTR -> IO CInt)
                   -> Ptr CONFIG_HANDLE -> LPCSTR -> IO CInt

foreign import ccall "dynamic"
  mkGetColorCodeIndex :: FunPtr (Ptr CONFIG_HANDLE -> LPCSTR -> CInt -> IO CInt)
                       -> Ptr CONFIG_HANDLE -> LPCSTR -> CInt -> IO CInt

-- | 表示文字列を現在の言語設定に従って翻訳します。
-- |
-- | AviUtl2側が管理する翻訳テーブルを使って文字列を変換したい場合に使います。
translate :: Ptr CONFIG_HANDLE -> LPCWSTR -> IO LPCWSTR
translate ptr text = do
  h <- peek ptr
  mkTranslate (chTranslate h) ptr text

-- | セクション名とキー名からローカライズ済み文字列を取得します。
-- |
-- | INI風の分類単位で文言を引くためのAPIで、組み込み文言の再利用に向いています。
getLanguageText :: Ptr CONFIG_HANDLE -> LPCWSTR -> LPCWSTR -> IO LPCWSTR
getLanguageText ptr section text = do
  h <- peek ptr
  mkGetLanguageText (chGetLanguageText h) ptr section text

-- | 指定キーに対応するフォント情報を取得します。
-- |
-- | 返るポインタは 'FONT_INFO' を指します。必要なら 'peek' で内容を読み取ります。
getFontInfo :: Ptr CONFIG_HANDLE -> LPCSTR -> IO (Ptr FONT_INFO)
getFontInfo ptr key = do
  h <- peek ptr
  mkGetFontInfo (chGetFontInfo h) ptr key

-- | シンボル名で指定した色コードを取得します。
-- |
-- | AviUtl2本体テーマに合わせた色を使いたい場合の入口です。
getColorCode :: Ptr CONFIG_HANDLE -> LPCSTR -> IO CInt
getColorCode ptr key = do
  h <- peek ptr
  mkGetColorCode (chGetColorCode h) ptr key

-- | シンボル名で指定したレイアウト寸法を取得します。
-- |
-- | 余白、線幅、アイコンサイズなどのUI寸法を本体と揃える用途を想定しています。
getLayoutSize :: Ptr CONFIG_HANDLE -> LPCSTR -> IO CInt
getLayoutSize ptr key = do
  h <- peek ptr
  mkGetLayoutSize (chGetLayoutSize h) ptr key

-- | 配列状に管理されている色コードをインデックス指定で取得します。
-- |
-- | 同一カテゴリに複数色が定義されているテーマ項目を参照するときに使います。
getColorCodeIndex :: Ptr CONFIG_HANDLE -> LPCSTR -> CInt -> IO CInt
getColorCodeIndex ptr key idx = do
  h <- peek ptr
  mkGetColorCodeIndex (chGetColorCodeIndex h) ptr key idx
