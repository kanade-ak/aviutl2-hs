#include <windows.h>
#include "HsFFI.h"

static LONG hs_runtime_initialized = 0;

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
  switch (fdwReason) {
    case DLL_PROCESS_ATTACH: {
      int argc = 1;
      char* argv_[] = { "aviutl2-hs-plugin", NULL };
      char** argv = argv_;
      DisableThreadLibraryCalls(hinstDLL);
      hs_init(&argc, &argv);
      InterlockedExchange(&hs_runtime_initialized, 1);
      break;
    }
    case DLL_PROCESS_DETACH:
      if (lpvReserved == NULL &&
          InterlockedCompareExchange(&hs_runtime_initialized, 0, 1) == 1) {
        hs_exit();
      }
      break;
    default:
      break;
  }
  return TRUE;
}
