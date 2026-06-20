# SPDX-License-Identifier: GPL-2.0-or-later


# -----------------------------------------------------------------------------
# Build datatoc executable
# Skip if using a pre-built host binary for cross-compilation
if(DEFINED DATATOC_EXECUTABLE AND NOT DATATOC_EXECUTABLE STREQUAL "")
  message(STATUS "Using pre-built datatoc: ${DATATOC_EXECUTABLE}")
  # Create a custom target so other targets can depend on it
  add_custom_target(datatoc DEPENDS "${DATATOC_EXECUTABLE}")
else()
  set(SRC
    datatoc.c
  )

  # SRC_DNA_INC is defined in the parent dir
  add_executable(datatoc ${SRC})
endif()


# -----------------------------------------------------------------------------
# Build datatoc_icon executable
# Skip if using a pre-built host binary for cross-compilation

if(NOT WITH_HEADLESS AND (NOT DEFINED DATATOC_ICON_EXECUTABLE OR DATATOC_ICON_EXECUTABLE STREQUAL ""))

  set(SRC
    datatoc_icon.c
  )
  setup_platform_linker_flags(datatoc)
  if(WIN32)
    include_directories(
      ../blenlib
      ../../../intern/utfconv
    )

    # for winstuff_dir.c
    add_definitions(-DUSE_STANDALONE)

    list(APPEND SRC
      ../blenlib/intern/winstuff_dir.c
      ../../../intern/utfconv/utfconv.c
    )

  endif()

  include_directories(${PNG_INCLUDE_DIRS})

  add_executable(datatoc_icon ${SRC})
  setup_platform_linker_flags(datatoc_icon)

  target_link_libraries(datatoc_icon ${PNG_LIBRARIES} ${ZLIB_LIBRARIES})
  # PNG library uses pow() and floow(), so seems -lm is required for proper
  # working binary.
  if(UNIX AND NOT APPLE)
    target_link_libraries(datatoc_icon m)
  endif()
elseif(NOT WITH_HEADLESS)
  message(STATUS "Using pre-built datatoc_icon: ${DATATOC_ICON_EXECUTABLE}")
  add_custom_target(datatoc_icon DEPENDS "${DATATOC_ICON_EXECUTABLE}")
endif()
