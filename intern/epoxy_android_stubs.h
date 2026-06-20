#ifdef __ANDROID__
#include <epoxy/gl.h>
#ifndef epoxy_is_gles
#define epoxy_is_gles() (!epoxy_is_desktop_gl())
#endif
#endif
