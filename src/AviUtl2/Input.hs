{-|
Module      : AviUtl2.Input
Description : AviUtl2の入力プラグインを実装するためのABI定義です。

入力プラグインは、メディアファイルを開き、映像・音声の情報を報告し、
必要に応じてフレームやサンプルをホストへ供給します。

このモジュールはC SDKの 'input2.h' 相当の薄いバインディングであり、
値は生ポインタ、フラグ、フレーム番号のまま扱います。安全な抽象化ではないため、
ハンドルの寿命やバッファサイズは呼び出し側で正しく管理してください。
-}
module AviUtl2.Input
  ( INPUT_HANDLE
  , INPUT_INFO(..)
  , INPUT_PLUGIN_TABLE(..)
  , inputFlagVideo
  , inputFlagAudio
  , inputFlagTimeToFrame
  , inputPluginFlagVideo
  , inputPluginFlagAudio
  , inputPluginFlagConcurrent
  , inputPluginFlagMultiTrack
  , trackTypeVideo
  , trackTypeAudio
  , iptOpen
  , iptClose
  , iptInfoGet
  , iptReadVideo
  , iptReadAudio
  , iptConfig
  , iptSetTrack
  , iptTimeToFrame
  ) where

import Foreign.C.Types (CInt(..), CDouble(..), CBool(..))
import Foreign.Ptr (Ptr, FunPtr)
import Foreign.Storable (Storable(..))
import AviUtl2.Types (LPCWSTR, HWND, HINSTANCE, BOOL_)

-- | ファイルオープン後に入力プラグインが返す不透明ハンドルです。
-- |
-- | デコーダ状態やファイルストリームなど、プラグイン固有の内部状態を
-- | ホストへ引き渡すために使います。
type INPUT_HANDLE = Ptr ()

-- | 開いた入力ソースのメディア情報です。
-- |
-- | 映像のフレームレートや総フレーム数、映像フォーマット情報、
-- | 音声フォーマット情報などをホストへ伝えるために使います。
data INPUT_INFO = INPUT_INFO
  { iiFlag            :: CInt
  , iiRate            :: CInt
  , iiScale           :: CInt
  , iiN               :: CInt
  , iiFormat          :: Ptr ()
  , iiFormatSize      :: CInt
  , iiAudioN          :: CInt
  , iiAudioFormat     :: Ptr ()
  , iiAudioFormatSize :: CInt
  } deriving (Show)

-- | 映像ストリームを持つことを示すフラグです。
inputFlagVideo :: CInt
inputFlagVideo = 1
-- | 音声ストリームを持つことを示すフラグです。
inputFlagAudio :: CInt
inputFlagAudio = 2
-- | 時刻からフレーム番号への変換をサポートすることを示すフラグです。
inputFlagTimeToFrame :: CInt
inputFlagTimeToFrame = 16

instance Storable INPUT_INFO where
  sizeOf _ = 48
  alignment _ = 8
  peek ptr = INPUT_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 4
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 28
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
  poke ptr v = do
    pokeByteOff ptr 0 (iiFlag v)
    pokeByteOff ptr 4 (iiRate v)
    pokeByteOff ptr 8 (iiScale v)
    pokeByteOff ptr 12 (iiN v)
    pokeByteOff ptr 16 (iiFormat v)
    pokeByteOff ptr 24 (iiFormatSize v)
    pokeByteOff ptr 28 (iiAudioN v)
    pokeByteOff ptr 32 (iiAudioFormat v)
    pokeByteOff ptr 40 (iiAudioFormatSize v)

