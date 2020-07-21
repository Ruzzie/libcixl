cmake_minimum_required(VERSION 3.16)
set(CMAKE_CXX_STANDARD 14)


add_executable(libcixl-tests)

target_sources(libcixl-tests
        PUBLIC
        libcixl-tests.cpp
        )

add_compile_definitions(WITH_INTERNALS_VISIBLE)
target_compile_definitions(libcixl-for-testing PUBLIC WITH_INTERNALS_VISIBLE)

target_link_libraries(libcixl-tests PUBLIC libcixl-for-testing)

target_compile_definitions(libcixl-tests PUBLIC WITH_INTERNALS_VISIBLE)


add_test(myTest libcixl-tests)