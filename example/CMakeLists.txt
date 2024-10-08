add_executable(example example.cpp)
target_link_libraries(example PRIVATE basisu::encoder)
target_compile_features(example INTERFACE cxx_std_11)
target_compile_definitions(example PRIVATE
    BASISU_SUPPORT_OPENCL=$<BOOL:${BASISU_WITH_OPENCL}>
)
target_compile_options(example PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4;/WX>
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Werror>
)

# Sanitizer options need to be added to both compile and link phases
target_compile_options(example PRIVATE
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)
target_link_options(example PRIVATE
    $<$<AND:$<NOT:$<CXX_COMPILER_ID:MSVC>>,$<BOOL:${BASISU_WITH_ASAN}>>:
        -fsanitize=address -fno-omit-frame-pointer -fsanitize=undefined>
)

set_target_properties(example PROPERTIES
    INTERPROCEDURAL_OPTIMIZATION
        $<AND:$<BOOL:${CMAKE_CXX_LTO_SUPPORTED}>,$<NOT:$<CONFIG:Debug>>>
    POSITION_INDEPENDENT_CODE ON
    RUNTIME_OUTPUT_NAME "example"
    # Prevent MSVC from creating separate output directories for each configuration.
    RUNTIME_OUTPUT_DIRECTORY $<1:${CMAKE_RUNTIME_OUTPUT_DIRECTORY}>
)
