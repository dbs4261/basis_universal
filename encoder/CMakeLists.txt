set(BASISU_ENCODER_SOURCES
    basisu_backend.cpp
    basisu_basis_file.cpp
    basisu_bc7enc.cpp
    basisu_bc7enc.h
    basisu_comp.cpp
    basisu_enc.cpp
    basisu_etc.cpp
    basisu_frontend.cpp
    basisu_gpu_texture.cpp
    basisu_kernels_declares.h
    basisu_kernels_imp.h
    basisu_kernels_sse.cpp
    basisu_miniz.h
    basisu_ocl_kernels.h
    basisu_opencl.cpp
    basisu_pvrtc1_4.cpp
    basisu_resample_filters.cpp
    basisu_resampler_filters.h
    basisu_resampler.cpp
    basisu_resampler.h
    basisu_ssim.cpp
    basisu_uastc_enc.cpp
    cppspmd_flow.h
    cppspmd_math.h
    cppspmd_math_declares.h
    cppspmd_see.h
    cppspmd_type_aliases.h
    jpgd.cpp
    jpgd.h
    pvpngreader.cpp
    pvpngreader.h
)

set(BASISU_ENCODER_PUBLIC_HEADERS
    basisu_backend.h
    basisu_basis_file.h
    basisu_comp.h
    basisu_enc.h
    basisu_etc.h
    basisu_frontend.h
    basisu_gpu_texture.h
    basisu_opencl.h
    basisu_pvrtc1_4.h
    basisu_ssim.h
    basisu_uastc_enc.h
)

if (BASISU_BUILD_SHARED)
    add_library(basisu_encoder SHARED ${BASISU_ENCODER_SOURCES})
else()
    add_library(basisu_encoder STATIC ${BASISU_ENCODER_SOURCES})
endif()
add_library(basisu::encoder ALIAS basisu_encoder)

target_compile_features(basisu_encoder PRIVATE cxx_std_11)

target_include_directories(basisu_encoder PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/../>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/basisu/>
)

# TODO: If all minor versions are abi compatible, remove minor from SOVERSION
set_target_properties(basisu_encoder PROPERTIES
    EXPORT_NAME basisu_encoder
    VERSION "${basisu_VERSION}"
    SOVERSION "${basisu_VERSION_MAJOR}.${basisu_VERSION_MINOR}"
    INTERPROCEDURAL_OPTIMIZATION
        $<AND:$<BOOL:${CMAKE_CXX_LTO_SUPPORTED}>, $<BOOL:${BASISU_ENABLE_IPO}>, $<NOT:$<CONFIG:Debug>>>
    POSITION_INDEPENDENT_CODE ON
    WINDOWS_EXPORT_ALL_SYMBOLS ON
)

target_link_libraries(basisu_encoder
    PUBLIC
        basisu::transcoder
        $<$<AND:$<BOOL:${BASISU_WITH_ZSTD}>,$<TARGET_EXISTS:zstd::libzstd_static>>:zstd::libzstd_static>
        $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${HAVE_LIB_M}>>:m>
        $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<TARGET_EXISTS:OpenCL::OpenCL>>:OpenCL::OpenCL>
)

target_compile_definitions(basisu_encoder PUBLIC
    $<$<CONFIG:Debug>:_DEBUG>
    BASISD_SUPPORT_KTX2_ZSTD=$<AND:$<BOOL:${BASISU_WITH_ZSTD}>,$<TARGET_EXISTS:zstd::libzstd_static>>
    BASISU_SUPPORT_SSE=$<AND:$<BOOL:${BASISU_WITH_SSE41}>,$<NOT:$<CXX_COMPILER_ID:EMSCRIPTEN>>>
)
target_compile_definitions(basisu_encoder PRIVATE
    BASISU_SUPPORT_OPENCL=$<BOOL:BASISU_WITH_OPENCL_LOADER>
    $<$<CXX_COMPILER_ID:GNU>:_LARGEFILE64_SOURCE=1;_FILE_OFFSET_BITS=64>
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)

target_compile_options(basisu_encoder PRIVATE
    $<$<AND:$<BOOL:${BASISU_WITH_SSE41}>,$<NOT:$<CXX_COMPILER_ID:MSVC,EMSCRIPTEN>>>:-msse4.1>
    $<$<AND:$<BOOL:${BASISU_WITH_SSE41}>,$<CXX_COMPILER_ID:MSVC>>:/arch:SSE4.1>
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
