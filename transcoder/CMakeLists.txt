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

install(TARGETS basisu_transcoder EXPORT basisu-targets
    RUNTIME COMPONENT BasisUniversal_Runtime
    LIBRARY COMPONENT BasisUniversal_Runtime NAMELINK_COMPONENT BasisUniversal_Development
    ARCHIVE COMPONENT BasisUniversal_Development
)
install(FILES ${BASISU_TRANSCODER_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/basisu/transcoder/
    COMPONENT BasisUniversal_Development
)
