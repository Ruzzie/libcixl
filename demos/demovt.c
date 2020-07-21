/*! \file
 * \brief Demo VT Console that uses libcixl. Works on Dos (with ansi) and win.
 * \author Dorus Verhoeckx
 * \date 2020
 * \copyright Dorus Verhoeckx or https://unlicense.org/ or  https://mit-license.org/
 * document with https://www.doxygen.nl/manual/docblocks.html#cppblock
 * */
#include<stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <time.h>
#include "libcixl.h"

int move_cursor(int x, int y)
{

    /*  Moves the cursor to row n, column m. The values are 1-based, and default to 1 (top left corner) if omitted.
     * A sequence such as CSI ;5H is a synonym for CSI 1;5H as well as CSI 17;H is the same as CSI 17H and CSI 17;1H*/
    return printf("\033[%i;%iH", y + 1, x + 1);
}

int hide_cursor()
{
    /*CSI ? 25 l        DECTCEM Hides the cursor.*/
    return puts("\033[?25l");
}

int show_cursor()
{
    /*DECTCEM Shows the cursor, from the VT320.*/
    return puts("\033[?25h");
}

void cls()
{
    puts("\033[2J");
}

void set_video_mode()
{
    /*80x25 color text
    https://www.robvanderwoude.com/ansi.php*/
    puts("\033[=3h;\033[=3l;");
}

void draw_cixl(const int start_x, const int start_y, const Cixl cixl)
{
    move_cursor(start_x, start_y);
    putchar(cixl.char_value);
}

void
draw_cixl_s(const int start_x, const int start_y, char *str, const int size, const Color fg_color, const Color bg_color,
            const FontDecoration decoration)
{
    move_cursor(start_x, start_y);
    puts(str);
}

static RenderDevice VT_RENDER_DEVICE = {draw_cixl, draw_cixl_s};
static const char   HEADER_S[44]     = "[Ruzzie Termlib ANSI VT Demo & Test program]";
static const char   INFO_LINE_S[27]  = "            press x to exit";


#define DEMO_VT_MAX_INPUT_BUFFER_SIZE 80
static char INPUT_BUFFER[DEMO_VT_MAX_INPUT_BUFFER_SIZE];//arbitrary size, what if someone copy and pastes stuff....?
static int  INPUT_BUFFER_SIZE        = 0;
Cixl        PLAYER                   = {'@', 0, 0, 0};

int main(void)
{
    unsigned int total_loop_count = 0;
    clock_t      program_begin    = clock(), begin, total_loop_time_clocks = 0;
    char         loops_per_seconds_s[32];
    char         clock_info_s[48];

    cixl_init(&VT_RENDER_DEVICE);

    hide_cursor();
    set_video_mode();
    cls();
    move_cursor(0, 0);

    cixl_put(0, 12, PLAYER);
    cixl_puts(0, 0, HEADER_S, (int) strlen(HEADER_S), 0, 0, 0);
    cixl_puts(0, 1, INFO_LINE_S, (int) strlen(INFO_LINE_S), 0, 0, 0);

    sprintf(clock_info_s, "cps: %lu currclock:%lu", CLOCKS_PER_SEC, program_begin);
    cixl_puts(0, 2, clock_info_s, (int) strlen(clock_info_s), 0, 0, 0);

    cixl_render();// first render
    fflush(stdout);  // flush output after first render

    while (true)
    {
        begin = clock() - program_begin; //assure relative offset
        while (_kbhit() && (INPUT_BUFFER_SIZE < DEMO_VT_MAX_INPUT_BUFFER_SIZE)) //check for keys in input buffer
        {
            INPUT_BUFFER[INPUT_BUFFER_SIZE++] = (char) _getch();
        }

        if (INPUT_BUFFER_SIZE != 0)
        {
            cixl_puts(0, 12, INPUT_BUFFER, INPUT_BUFFER_SIZE, 0, 0, 0);
            INPUT_BUFFER_SIZE = 0;
            if (INPUT_BUFFER[0] == 'x')
            {
                goto exit;
            }
        }

        if ((total_loop_time_clocks / CLOCKS_PER_SEC) == 1) //dirty % calc, mod does not seem to work on dos
        {
            float avg_clocks_per_loop  = (total_loop_time_clocks / (float) total_loop_count);
            float loop_duration_in_sec = avg_clocks_per_loop / (float) CLOCKS_PER_SEC;
            sprintf(loops_per_seconds_s, "|%.1f|[%lu]<%lu> ", (float) (1.0 / loop_duration_in_sec), begin,
                    total_loop_time_clocks);
            cixl_puts(80 - 32, 1, loops_per_seconds_s, (int) strlen(loops_per_seconds_s), 0, 0, 0);
        }

        if (cixl_render() > 0) //only flush when there is new data
        {
            fflush(stdout);
        }

        if (total_loop_time_clocks >= (CLOCKS_PER_SEC)) //Reset after 1 sec
        {
            total_loop_count       = 0;
            total_loop_time_clocks = 0;
        }
        else
        {
            total_loop_count++;
            total_loop_time_clocks += (clock() - begin);
        }
    }
    exit:
    {
        //printf("loop count: [%i]\r\n", total_loop_count);
        show_cursor();
        //Cleanup
        printf("\033[0m");
        return 1;
    }

    return -1;
}

