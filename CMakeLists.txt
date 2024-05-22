cmake_minimum_required(VERSION 3.14)

project(basisu
	VERSION 1.16.4
	LANGUAGES CXX
	HOMEPAGE_URL "https://github.com/BinomialLLC/basis_universal"
)

if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif()

option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(BASISU_BUILD_SHARED_LIBS "Build BasisU with shared libraries" ${BUILD_SHARED_LIBS})
option(BASISU_WITH_ZSTD "ZSTD support for KTX2 transcoding/encoding" ON)
option(BASISU_WITH_OPENCL_LOADER "OpenCL support in encoder" OFF)
option(BASISU_WITH_SSE41 "Build basisu with sse4.1 acceleration" ON)
option(BASISU_WITH_ASAN "Build basisu with address sanitizer" OFF)

message(STATUS "${PROJECT_NAME} build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "BasisU requested build shared libraries: ${BASISU_BUILD_SHARED_LIBS}")
message(STATUS "BasisU requested ZStandard support: ${BASISU_WITH_ZSTD}")
message(STATUS "BasisU requested OpenCL support: ${BASISU_WITH_OPENCL_LOADER}")
message(STATUS "BasisU requested SSE4.1 support: ${BASISU_WITH_SSE41}")
message(STATUS "BasisU requested Address Sanitizer support: ${BASISU_WITH_ASAN}")

# Notify about deprecated options
if (DEFINED BUILD_X64)
	message(DEPRECATION "BUILD_X64 option has been removed. Either add -DCMAKE_CXX_FLAGS=\"-m32\" "
			"on Linux or pass -A Win32 on Windows to the cmake configure command")
endif()
if (DEFINED SSE)
	message(DEPRECATION "SSE option has been renamed to BASISU_WITH_SSE41")
endif()
if (DEFINED ZSTD)
	message(DEPRECATION "ZSTD option has been renamed to BASISU_WITH_ZSTD")
endif()
if (DEFINED OPENCL)
	message(DEPRECATION "OPENCL option has been renamed to BASISU_WITH_OPENCL_LOADER")
endif()
if (DEFINED SAN)
	message(DEPRECATION "SAN option has been renamed to BASISU_WITH_ASAN")
endif()
if (DEFINED STATIC)
	message(DEPRECATION "STATIC option has been depreciated in favor of BUILD_STATIC_LIBS and BASISU_BUILD_STATIC_LIBS")
endif()

include(GNUInstallDirs)

include(CheckLibraryExists)
check_library_exists(m sin "" HAVE_LIB_M)

include(CheckIPOSupported)
check_ipo_supported(RESULT CMAKE_CXX_LTO_SUPPORTED OUTPUT LTO_ERROR_DETAILS LANGUAGES CXX)
if (NOT CMAKE_CXX_LTO_SUPPORTED)
	message(WARNING "Interprocedural Optimization was requested but not supported with details:\n${LTO_ERROR_DETAILS}")
endif()

include(cmake/onetbb-provider.cmake)

if (BASISU_WITH_ZSTD)
	include(cmake/zstd-provider.cmake)
	if (NOT TARGET zstd::libzstd_static)
		message(FATAL_ERROR "Zstandard was requested but neither could be found nor compiled from source")
	else()
		message(STATUS "Zstandard enabled")
	endif()
else()
	message(STATUS "Zstandard disabled")
endif()

if (BASISU_WITH_OPENCL_LOADER)
	include(cmake/opencl-provider.cmake)
	if (NOT TARGET OpenCL::OpenCL)
		message(FATAL_ERROR "OpenCL was requested but neither could be found nor compiled from source")
	else()
		message(STATUS "OpenCL enabled")
	endif()
else()
	message(STATUS "OpenCL disabled")
endif()

find_package(TBB REQUIRED)

add_subdirectory(transcoder)
add_subdirectory(encoder)

add_executable(basisu-tool basisu_tool.cpp)

target_link_libraries(basisu-tool PRIVATE basisu::encoder)
target_compile_features(basisu-tool INTERFACE c_std_99 cxx_std_11)
target_compile_definitions(basisu-tool PRIVATE
	BASISU_SUPPORT_OPENCL=$<BOOL:${BASISU_WITH_OPENCL_LOADER}>
	$<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
		-fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)
target_compile_options(basisu-tool PRIVATE
	$<$<CXX_COMPILER_ID:MSVC>:/W4;/WX>
	$<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Werror>
	$<$<CXX_COMPILER_ID:GNU>:-Wno-unused-value;-Wno-reorder;-Wno-sign-compare;-Wno-unused-variable;-Wno-class-memaccess;-Wno-misleading-indentation;-Wno-extra;-Wno-deprecated-copy;-Wno-parentheses;-Wno-strict-aliasing>
	$<$<CXX_COMPILER_ID:EMSCRIPTEN>:-Wno-nested-anon-types -Wno-gnu-anonymous-struct>
	$<$<AND:$<NOT:$<CXX_COMPILER_ID:EMSCRIPTEN>>,$<CXX_COMPILER_ID:GNU>>:-Wno-cast-function-type>
	$<$<AND:$<NOT:$<CXX_COMPILER_ID:EMSCRIPTEN>>,$<CXX_COMPILER_ID:AppleClang,Clang>>:-Wno-nested-anon-types -Wno-gnu-anonymous-struct>
	$<$<NOT:$<CXX_COMPILER_ID:EMSCRIPTEN,MSVC>>:-Wno-pedantic>
)
set_target_properties(basisu-tool PROPERTIES
	INTERPROCEDURAL_OPTIMIZATION
		$<AND:$<BOOL:${CMAKE_CXX_LTO_SUPPORTED}>,$<NOT:$<CONFIG:Debug>>>
	POSITION_INDEPENDENT_CODE ON
)

install(TARGETS basisu-tool
	RUNTIME COMPONENT BasisU_Applications
)

install(EXPORT basisu-targets
	FILE basisu-targets.cmake
	NAMESPACE basisu::
	DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/basisu/
	COMPONENT BasisUniversal_Development
)

install(FILES LICENSE README.md
	DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/basisu/
	COMPONENT BasisUniversal_Runtime NAMELINK_COMPONENT BasisUniversal_Development
)

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
	basisu-config-version.cmake
	VERSION ${BASISU_VERSION}
	COMPATIBILITY SameMinorVersion
)

configure_package_config_file(
	${CMAKE_CURRENT_LIST_DIR}/cmake/basisu-config.cmake.in
	${CMAKE_CURRENT_BINARY_DIR}/basisu-config.cmake
	INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/basisu/
)

install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/basisu-config.cmake
	${CMAKE_CURRENT_BINARY_DIR}/basisu-config-version.cmake
	DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/basisu/
	COMPONENT BasisUniversal_Development
)

