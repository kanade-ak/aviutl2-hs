#include <HsFFI.h>
#if defined(__cplusplus)
extern "C" {
#endif
extern HsWord32 RequiredVersion(void);
extern HsWord8 InitializePlugin(HsWord32 a1);
extern void UninitializePlugin(void);
extern HsPtr GetInputPluginTable(void);
extern HsInt32 zdmainzdPixelFormatTestInputzdPixelFormatTestInputzumkReadVideo(StgStablePtr the_stableptr, HsPtr a1, HsInt32 a2, HsPtr a3);
extern HsWord8 zdmainzdPixelFormatTestInputzdPixelFormatTestInputzumkInfoGet(StgStablePtr the_stableptr, HsPtr a1, HsPtr a2);
extern HsWord8 zdmainzdPixelFormatTestInputzdPixelFormatTestInputzumkClose(StgStablePtr the_stableptr, HsPtr a1);
extern HsPtr zdmainzdPixelFormatTestInputzdPixelFormatTestInputzumkOpen(StgStablePtr the_stableptr, HsPtr a1);
#if defined(__cplusplus)
}
#endif

