set(BASISU_TRANSCODER_PUBLIC_HEADERS
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

# For IDE integration
target_sources(basisu_transcoder PRIVATE
    ${BASISU_TRANSCODER_PUBLIC_HEADERS}
)

target_compile_features(basisu_transcoder PRIVATE cxx_std_11)

target_include_directories(basisu_transcoder PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/../>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/basisu/>
)

# TODO: If all minor versions are abi compatible, remove minor from SOVERSION
set_target_properties(basisu_transcoder PROPERTIES
    EXPORT_NAME transcoder
    VERSION "${basisu_VERSION}"
    SOVERSION "${basisu_VERSION_MAJOR}.${basisu_VERSION_MINOR}"
    INTERPROCEDURAL_OPTIMIZATION
        $<AND:$<BOOL:${CMAKE_CXX_LTO_SUPPORTED}>,$<NOT:$<CONFIG:Debug>>>
    POSITION_INDEPENDENT_CODE ON
    WINDOWS_EXPORT_ALL_SYMBOLS ON
)

target_link_libraries(basisu_transcoder PUBLIC
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${HAVE_LIB_M}>>:m>
)
target_link_libraries(basisu_transcoder PRIVATE
    $<$<AND:$<BOOL:${BASISU_WITH_ZSTD}>,$<TARGET_EXISTS:zstd::libzstd_static>>:zstd::libzstd_static>
)

target_compile_definitions(basisu_transcoder PUBLIC $<$<CONFIG:Debug>:_DEBUG>)
target_compile_definitions(basisu_transcoder PRIVATE
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:_LARGEFILE64_SOURCE=1;_FILE_OFFSET_BITS=64>
)

target_compile_options(basisu_transcoder PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4 /WX>
    $<$<CXX_COMPILER_ID:AppleClang,GNU,Clang>:-Wall -Wextra -Werror -Wno-unused-function>
    $<$<CXX_COMPILER_ID:GNU>:-Wno-class-memaccess>
)
target_compile_options(basisu_transcoder PUBLIC
    $<$<CXX_COMPILER_ID:AppleClang,Clang>:-Wno-unknown-warning-option>
    $<$<CXX_COMPILER_ID:GNU>:-Wno-unused-value>
)

# Sanitizer options need to be added to both compile and link phases
target_compile_options(basisu_transcoder PRIVATE
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)
target_link_options(basisu_transcoder PRIVATE
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)

# Format Support
target_compile_definitions(basisu_transcoder PRIVATE
    BASISD_SUPPORT_FXT1=$<BOOL:${BASISU_SUPPORT_FTX1}>
    BASISD_SUPPORT_ATC=$<AND:$<BOOL:${BASISU_SUPPORT_ATC}>,$<NOT:$<PLATFORM_ID:Emscripten>>>
    BASISD_SUPPORT_PVRTC2=$<AND:$<BOOL:${BASISU_SUPPORT_ASTC_HIGHER_OPAQUE_QUALITY}>,$<NOT:$<PLATFORM_ID:Emscripten>>>
)

install(TARGETS basisu_transcoder EXPORT basisu-targets
    RUNTIME COMPONENT BasisUniversal_Runtime
    LIBRARY COMPONENT BasisUniversal_Runtime NAMELINK_COMPONENT BasisUniversal_Development
    ARCHIVE COMPONENT BasisUniversal_Development
)
install(FILES ${BASISU_TRANSCODER_PUBLIC_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/basisu/transcoder/
    COMPONENT BasisUniversal_Development
)
