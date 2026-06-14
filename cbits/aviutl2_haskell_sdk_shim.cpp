#include <windows.h>
#include <cstdint>
#include <new>

#include "HsFFI.h"
#include "aviutl2_sdk/filter2.h"
#include "aviutl2_sdk/cache2.h"

static LONG hs_runtime_initialized = 0;

extern "C" BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
  switch (fdwReason) {
    case DLL_PROCESS_ATTACH: {
      int argc = 1;
      char* argv_[] = { const_cast<char*>("aviutl2-haskell-sdk-plugin"), nullptr };
      char** argv = argv_;
      DisableThreadLibraryCalls(hinstDLL);
      hs_init(&argc, &argv);
      InterlockedExchange(&hs_runtime_initialized, 1);
      break;
    }
    case DLL_PROCESS_DETACH:
      if (lpvReserved == nullptr &&
          InterlockedCompareExchange(&hs_runtime_initialized, 0, 1) == 1) {
        hs_exit();
      }
      break;
    default:
      break;
  }
  return TRUE;
}

extern "C" {

struct HS_CACHE_IMAGE {
  void* handle;
  PIXEL_RGBA* buffer;
  int width;
  int height;
};

struct HS_CACHE_AUDIO {
  void* handle;
  float* buffer0;
  float* buffer1;
  int sample_num;
  int channel_num;
};

struct HS_CACHE_FILE_IMAGE {
  void* handle;
  const void* buffer;
  int width;
  int height;
  int pitch;
  int format;
};

}

namespace {

struct ImageHolder {
  CACHE_IMAGE value;

  ImageHolder(CACHE_HANDLE* cache, void* identifier, LPCWSTR name)
      : value(cache->get_image_cache(identifier, name)) {}

  ImageHolder(CACHE_HANDLE* cache, void* identifier, LPCWSTR name, int width, int height)
      : value(cache->create_image_cache(identifier, name, width, height)) {}

  explicit ImageHolder(CACHE_HANDLE* cache, LPCWSTR file)
      : value(cache->deprecated_get_image_file_cache(file)) {}
};

struct AudioHolder {
  CACHE_AUDIO value;

  AudioHolder(CACHE_HANDLE* cache, void* identifier, LPCWSTR name)
      : value(cache->get_audio_cache(identifier, name)) {}

  AudioHolder(CACHE_HANDLE* cache, void* identifier, LPCWSTR name, int sample_num, int channel_num)
      : value(cache->create_audio_cache(identifier, name, sample_num, channel_num)) {}
};

struct FileImageHolder {
  CACHE_FILE_IMAGE value;

  FileImageHolder(CACHE_HANDLE* cache, LPCWSTR file)
      : value(cache->get_image_file_cache(file)) {}

  FileImageHolder(CACHE_HANDLE* cache, LPCWSTR file, int track, int frame)
      : value(cache->get_video_file_cache(file, track, frame)) {}

  FileImageHolder(CACHE_HANDLE* cache, LPCWSTR file, int track, double time)
      : value(cache->get_video_file_cache_by_time(file, track, time)) {}
};

void clear_image(HS_CACHE_IMAGE* out) {
  if (!out) return;
  out->handle = nullptr;
  out->buffer = nullptr;
  out->width = 0;
  out->height = 0;
}

void clear_audio(HS_CACHE_AUDIO* out) {
  if (!out) return;
  out->handle = nullptr;
  out->buffer0 = nullptr;
  out->buffer1 = nullptr;
  out->sample_num = 0;
  out->channel_num = 0;
}

void clear_file_image(HS_CACHE_FILE_IMAGE* out) {
  if (!out) return;
  out->handle = nullptr;
  out->buffer = nullptr;
  out->width = 0;
  out->height = 0;
  out->pitch = 0;
  out->format = 0;
}

bool write_image(ImageHolder* holder, HS_CACHE_IMAGE* out) {
  if (!holder || !out || !holder->value) {
    delete holder;
    clear_image(out);
    return false;
  }
  out->handle = holder;
  out->buffer = holder->value.buffer;
  out->width = holder->value.width;
  out->height = holder->value.height;
  return true;
}

bool write_audio(AudioHolder* holder, HS_CACHE_AUDIO* out) {
  if (!holder || !out || !holder->value) {
    delete holder;
    clear_audio(out);
    return false;
  }
  out->handle = holder;
  out->buffer0 = holder->value.buffer0;
  out->buffer1 = holder->value.buffer1;
  out->sample_num = holder->value.sample_num;
  out->channel_num = holder->value.channel_num;
  return true;
}

bool write_file_image(FileImageHolder* holder, HS_CACHE_FILE_IMAGE* out) {
  if (!holder || !out || !holder->value) {
    delete holder;
    clear_file_image(out);
    return false;
  }
  out->handle = holder;
  out->buffer = holder->value.buffer;
  out->width = holder->value.width;
  out->height = holder->value.height;
  out->pitch = holder->value.pitch;
  out->format = static_cast<int>(holder->value.format);
  return true;
}

}

