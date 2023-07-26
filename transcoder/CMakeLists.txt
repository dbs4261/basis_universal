set(BASISU_TRANSCODER_HEADERS
    basisu.h
    basisu_containers.h
    basisu_containers_impl.h
    basisu_file_headers.h
    basisu_transcoder.h
    basisu_transcoder_internal.h
    basisu_transcoder_uastc.h
)

if (BASISU_BUILD_SHARED)
    add_library(basisu_transcoder SHARED basisu_transcoder.cpp)
else()
    add_library(basisu_transcoder STATIC basisu_transcoder.cpp)
endif()
add_library(basisu::transcoder ALIAS basisu_transcoder)

target_compile_features(basisu_transcoder PRIVATE cxx_std_11)

target_include_directories(basisu_transcoder PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/../>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/basisu/>
)

# TODO: If all minor versions are abi compatible, remove minor from SOVERSION
set_target_properties(basisu_transcoder PROPERTIES
    EXPORT_NAME basisu_transcoder
    VERSION "${basisu_VERSION}"
    SOVERSION "${basisu_VERSION_MAJOR}.${basisu_VERSION_MINOR}"
    INTERPROCEDURAL_OPTIMIZATION
    $<AND:$<BOOL:${CMAKE_CXX_LTO_SUPPORTED}>, $<BOOL:${BASISU_ENABLE_IPO}>, $<NOT:$<CONFIG:Debug>>>
    POSITION_INDEPENDENT_CODE ON
    WINDOWS_EXPORT_ALL_SYMBOLS ON
)

target_compile_definitions(basisu_transcode PUBLIC $<$<CONFIG:Debug>:_DEBUG>)
target_compile_definitions(basisu_transcode PRIVATE
    $<$<CXX_COMPILER_ID:GNU>:_LARGEFILE64_SOURCE=1;_FILE_OFFSET_BITS=64>
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)

set_target_compile_options(basisu_transcoder PRIVATE
    $<$<CXX_COMPILER_ID:GNU>:-Wno-sign-compare;-Wno-unused-function;-Wno-unused-variable;-Wno-class-memaccess;-Wno-maybe-uninitialized>
    $<$<AND:$<CXX_COMPILER_ID:Clang>,$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,14.0>
)

# Format Support
target_compile_definitions(basisu_transcoder PRIVATE
    BASISD_SUPPORT_FXT1=$<BOOL:${BASISU_SUPPORT_FTX1}>
    BASISD_SUPPORT_ATC=$<AND:$<BOOL:${BASISU_SUPPORT_ATC}>,$<NOT:$<CXX_COMPILER_ID:EMSCRIPTEN>>>
    BASISD_SUPPORT_PVRTC2=$<AND:$<BOOL:${BASISU_SUPPORT_ASTC_HIGHER_OPAQUE_QUALITY}>,$<NOT:$<CXX_COMPILER_ID:EMSCRIPTEN>>>
)

install(TARGETS basisu_transcoder EXPORT basisu-targets
    RUNTIME COMPONENT BasisUniversal_Runtime
    LIBRARY COMPONENT BasisUniversal_Runtime NAMELINK_COMPONENT BasisUniversal_Development
    ARCHIVE COMPONENT BasisUniversal_Development
)
install(FILES ${BASISU_TRANSCODER_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/basisu/transcoder/
    COMPONENT BasisUniversal_Development
)
