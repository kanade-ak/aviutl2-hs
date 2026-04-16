{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}
{-|
Module      : AviUtl2.Types
Description : AviUtl2 SDK全体で共有される基本型とABI互換構造体です。

このモジュールには、入力・出力・フィルタ・汎用プラグインのいずれからも
参照される共通定義をまとめています。

ここで定義している 'data' や 'type' の多くは、AviUtl2 SDKのCヘッダーを
そのままHaskellのFFI向けに写したものです。そのため、フィールド順序、
サイズ、アラインメントは元ヘッダーと一致している必要があります。

高水準な安全ラッパーではなく、あくまでABI境界を表す低水準定義なので、
文字列ポインタやハンドルの寿命管理はAviUtl2側の規約に従って扱ってください。
-}
module AviUtl2.Types
  ( OBJECT_HANDLE
  , LPCWSTR
  , LPCSTR
  , HWND
  , HINSTANCE
  , DWORD
  , BOOL_
  , boolToBOOL
  , boolFromBOOL
  , COMMON_PLUGIN_TABLE(..)
  , OBJECT_LAYER_FRAME(..)
  , MEDIA_INFO(..)
  , MODULE_TYPE
  , moduleTypeScriptFilter
  , moduleTypeScriptObject
  , moduleTypeScriptCamera
  , moduleTypeScriptTrack
  , moduleTypeScriptModule
  , moduleTypePluginInput
  , moduleTypePluginOutput
  , moduleTypePluginFilter
  , moduleTypePluginCommon
  , MODULE_INFO(..)
  , EDIT_INFO(..)
  , PIXEL_RGBA(..)
  , SCENE_INFO(..)
  , OBJECT_INFO(..)
  , objFlagFilterObject
  , isObjectFilterObject
  , EFFECT_TYPE
  , effectTypeFilter
  , effectTypeInput
  , effectTypeTransition
  , EFFECT_FLAG
  , effectFlagVideo
  , effectFlagAudio
  , effectFlagFilter
  , EDIT_STATE
  , editStateEdit
  , editStatePlay
  , editStateSave
  ) where

import Foreign.C.Types (CChar, CWchar, CInt(..), CDouble(..), CFloat(..), CBool(..), CULong(..))
import Foreign.Ptr (Ptr)
import Foreign.Storable (Storable(..))
import GHC.Generics (Generic)
import Data.Word (Word8)
import Data.Int (Int64)
import Data.Bits ((.&.))

-- | AviUtl2上のオブジェクトを指す不透明ハンドルです。
-- |
-- | タイムライン上のオブジェクト、メディアオブジェクト、フィルタオブジェクトなどを
-- | SDK経由で操作するときに使用します。実体の型は公開されていないため、
-- | Haskell側では単なる不透明ポインタとして扱います。
type OBJECT_HANDLE = Ptr ()
-- | Windows向けAPIで使われるUTF-16文字列へのポインタです。
-- |
-- | AviUtl2 SDKでは多くの表示用文字列やファイルパスがワイド文字列で表現されるため、
-- | 文字列の受け渡し時にはこの型が頻繁に登場します。
type LPCWSTR = Ptr CWchar
-- | 一部の低水準APIで使われるナロー文字列へのポインタです。
-- |
-- | 主にスクリプトモジュールやエイリアス名など、UTF-16ではなく
-- | バイト列ベースで扱われる文字列に使われます。
type LPCSTR = Ptr CChar
-- | Win32のウィンドウハンドルです。
-- |
-- | 設定ダイアログの親ウィンドウや、ホストウィンドウの取得結果などに使われます。
type HWND = Ptr ()
-- | Win32のモジュールインスタンスハンドルです。
-- |
-- | DLLのインスタンスハンドルとして設定コールバックなどに渡されます。
type HINSTANCE = Ptr ()
-- | SDK内でフラグ値やフォーマット識別子に使われる符号なし整数です。
type DWORD = CULong
-- | AviUtl2 SDKが使用するブール値表現です。
-- |
-- | 実体は 'CBool' ですが、SDKの戻り値や構造体フィールドで頻繁に使うため
-- | 別名を与えています。
type BOOL_ = CBool

-- | Haskellの 'Bool' をSDK互換のブール値へ変換します。
-- |
-- | FFIコールバックへ真偽値を返すときに使用します。
boolToBOOL :: Bool -> BOOL_
boolToBOOL True = 1
boolToBOOL False = 0

-- | SDK互換のブール値をHaskellの 'Bool' に戻します。
-- |
-- | SDKの戻り値を通常の分岐で扱いたいときに使用します。
boolFromBOOL :: BOOL_ -> Bool
boolFromBOOL = (/= 0)

