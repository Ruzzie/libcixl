/*! \file
 * \brief Simple Terminal Text library Unit Tests
 * \author Dorus Verhoeckx
 * \date 2020
 * \copyright Dorus Verhoeckx or https://unlicense.org/ or  https://mit-license.org/
 * document with https://www.doxygen.nl/manual/docblocks.html#cppblock
 * */
#pragma warning (disable : 4068 )
#pragma clang diagnostic push
#pragma ide diagnostic ignored "bugprone-infinite-loop"

#define CATCH_CONFIG_MAIN // provides main(); this line is required in only one .cpp file

#include "deps/catch.hpp"
#include "../src/libcixl.h"

int move_cursor(int x, int y, FILE *output)
{
    return 1;
    return fprintf(output, "\033[%i;%iH", x, y);
}

int      LAST_START_X_CALLED = -1;
int      LAST_START_Y_CALLED = -1;
CIXL_Cxl LAST_CIXL_CALLED    = CXL_EMPTY;
char     *LAST_STR_CALLED    = nullptr;


void draw_cixl(const int start_x, const int start_y, const CIXL_Cxl cixl)
{
    LAST_START_X_CALLED = start_x;
    LAST_START_Y_CALLED = start_y;
    LAST_CIXL_CALLED    = cixl;

    move_cursor(start_x, start_y, stdout);
    //fputc(cixl.char_value, stdout);
}

void draw_cixl_s(const int start_x, const int start_y, char *str, const unsigned int size, const CIXL_Color fg_color,
                 const CIXL_Color bg_color, const CIXL_StyleOpts decoration)
{
    LAST_START_X_CALLED = start_x;
    LAST_START_Y_CALLED = start_y;
    LAST_STR_CALLED     = str;

    move_cursor(start_x, start_y, stdout);
    //fputs(str, stdout);
}

CIXL_RenderDevice X{draw_cixl, draw_cixl_s};

/*
TEST_CASE("Size tests CIXL_Cxl", "should be valid")
{
    CIXL_Cxl a{65, 0, 0, 0};


    printf_s("cxl %zi, cxl bitfields %zi \n", sizeof(CIXL_Cxl), sizeof (CIXL_PackedCxl));
    printf_s("cxl [96] %zi, cxl [96] bitfields %zi", sizeof(CIXL_TEST_NOTPACKED), sizeof (CIXL_TEST_PACKED));
}
*/


TEST_CASE("Pack CIXL_Cxl", "should be valid")
{
    CIXL_Cxl a{65, 0, 0, 0};

    REQUIRE(cixl_pack_cxl(&a) == 65);
}

TEST_CASE("Pack CIXL_Cxl all attrs", "should be valid")
{
    CIXL_Cxl a{65, 3, 5, 4};

    //0x04_5_3_41
    REQUIRE(cixl_pack_cxl(&a) == 0x45341);
}

TEST_CASE("Unpack CIXL_Cxl", "should be valid")
{
    CIXL_Cxl a{65, 3, 5, 4};
    int32_t  int_value = cixl_pack_cxl(&a);
    REQUIRE(int_value == 0x45341);
    //int32_t  *int_ptr  = &int_value;
    //CIXL_Cxl unpacked_cxl ={};

    CIXL_Cxl unpacked_cxl = cixl_unpack_cxl(&int_value);

    /*REQUIRE(unpacked_cxl.char_value == 65);
    REQUIRE(unpacked_cxl.fg_color == 3);
    REQUIRE(unpacked_cxl.bg_color == 5);
    REQUIRE(unpacked_cxl.style_opts == 4);*/

    int unpacked_cxl_int_value = cixl_pack_cxl(&unpacked_cxl);

    REQUIRE(0x45341 == unpacked_cxl_int_value);
}

TEST_CASE("cixl_put and cixl_pick", "should be valid")
{
    cixl_init_screen_buffer(10, 10, &X);

    CIXL_Cxl a{65, 0, 0, 0};
    REQUIRE(cixl_put(1, 1, a));

    CIXL_Cxl b = cixl_pick(1, 1);

    REQUIRE(cixl_pack_cxl(&a) == cixl_pack_cxl(&b));
}

TEST_CASE("cxl_is_out_of_drawing_area", "should be valid")
{
    REQUIRE(!cxl_is_out_of_drawing_area(1, 1, 1));
    REQUIRE(!cxl_is_out_of_drawing_area(0, 0, 1));
    REQUIRE(cxl_is_out_of_drawing_area(81, 0, 1));
}

TEST_CASE("is out of drawing area", "should be valid")
{
    cixl_init_screen_buffer(80, 25, &X);
    REQUIRE(cxl_is_out_of_drawing_area(500, 20, 1));
}


