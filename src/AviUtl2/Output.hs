{-|
Module      : AviUtl2.Output
Description : AviUtl2の出力プラグインを実装するためのABI定義です。

出力プラグインは、AviUtl2本体から書き出し要求を受け取り、必要な映像フレームや
音声サンプルをホストから取り出しながらファイルを生成します。

このモジュールでは、書き出し時に渡される 'OUTPUT_INFO' と、
プラグイン登録用の 'OUTPUT_PLUGIN_TABLE'、およびホストコールバックを
呼び出すための小さなラッパーを提供します。
-}
module AviUtl2.Output
  ( OUTPUT_INFO(..)
  , OUTPUT_PLUGIN_TABLE(..)
  , outputInfoFlagVideo
  , outputInfoFlagAudio
  , outputFlagVideo
  , outputFlagAudio
  , outputFlagImage
  , oiGetVideo
  , oiGetAudio
  , oiIsAbort
  , oiRestTimeDisp
  , oiSetBufferSize
  ) where

import Foreign.C.Types (CInt(..), CBool(..), CULong(..))
import Foreign.Ptr (Ptr, FunPtr)
import Foreign.Storable (Storable(..))
import AviUtl2.Types (LPCWSTR, HWND, HINSTANCE, BOOL_, DWORD)

-- | 出力処理開始時にAviUtl2から渡される書き出し文脈です。
-- |
-- | 映像サイズ、フレームレート、音声仕様、保存先パスに加え、
-- | ホストから映像・音声データを取得するためのコールバックが含まれます。
data OUTPUT_INFO = OUTPUT_INFO
  { outInfoFlag              :: CInt
  , outInfoWidth             :: CInt
  , outInfoHeight            :: CInt
  , outInfoRate              :: CInt
  , outInfoScale             :: CInt
  , outInfoFrameCount        :: CInt
  , outInfoAudioRate         :: CInt
  , outInfoAudioChannels     :: CInt
  , outInfoAudioSamples      :: CInt
  , outInfoSavefile          :: LPCWSTR
  , outInfoFuncGetVideo      :: FunPtr (CInt -> DWORD -> IO (Ptr ()))
  , outInfoFuncGetAudio      :: FunPtr (CInt -> CInt -> Ptr CInt -> DWORD -> IO (Ptr ()))
  , outInfoFuncIsAbort       :: FunPtr (IO BOOL_)
  , outInfoFuncRestTimeDisp  :: FunPtr (CInt -> CInt -> IO ())
  , outInfoFuncSetBufferSize :: FunPtr (CInt -> CInt -> IO ())
  }

-- | 出力対象に映像が含まれることを示すフラグです。
outputInfoFlagVideo :: CInt
outputInfoFlagVideo = 1
-- | 出力対象に音声が含まれることを示すフラグです。
outputInfoFlagAudio :: CInt
outputInfoFlagAudio = 2

instance Storable OUTPUT_INFO where
  sizeOf _ = 88
  alignment _ = 8
  peek ptr = OUTPUT_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 4
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 28
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
    <*> peekByteOff ptr 56
    <*> peekByteOff ptr 64
    <*> peekByteOff ptr 72
    <*> peekByteOff ptr 80
  poke ptr v = do
    pokeByteOff ptr 0 (outInfoFlag v)
    pokeByteOff ptr 4 (outInfoWidth v)
    pokeByteOff ptr 8 (outInfoHeight v)
    pokeByteOff ptr 12 (outInfoRate v)
    pokeByteOff ptr 16 (outInfoScale v)
    pokeByteOff ptr 20 (outInfoFrameCount v)
    pokeByteOff ptr 24 (outInfoAudioRate v)
    pokeByteOff ptr 28 (outInfoAudioChannels v)
    pokeByteOff ptr 32 (outInfoAudioSamples v)
    pokeByteOff ptr 40 (outInfoSavefile v)
    pokeByteOff ptr 48 (outInfoFuncGetVideo v)
    pokeByteOff ptr 56 (outInfoFuncGetAudio v)
    pokeByteOff ptr 64 (outInfoFuncIsAbort v)
    pokeByteOff ptr 72 (outInfoFuncRestTimeDisp v)
    pokeByteOff ptr 80 (outInfoFuncSetBufferSize v)