-- | すべてのプラグイン種別で共通になる基本情報です。
-- |
-- | プラグイン名と説明文を保持します。ホスト側はこの情報を
-- | 一覧表示や識別に用います。
data COMMON_PLUGIN_TABLE = COMMON_PLUGIN_TABLE
  { cptName        :: LPCWSTR
  , cptInformation :: LPCWSTR
  } deriving (Show, Generic)

instance Storable COMMON_PLUGIN_TABLE where
  sizeOf _ = 16
  alignment _ = 8
  peek ptr = COMMON_PLUGIN_TABLE
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (cptName v)
    pokeByteOff ptr 8 (cptInformation v)

-- | タイムライン上のオブジェクト位置を表す構造体です。
-- |
-- | レイヤー番号と開始フレーム・終了フレームをまとめて保持します。
-- | SDKではUI表示と異なり、番号が0始まりである点に注意してください。
data OBJECT_LAYER_FRAME = OBJECT_LAYER_FRAME
  { olfLayer :: CInt
  , olfStart :: CInt
  , olfEnd   :: CInt
  } deriving (Show, Eq, Generic)

instance Storable OBJECT_LAYER_FRAME where
  sizeOf _ = 12
  alignment _ = 4
  peek ptr = OBJECT_LAYER_FRAME
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 4
    <*> peekByteOff ptr 8
  poke ptr v = do
    pokeByteOff ptr 0 (olfLayer v)
    pokeByteOff ptr 4 (olfStart v)
    pokeByteOff ptr 8 (olfEnd v)

-- | メディアファイル解析結果を表す構造体です。
-- |
-- | 動画・音声トラック数、総時間、映像サイズなど、
-- | ファイルから取得できた基本情報が格納されます。
data MEDIA_INFO = MEDIA_INFO
  { miVideoTrackNum :: CInt
  , miAudioTrackNum :: CInt
  , miTotalTime     :: CDouble
  , miWidth         :: CInt
  , miHeight        :: CInt
  } deriving (Show, Eq, Generic)

instance Storable MEDIA_INFO where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = MEDIA_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 4
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
  poke ptr v = do
    pokeByteOff ptr 0 (miVideoTrackNum v)
    pokeByteOff ptr 4 (miAudioTrackNum v)
    pokeByteOff ptr 8 (miTotalTime v)
    pokeByteOff ptr 16 (miWidth v)
    pokeByteOff ptr 20 (miHeight v)

-- | モジュールの種別を表す数値IDです。
-- |
-- | 列挙APIで返される 'MODULE_INFO' の 'miType' に入り、
-- | スクリプト由来かプラグイン由来か、どの種別なのかを判定するために使います。
type MODULE_TYPE = CInt

-- | スクリプトフィルタモジュールを表す種別値です。
moduleTypeScriptFilter :: MODULE_TYPE
moduleTypeScriptFilter = 1
-- | スクリプトオブジェクトモジュールを表す種別値です。
moduleTypeScriptObject :: MODULE_TYPE
moduleTypeScriptObject = 2
-- | スクリプトカメラモジュールを表す種別値です。
moduleTypeScriptCamera :: MODULE_TYPE
moduleTypeScriptCamera = 3
-- | スクリプトトラックモジュールを表す種別値です。
moduleTypeScriptTrack :: MODULE_TYPE
moduleTypeScriptTrack = 4
-- | スクリプトモジュールを表す種別値です。
moduleTypeScriptModule :: MODULE_TYPE
moduleTypeScriptModule = 5
-- | 入力プラグインを表す種別値です。
moduleTypePluginInput :: MODULE_TYPE
moduleTypePluginInput = 6
-- | 出力プラグインを表す種別値です。
moduleTypePluginOutput :: MODULE_TYPE
moduleTypePluginOutput = 7
-- | フィルタプラグインを表す種別値です。
moduleTypePluginFilter :: MODULE_TYPE
moduleTypePluginFilter = 8
-- | 汎用プラグインを表す種別値です。
moduleTypePluginCommon :: MODULE_TYPE
moduleTypePluginCommon = 9

-- | モジュール列挙時に返される基本情報です。
-- |
-- | 種別、名前、説明文をまとめて保持します。'enumModuleInfo' のような
-- | 列挙系APIのコールバックで受け取る想定の構造体です。
data MODULE_INFO = MODULE_INFO
  { miType        :: MODULE_TYPE
  , miName        :: LPCWSTR
  , miInformation :: LPCWSTR
  } deriving (Show, Generic)

instance Storable MODULE_INFO where
  sizeOf _ = 24
  alignment _ = 8
  peek ptr = MODULE_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (miType v)
    pokeByteOff ptr 8 (miName v)
    pokeByteOff ptr 16 (miInformation v)

