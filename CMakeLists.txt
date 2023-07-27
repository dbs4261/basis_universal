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

include(CheckLibraryExists)
check_library_exists(m sin "" HAVE_LIB_M)

include(CheckIPOSupported)
check_ipo_supported(RESULT CMAKE_CXX_LTO_SUPPORTED OUTPUT LTO_ERROR_DETAILS LANGUAGES CXX)
if (NOT CMAKE_CXX_LTO_SUPPORTED)
	message(WARNING "Interprocedural Optimization was requested but not supported with details:\n${LTO_ERROR_DETAILS}")
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

if (NOT MSVC)
   set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g")
   set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g")
   
   set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
   set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")

   if (SAN)
      set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined")
      set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined")
   endif()

   set(CMAKE_CXX_FLAGS -std=c++11)
   set(GCC_COMPILE_FLAGS "-fvisibility=hidden -fPIC -fno-strict-aliasing -D_LARGEFILE64_SOURCE=1 -D_FILE_OFFSET_BITS=64 -Wall -Wextra -Wno-unused-local-typedefs -Wno-unused-value -Wno-unused-parameter -Wno-unused-variable")

   if (NOT BUILD_X64)
	  set(GCC_COMPILE_FLAGS "${GCC_COMPILE_FLAGS} -m32")
   endif()

   if (EMSCRIPTEN)
	  set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -s ALLOW_MEMORY_GROWTH=1 -DBASISU_SUPPORT_SSE=0")
	  set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -s ALLOW_MEMORY_GROWTH=1 -DBASISU_SUPPORT_SSE=0")

	  set(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${GCC_LINK_FLAGS}")
   elseif (STATIC)
      if (SSE)
		set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -DBASISU_SUPPORT_SSE=1 -msse4.1")
		set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DBASISU_SUPPORT_SSE=1 -msse4.1")
	  else()
	  	set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -DBASISU_SUPPORT_SSE=0")
		set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DBASISU_SUPPORT_SSE=0")
	  endif()

	  set(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${GCC_LINK_FLAGS} -static-libgcc -static-libstdc++ -static")
   else()
   	  if (SSE)
		set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -DBASISU_SUPPORT_SSE=1 -msse4.1")
		set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DBASISU_SUPPORT_SSE=1 -msse4.1")
	  else()
	  	set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -DBASISU_SUPPORT_SSE=0")
		set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DBASISU_SUPPORT_SSE=0")
	  endif()
	  
	  set(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${GCC_LINK_FLAGS} -Wl,-rpath .")
   endif()

   set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} ${GCC_COMPILE_FLAGS}")
   set(CMAKE_C_FLAGS_RELEASE  "${CMAKE_C_FLAGS_RELEASE} ${GCC_COMPILE_FLAGS}")
   set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${GCC_COMPILE_FLAGS} -D_DEBUG")

   set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${GCC_COMPILE_FLAGS}")
   set(CMAKE_CXX_FLAGS_RELEASE  "${CMAKE_CXX_FLAGS_RELEASE} ${GCC_COMPILE_FLAGS}")
   set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${GCC_COMPILE_FLAGS} -D_DEBUG")
else()
	if (SSE)
		set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -DBASISU_SUPPORT_SSE=1")
		set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DBASISU_SUPPORT_SSE=1")
	else()
		set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -DBASISU_SUPPORT_SSE=0")
		set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DBASISU_SUPPORT_SSE=0")
	endif()
endif()

add_subdirectory(transcoder)
add_subdirectory(encoder)

set(BASISU_SRC_LIST ${COMMON_SRC_LIST} 
	basisu_tool.cpp
	encoder/basisu_backend.cpp
	encoder/basisu_basis_file.cpp
	encoder/basisu_comp.cpp
	encoder/basisu_enc.cpp
	encoder/basisu_etc.cpp
	encoder/basisu_frontend.cpp
	encoder/basisu_gpu_texture.cpp
	encoder/basisu_pvrtc1_4.cpp
	encoder/basisu_resampler.cpp
	encoder/basisu_resample_filters.cpp
	encoder/basisu_ssim.cpp
	encoder/basisu_uastc_enc.cpp
	encoder/basisu_bc7enc.cpp
	encoder/jpgd.cpp
	encoder/basisu_kernels_sse.cpp
	encoder/basisu_opencl.cpp
	encoder/pvpngreader.cpp
	transcoder/basisu_transcoder.cpp
)

if (APPLE)
   set(BIN_DIRECTORY "bin_osx")
else()
   set(BIN_DIRECTORY "bin")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${BIN_DIRECTORY})

add_executable(basisu ${BASISU_SRC_LIST})

target_link_libraries(basisu
	PRIVATE
		$<$<BOOL:${BASISU_WITH_ZSTD}>:zstd::libzstd_static>
)

target_compile_definitions(basisu
	PRIVATE
		BASISD_SUPPORT_KTX2_ZSTD=$<BOOL:${BASISU_WITH_ZSTD}>
)

if (NOT MSVC)
	# For Non-Windows builds, let cmake try and find the system OpenCL headers/libs for us.
	if (OPENCL_FOUND)
		set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -DBASISU_SUPPORT_OPENCL=1")
		set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DBASISU_SUPPORT_OPENCL=1")	
		
		target_include_directories( basisu PRIVATE ${OpenCL_INCLUDE_DIRS} )
		set(BASISU_EXTRA_LIBS ${OpenCL_LIBRARIES})
	endif()

else()
	# For Windows builds, we use our local copies of the OpenCL import lib and Khronos headers.
	if (OPENCL)
		set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} -DBASISU_SUPPORT_OPENCL=1")
		set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DBASISU_SUPPORT_OPENCL=1")	
		
		target_include_directories( basisu PRIVATE "OpenCL" )

		if ( BUILD_X64 )
			target_link_libraries( basisu PRIVATE "OpenCL/lib/OpenCL64" )
		else()
			target_link_libraries( basisu PRIVATE "OpenCL/lib/OpenCL" )
		endif()

	endif()
endif()	

if (NOT MSVC)
   target_link_libraries(basisu PRIVATE m pthread ${BASISU_EXTRA_LIBS})
endif()

if (NOT EMSCRIPTEN)
	install(TARGETS basisu DESTINATION bin)

	if (UNIX)
		if (CMAKE_BUILD_TYPE STREQUAL Release)
			if (APPLE)
				add_custom_command(TARGET basisu POST_BUILD COMMAND strip -X -x ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/basisu)
			else()
				add_custom_command(TARGET basisu POST_BUILD COMMAND strip -g -X -x ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/basisu)
			endif()
		endif()
	endif()
endif()
