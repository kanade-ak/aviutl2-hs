{-# LANGUAGE ScopedTypeVariables #-}
{-|
Module      : AviUtl2.Filter
Description : AviUtl2のフィルタプラグインと設定UI項目を定義するABIバインディングです。

このモジュールには大きく分けて次の3種類の定義があります。

* フィルタ設定UIを構築するための各種項目構造体
* 映像処理・音声処理コールバックで受け取る処理文脈構造体
* フィルタプラグイン自体を登録するための関数テーブル

Rust側の `filter2` 相当であり、ポインタやバッファの扱いは意図的に低水準のままです。
そのため、各UI項目のメモリ配置やコールバックの寿命管理はSDKの規約に合わせてください。
-}
module AviUtl2.Filter
  ( FILTER_ITEM_TRACK(..)
  , FILTER_ITEM_CHECK(..)
  , FILTER_ITEM_COLOR(..)
  , FILTER_ITEM_COLOR_VALUE(..)
  , FILTER_ITEM_SELECT(..)
  , FILTER_ITEM_SELECT_ITEM(..)
  , FILTER_ITEM_FILE(..)
  , FILTER_ITEM_GROUP(..)
  , FILTER_ITEM_BUTTON(..)
  , FILTER_ITEM_STRING(..)
  , FILTER_ITEM_TEXT(..)
  , FILTER_ITEM_FOLDER(..)
  , FILTER_ITEM_SEPARATOR(..)
  , FILTER_ITEM_DATA_HEADER(..)
  , filterItemDataHeaderSize
  , filterItemDataValueOffset
  , filterItemDataSize
  , filterItemTypeData
  , FILTER_PROC_VIDEO(..)
  , FILTER_PROC_AUDIO(..)
  , FILTER_PLUGIN_TABLE(..)
  , filterFlagVideo
  , filterFlagAudio
  , filterFlagInput
  , filterFlagFilter
  , getImageData
  , setImageData
  , getImageTexture2d
  , getFramebufferTexture2d
  , getSampleData
  , setSampleData
  ) where

import Foreign.C.Types (CInt(..), CDouble(..), CFloat(..))
import Foreign.C.String (newCWString)
import Foreign.Ptr (Ptr, FunPtr)
import Foreign.Storable (Storable(..))
import System.IO.Unsafe (unsafePerformIO)
import AviUtl2.Edit (EDIT_SECTION)
import AviUtl2.Types (LPCWSTR, PIXEL_RGBA, SCENE_INFO, OBJECT_INFO, BOOL_)

-- | トラックバー項目を表す構造体です。
-- |
-- | 数値をスライダーで編集させたいときに使います。
-- | 初期値、最小値、最大値、増分をまとめて保持します。
data FILTER_ITEM_TRACK = FILTER_ITEM_TRACK
  { fitType  :: LPCWSTR
  , fitName  :: LPCWSTR
  , fitValue :: CDouble
  , fitS     :: CDouble
  , fitE     :: CDouble
  , fitStep  :: CDouble
  } deriving (Show)

instance Storable FILTER_ITEM_TRACK where
  sizeOf _ = 48
  alignment _ = 8
  peek ptr = FILTER_ITEM_TRACK
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
  poke ptr v = do
    pokeByteOff ptr 0 (fitType v)
    pokeByteOff ptr 8 (fitName v)
    pokeByteOff ptr 16 (fitValue v)
    pokeByteOff ptr 24 (fitS v)
    pokeByteOff ptr 32 (fitE v)
    pokeByteOff ptr 40 (fitStep v)

-- | チェックボックス項目を表す構造体です。
-- |
-- | ON/OFFの二値設定をUIへ公開するときに使います。
data FILTER_ITEM_CHECK = FILTER_ITEM_CHECK
  { ficType  :: LPCWSTR
  , ficName  :: LPCWSTR
  , ficValue :: BOOL_
  } deriving (Show)

instance Storable FILTER_ITEM_CHECK where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_CHECK
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (ficType v)
    pokeByteOff ptr 8 (ficName v)
    pokeByteOff ptr 16 (ficValue v)

-- | 色項目に格納される色コードです。
-- |
-- | 実体は整数ですが、色選択UIの値であることが分かるように
-- | 別型に切り出しています。
newtype FILTER_ITEM_COLOR_VALUE = FILTER_ITEM_COLOR_VALUE
  { ficvCode :: CInt
  } deriving (Show, Eq)

instance Storable FILTER_ITEM_COLOR_VALUE where
  sizeOf _ = 4
  alignment _ = 4
  peek ptr = FILTER_ITEM_COLOR_VALUE <$> peekByteOff ptr 0
  poke ptr v = pokeByteOff ptr 0 (ficvCode v)

-- | 色選択項目を表す構造体です。
-- |
-- | フィルタ設定画面上で色を選ばせたい場合に使用します。
data FILTER_ITEM_COLOR = FILTER_ITEM_COLOR
  { fiColType  :: LPCWSTR
  , fiColName  :: LPCWSTR
  , fiColValue :: FILTER_ITEM_COLOR_VALUE
  } deriving (Show)

instance Storable FILTER_ITEM_COLOR where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_COLOR
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fiColType v)
    pokeByteOff ptr 8 (fiColName v)
    pokeByteOff ptr 16 (fiColValue v)