-- | 現在の編集状態をまとめたスナップショットです。
-- |
-- | シーンのサイズ、フレームレート、サンプルレート、現在位置、
-- | 表示範囲、選択範囲、グリッド設定など、編集画面の状態が入ります。
-- | 値は取得時点の状態を表すもので、自動更新はされません。
data EDIT_INFO = EDIT_INFO
  { eiWidth             :: CInt
  , eiHeight            :: CInt
  , eiRate              :: CInt
  , eiScale             :: CInt
  , eiSampleRate        :: CInt
  , eiFrame             :: CInt
  , eiLayer             :: CInt
  , eiFrameMax          :: CInt
  , eiLayerMax          :: CInt
  , eiDisplayFrameStart :: CInt
  , eiDisplayLayerStart :: CInt
  , eiDisplayFrameNum   :: CInt
  , eiDisplayLayerNum   :: CInt
  , eiSelectRangeStart  :: CInt
  , eiSelectRangeEnd    :: CInt
  , eiGridBpmTempo      :: CFloat
  , eiGridBpmBeat       :: CInt
  , eiGridBpmOffset     :: CFloat
  , eiSceneId           :: CInt
  } deriving (Show, Generic)

instance Storable EDIT_INFO where
  sizeOf _ = 76
  alignment _ = 4
  peek ptr = EDIT_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 4
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 20
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 28
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 36
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 44
    <*> peekByteOff ptr 48
    <*> peekByteOff ptr 52
    <*> peekByteOff ptr 56
    <*> peekByteOff ptr 60
    <*> peekByteOff ptr 64
    <*> peekByteOff ptr 68
    <*> peekByteOff ptr 72
  poke ptr v = do
    pokeByteOff ptr 0 (eiWidth v)
    pokeByteOff ptr 4 (eiHeight v)
    pokeByteOff ptr 8 (eiRate v)
    pokeByteOff ptr 12 (eiScale v)
    pokeByteOff ptr 16 (eiSampleRate v)
    pokeByteOff ptr 20 (eiFrame v)
    pokeByteOff ptr 24 (eiLayer v)
    pokeByteOff ptr 28 (eiFrameMax v)
    pokeByteOff ptr 32 (eiLayerMax v)
    pokeByteOff ptr 36 (eiDisplayFrameStart v)
    pokeByteOff ptr 40 (eiDisplayLayerStart v)
    pokeByteOff ptr 44 (eiDisplayFrameNum v)
    pokeByteOff ptr 48 (eiDisplayLayerNum v)
    pokeByteOff ptr 52 (eiSelectRangeStart v)
    pokeByteOff ptr 56 (eiSelectRangeEnd v)
    pokeByteOff ptr 60 (eiGridBpmTempo v)
    pokeByteOff ptr 64 (eiGridBpmBeat v)
    pokeByteOff ptr 68 (eiGridBpmOffset v)
    pokeByteOff ptr 72 (eiSceneId v)

-- | RGBA 8bitずつで構成された1ピクセルです。
-- |
-- | フィルタ処理や出力処理で画像バッファを扱う際の基本単位として使います。
data PIXEL_RGBA = PIXEL_RGBA
  { prR :: Word8
  , prG :: Word8
  , prB :: Word8
  , prA :: Word8
  } deriving (Show, Eq, Generic)

instance Storable PIXEL_RGBA where
  sizeOf _ = 4
  alignment _ = 1
  peek ptr = PIXEL_RGBA
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 1
    <*> peekByteOff ptr 2
    <*> peekByteOff ptr 3
  poke ptr v = do
    pokeByteOff ptr 0 (prR v)
    pokeByteOff ptr 1 (prG v)
    pokeByteOff ptr 2 (prB v)
    pokeByteOff ptr 3 (prA v)

-- | フィルタ処理中のシーン情報です。
-- |
-- | 現在処理対象となっているシーンの映像サイズ、フレームレート、
-- | サンプルレートなど、映像・音声処理共通の環境情報が格納されます。
data SCENE_INFO = SCENE_INFO
  { siWidth      :: CInt
  , siHeight     :: CInt
  , siRate       :: CInt
  , siScale      :: CInt
  , siSampleRate :: CInt
  } deriving (Show, Eq, Generic)

instance Storable SCENE_INFO where
  sizeOf _ = 20
  alignment _ = 4
  peek ptr = SCENE_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 4
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12
    <*> peekByteOff ptr 16
  poke ptr v = do
    pokeByteOff ptr 0 (siWidth v)
    pokeByteOff ptr 4 (siHeight v)
    pokeByteOff ptr 8 (siRate v)
    pokeByteOff ptr 12 (siScale v)
    pokeByteOff ptr 16 (siSampleRate v)

