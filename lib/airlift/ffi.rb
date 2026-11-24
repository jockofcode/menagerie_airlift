# SDL3 entry points the sdl package does not bind itself. Everything the
# procedural art pipeline needs: creating a texture from a pixel buffer
# built in Ruby, blend modes, and reading glyph pixels back out of a
# TTF-rendered surface so text can be baked into the playfield art.
module ChopFFI
  ffi_lib "SDL3"

  ffi_func :SDL_CreateTexture,          [:ptr, :int, :int, :int, :int], :ptr
  ffi_func :SDL_UpdateTexture,          [:ptr, :ptr, :ptr, :int], :bool
  ffi_func :SDL_SetTextureBlendMode,    [:ptr, :uint32], :bool
  ffi_func :SDL_SetTextureScaleMode,    [:ptr, :int], :bool
  ffi_func :SDL_SetRenderDrawBlendMode, [:ptr, :uint32], :bool
  ffi_func :SDL_ReadSurfacePixel,       [:ptr, :int, :int, :ptr, :ptr, :ptr, :ptr], :bool
  ffi_func :SDL_GetWindowPosition,      [:ptr, :ptr, :ptr], :bool
  ffi_func :SDL_RaiseWindow,            [:ptr], :bool
  ffi_func :SDL_SetWindowPosition,      [:ptr, :int, :int], :bool
  ffi_func :SDL_WarpMouseInWindow,      [:ptr, :float, :float], :void
  ffi_func :SDL_RenderReadPixels,       [:ptr, :ptr], :ptr
  ffi_func :SDL_SaveBMP,                [:ptr, :str], :bool
  ffi_func :SDL_DestroySurface,         [:ptr], :void

  PIXELFORMAT_RGBA32   = 0x16762004
  TEXTUREACCESS_STATIC = 0
  BLENDMODE_NONE  = 0
  BLENDMODE_BLEND = 1
  BLENDMODE_ADD   = 2
  SCALEMODE_NEAREST = 0
  SCALEMODE_LINEAR  = 1
end