-- | 選択リスト項目の1要素です。
-- |
-- | 表示名と内部値の組を表し、'FILTER_ITEM_SELECT' から配列で参照されます。
data FILTER_ITEM_SELECT_ITEM = FILTER_ITEM_SELECT_ITEM
  { fisiName  :: LPCWSTR
  , fisiValue :: CInt
  } deriving (Show)

instance Storable FILTER_ITEM_SELECT_ITEM where
  sizeOf _ = 16
  alignment _ = 8
  peek ptr = FILTER_ITEM_SELECT_ITEM
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (fisiName v)
    pokeByteOff ptr 8 (fisiValue v)

-- | 選択リスト項目を表す構造体です。
-- |
-- | ドロップダウンや選択式UIとして使われ、'fiselList' が選択肢配列を指します。
data FILTER_ITEM_SELECT = FILTER_ITEM_SELECT
  { fiselType  :: LPCWSTR
  , fiselName  :: LPCWSTR
  , fiselValue :: CInt
  , fiselList  :: Ptr FILTER_ITEM_SELECT_ITEM
  } deriving (Show)

instance Storable FILTER_ITEM_SELECT where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = FILTER_ITEM_SELECT
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (fiselType v)
    pokeByteOff ptr 8 (fiselName v)
    pokeByteOff ptr 16 (fiselValue v)
    pokeByteOff ptr 24 (fiselList v)

-- | ファイル選択項目を表す構造体です。
-- |
-- | パス文字列とファイルフィルタを保持し、設定UIからファイルを選択させます。
data FILTER_ITEM_FILE = FILTER_ITEM_FILE
  { fifType       :: LPCWSTR
  , fifName       :: LPCWSTR
  , fifValue      :: LPCWSTR
  , fifFilefilter :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_FILE where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = FILTER_ITEM_FILE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (fifType v)
    pokeByteOff ptr 8 (fifName v)
    pokeByteOff ptr 16 (fifValue v)
    pokeByteOff ptr 24 (fifFilefilter v)

-- | 設定項目をグループ化するための項目です。
-- |
-- | 以降の項目を折りたたみ可能なまとまりとして見せたいときに使います。
-- | 空名の項目を終端として使うSDK流儀を再現する用途もあります。
data FILTER_ITEM_GROUP = FILTER_ITEM_GROUP
  { figType           :: LPCWSTR
  , figName           :: LPCWSTR
  , figDefaultVisible :: BOOL_
  } deriving (Show)

instance Storable FILTER_ITEM_GROUP where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_GROUP
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (figType v)
    pokeByteOff ptr 8 (figName v)
    pokeByteOff ptr 16 (figDefaultVisible v)

-- | ボタン項目を表す構造体です。
-- |
-- | 押下時に 'EDIT_SECTION' を受け取るコールバックを呼び出します。
data FILTER_ITEM_BUTTON = FILTER_ITEM_BUTTON
  { fibType     :: LPCWSTR
  , fibName     :: LPCWSTR
  , fibCallback :: FunPtr (Ptr EDIT_SECTION -> IO ())
  } deriving (Show)

instance Storable FILTER_ITEM_BUTTON where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_BUTTON
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fibType v)
    pokeByteOff ptr 8 (fibName v)
    pokeByteOff ptr 16 (fibCallback v)