-- | フィルタ処理対象オブジェクトの情報です。
-- |
-- | 現在フレーム、経過時間、オブジェクト全体の長さ、音声サンプル位置、
-- | エフェクトID、フラグなど、処理対象オブジェクトの状態を参照できます。
data OBJECT_INFO = OBJECT_INFO
  { oiId          :: Int64
  , oiFrame       :: CInt
  , oiFrameTotal  :: CInt
  , oiTime        :: CDouble
  , oiTimeTotal   :: CDouble
  , oiWidth       :: CInt
  , oiHeight      :: CInt
  , oiSampleIndex :: Int64
  , oiSampleTotal :: Int64
  , oiSampleNum   :: CInt
  , oiChannelNum  :: CInt
  , oiEffectId    :: Int64
  , oiFlag        :: CInt
  } deriving (Show, Generic)

-- | オブジェクトがフィルタオブジェクトであることを示すフラグです。
objFlagFilterObject :: CInt
objFlagFilterObject = 1

-- | 'OBJECT_INFO' がフィルタオブジェクトを指しているかを判定します。
-- |
-- | 'oiFlag' のビット列から 'objFlagFilterObject' を検査します。
isObjectFilterObject :: OBJECT_INFO -> Bool
isObjectFilterObject oi = oiFlag oi .&. objFlagFilterObject /= 0

instance Storable OBJECT_INFO where
  sizeOf _ = 80
  alignment _ = 8
  peek ptr = OBJECT_INFO
    <$> peekByteOff ptr 0
    <*> peekByteOff ptr 8
    <*> peekByteOff ptr 12
    <*> peekByteOff ptr 16
    <*> peekByteOff ptr 24
    <*> peekByteOff ptr 32
    <*> peekByteOff ptr 36
    <*> peekByteOff ptr 40
    <*> peekByteOff ptr 48
    <*> peekByteOff ptr 56
    <*> peekByteOff ptr 60
    <*> peekByteOff ptr 64
    <*> peekByteOff ptr 72
  poke ptr v = do
    pokeByteOff ptr 0 (oiId v)
    pokeByteOff ptr 8 (oiFrame v)
    pokeByteOff ptr 12 (oiFrameTotal v)
    pokeByteOff ptr 16 (oiTime v)
    pokeByteOff ptr 24 (oiTimeTotal v)
    pokeByteOff ptr 32 (oiWidth v)
    pokeByteOff ptr 36 (oiHeight v)
    pokeByteOff ptr 40 (oiSampleIndex v)
    pokeByteOff ptr 48 (oiSampleTotal v)
    pokeByteOff ptr 56 (oiSampleNum v)
    pokeByteOff ptr 60 (oiChannelNum v)
    pokeByteOff ptr 64 (oiEffectId v)
    pokeByteOff ptr 72 (oiFlag v)

-- | エフェクト種別を表す数値IDです。
-- |
-- | エフェクト列挙時などに、通常フィルタなのか、入力系なのか、
-- | トランジションなのかを識別するために使います。
type EFFECT_TYPE = CInt
-- | 通常のフィルタエフェクトを表す種別値です。
effectTypeFilter :: EFFECT_TYPE
effectTypeFilter = 1
-- | 入力系エフェクトを表す種別値です。
effectTypeInput :: EFFECT_TYPE
effectTypeInput = 2
-- | トランジションエフェクトを表す種別値です。
effectTypeTransition :: EFFECT_TYPE
effectTypeTransition = 3

-- | エフェクトが扱うデータ種別を示すビットフラグです。
-- |
-- | 映像対応、音声対応、フィルタ扱いかどうかなどを表現します。
type EFFECT_FLAG = CInt
-- | 映像を扱うエフェクトであることを示すフラグです。
effectFlagVideo :: EFFECT_FLAG
effectFlagVideo = 1
-- | 音声を扱うエフェクトであることを示すフラグです。
effectFlagAudio :: EFFECT_FLAG
effectFlagAudio = 2
-- | フィルタとして扱われることを示すフラグです。
effectFlagFilter :: EFFECT_FLAG
effectFlagFilter = 4

-- | 編集状態を表す値です。
-- |
-- | 'getEditState' の戻り値として使われ、現在が通常編集中か、
-- | 再生中か、保存中かを判定できます。
type EDIT_STATE = CInt
-- | 通常の編集状態です。
editStateEdit :: EDIT_STATE
editStateEdit = 0
-- | 再生中であることを示します。
editStatePlay :: EDIT_STATE
editStatePlay = 1
-- | 保存処理中であることを示します。
editStateSave :: EDIT_STATE
editStateSave = 2
