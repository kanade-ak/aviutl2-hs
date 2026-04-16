#include <stdint.h>
#include <stdlib.h>
#include <string.h>

uintptr_t __stack_chk_guard = 0x595e9fbd94fda766ULL;

void __stack_chk_fail(void) {
    abort();
}

void* __memcpy_chk(void* dest, const void* src, size_t len, size_t destlen) {
    if (len > destlen) {
        abort();
    }
    return memcpy(dest, src, len);
}
