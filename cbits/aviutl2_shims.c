#include <stdint.h>

typedef void* OBJECT_HANDLE;

typedef struct OBJECT_LAYER_FRAME {
  int layer;
  int start;
  int end;
} OBJECT_LAYER_FRAME;

typedef OBJECT_LAYER_FRAME (*get_object_layer_frame_fn)(OBJECT_HANDLE object);

void hs_aviutl2_get_object_layer_frame(get_object_layer_frame_fn fn, OBJECT_HANDLE object, OBJECT_LAYER_FRAME* out) {
  *out = fn(object);
}