TEST_CASE("screen_buffer_put_next screen_buffer_pick_next", "should be the same and dirty")
{
    //Arrange
    CIXL_Cxl a{65, 0, 0, 0};
    int      is_dirty = 0;
    cixl_init_screen_buffer(80, 25, &X);

    //Act
    REQUIRE(screen_buffer_put_next(1, a));
    CIXL_Cxl b        = screen_buffer_pick_next(1, &is_dirty);

    //Assert
    REQUIRE(b.char_value == a.char_value);
    REQUIRE(is_dirty == 1);
}

TEST_CASE("screen_buffer_put_current screen_buffer_pick_current", "should be the same")
{
    //Arrange
    CIXL_Cxl a{65, 0, 0, 0};
    cixl_init_screen_buffer(80, 25, &X);

    //Act
    REQUIRE(screen_buffer_put_current(1, a));
    CIXL_Cxl b = screen_buffer_pick_current(1);

    //Assert
    REQUIRE(b.char_value == 65);
}

TEST_CASE("buffer_get_state", "should be the same")
{
    //Arrange
    CIXL_Cxl a{65, 0, 0, 0};
    CIXL_Cxl b{66, 0, 0, 0};
    REQUIRE(cixl_init_screen_buffer(80, 25, &X));

    REQUIRE(screen_buffer_put_current(1, a));
    REQUIRE(screen_buffer_put_next(1, b));

    CIXL_Cxl out_current;
    CIXL_Cxl out_next;
    int      is_dirty = 0;

    //Act
    REQUIRE(screen_buffer_get_cixl_state(1, &out_current, &out_next, &is_dirty));

    //Assert
    REQUIRE(a.char_value == out_current.char_value);
    REQUIRE(b.char_value == out_next.char_value);

    REQUIRE(is_dirty == 1);
}

TEST_CASE("screen_buffer_swap_and_clear_is_dirty", "smoke test")
{
    //Arrange
    CIXL_Cxl a{65, 0, 0, 0};
    int      is_dirty = 0;
    cixl_init_screen_buffer(80, 25, &X);

    REQUIRE(screen_buffer_put_current(1, CXL_EMPTY));
    REQUIRE(screen_buffer_put_next(1, a));
    screen_buffer_pick_next(1, &is_dirty);
    REQUIRE(is_dirty == 1);

    //Act
    screen_buffer_swap_and_clear_is_dirty(1);

    //Assert
    //Next should now be swapped with an empty CIXL_Cxl
    CIXL_Cxl c = screen_buffer_pick_next(1, &is_dirty);
    REQUIRE(is_dirty == 0);
    REQUIRE(c.char_value == 0);
}


TEST_CASE("reset and render should result in 0 draw calls", "smoke test")
{
    //Arrange
    cixl_init_screen_buffer(80, 25, &X);

    cixl_render();

    //Act
    int draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 0);
}

TEST_CASE("put and then clear should result empty cxl", "smoke test")
{
    //Arrange
    CIXL_Cxl          b{'B', 0, 0, 0};
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init_screen_buffer(80, 25, &x);

    REQUIRE(cixl_put(1, 1, b));

    //Act
    REQUIRE(cixl_clear(1, 1));

    //Assert
    CIXL_Cxl picked = cixl_pick(1, 1);
    REQUIRE(picked.char_value == CXL_EMPTY.char_value);
}

TEST_CASE("put and then clear_area should result empty cxl", "smoke test")
{
    //Arrange
    CIXL_Cxl          b{'B', 0, 0, 0};
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init_screen_buffer(80, 25, &x);

    REQUIRE(cixl_put(1, 1, b));
    REQUIRE(cixl_put(2, 2, b));

    //Act
    cixl_clear_area(1, 1, 1, 1);

    //Assert
    CIXL_Cxl picked = cixl_pick(1, 1);
    REQUIRE(picked.char_value == CXL_EMPTY.char_value);
    picked = cixl_pick(2, 2);
    REQUIRE(picked.char_value == CXL_EMPTY.char_value);
}

TEST_CASE("when A is current put A then B then A should result in NOT DIRTY", "smoke test")
{
    //Arrange
    CIXL_Cxl          a{'A', 0, 0, 0};
    CIXL_Cxl          b{'B', 0, 0, 0};
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init_screen_buffer(80, 25, &x);

    cixl_put(1, 1, a);
    cixl_render();

    //Act
    REQUIRE(!cixl_put(1, 1, a));
    REQUIRE(cixl_put(1, 1, b));
    REQUIRE(cixl_put(1, 1, a));

    //Assert
    CIXL_Cxl picked = cixl_pick(1, 1);
    CIXL_Cxl out_current;
    CIXL_Cxl out_next;
    int      is_dirty;

    screen_buffer_get_cixl_state(81, &out_current, &out_next, &is_dirty);
    REQUIRE(picked.char_value == a.char_value);
    REQUIRE(is_dirty == 0);
}

