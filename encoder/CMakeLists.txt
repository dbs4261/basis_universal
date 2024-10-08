set(BASISU_ENCODER_SOURCES
    basisu_astc_hdr_enc.cpp
    basisu_backend.cpp
    basisu_basis_file.cpp
    basisu_bc7enc.cpp
    basisu_comp.cpp
    basisu_enc.cpp
    basisu_etc.cpp
    basisu_frontend.cpp
    basisu_gpu_texture.cpp
    basisu_kernels_sse.cpp
    basisu_opencl.cpp
    basisu_pvrtc1_4.cpp
    basisu_resample_filters.cpp
    basisu_resampler.cpp
    basisu_ssim.cpp
    basisu_uastc_enc.cpp
    jpgd.cpp
    pvpngreader.cpp
    3rdparty/android_astc_decomp.cpp
    3rdparty/tinyexr.cpp
)

set(BASISU_ENCODER_PRIVATE_HEADERS
    basisu_bc7enc.h
    basisu_kernels_declares.h
    basisu_ocl_kernels.h
    basisu_pvrtc1_4.h
    basisu_resampler_filters.h
    basisu_resampler.h
    cppspmd_flow.h
    cppspmd_math.h
    cppspmd_math_declares.h
    cppspmd_sse.h
    cppspmd_type_aliases.h
    jpgd.h
    pvpngreader.h
    3rdparty/android_astc_decomp.h
    3rdparty/qoi.h
    3rdparty/tinydds.h
    3rdparty/tinyexr.h
)

set(BASISU_ENCODER_PUBLIC_HEADERS
    basisu_astc_hdr_enc.h
    basisu_backend.h
    basisu_basis_file.h
    basisu_comp.h
    basisu_enc.h
    basisu_etc.h
    basisu_frontend.h
    basisu_gpu_texture.h
    basisu_kernels_imp.h
    basisu_miniz.h
    basisu_opencl.h
    basisu_ssim.h
    basisu_uastc_enc.h
)

if (BASISU_BUILD_SHARED)
    add_library(basisu_encoder SHARED ${BASISU_ENCODER_SOURCES})
else()
    add_library(basisu_encoder STATIC ${BASISU_ENCODER_SOURCES})
endif()
add_library(basisu::encoder ALIAS basisu_encoder)

# For IDE integration
target_sources(basisu_encoder PRIVATE
    ${BASISU_ENCODER_PUBLIC_HEADERS}
    ${BASISU_ENCODER_PRIVATE_HEADERS}
)

# Braced initialization of struct containing members with default values requires c++14
target_compile_features(basisu_encoder PRIVATE cxx_std_14)

target_include_directories(basisu_encoder PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/../>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/basisu/>
)

# TODO: If all minor versions are abi compatible, remove minor from SOVERSION
set_target_properties(basisu_encoder PROPERTIES
    EXPORT_NAME encoder
    VERSION "${basisu_VERSION}"
    SOVERSION "${basisu_VERSION_MAJOR}.${basisu_VERSION_MINOR}"
    INTERPROCEDURAL_OPTIMIZATION
        $<AND:$<BOOL:${CMAKE_CXX_LTO_SUPPORTED}>,$<NOT:$<CONFIG:Debug>>>
    POSITION_INDEPENDENT_CODE ON
    WINDOWS_EXPORT_ALL_SYMBOLS ON
)

target_link_libraries(basisu_encoder PUBLIC
    basisu::transcoder TBB::tbb
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${HAVE_LIB_M}>>:m>
)
target_link_libraries(basisu_encoder PRIVATE
    $<$<AND:$<BOOL:${BASISU_WITH_OPENCL}>,$<TARGET_EXISTS:OpenCL::OpenCL>>:OpenCL::OpenCL>
    $<$<AND:$<BOOL:${BASISU_WITH_ZSTD}>,$<TARGET_EXISTS:zstd::libzstd_static>>:zstd::libzstd_static>
)

target_compile_definitions(basisu_encoder PUBLIC
    $<$<CONFIG:Debug>:_DEBUG>
    BASISD_SUPPORT_KTX2_ZSTD=$<AND:$<BOOL:${BASISU_WITH_ZSTD}>,$<TARGET_EXISTS:zstd::libzstd_static>>
    BASISU_SUPPORT_SSE=$<AND:$<BOOL:${BASISU_WITH_SSE41}>,$<NOT:$<PLATFORM_ID:Emscripten>>>
    BASISU_SUPPORT_OPENCL=$<BOOL:${BASISU_WITH_OPENCL}>  # Doesn't need to be public, but is based on usage.
)
target_compile_definitions(basisu_encoder PRIVATE
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:_LARGEFILE64_SOURCE=1;_FILE_OFFSET_BITS=64>
)

target_compile_options(basisu_encoder PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4;/WX>
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Werror -fno-strict-aliasing -Wno-maybe-uninitialized -Wno-stringop-overflow>
    $<$<AND:$<BOOL:${BASISU_WITH_SSE41}>,$<NOT:$<OR:$<CXX_COMPILER_ID:MSVC>,$<PLATFORM_ID:Emscripten>>>>:-msse4.1 -Wno-unused-parameter>
    # Were cppspmd to support emscripten, this flag would need to be added.
    # $<$<AND:$<BOOL:${BASISU_WITH_SSE41}>,$<PLATFORM_ID:Emscripten>>:-msimd128>
    $<$<CXX_COMPILER_ID:GNU>:-Wno-class-memaccess -Wno-unused-variable>
    $<$<PLATFORM_ID:Emscripten>:-mbulk-memory -matomics>
)
target_compile_options(basisu_encoder PUBLIC
    $<$<CXX_COMPILER_ID:GNU>:-Wno-misleading-indentation>
    $<$<PLATFORM_ID:Emscripten>:-Wno-unused-parameter>
)

# Sanitizer options need to be added to both compile and link phases
target_compile_options(basisu_encoder PRIVATE
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)
target_link_options(basisu_encoder PRIVATE
        $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)

install(TARGETS basisu_encoder EXPORT basisu-targets
    RUNTIME COMPONENT BasisUniversal_Runtime
    LIBRARY COMPONENT BasisUniversal_Runtime NAMELINK_COMPONENT BasisUniversal_Development
    ARCHIVE COMPONENT BasisUniversal_Development
)
install(FILES ${BASISU_ENCODER_PUBLIC_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/basisu/encoder/
    COMPONENT BasisUniversal_Development
)
