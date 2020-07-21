cmake_minimum_required(VERSION 3.16)
set(CMAKE_CXX_STANDARD 14)


add_executable(libcixl-tests)

target_sources(libcixl-tests
        PUBLIC
        libcixl-tests.cpp
        )

target_link_libraries(libcixl-tests PUBLIC libcixl-for-testing)

target_compile_definitions(libcixl-tests PUBLIC WITH_INTERNALS_VISIBLE)


add_test(myTest libcixl-tests)

if(MSVC)
    target_compile_options(libcixl PRIVATE /W4)
else()
    target_compile_options(libcixl PRIVATE -Wall -Wextra)
endif()