-- | 入力プラグイン登録用の関数テーブルです。
-- |
-- | プラグイン情報に加え、ファイルを開く、閉じる、情報取得、映像読込、
-- | 音声読込、設定ダイアログ表示、トラック切替などのコールバックを保持します。
data INPUT_PLUGIN_TABLE = INPUT_PLUGIN_TABLE
  { iptFlag           :: CInt
  , iptName           :: LPCWSTR
  , iptFilefilter     :: LPCWSTR
  , iptInformation    :: LPCWSTR
  , iptFuncOpen       :: FunPtr (LPCWSTR -> IO INPUT_HANDLE)
  , iptFuncClose      :: FunPtr (INPUT_HANDLE -> IO BOOL_)
  , iptFuncInfoGet    :: FunPtr (INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_)
  , iptFuncReadVideo  :: FunPtr (INPUT_HANDLE -> CInt -> Ptr () -> IO CInt)
  , iptFuncReadAudio  :: FunPtr (INPUT_HANDLE -> CInt -> CInt -> Ptr () -> IO CInt)
  , iptFuncConfig     :: FunPtr (HWND -> HINSTANCE -> IO BOOL_)
  , iptFuncSetTrack   :: FunPtr (INPUT_HANDLE -> CInt -> CInt -> IO CInt)
  , iptFuncTimeToFrame :: FunPtr (INPUT_HANDLE -> CDouble -> IO CInt)
  } deriving (Show)

-- | 入力プラグインが映像を扱うことを示すフラグです。
inputPluginFlagVideo :: CInt
inputPluginFlagVideo = 1
-- | 入力プラグインが音声を扱うことを示すフラグです。
inputPluginFlagAudio :: CInt
inputPluginFlagAudio = 2
-- | 同時並行アクセスに対応していることを示すフラグです。
inputPluginFlagConcurrent :: CInt
inputPluginFlagConcurrent = 16
-- | 複数トラックの選択に対応していることを示すフラグです。
inputPluginFlagMultiTrack :: CInt
inputPluginFlagMultiTrack = 32

-- | 映像トラックを指定するための種別値です。
trackTypeVideo :: CInt
trackTypeVideo = 0
-- | 音声トラックを指定するための種別値です。
trackTypeAudio :: CInt
trackTypeAudio = 1

instance Storable INPUT_PLUGIN_TABLE where
  sizeOf _ = 96
  alignment _ = 8
  peek ptr = INPUT_PLUGIN_TABLE
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
  poke ptr v = do
    pokeByteOff ptr 0 (iptFlag v)
    pokeByteOff ptr 8 (iptName v)
    pokeByteOff ptr 16 (iptFilefilter v)
    pokeByteOff ptr 24 (iptInformation v)
    pokeByteOff ptr 32 (iptFuncOpen v)
    pokeByteOff ptr 40 (iptFuncClose v)
    pokeByteOff ptr 48 (iptFuncInfoGet v)
    pokeByteOff ptr 56 (iptFuncReadVideo v)
    pokeByteOff ptr 64 (iptFuncReadAudio v)
    pokeByteOff ptr 72 (iptFuncConfig v)
    pokeByteOff ptr 80 (iptFuncSetTrack v)
    pokeByteOff ptr 88 (iptFuncTimeToFrame v)

foreign import ccall "dynamic"
  mkIptOpen :: FunPtr (LPCWSTR -> IO INPUT_HANDLE) -> LPCWSTR -> IO INPUT_HANDLE

foreign import ccall "dynamic"
  mkIptClose :: FunPtr (INPUT_HANDLE -> IO BOOL_) -> INPUT_HANDLE -> IO BOOL_

foreign import ccall "dynamic"
  mkIptInfoGet :: FunPtr (INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_) -> INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_

foreign import ccall "dynamic"
  mkIptReadVideo :: FunPtr (INPUT_HANDLE -> CInt -> Ptr () -> IO CInt) -> INPUT_HANDLE -> CInt -> Ptr () -> IO CInt

foreign import ccall "dynamic"
  mkIptReadAudio :: FunPtr (INPUT_HANDLE -> CInt -> CInt -> Ptr () -> IO CInt) -> INPUT_HANDLE -> CInt -> CInt -> Ptr () -> IO CInt

foreign import ccall "dynamic"
  mkIptConfig :: FunPtr (HWND -> HINSTANCE -> IO BOOL_) -> HWND -> HINSTANCE -> IO BOOL_

foreign import ccall "dynamic"
  mkIptSetTrack :: FunPtr (INPUT_HANDLE -> CInt -> CInt -> IO CInt) -> INPUT_HANDLE -> CInt -> CInt -> IO CInt

