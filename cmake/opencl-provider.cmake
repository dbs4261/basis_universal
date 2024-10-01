include_guard()

include(FetchContent)
FetchContent_Declare(OpenCL-Headers
    GIT_REPOSITORY "https://github.com/KhronosGroup/OpenCL-Headers.git"
    GIT_TAG "a49c88ad024730a7c90c1adfd949ef5d4bd12290" # v2023.04.17
    CMAKE_ARGS "-DOPENCL_HEADERS_BUILD_TESTING:BOOL=OFF
                -DOPENCL_HEADERS_BUILD_CXX_TESTS:BOOL=OFF"
    SYSTEM
)
FetchContent_MakeAvailable(OpenCL-Headers)
FetchContent_Declare(OpenCL-ICD-Loader
    GIT_REPOSITORY "https://github.com/KhronosGroup/OpenCL-ICD-Loader.git"
    GIT_TAG "b176b0bd82fa342de65c150589f6287a41f2488c" # v2023.04.17
    CMAKE_ARGS "-DOPENCL_ICD_LOADER_BUILD_SHARED_LIBS:BOOL=OFF
                -DENABLE_OPENCL_LAYERINFO:BOOL=OFF"
    SYSTEM
)
FetchContent_MakeAvailable(OpenCL-ICD-Loader)
