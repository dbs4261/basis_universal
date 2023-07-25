find_package(zstd 1.4.9 QUIET)

include(CMakeDependentOption)
cmake_dependent_option(ZSTD_LEGACY_SUPPORT "LEGACY SUPPORT" OFF "NOT ZSTD_FOUND" "UNUSED")
cmake_dependent_option(ZSTD_MULTITHREAD_SUPPORT "MULTITHREADING SUPPORT" ON "NOT ZSTD_FOUND" "UNUSED")

if (NOT ZSTD_FOUND)
    message(STATUS "Building ZSTD from source...")
    include(FetchContent)
    FetchContent_Declare(zstd
        GIT_REPOSITORY "https://github.com/facebook/zstd.git"
        GIT_TAG "954413f8434ee2a044116188d22c15179de4cdb2" # v1.4.9
        SOURCE_SUBDIR "build/cmake"
        CMAKE_ARGS "-DZSTD_BUILD_TESTS:BOOL=OFF
                    -DZSTD_BUILD_PROGRAMS:BOOL=OFF
                    -DZSTD_BUILD_CONTRIB:BOOL=OFF
                    -DZSTD_LEGACY_SUPPORT:BOOL=${ZSTD_LEGACY_SUPPORT}
                    -DZSTD_MULTITHREAD_SUPPORT:BOOL=${ZSTD_MULTITHREAD_SUPPORT}
                    -DZSTD_BUILD_STATIC:BOOL=ON
                    -DZSTD_BUILD_SHARED:BOOL=OFF"
    )
    FetchContent_MakeAvailable(zstd)
    FetchContent_GetProperties(zstd SOURCE_DIR ZSTD_SOURCE_DIR)
    target_include_directories(libzstd_static PUBLIC
        "$<BUILD_INTERFACE:${ZSTD_SOURCE_DIR}/lib>"
        "$<INSTALL_INTERFACE:include>"
    )
    add_library(zstd::libzstd_static ALIAS libzstd_static)
else()
    message(DEBUG "Found ZSTD using find_package()")
endif()
