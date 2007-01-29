#ifndef tkutil_h_
#define tkutil_h_

#include "Glish/Proxy.h"
#include "Glish/glishtk.h"

// turn the string into a value
extern Value *glishtk_str( const char * );
extern const char *glishtk_onestr(TkProxy *proxy, const char *cmd, Value *args);
extern const char *glishtk_onedim(TkProxy *proxy, const char *cmd, Value *args);
extern Value *glishtk_strtoint( const char *str );

#endif
