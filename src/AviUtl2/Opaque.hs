module AviUtl2.Opaque
  ( OpaqueHandle
  , wrapOpaqueHandle
  , unwrapOpaqueHandle
  , nullOpaqueHandle
  , isNullOpaqueHandle
  , ObjectTag
  , WindowTag
  , ModuleInstanceTag
  , InputStateTag
  , UserDataTag
  , RawBufferTag
  , D3D11Texture2DTag
  , D3D11BlendStateTag
  , D3D11SamplerStateTag
  , DWriteFontCollectionTag
  , ObjectHandle
  , WindowHandle
  , ModuleInstanceHandle
  , InputStateHandle
  , UserDataHandle
  , RawBufferHandle
  , D3D11Texture2DHandle
  , D3D11BlendStateHandle
  , D3D11SamplerStateHandle
  , DWriteFontCollectionHandle
  ) where

import Foreign.Ptr (Ptr, nullPtr)

newtype OpaqueHandle tag = OpaqueHandle { unwrapOpaqueHandle :: Ptr () }
  deriving (Eq, Ord, Show)

wrapOpaqueHandle :: Ptr () -> OpaqueHandle tag
wrapOpaqueHandle = OpaqueHandle

nullOpaqueHandle :: OpaqueHandle tag
nullOpaqueHandle = OpaqueHandle nullPtr

isNullOpaqueHandle :: OpaqueHandle tag -> Bool
isNullOpaqueHandle (OpaqueHandle ptr) =
  ptr == nullPtr

data ObjectTag
data WindowTag
data ModuleInstanceTag
data InputStateTag
data UserDataTag
data RawBufferTag
data D3D11Texture2DTag
data D3D11BlendStateTag
data D3D11SamplerStateTag
data DWriteFontCollectionTag

type ObjectHandle = OpaqueHandle ObjectTag
type WindowHandle = OpaqueHandle WindowTag
type ModuleInstanceHandle = OpaqueHandle ModuleInstanceTag
type InputStateHandle = OpaqueHandle InputStateTag
type UserDataHandle = OpaqueHandle UserDataTag
type RawBufferHandle = OpaqueHandle RawBufferTag
type D3D11Texture2DHandle = OpaqueHandle D3D11Texture2DTag
type D3D11BlendStateHandle = OpaqueHandle D3D11BlendStateTag
type D3D11SamplerStateHandle = OpaqueHandle D3D11SamplerStateTag
type DWriteFontCollectionHandle = OpaqueHandle DWriteFontCollectionTag
