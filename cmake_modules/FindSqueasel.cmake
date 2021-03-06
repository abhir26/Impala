# - Find Squeasel (squeasel.h and squeasel.c)
# This module defines
#  SQUEASEL_INCLUDE_DIR, directory containing headers
#  SQUEASEL_SRC_DIR, directory containing source
#  SQUEASEL_FOUND, whether the Squeasel library has been located

find_path(SQUEASEL_INCLUDE_DIR squeasel/squeasel.h HINTS ${CMAKE_SOURCE_DIR}/thirdparty)
find_path(SQUEASEL_SRC_DIR squeasel.c HINTS ${CMAKE_SOURCE_DIR}/thirdparty/squeasel)

if (SQUEASEL_INCLUDE_DIR)
  set(SQUEASEL_FOUND TRUE)
else ()
  set(SQUEASEL_FOUND FALSE)
endif ()

if (SQUEASEL_FOUND)
  if (NOT SQUEASEL_FIND_QUIETLY)
    message(STATUS "Squeasel web server library found in ${SQUEASEL_INCLUDE_DIR}")
  endif ()
else ()
  message(STATUS "Squeasel web server library includes NOT found. ")
endif ()

mark_as_advanced(
  SQUEASEL_INCLUDE_DIR
)