foreign import ccall "dynamic"
  mkIptTimeToFrame :: FunPtr (INPUT_HANDLE -> CDouble -> IO CInt) -> INPUT_HANDLE -> CDouble -> IO CInt

-- | メディアファイルを開き、以後の読込で使う 'INPUT_HANDLE' を取得します。
-- |
-- | 実際には 'INPUT_PLUGIN_TABLE' に格納された open コールバックを呼び出します。
iptOpen :: Ptr INPUT_PLUGIN_TABLE -> LPCWSTR -> IO INPUT_HANDLE
iptOpen ptr file = do
  ipt <- peek ptr
  mkIptOpen (iptFuncOpen ipt) file

-- | 以前 'iptOpen' で開いた入力ハンドルを閉じます。
-- |
-- | デコーダやファイルハンドルなど、プラグイン側で確保した資源を解放する契機です。
iptClose :: Ptr INPUT_PLUGIN_TABLE -> INPUT_HANDLE -> IO BOOL_
iptClose ptr ih = do
  ipt <- peek ptr
  mkIptClose (iptFuncClose ipt) ih

-- | 開いている入力ハンドルのストリーム情報を取得します。
-- |
-- | 呼び出し側が用意した 'INPUT_INFO' 領域へプラグインが情報を書き込みます。
iptInfoGet :: Ptr INPUT_PLUGIN_TABLE -> INPUT_HANDLE -> Ptr INPUT_INFO -> IO BOOL_
iptInfoGet ptr ih iip = do
  ipt <- peek ptr
  mkIptInfoGet (iptFuncInfoGet ipt) ih iip

-- | 指定フレームの映像をホスト提供バッファへ読み込みます。
-- |
-- | バッファの形式とサイズは事前に 'INPUT_INFO' の内容と整合している必要があります。
iptReadVideo :: Ptr INPUT_PLUGIN_TABLE -> INPUT_HANDLE -> CInt -> Ptr () -> IO CInt
iptReadVideo ptr ih frame buf = do
  ipt <- peek ptr
  mkIptReadVideo (iptFuncReadVideo ipt) ih frame buf

-- | 指定位置から音声サンプル列をホスト提供バッファへ読み込みます。
-- |
-- | 戻り値は実際に読み込めたサンプル数として使われる想定です。
iptReadAudio :: Ptr INPUT_PLUGIN_TABLE -> INPUT_HANDLE -> CInt -> CInt -> Ptr () -> IO CInt
iptReadAudio ptr ih start sampleCount buf = do
  ipt <- peek ptr
  mkIptReadAudio (iptFuncReadAudio ipt) ih start sampleCount buf

-- | 入力プラグインの設定ダイアログを表示します。
-- |
-- | 設定画面を持たないプラグインでは、常に失敗を返す実装でも問題ありません。
iptConfig :: Ptr INPUT_PLUGIN_TABLE -> HWND -> HINSTANCE -> IO BOOL_
iptConfig ptr hwnd dllHinst = do
  ipt <- peek ptr
  mkIptConfig (iptFuncConfig ipt) hwnd dllHinst

-- | 以後の読み込み対象となるトラックを切り替えます。
-- |
-- | 映像か音声かは 'trackTypeVideo' / 'trackTypeAudio' で指定します。
iptSetTrack :: Ptr INPUT_PLUGIN_TABLE -> INPUT_HANDLE -> CInt -> CInt -> IO CInt
iptSetTrack ptr ih type_ index = do
  ipt <- peek ptr
  mkIptSetTrack (iptFuncSetTrack ipt) ih type_ index

-- | 時刻からフレーム番号へ変換します。
-- |
-- | 可変フレームレートなどで時刻基準のアクセスが必要な場合に使われます。
-- | 事前に 'inputFlagTimeToFrame' を確認してください。
iptTimeToFrame :: Ptr INPUT_PLUGIN_TABLE -> INPUT_HANDLE -> CDouble -> IO CInt
iptTimeToFrame ptr ih time = do
  ipt <- peek ptr
  mkIptTimeToFrame (iptFuncTimeToFrame ipt) ih time