-- | 単一行の文字列入力項目を表す構造体です。
data FILTER_ITEM_STRING = FILTER_ITEM_STRING
  { fistrType  :: LPCWSTR
  , fistrName  :: LPCWSTR
  , fistrValue :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_STRING where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_STRING
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fistrType v)
    pokeByteOff ptr 8 (fistrName v)
    pokeByteOff ptr 16 (fistrValue v)

-- | 複数行テキスト入力項目を表す構造体です。
data FILTER_ITEM_TEXT = FILTER_ITEM_TEXT
  { fitxtType  :: LPCWSTR
  , fitxtName  :: LPCWSTR
  , fitxtValue :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_TEXT where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_TEXT
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fitxtType v)
    pokeByteOff ptr 8 (fitxtName v)
    pokeByteOff ptr 16 (fitxtValue v)

-- | フォルダ選択項目を表す構造体です。
data FILTER_ITEM_FOLDER = FILTER_ITEM_FOLDER
  { fifolType  :: LPCWSTR
  , fifolName  :: LPCWSTR
  , fifolValue :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_FOLDER where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = FILTER_ITEM_FOLDER
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (fifolType v)
    pokeByteOff ptr 8 (fifolName v)
    pokeByteOff ptr 16 (fifolValue v)

-- | 設定UI上の区切り線を表す項目です。
-- |
-- | 視覚的に項目群を分けたいときに使用します。
data FILTER_ITEM_SEPARATOR = FILTER_ITEM_SEPARATOR
  { fisepType :: LPCWSTR
  , fisepName :: LPCWSTR
  } deriving (Show)

instance Storable FILTER_ITEM_SEPARATOR where
  sizeOf _ = 16
  alignment _ = 8
  peek ptr = FILTER_ITEM_SEPARATOR
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (fisepType v)
    pokeByteOff ptr 8 (fisepName v)

-- | 汎用データ項目であることを示す型名文字列です。
-- |
-- | SDKでは項目種別を文字列で識別するため、この値を 'FILTER_ITEM_DATA_HEADER' の
-- | 型名として利用します。
filterItemTypeData :: LPCWSTR
filterItemTypeData = unsafePerformIO (newCWString "data")
{-# NOINLINE filterItemTypeData #-}

-- | 汎用データ項目のヘッダー部分です。
-- |
-- | 実データ本体はこのヘッダーの後ろに続くメモリ領域へ配置される前提で、
-- | 'fidhValue' は値領域の先頭を指します。
data FILTER_ITEM_DATA_HEADER = FILTER_ITEM_DATA_HEADER
  { fidhType  :: LPCWSTR
  , fidhName  :: LPCWSTR
  , fidhValue :: Ptr ()
  , fidhSize  :: CInt
  }

instance Storable FILTER_ITEM_DATA_HEADER where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = FILTER_ITEM_DATA_HEADER
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (fidhType v)
    pokeByteOff ptr 8 (fidhName v)
    pokeByteOff ptr 16 (fidhValue v)
    pokeByteOff ptr 24 (fidhSize v)

-- | 汎用データ項目ヘッダーのSDK上の論理サイズです。
-- |
-- | Haskellの 'Storable' 上のサイズとは別に、SDKの実メモリ配置で
-- | 値領域計算に使うサイズを返します。
filterItemDataHeaderSize :: Int
filterItemDataHeaderSize = 28

-- | 汎用データ項目における実データ開始オフセットを計算します。
-- |
-- | 値型 'a' のアラインメントを考慮して、ヘッダー直後のどこから
-- | 実データを置くべきかを返します。
filterItemDataValueOffset :: forall a proxy. Storable a => proxy a -> Int
filterItemDataValueOffset _ = alignUp filterItemDataHeaderSize (alignment (undefined :: a))

-- | 汎用データ項目全体の必要サイズを計算します。
-- |
-- | ヘッダー、アラインメント調整、値本体を含めた総サイズを返します。
filterItemDataSize :: forall a proxy. Storable a => proxy a -> Int
filterItemDataSize proxy =
  let valueAlign = alignmentValue proxy
      valueSize = sizeOf (undefined :: a)
      structAlign = max 8 valueAlign
      totalSize = filterItemDataValueOffset proxy + valueSize
  in alignUp totalSize structAlign

alignmentValue :: forall a proxy. Storable a => proxy a -> Int
alignmentValue _ = alignment (undefined :: a)

alignUp :: Int -> Int -> Int
alignUp value align =
  ((value + align - 1) `div` align) * align

-- | 映像フィルタ処理中に渡される文脈構造体です。
-- |
-- | シーン情報、オブジェクト情報、画像バッファ取得・反映用コールバック、
-- | GPUテクスチャ取得用コールバックを含みます。
data FILTER_PROC_VIDEO = FILTER_PROC_VIDEO
  { fpvScene              :: Ptr SCENE_INFO
  , fpvObject             :: Ptr OBJECT_INFO
  , fpvGetImageData       :: FunPtr (Ptr PIXEL_RGBA -> IO ())
  , fpvSetImageData       :: FunPtr (Ptr PIXEL_RGBA -> CInt -> CInt -> IO ())
  , fpvGetImageTexture2d  :: FunPtr (IO (Ptr ()))
  , fpvGetFramebufferTexture2d :: FunPtr (IO (Ptr ()))
  }

instance Storable FILTER_PROC_VIDEO where
  sizeOf _ = 48
  alignment _ = 8
  peek ptr = FILTER_PROC_VIDEO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
  poke ptr v = do
    pokeByteOff ptr 0 (fpvScene v)
    pokeByteOff ptr 8 (fpvObject v)
    pokeByteOff ptr 16 (fpvGetImageData v)
    pokeByteOff ptr 24 (fpvSetImageData v)
    pokeByteOff ptr 32 (fpvGetImageTexture2d v)
    pokeByteOff ptr 40 (fpvGetFramebufferTexture2d v)

-- | 音声フィルタ処理中に渡される文脈構造体です。
-- |
-- | シーン情報、オブジェクト情報、音声サンプルの取得・反映コールバックを保持します。
data FILTER_PROC_AUDIO = FILTER_PROC_AUDIO
  { fpaScene         :: Ptr SCENE_INFO
  , fpaObject        :: Ptr OBJECT_INFO
  , fpaGetSampleData :: FunPtr (Ptr CFloat -> CInt -> IO ())
  , fpaSetSampleData :: FunPtr (Ptr CFloat -> CInt -> IO ())
  }

instance Storable FILTER_PROC_AUDIO where
  sizeOf _ = 32
  alignment _ = 8
  peek ptr = FILTER_PROC_AUDIO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
  poke ptr v = do
    pokeByteOff ptr 0 (fpaScene v)
    pokeByteOff ptr 8 (fpaObject v)
    pokeByteOff ptr 16 (fpaGetSampleData v)
    pokeByteOff ptr 24 (fpaSetSampleData v)

-- | フィルタプラグイン登録用の関数テーブルです。
-- |
-- | プラグイン名、UIラベル、設定項目配列、映像処理関数、音声処理関数を登録します。
data FILTER_PLUGIN_TABLE = FILTER_PLUGIN_TABLE
  { fptFlag           :: CInt
  , fptName           :: LPCWSTR
  , fptLabel          :: LPCWSTR
  , fptInformation    :: LPCWSTR
  , fptItems          :: Ptr (Ptr ())
  , fptFuncProcVideo  :: FunPtr (Ptr FILTER_PROC_VIDEO -> IO BOOL_)
  , fptFuncProcAudio  :: FunPtr (Ptr FILTER_PROC_AUDIO -> IO BOOL_)
  } deriving (Show)

-- | このフィルタが映像処理を行うことを示すフラグです。
filterFlagVideo :: CInt
filterFlagVideo = 1

-- | このフィルタが音声処理を行うことを示すフラグです。
filterFlagAudio :: CInt
filterFlagAudio = 2

-- | 入力系フィルタとして扱うことを示すフラグです。
filterFlagInput :: CInt
filterFlagInput = 4

-- | 通常フィルタとして扱うことを示すフラグです。
filterFlagFilter :: CInt
filterFlagFilter = 8

instance Storable FILTER_PLUGIN_TABLE where
  sizeOf _ = 56
  alignment _ = 8
  peek ptr = FILTER_PLUGIN_TABLE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
  poke ptr v = do
    pokeByteOff ptr 0 (fptFlag v)
    pokeByteOff ptr 8 (fptName v)
    pokeByteOff ptr 16 (fptLabel v)
    pokeByteOff ptr 24 (fptInformation v)
    pokeByteOff ptr 32 (fptItems v)
    pokeByteOff ptr 40 (fptFuncProcVideo v)
    pokeByteOff ptr 48 (fptFuncProcAudio v)

foreign import ccall "dynamic"
  mkGetImageData :: FunPtr (Ptr PIXEL_RGBA -> IO ()) -> Ptr PIXEL_RGBA -> IO ()

foreign import ccall "dynamic"
  mkSetImageData :: FunPtr (Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()) -> Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()

foreign import ccall "dynamic"
  mkGetImageTexture2d :: FunPtr (IO (Ptr ())) -> IO (Ptr ())

foreign import ccall "dynamic"
  mkGetFramebufferTexture2d :: FunPtr (IO (Ptr ())) -> IO (Ptr ())

foreign import ccall "dynamic"
  mkGetSampleData :: FunPtr (Ptr CFloat -> CInt -> IO ()) -> Ptr CFloat -> CInt -> IO ()

foreign import ccall "dynamic"
  mkSetSampleData :: FunPtr (Ptr CFloat -> CInt -> IO ()) -> Ptr CFloat -> CInt -> IO ()

-- | 映像処理用コールバックから現在の画像データを取得します。
-- |
-- | 'buf' は呼び出し側が確保した書き込み先バッファです。
getImageData :: Ptr FILTER_PROC_VIDEO -> Ptr PIXEL_RGBA -> IO ()
getImageData ptr buf = do
  v <- peek ptr
  mkGetImageData (fpvGetImageData v) buf

-- | 映像処理結果の画像データをホスト側へ反映します。
-- |
-- | 幅と高さは反映対象バッファの寸法を表します。
setImageData :: Ptr FILTER_PROC_VIDEO -> Ptr PIXEL_RGBA -> CInt -> CInt -> IO ()
setImageData ptr buf w h = do
  v <- peek ptr
  mkSetImageData (fpvSetImageData v) buf w h

-- | 現在の入力画像に対応するGPUテクスチャを取得します。
-- |
-- | 返り値はSDKが扱う生ポインタであり、API依存の具体型は公開されません。
getImageTexture2d :: Ptr FILTER_PROC_VIDEO -> IO (Ptr ())
getImageTexture2d ptr = do
  v <- peek ptr
  mkGetImageTexture2d (fpvGetImageTexture2d v)

-- | 現在の描画先フレームバッファに対応するGPUテクスチャを取得します。
getFramebufferTexture2d :: Ptr FILTER_PROC_VIDEO -> IO (Ptr ())
getFramebufferTexture2d ptr = do
  v <- peek ptr
  mkGetFramebufferTexture2d (fpvGetFramebufferTexture2d v)

-- | 音声処理用コールバックからサンプルデータを取得します。
-- |
-- | 'ch' はチャンネル数または取得対象単位としてSDK側が解釈する値です。
getSampleData :: Ptr FILTER_PROC_AUDIO -> Ptr CFloat -> CInt -> IO ()
getSampleData ptr buf ch = do
  a <- peek ptr
  mkGetSampleData (fpaGetSampleData a) buf ch

-- | 音声処理結果のサンプルデータをホスト側へ反映します。
setSampleData :: Ptr FILTER_PROC_AUDIO -> Ptr CFloat -> CInt -> IO ()
setSampleData ptr buf ch = do
  a <- peek ptr
  mkSetSampleData (fpaSetSampleData a) buf ch