TEST_CASE("put and then clear should result in 0 draw calls", "smoke test")
{
    //Arrange
    CIXL_Cxl          a{'B', 0, 0, 0};
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init_screen_buffer(80, 25, &x);

    REQUIRE(cixl_put(1, 1, a));
    REQUIRE(cixl_clear(1, 1));

    //Act
    int draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 0);
}

TEST_CASE("first render ok", "smoke test")
{
    //Arrange
    CIXL_Cxl a{'A', 0, 0, 0};

    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init_screen_buffer(80, 25, &x);

    REQUIRE(cixl_put(0, 1, a));

    //Act
    int draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 1);
}

TEST_CASE("write line buffer second render ok", "smoke test")
{
    //Arrange
    CIXL_Cxl          a{'A', 0, 0, 0};
    CIXL_Cxl          b{'B', 0, 0, 0};
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init_screen_buffer(80, 25, &x);

    cixl_render();

    REQUIRE(cixl_put(1, 1, a));
    REQUIRE(cixl_put(1, 2, b));
    //first render, ignore this result
    cixl_render();

    //Act
    REQUIRE(cixl_put(0, 1, a));
    REQUIRE(cixl_put(79, 24, b));
    int               draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 2);
}

TEST_CASE("render calls draw_s for same cixel styles on same line..", "smoke test")
{
    //Arrange
    CIXL_Cxl          a{'A', 0, 0, 0};
    CIXL_Cxl          b{'B', CIXL_Color_Green, 0, 0};
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init_screen_buffer(80, 25, &x);


    //put a string block, this should result in one draw call when rendered
    for (int i = 0; i < 5; i++)
    {
        REQUIRE(cixl_put(i, 1, a));
    }
    //write immediately after previous on the same line, with a different style
    for (int i = 5; i < 10; i++)
    {
        REQUIRE(cixl_put(i, 1, b));
    }

    //Act
    int draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 2);//2 draw count, 2 styles
    REQUIRE(LAST_START_X_CALLED == 5);
    REQUIRE(LAST_START_Y_CALLED == 1);

    REQUIRE(LAST_STR_CALLED == std::string("BBBBB"));
}

TEST_CASE("render calls draw_s for when writing with puts", "smoke test")
{
    //Arrange
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init_screen_buffer(80, 25, &x);

    //put a string block, this should result in one draw call when rendered

    cixl_print(0, 1, "AAAAAAAAAA", 0, 0, 0);

    //Act
    int draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 1);
    REQUIRE(LAST_START_X_CALLED == 0);
    REQUIRE(LAST_START_Y_CALLED == 1);

    REQUIRE(LAST_STR_CALLED == std::string("AAAAAAAAAA"));
}

TEST_CASE("game ms_to_ticks", "smoke test")
{
    REQUIRE(ms_to_ticks(10, 1000) == 10);
    REQUIRE(ms_to_ticks(10, 1001) == 10);
    REQUIRE(ms_to_ticks(2000, 1000) == 2000);
}

TEST_CASE("game ticks_to_ms", "smoke test")
{
    REQUIRE(ticks_to_ms(16, 1000) == 16);
    REQUIRE(ticks_to_ms(16, 1001) == 15);
    REQUIRE(ticks_to_ms(500, 1001) == 499);

    REQUIRE(ticks_to_ms(500, CLOCKS_PER_SEC) == 500);
}

TEST_CASE("game one tick fixed step should progress 16 ms", "smoke test")
{

    CIXL_Game *p_cixl_game = cixl_game_create(CLOCKS_PER_SEC);
    REQUIRE(p_cixl_game->is_fixed_time_step);
    REQUIRE(p_cixl_game->clocks_per_second == CLOCKS_PER_SEC);

    bool    should_exit   = false;
    REQUIRE(cixl_game_init(NULL) == 1);
    clock_t current_ticks = clock();
    REQUIRE(current_ticks > 0);

    //Perform one init tick plus one
    REQUIRE(cixl_game_tick(&CURRENT_GAME_TIME, NULL, &should_exit) == 1);
    REQUIRE(cixl_game_tick(&CURRENT_GAME_TIME, NULL, &should_exit) == 1);


    REQUIRE(CURRENT_GAME_TIME.elapsed_game_time_ticks == 16);
    REQUIRE(CURRENT_GAME_TIME.elapsed_game_time_ms == 16);
    REQUIRE(CURRENT_GAME_TIME.total_game_time_ticks == 32);
}

#pragma clang diagnostic pop