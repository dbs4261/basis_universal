include_guard()

find_package(Git REQUIRED)

# So TBB does this really stupid thing where it allows you to configure the repo
# but exclude the source and find the targets from an installed version.
# The problem is how it detects if this is the behavior you want.
# It does this if *EITHER* TBB_FIND_PACKAGE is ON OR if it finds a variable named TBB_DIR which is used by find_package.
# This is a pain because FetchContent also defines that variable pointing to a file that just refers back to the source directory.
# This would all be fine, except that the if statement that checks this EXCLUDES ALL THE SOURCE CODE.
# Ugh so we need to apply a patch here, so any local modifications to the TBB source will be overwritten the next time cmake configures.
include(FetchContent)
FetchContent_Declare(TBB
    GIT_REPOSITORY "https://github.com/oneapi-src/oneTBB.git"
    GIT_TAG "8b829acc65569019edb896c5150d427f288e8aba" # 2021.11.0
    GIT_SHALLOW ON
    GIT_REMOTE_UPDATE_STRATEGY CHECKOUT
    PATCH_COMMAND ${GIT_EXECUTABLE} reset --hard && ${GIT_EXECUTABLE} apply --whitespace=fix ${CMAKE_CURRENT_LIST_DIR}/tbb.patch
    CMAKE_ARGS "-DTBB_TEST:BOOL=OFF
                -DTBB_EXAMPLES:BOOL=OFF
                -DTBB_BENCH:BOOL=OFF
                -DTBB_BUILD:BOOL=ON
                -DTBB_FIND_PACKAGE:BOOL=OFF
                -DTBB_FUZZ_TESTING:BOOL=OFF
                -DTBB_INSTALL:BOOL=ON"
    OVERRIDE_FIND_PACKAGE
)

set(TBB_TEST OFF CACHE INTERNAL "" FORCE)
set(TBB_EXAMPLES OFF CACHE INTERNAL "" FORCE)
set(TBB_BENCH OFF CACHE INTERNAL "" FORCE)
set(TBB_BUILD ON CACHE INTERNAL "" FORCE)
set(TBB_FIND_PACKAGE OFF CACHE INTERNAL "" FORCE)
set(TBB_FUZZ_TESTING OFF CACHE INTERNAL "" FORCE)
set(TBB_INSTALL ON CACHE INTERNAL "" FORCE)

FetchContent_MakeAvailable(TBB)
if (NOT TARGET TBB::tbb)
    message(FATAL_ERROR "TBB setup failed")
endif()
message(STATUS "TBB added")