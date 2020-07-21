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

#include "catch.hpp"
#include "../src/libcixl.h"

TEST_CASE("Pack CIXL_Cxl", "should be valid")
{
    CIXL_Cxl a{65, 0, 0, 0};

    REQUIRE(cixl_pack(&a) == 65);
}

TEST_CASE("Unpack CIXL_Cxl", "should be valid")
{
    CIXL_Cxl a{65, 0, 0, 0};
    int      int_value = cixl_pack(&a);
    int  *int_ptr  = &int_value;

    CIXL_Cxl *unpacked_cixel          = cixl_unpack(int_ptr);
    int      unpacked_cixel_int_value = cixl_pack(unpacked_cixel);

    REQUIRE(65 == unpacked_cixel_int_value);
}

TEST_CASE("cixl_put and cixl_pick", "should be valid")
{
    cixl_reset();
    CIXL_Cxl a{65, 0, 0, 0};
    REQUIRE(cixl_put(1, 1, a));

    CIXL_Cxl b = cixl_pick(1, 1);

    REQUIRE(cixl_pack(&a) == cixl_pack(&b));
}

TEST_CASE("cxl_is_out_of_drawing_area", "should be valid")
{
    REQUIRE(!cxl_is_out_of_drawing_area(1, 1, 1));
    REQUIRE(!cxl_is_out_of_drawing_area(0, 0, 1));
    REQUIRE(cxl_is_out_of_drawing_area(81, 0, 1));
}

TEST_CASE("is out of drawing area", "should be valid")
{
    REQUIRE(cxl_is_out_of_drawing_area(500, 20, 1));
}


TEST_CASE("buffer_put_next buffer_pick_next", "should be the same and dirty")
{
    //Arrange
    CIXL_Cxl a{65, 0, 0, 0};
    int      is_dirty = 0;

    //Act
    REQUIRE(buffer_put_next(1, a));
    CIXL_Cxl b        = buffer_pick_next(1, &is_dirty);

    //Assert
    REQUIRE(b.char_value == a.char_value);
    REQUIRE(is_dirty == 1);
}

TEST_CASE("buffer_put_current buffer_pick_current", "should be the same")
{
    //Arrange
    CIXL_Cxl a{65, 0, 0, 0};

    //Act
    REQUIRE(buffer_put_current(1, a));
    CIXL_Cxl b = buffer_pick_current(1);

    //Assert
    REQUIRE(b.char_value == 65);
}

TEST_CASE("buffer_get_state", "should be the same")
{
    //Arrange
    CIXL_Cxl a{65, 0, 0, 0};
    CIXL_Cxl b{66, 0, 0, 0};

    REQUIRE(buffer_put_current(1, a));
    REQUIRE(buffer_put_next(1, b));

    CIXL_Cxl out_current;
    CIXL_Cxl out_next;
    int      is_dirty = 0;

    //Act
    REQUIRE(buffer_get_cixl_state(1, &out_current, &out_next, &is_dirty));

    //Assert
    REQUIRE(a.char_value == out_current.char_value);
    REQUIRE(b.char_value == out_next.char_value);

    REQUIRE(is_dirty == 1);
}

TEST_CASE("buffer_swap_and_clear_is_dirty", "smoke test")
{
    //Arrange
    CIXL_Cxl a{65, 0, 0, 0};
    int      is_dirty = 0;
    REQUIRE(buffer_put_current(1, CXL_EMPTY));
    REQUIRE(buffer_put_next(1, a));
    buffer_pick_next(1, &is_dirty);
    REQUIRE(is_dirty == 1);

    //Act
    buffer_swap_and_clear_is_dirty(1);

    //Assert
    //Next should now be swapped with an empty CIXL_Cxl
    CIXL_Cxl c = buffer_pick_next(1, &is_dirty);
    REQUIRE(is_dirty == 0);
    REQUIRE(c.char_value == 0);
}


int move_cursor(int x, int y, FILE *output)
{
    return fprintf(output, "\033[%i;%iH", x, y);
}

int  LAST_START_X_CALLED = -1;
int      LAST_START_Y_CALLED = -1;
CIXL_Cxl LAST_CIXL_CALLED    = CXL_EMPTY;
char     *LAST_STR_CALLED    = nullptr;


void draw_cixl(const int start_x, const int start_y, const CIXL_Cxl cixl)
{
    LAST_START_X_CALLED = start_x;
    LAST_START_Y_CALLED = start_y;
    LAST_CIXL_CALLED    = cixl;

    move_cursor(start_x, start_y, stdout);
    fputc(cixl.char_value, stdout);
}

void
draw_cixl_s(const int start_x, const int start_y, char *str, const int size, const CIXL_Color fg_color, const CIXL_Color bg_color,
            const CIXL_StyleOpts decoration)
{
    LAST_START_X_CALLED = start_x;
    LAST_START_Y_CALLED = start_y;
    LAST_STR_CALLED     = str;

    move_cursor(start_x, start_y, stdout);
    fputs(str, stdout);
}

TEST_CASE("clear and render should result in 0 draw calls", "smoke test")
{
    //Arrange
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init(&x);
    cixl_reset();
    cixl_render();

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
    cixl_init(&x);
    cixl_reset();

    REQUIRE(cixl_put(0, 1, a));

    //Act
    int draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 1);
}

TEST_CASE("write line buffer second render ok", "smoke test")
{
    //Arrange
    CIXL_Cxl     a{'A', 0, 0, 0};
    CIXL_Cxl          b{'B', 0, 0, 0};
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init(&x);

    cixl_reset();
    cixl_render();

    REQUIRE(cixl_put(1, 1, a));
    REQUIRE(cixl_put(1, 2, b));
    //first render, ignore this result
    cixl_render();

    //Act
    REQUIRE(cixl_put(0, 1, a));
    REQUIRE(cixl_put(79, 24, b));
    int          draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 2);
}

TEST_CASE("render calls draw_s for same cixel styles on same line..", "smoke test")
{
    //Arrange
    CIXL_Cxl          a{'A', 0, 0, 0};
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init(&x);

    cixl_reset();

    //put a string block, this should result in one draw call when rendered
    for (int i = 0; i < 10; i++)
    {
        REQUIRE(cixl_put(i, 1, a));
    }

    //Act
    int draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 1);
    REQUIRE(LAST_START_X_CALLED == 0);
    REQUIRE(LAST_START_Y_CALLED == 1);

    REQUIRE(LAST_STR_CALLED == std::string("AAAAAAAAAA"));
}

TEST_CASE("render calls draw_s for when writing with puts", "smoke test")
{
    //Arrange
    CIXL_RenderDevice x{draw_cixl, draw_cixl_s};
    cixl_init(&x);

    cixl_reset();

    //put a string block, this should result in one draw call when rendered

    cixl_puts(0, 1, "AAAAAAAAAA", 10, 0, 0, 0);

    //Act
    int draw_count = cixl_render();

    //Assert
    REQUIRE(draw_count == 1);
    REQUIRE(LAST_START_X_CALLED == 0);
    REQUIRE(LAST_START_Y_CALLED == 1);

    REQUIRE(LAST_STR_CALLED == std::string("AAAAAAAAAA"));
}

#pragma clang diagnostic pop