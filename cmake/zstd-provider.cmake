include_guard()

include(CMakeDependentOption)
cmake_dependent_option(ZSTD_MULTITHREAD_SUPPORT "MULTITHREADING SUPPORT" ON "NOT ${CMAKE_SYSTEM_NAME} MATCHES EMSCRIPTEN" "UNUSED")

include(FetchContent)
FetchContent_Declare(zstd
    GIT_REPOSITORY "https://github.com/facebook/zstd.git"
    GIT_TAG "954413f8434ee2a044116188d22c15179de4cdb2" # v1.4.9
    SOURCE_SUBDIR "build/cmake"
    CMAKE_ARGS "-DZSTD_BUILD_TESTS:BOOL=OFF
                -DZSTD_BUILD_PROGRAMS:BOOL=OFF
                -DZSTD_BUILD_CONTRIB:BOOL=OFF
                -DZSTD_MULTITHREAD_SUPPORT:BOOL=${ZSTD_MULTITHREAD_SUPPORT}
                -DZSTD_BUILD_STATIC:BOOL=ON
                -DZSTD_BUILD_SHARED:BOOL=OFF"
    OVERRIDE_FIND_PACKAGE
    SYSTEM
)

if (NOT ${CMAKE_SYSTEM_NAME} MATCHES "EMSCRIPTEN")
    set(ZSTD_MULTITHREAD_SUPPORT ON CACHE INTERNAL "" FORCE)
endif()

set(ZSTD_BUILD_TESTS OFF CACHE INTERNAL "" FORCE)
set(ZSTD_BUILD_PROGRAMS OFF CACHE INTERNAL "" FORCE)
set(ZSTD_BUILD_CONTRIB OFF CACHE INTERNAL "" FORCE)
set(ZSTD_BUILD_STATIC ON CACHE INTERNAL "" FORCE)
set(ZSTD_BUILD_SHARED OFF CACHE INTERNAL "" FORCE)

FetchContent_MakeAvailable(zstd)
# Fix issue ZStandard has with the include directories when built as a sub-project
FetchContent_GetProperties(zstd SOURCE_DIR ZSTD_SOURCE_DIR)
target_include_directories(libzstd_static PUBLIC
    "$<BUILD_INTERFACE:${ZSTD_SOURCE_DIR}/lib>"
    "$<INSTALL_INTERFACE:include>"
)
target_compile_options(libzstd_static PRIVATE
    $<$<PLATFORM_ID:Emscripten>:-Wno-bitwise-instead-of-logical>
)
add_library(zstd::libzstd_static ALIAS libzstd_static)
