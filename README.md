# aviutl2-hs

# 研究目的以外で使用するのは非推奨です

Haskell から AviUtl ExEdit2 プラグインを作るための SDK です。  
`aviutl2_sdk` の C/C++ ヘッダを Haskell FFI 向けに移植し、`Storable` 実装、関数ポインタ呼び出し、各種プラグイン用の型を提供します。  


SDKの更新に合わせてリアルタイムに追従はしません。  
最新のSDKを使用したい場合は本家のSDKで作るかRustで作成してください。

SDK対応状態
- AviUtl2 beta41a
- 2026/4/12 に更新されたSDK

## 状態

- SDK 本体はロード可能な水準まで移植済みです
- `cabal build` は通ります
- Win64 ABI に合わせて struct layout / basic type を調整済みです
- サンプルは `aviutl2-rs` 由来の移植を優先して整理しています

現状の exposed modules:

- `AviUtl2.Plugin`
- `AviUtl2.Types`
- `AviUtl2.Logger`
- `AviUtl2.Config`
- `AviUtl2.Filter`
- `AviUtl2.Input`
- `AviUtl2.Output`
- `AviUtl2.Module`
- `AviUtl2.Edit`
- `AviUtl2.Host`

`AviUtl2.Plugin` は上記をまとめて再 export する入口です。

## 前提

- Windows x86_64
- GHC / Cabal
- AviUtl ExEdit2

この repo では `RequiredVersion = 2003300` を使っています。

## 構成

- `src/`: SDK 本体
- `cbits/`: DLL 初期化や ABI 補助用の C コード
- `examples/`: Haskell 製サンプル
- `scripts/`: 配布用ビルドスクリプト
- `plugin/`: 配布用にまとめた成果物
- `vendor/`: 配布時に同梱する外部ランタイム

`build/`、`dist-newstyle/`、`.tmp/` はローカル生成物です。配布物には含めません。

## ライブラリのビルド

```powershell
cabal build
```

ライブラリ本体は [aviutl2.cabal](/E:/opencode/aviutl2_sdk/aviutl2-hs/aviutl2.cabal:1) で定義しています。

## 配布用サンプルのビルド

`aviutl2-rs` と同様に、配布物は `plugin/` に集約します。

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-rs-port-samples.ps1
```

これで次の成果物が `plugin/` に出力されます。

- `RsMetronomePlugin.aux2`
- `RsRandomColorFilter.auf2`
- `RsSingleImageOutput.auo2`
- `RsUsernameModule.mod2`
- `RsPixelFormatTestInput.aui2`
- `libsharpyuv-0.dll`
- `libwebp-7.dll`
- `zlib1.dll`
- `licenses/`

そのまま AviUtl2 にコピーしたい場合は `-Deploy` を付けます。

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-rs-port-samples.ps1 -Deploy
```

`.auf2` / `.aui2` / `.auo2` / `.aux2` は `C:\ProgramData\aviutl2\Plugin`、`.mod2` は `C:\ProgramData\aviutl2\Script` にコピーされます。

## DLL プラグインの作り方

この SDK はライブラリとして使えますが、AviUtl2 に読み込ませるには最終的に Windows DLL としてビルドする必要があります。

重要な点:

- `foreign export ccall` だけでは export 名が安定しないため、`.def` ファイルを併用します
- Haskell RTS 初期化のために [cbits/hs_dllmain.c](/E:/opencode/aviutl2_sdk/aviutl2-hs/cbits/hs_dllmain.c:1) を一緒にリンクします
- struct return の都合で [cbits/aviutl2_shims.c](/E:/opencode/aviutl2_sdk/aviutl2-hs/cbits/aviutl2_shims.c:1) をリンクします

典型的なビルド例:

```powershell
ghc --make -shared -no-hs-main `
  -isrc -iexamples `
  -odir build\MyPlugin_obj `
  -hidir build\MyPlugin_obj `
  -o build\MyPlugin.auf2 `
  examples\MyPlugin.hs `
  cbits\hs_dllmain.c `
  cbits\aviutl2_shims.c `
  build\MyPlugin.def
```

`.def` の中身の例

```def
EXPORTS
  RequiredVersion
  InitializePlugin
  UninitializePlugin
  GetFilterPluginTable
```

## 収録サンプル

主サンプルは `aviutl2-rs` の examples を Haskell に移植したものです。

- `RandomColorFilter.hs` → `aviutl2-rs/examples/random-color-filter`
- `SingleImageOutput.hs` → `aviutl2-rs/examples/image-rs-single-output`
- `UsernameModule.hs` → `aviutl2-rs/examples/username-module`
- `PixelFormatTestInput.hs` → `aviutl2-rs/examples/pixel-format-test-input`
- `MetronomePlugin.hs` → `aviutl2-rs/examples/metronome-plugin`

実際の export 定義や table 構築は [examples](/E:/opencode/aviutl2_sdk/aviutl2-hs/examples) を参照してください。

## 最小のコード例

```haskell
module MyModule where

import AviUtl2.Plugin
```

## 注意

- これは AviUtl2 用の Windows 専用 SDK です
- SDK 本体は移植済みですが、すべてのサンプルが C++ 版と同等機能ではありません
- 実運用するプラグインでは、エラー処理とメモリ寿命を各自で明示的に管理してください
