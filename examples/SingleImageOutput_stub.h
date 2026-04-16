#include <HsFFI.h>
#if defined(__cplusplus)
extern "C" {
#endif
extern HsWord32 RequiredVersion(void);
extern HsWord8 InitializePlugin(HsWord32 a1);
extern void UninitializePlugin(void);
extern HsPtr GetOutputPluginTable(void);
extern HsPtr zdmainzdSingleImageOutputzdSingleImageOutputzumkConfigText(StgStablePtr the_stableptr);
extern HsWord8 zdmainzdSingleImageOutputzdSingleImageOutputzumkOutput(StgStablePtr the_stableptr, HsPtr a1);
#if defined(__cplusplus)
}
#endif

