/* SPDX-License-Identifier: GPL-2.0-or-later
 * Copyright 2024 Blender Foundation. All rights reserved. */

#ifdef __ANDROID__
#  ifndef epoxy_is_gles
/* epoxy_is_gles was added in Epoxy 1.5.5; pre-compiled NDK libs are older.
 * On Android we are always GLES, so the inverse of epoxy_is_desktop_gl is correct. */
#    define epoxy_is_gles() (!epoxy_is_desktop_gl())
#  endif
#endif
