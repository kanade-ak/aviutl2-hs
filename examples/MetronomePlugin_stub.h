#include <HsFFI.h>
#if defined(__cplusplus)
extern "C" {
#endif
extern HsWord32 RequiredVersion(void);
extern HsWord8 InitializePlugin(HsWord32 a1);
extern void UninitializePlugin(void);
extern void InitializeLogger(HsPtr a1);
extern void InitializeConfig(HsPtr a1);
extern HsPtr GetCommonPluginTable(void);
extern void RegisterPlugin(HsPtr a1);
extern void zdmainzdMetronomePluginzdMetronomePluginzumkEditSectionProc(StgStablePtr the_stableptr, HsPtr a1);
extern HsWord8 zdmainzdMetronomePluginzdMetronomePluginzumkAudioProc(StgStablePtr the_stableptr, HsPtr a1);
extern HsInt zdmainzdMetronomePluginzdMetronomePluginzumkWindowProc(StgStablePtr the_stableptr, HsPtr a1, HsWord32 a2, HsWord a3, HsInt a4, void* original_return_addr);
#if defined(__cplusplus)
}
#endif

