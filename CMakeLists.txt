# Important: The Basis Universal encoder and transcoder libraries must be compiled with -fno-strict-aliasing (MSVC's default, and also the Linux kernel).
# It should also work without this option, but we do not test with it.
cmake_minimum_required(VERSION 3.25)

project(basisu
    VERSION 1.50.0
    LANGUAGES CXX
    HOMEPAGE_URL "https://github.com/BinomialLLC/basis_universal"
)

if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif()

option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(BASISU_BUILD_SHARED_LIBS "Build BasisU with shared libraries" ${BUILD_SHARED_LIBS})
option(BASISU_WITH_ZSTD "ZSTD support for KTX2 transcoding/encoding" ON)
option(BASISU_WITH_OPENCL "OpenCL support in encoder" OFF)
option(BASISU_WITH_ASAN "Build basisu with address sanitizer" OFF)
if (EMSCRIPTEN)
	set(BASISU_WITH_SSE41 OFF)
else()
	option(BASISU_WITH_SSE41 "Build basisu with sse4.1 acceleration" ON)
endif()
option(BASISU_BUILD_EXAMPLE "Build BasisU example application" OFF)

message(STATUS "${PROJECT_NAME} build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "BasisU requested build shared libraries: ${BASISU_BUILD_SHARED_LIBS}")
message(STATUS "BasisU requested ZStandard support: ${BASISU_WITH_ZSTD}")
message(STATUS "BasisU requested OpenCL support: ${BASISU_WITH_OPENCL}")
message(STATUS "BasisU requested SSE4.1 support: ${BASISU_WITH_SSE41}")
message(STATUS "BasisU requested Address Sanitizer support: ${BASISU_WITH_ASAN}")

# Notify about deprecated options
if (DEFINED BUILD_X64)
	message(DEPRECATION "BUILD_X64 option has been removed. Either add -DCMAKE_CXX_FLAGS=\"-m32\" "
			"on Linux or pass -A Win32 on Windows to the cmake configure command. "
            "The correct method is to define this in a toolchain.cmake file "
            "and pass it to cmake with -DCMAKE_TOOLCHAIN_FILE."
    )
endif()
if (DEFINED SSE)
	message(DEPRECATION "SSE option has been renamed to BASISU_WITH_SSE41")
endif()
if (DEFINED ZSTD)
	message(DEPRECATION "ZSTD option has been renamed to BASISU_WITH_ZSTD")
endif()
if (DEFINED OPENCL)
	message(DEPRECATION "OPENCL option has been renamed to BASISU_WITH_OPENCL")
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
if (NOT CMAKE_CXX_LTO_SUPPORTED AND NOT EMSCRIPTEN)
	message(WARNING "Interprocedural Optimization was requested but not supported with details:"
            "\n${LTO_ERROR_DETAILS}\nEnd of IPO error details.")
endif()

if (BASISU_WITH_ZSTD)
	include(cmake/zstd-provider.cmake)
	if (NOT TARGET zstd::libzstd_static)
		message(FATAL_ERROR "Zstandard was requested but neither could be found nor compiled from source")
	else()
		message(STATUS "Zstandard enabled")
	endif()
else()
	message(STATUS "Zstandard disabled")
	set(BASISU_WITH_ZSTD OFF)
endif()

if (BASISU_WITH_OPENCL)
	include(cmake/opencl-provider.cmake)
	if (NOT TARGET OpenCL::OpenCL)
		message(FATAL_ERROR "OpenCL was requested but neither could be found nor compiled from source")
	else()
		message(STATUS "OpenCL enabled")
		set(BASISU_WITH_OPENCL OFF)
	endif()
else()
	message(STATUS "OpenCL disabled")
endif()

if (NOT DEFINED CMAKE_STRIP)
	find_program(CMAKE_STRIP strip)
endif()

add_subdirectory(transcoder)
add_subdirectory(encoder)
if (BASISU_BUILD_EXAMPLE)
	add_subdirectory(example)
endif()

add_executable(basisu basisu_tool.cpp)

target_link_libraries(basisu PRIVATE basisu::encoder)
target_compile_features(basisu INTERFACE cxx_std_11)
target_compile_definitions(basisu PRIVATE
	BASISU_SUPPORT_OPENCL=$<BOOL:${BASISU_WITH_OPENCL}>
	$<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
		-fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)
target_compile_options(basisu PRIVATE
	$<$<CXX_COMPILER_ID:MSVC>:/W4;/WX>
	$<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Werror>
)
# Sanitizer options need to be added to both compile and link phases
target_compile_options(basisu PRIVATE
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)
target_link_options(basisu PRIVATE
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)
set_target_properties(basisu PROPERTIES
	INTERPROCEDURAL_OPTIMIZATION
		$<AND:$<BOOL:${CMAKE_CXX_LTO_SUPPORTED}>,$<NOT:$<CONFIG:Debug>>>
	POSITION_INDEPENDENT_CODE ON
    RUNTIME_OUTPUT_NAME "basisu"
	# Prevent MSVC from creating separate output directories for each configuration
    RUNTIME_OUTPUT_DIRECTORY $<1:${CMAKE_RUNTIME_OUTPUT_DIRECTORY}>
)

if (DEFINED CMAKE_STRIP AND UNIX AND NOT EMSCRIPTEN)
	message(STATUS "Found strip at: ${CMAKE_STRIP}")
	add_custom_command(TARGET basisu POST_BUILD COMMAND_EXPAND_LISTS COMMAND
			"$<$<CONFIG:Release>:${CMAKE_STRIP};$<$<NOT:$<BOOL:${APPLE}>>:-g>;-X;-x;$<TARGET_FILE:basisu>>")
endif()

install(TARGETS basisu
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

