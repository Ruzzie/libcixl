cmake_minimum_required(VERSION 3.16)
set(CMAKE_C_STANDARD 90)

add_library(libcixl SHARED)
add_library(libcixl-for-testing SHARED)

set(LIBCIXL_SOURCES libcixl.c)

target_sources(
        libcixl
        PRIVATE
            ${LIBCIXL_SOURCES}
)

target_sources(
        libcixl-for-testing
        PUBLIC
            ${LIBCIXL_SOURCES}
)

target_compile_definitions(libcixl-for-testing PUBLIC WITH_INTERNALS_VISIBLE)
target_compile_definitions(libcixl-for-testing PUBLIC LIBCIXL_EXPORTS)

target_compile_definitions(libcixl PRIVATE LIBCIXL_EXPORTS)


target_include_directories(libcixl
        PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
        )

target_include_directories(libcixl-for-testing
        PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
        )