-- | 出力プラグイン登録用の関数テーブルです。
-- |
-- | プラグイン名、対応ファイルフィルタ、出力本体コールバック、
-- | 設定ダイアログ、設定内容文字列取得関数などを保持します。
data OUTPUT_PLUGIN_TABLE = OUTPUT_PLUGIN_TABLE
  { optFlag            :: CInt
  , optName            :: LPCWSTR
  , optFilefilter      :: LPCWSTR
  , optInformation     :: LPCWSTR
  , optFuncOutput      :: FunPtr (Ptr OUTPUT_INFO -> IO BOOL_)
  , optFuncConfig      :: FunPtr (HWND -> HINSTANCE -> IO BOOL_)
  , optFuncGetConfigText :: FunPtr (IO LPCWSTR)
  } deriving (Show)

-- | この出力プラグインが映像を書き出せることを示すフラグです。
outputFlagVideo :: CInt
outputFlagVideo = 1
-- | この出力プラグインが音声を書き出せることを示すフラグです。
outputFlagAudio :: CInt
outputFlagAudio = 2
-- | 静止画出力として扱われることを示すフラグです。
outputFlagImage :: CInt
outputFlagImage = 4

instance Storable OUTPUT_PLUGIN_TABLE where
  sizeOf _ = 64
  alignment _ = 8
  peek ptr = OUTPUT_PLUGIN_TABLE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
  poke ptr v = do
    pokeByteOff ptr 0 (optFlag v)
    pokeByteOff ptr 8 (optName v)
    pokeByteOff ptr 16 (optFilefilter v)
    pokeByteOff ptr 24 (optInformation v)
    pokeByteOff ptr 32 (optFuncOutput v)
    pokeByteOff ptr 40 (optFuncConfig v)
    pokeByteOff ptr 48 (optFuncGetConfigText v)

foreign import ccall "dynamic"
  mkOiGetVideo :: FunPtr (CInt -> DWORD -> IO (Ptr ())) -> CInt -> DWORD -> IO (Ptr ())

foreign import ccall "dynamic"
  mkOiGetAudio :: FunPtr (CInt -> CInt -> Ptr CInt -> DWORD -> IO (Ptr ())) -> CInt -> CInt -> Ptr CInt -> DWORD -> IO (Ptr ())

foreign import ccall "dynamic"
  mkOiIsAbort :: FunPtr (IO BOOL_) -> IO BOOL_

foreign import ccall "dynamic"
  mkOiRestTimeDisp :: FunPtr (CInt -> CInt -> IO ()) -> CInt -> CInt -> IO ()

foreign import ccall "dynamic"
  mkOiSetBufferSize :: FunPtr (CInt -> CInt -> IO ()) -> CInt -> CInt -> IO ()

-- | 書き出し中に、指定フレームの映像データをホストから取得します。
-- |
-- | 返されるポインタはホスト管理のバッファを指すため、寿命はSDKの規約に従います。
oiGetVideo :: Ptr OUTPUT_INFO -> CInt -> DWORD -> IO (Ptr ())
oiGetVideo ptr frame format = do
  oi <- peek ptr
  mkOiGetVideo (outInfoFuncGetVideo oi) frame format

-- | 書き出し中に、指定範囲の音声サンプルをホストから取得します。
-- |
-- | 'readed' には実際に取得できたサンプル数が書き込まれます。
oiGetAudio :: Ptr OUTPUT_INFO -> CInt -> CInt -> Ptr CInt -> DWORD -> IO (Ptr ())
oiGetAudio ptr start sampleCount readed format = do
  oi <- peek ptr
  mkOiGetAudio (outInfoFuncGetAudio oi) start sampleCount readed format

-- | ユーザー操作などにより書き出し中断要求が出ているかを確認します。
-- |
-- | 長時間処理では適宜呼び出して、早めに中断へ追従するのが一般的です。
oiIsAbort :: Ptr OUTPUT_INFO -> IO BOOL_
oiIsAbort ptr = do
  oi <- peek ptr
  mkOiIsAbort (outInfoFuncIsAbort oi)

-- | ホスト側の残り時間表示を更新します。
-- |
-- | 現在の進捗と総量を渡して、書き出しダイアログの表示更新に利用します。
oiRestTimeDisp :: Ptr OUTPUT_INFO -> CInt -> CInt -> IO ()
oiRestTimeDisp ptr now total = do
  oi <- peek ptr
  mkOiRestTimeDisp (outInfoFuncRestTimeDisp oi) now total

-- | 映像・音声の希望バッファサイズをホストへ通知します。
-- |
-- | 出力処理の都合に応じて、必要な一時バッファ量を事前に伝える用途です。
oiSetBufferSize :: Ptr OUTPUT_INFO -> CInt -> CInt -> IO ()
oiSetBufferSize ptr videoSize audioSize = do
  oi <- peek ptr
  mkOiSetBufferSize (outInfoFuncSetBufferSize oi) videoSize audioSize
