set(CMAKE_C_STANDARD 90)

add_executable(demovt)
target_sources(demovt
        PRIVATE
            demovt.c
        )

target_compile_definitions(libcixl-static PUBLIC LIBCIXL_STATIC)
target_link_libraries(demovt PRIVATE libcixl-static)