extern "C" {

bool hs_aviutl2_cache_get_image_cache(
    CACHE_HANDLE* cache,
    void* identifier,
    LPCWSTR name,
    HS_CACHE_IMAGE* out) {
  if (!cache || !cache->get_image_cache) {
    clear_image(out);
    return false;
  }
  return write_image(new (std::nothrow) ImageHolder(cache, identifier, name), out);
}

bool hs_aviutl2_cache_create_image_cache(
    CACHE_HANDLE* cache,
    void* identifier,
    LPCWSTR name,
    int width,
    int height,
    HS_CACHE_IMAGE* out) {
  if (!cache || !cache->create_image_cache) {
    clear_image(out);
    return false;
  }
  return write_image(new (std::nothrow) ImageHolder(cache, identifier, name, width, height), out);
}

void hs_aviutl2_cache_release_image(HS_CACHE_IMAGE* image) {
  if (!image || !image->handle) return;
  delete static_cast<ImageHolder*>(image->handle);
  clear_image(image);
}

bool hs_aviutl2_cache_get_audio_cache(
    CACHE_HANDLE* cache,
    void* identifier,
    LPCWSTR name,
    HS_CACHE_AUDIO* out) {
  if (!cache || !cache->get_audio_cache) {
    clear_audio(out);
    return false;
  }
  return write_audio(new (std::nothrow) AudioHolder(cache, identifier, name), out);
}

bool hs_aviutl2_cache_create_audio_cache(
    CACHE_HANDLE* cache,
    void* identifier,
    LPCWSTR name,
    int sample_num,
    int channel_num,
    HS_CACHE_AUDIO* out) {
  if (!cache || !cache->create_audio_cache) {
    clear_audio(out);
    return false;
  }
  return write_audio(new (std::nothrow) AudioHolder(cache, identifier, name, sample_num, channel_num), out);
}

void hs_aviutl2_cache_release_audio(HS_CACHE_AUDIO* audio) {
  if (!audio || !audio->handle) return;
  delete static_cast<AudioHolder*>(audio->handle);
  clear_audio(audio);
}

bool hs_aviutl2_cache_deprecated_get_image_file_cache(
    CACHE_HANDLE* cache,
    LPCWSTR file,
    HS_CACHE_IMAGE* out) {
  if (!cache || !cache->deprecated_get_image_file_cache) {
    clear_image(out);
    return false;
  }
  return write_image(new (std::nothrow) ImageHolder(cache, file), out);
}

bool hs_aviutl2_cache_get_image_file_cache(
    CACHE_HANDLE* cache,
    LPCWSTR file,
    HS_CACHE_FILE_IMAGE* out) {
  if (!cache || !cache->get_image_file_cache) {
    clear_file_image(out);
    return false;
  }
  return write_file_image(new (std::nothrow) FileImageHolder(cache, file), out);
}

bool hs_aviutl2_cache_get_video_file_cache(
    CACHE_HANDLE* cache,
    LPCWSTR file,
    int track,
    int frame,
    HS_CACHE_FILE_IMAGE* out) {
  if (!cache || !cache->get_video_file_cache) {
    clear_file_image(out);
    return false;
  }
  return write_file_image(new (std::nothrow) FileImageHolder(cache, file, track, frame), out);
}

bool hs_aviutl2_cache_get_video_file_cache_by_time(
    CACHE_HANDLE* cache,
    LPCWSTR file,
    int track,
    double time,
    HS_CACHE_FILE_IMAGE* out) {
  if (!cache || !cache->get_video_file_cache_by_time) {
    clear_file_image(out);
    return false;
  }
  return write_file_image(new (std::nothrow) FileImageHolder(cache, file, track, time), out);
}

void hs_aviutl2_cache_release_file_image(HS_CACHE_FILE_IMAGE* image) {
  if (!image || !image->handle) return;
  delete static_cast<FileImageHolder*>(image->handle);
  clear_file_image(image);
}

}
