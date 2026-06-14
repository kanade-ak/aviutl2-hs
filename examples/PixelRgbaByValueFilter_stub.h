#include <HsFFI.h>
#if defined(__cplusplus)
extern "C" {
#endif
extern HsWord32 RequiredVersion(void);
extern HsWord8 InitializePlugin(HsWord32 a1);
extern void UninitializePlugin(void);
extern HsPtr GetFilterPluginTable(void);
#if defined(__cplusplus)
}
#endif

