set(CMAKE_C_STANDARD 90)

add_executable(demovt)
target_sources(demovt
        PRIVATE
            demovt.c
        )
target_link_libraries(demovt PRIVATE libcixl)