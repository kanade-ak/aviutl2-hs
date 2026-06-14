# aviutl2-haskell-sdk

# 研究目的以外で使用するのは非推奨です

HaskellでAviUtl ExEdit2 プラグインを作るためのSDKです。  
`aviutl2_sdk`のC/C++ヘッダをHaskell FFI 向けに移植し、`Storable` 実装、関数ポインタ呼び出し、各種プラグイン用の型を提供します。

SDKの更新に合わせてリアルタイムに追従はしません。  
最新のSDKを使用したい場合は、本家のSDKで作るか、Rust版SDKの利用を行ってください。

## AviUtl2 SDK参照元

このリポジトリではAviUtl2 SDKヘッダを同梱せず、`external/aviutl2_sdk_mirror` submodule を[aviutl2/aviutl2_sdk_mirrorのcommit `95c244dfb1eb4796faafd415c9a0fe3be7645991`](https://github.com/aviutl2/aviutl2_sdk_mirror/tree/95c244dfb1eb4796faafd415c9a0fe3be7645991)に固定して参照します。

clone後は次を実行してください。

```powershell
git submodule update --init --recursive
```

AviUtl2 SDKのライセンスは`licenses/aviutl2_sdk_license.txt`を参照してください。

SDK 対応状態:

- AviUtl2 beta50
- 2026/6/14 に更新されたSDK
- Windows x86_64 / GHC 9.6系

## 状態

- SDK本体はロード可能な水準まで移植済みです
- `cabal build`は通ります
- Win64 ABIに合わせてstruct layout / basic typeを調整済みです
- 通常の型定義、関数ポインタテーブル、コールバック、プラグインエクスポートはHaskell側に置いています
- Haskell FFIだけではABI的に安全に扱えない部分は `cbits/aviutl2_haskell_sdk_shim.cpp`に残しています
- `cache2.h`はC++の値返しAPIをC++ shim経由で扱います
- サンプルは`aviutl2-rs`由来の移植を優先して整理しています

現状のexposed modules:

- `AviUtl2.Plugin`
- `AviUtl2.Opaque`
- `AviUtl2.Types`
- `AviUtl2.Logger`
- `AviUtl2.Config`
- `AviUtl2.Filter`
- `AviUtl2.Filter.Builder`
- `AviUtl2.Input`
- `AviUtl2.Output`
- `AviUtl2.Module`
- `AviUtl2.Edit`
- `AviUtl2.Host`
- `AviUtl2.Cache`
- `AviUtl2.Plugin.Export`

`AviUtl2.Plugin`は上記をまとめて再exportする入口です。

## 前提

- Windows x86_64
- GHC / Cabal
- AviUtl ExEdit2

このrepoでは`RequiredVersion = 2003300` を使っています。

## 構成

- `src/`: SDK本体
- `cbits/`: Haskell RTS初期化やABI補助用のC++ shim
- `external/aviutl2_sdk_mirror/`: C++ shimが参照するAviUtl2 SDK mirror submodule
- `examples/`: Haskell製サンプル
- `scripts/`: サンプルDLLのビルドスクリプト
- `licenses/`: 同梱ライセンス

`build/`、`dist-newstyle/`、`plugin/`、`.tmp/` はローカル生成物です。配布物には含めません。

## ライブラリのビルド

```powershell
cabal build
```

ライブラリ本体は`aviutl2-haskell-sdk.cabal`で定義しています。

## 配布用サンプルのビルド

配布物は`plugin/`に集約します。

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-rs-port-samples.ps1
```

これで次の成果物が`plugin/`に出力されます。

- `HsRandomColorFilter.auf2`
- `HsPixelRgbaByValueFilter.auf2`
- `HsObjectLayerFrameSretFilter.auf2`
- `HsUsernameModule.mod2`
- `HsPixelFormatTestInput.aui2`
- `HsMetronomePlugin.aux2`
- `licenses/`

C++ランタイムなどの非Windows標準依存はプラグインDLLへ静的リンクします。ビルド後にimport tableを検査し、非Windows標準DLLへの依存が残っている場合はビルドを失敗させます。

そのままAviUtl2にコピーしたい場合は`-Deploy`を付けます。

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-rs-port-samples.ps1 -Deploy -AviUtl2Dir ..\aviutl2beta50
```

`-Deploy`は`-AviUtl2Dir`で指定したAviUtl2フォルダ、または隣接する`..\aviutl2beta50`がある場合だけ動きます。デプロイ先の既定値には、ユーザー名や環境固有の絶対パスを使いません。

## DLLプラグインの作り方

AviUtl2に読み込ませるにはWindowsDLLとしてビルドする必要があります。

重要な点:

- `foreign export ccall`だけではexport名が安定しないため、`.def`ファイルを併用します
- Haskell RTS初期化のために`cbits/aviutl2_haskell_sdk_shim.cpp`を一緒にリンクします
- struct return、by-value引数、`cache2.h`のC++値返しAPIはC++ shimで補助します

ビルド例:

```powershell
ghc --make -shared -threaded -no-hs-main `
  -isrc -iexamples `
  -Iexternal\aviutl2_sdk_mirror\include `
  -optcxx-std=c++17 `
  -odir build\MyPlugin_obj `
  -hidir build\MyPlugin_obj `
  -o build\MyPlugin.auf2 `
  examples\MyPlugin.hs `
  cbits\aviutl2_haskell_sdk_shim.cpp `
  build\MyPlugin.def
```

`.def`の中身の例:

```def
EXPORTS
  RequiredVersion
  InitializePlugin
  UninitializePlugin
  GetFilterPluginTable
```

`.def`のEXPORTSは`AviUtl2.Plugin.Export`でも生成できます。

```haskell
import AviUtl2.Plugin.Export

main :: IO ()
main =
  writePluginDefFile "build/MyPlugin.def" filterPluginExportNames
```

最小構成だけが必要な場合は`minimalPluginExportNames ExportFilterPlugin`、ログ・設定・キャッシュ初期化なども含めたい場合は`pluginExportNames`と`PluginExportOptions`を使ってください。

## フィルタ項目ビルダー

`AviUtl2.Filter.Builder`はC++ SDKの各`FILTER_ITEM_*`コンストラクタ相当をHaskell側で生成できます。

```haskell
widthTrack = staticTrackItem (defaultFilterTrack "Width" 640)
enabled = staticCheckItem "Enabled" True
mode = staticSelectItem "Mode" 0 [("Normal", 0), ("Add", 1)]
hiddenData = staticDataItem "Data" (0 :: Int)
```

生成した項目は`trackFilterItem`、`checkFilterItem`、`selectFilterItem`、`dataFilterItem`などで`FilterItem`に変換し、`filterPluginItems`へ渡します。`FILTER_ITEM_DATA<T>`は`Storable a => DataItem a`として扱い、`readDataValue` / `writeDataValue`で現在値にアクセスします。

## opaque handle

低レベルAPIはSDK互換のため`Ptr ()`をそのまま受け渡しますが、Haskell側で用途を分けたい場合は`AviUtl2.Opaque`の`OpaqueHandle tag`を使えます。

```haskell
let objectHandle = wrapOpaqueHandle rawObjectPtr :: ObjectHandle
```

既存APIへ戻す場合は`unwrapOpaqueHandle`を使います。

## cache2.hの扱い

`cache2.h`のキャッシュ取得関数はC++の非自明な値戻り型を返します。Haskell FFIから直接受け取ると寿命管理とC++ ABIが破綻するため、C++ shim 内で RAIIオブジェクトを保持し、Haskell側にはビューだけを返します。

例:

```haskell
alloca $ \image -> do
  ok <- getImageCache cache identifier name image
  when (boolFromBOOL ok) $ do
    img <- peek image
    -- ciBuffer / ciWidth / ciHeight を利用
    releaseImageCache image
```

取得に成功した `CACHE_IMAGE`, `CACHE_AUDIO`, `CACHE_FILE_IMAGE` は、それぞれ `releaseImageCache`, `releaseAudioCache`, `releaseFileImageCache`で解放してください。

## 注意

- これはAviUtl 2用のWindows専用SDKです
- SDK本体は移植済みですが、すべてのサンプルがC++版と同等機能ではありません
- 実運用するプラグインでは、エラー処理とメモリ寿命を各自で明示的に管理してください
