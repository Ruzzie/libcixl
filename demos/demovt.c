/*! \file
 * \brief Demo VT Console that uses libcixl. Works on Dos (with ansi) and win.
 * \author Dorus Verhoeckx
 * \date 2020
 * \copyright Dorus Verhoeckx or https://unlicense.org/ or  https://mit-license.org/
 * document with https://www.doxygen.nl/manual/docblocks.html#cppblock
 * */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <time.h>

#define CIXL_GAME_STATE_TYPE int

#include "../src/libcixl.h"

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
    //puts("\033[=3h;\033[=3l;");

    /*320x200 16 colors*/
    //puts("\033[=13h\033[=13l");

    /*640x200 16 colors*/
    /* puts("\033[=14h");*/

    /*640x200 16 colors*/
    puts("\033[=18h");
}

void reset_video_mode()
{
    puts("\033[=18l");
}


int CURR_FG_COLOR = -1;
int CURR_BG_COLOR = -1;

int FG_COLOR_MAP[16] = {30, 31, 32, 33, 34, 35, 36, 37, 90, 91, 92, 93, 94, 95, 96, 97};
int BG_COLOR_MAP[16] = {40, 41, 42, 43, 44, 45, 46, 47, 100, 101, 102, 103, 104, 105, 106, 107};


inline void set_fg_color(const int color)
{
    if (CURR_FG_COLOR != color)
    {
        //printf("\033[38;5;%im", color);//8 bit fg color sgr
        if(color > 7)
            printf("\033[1;%im", (FG_COLOR_MAP[color]) - 60); // 4 bit color sgr
            //printf_s("Z[%i;1m", (FG_COLOR_MAP[color]) - 60); // 4 bit color sgr
        else
            printf("\033[0;%im", FG_COLOR_MAP[color]);

        CURR_FG_COLOR = color;
    }
}

inline void set_bg_color(const int color)
{
   /* if (CURR_BG_COLOR != color)
    {*/
        if (color > 7)
        {
            //bright color: try with bold style_opts, for older systems
            printf("\033[%im", (BG_COLOR_MAP[color]) - 60); // 4 bit color sgr
        }
        else
        {
            printf("\033[%im", BG_COLOR_MAP[color]); // 4 bit color sgr
        }
        //printf("\033[48;5;%im", color);//8 bit bg color sgr

        CURR_BG_COLOR = color;
    /*}*/
}

void draw_cixl(const int start_x, const int start_y, const CIXL_Cxl cxl)
{
    set_fg_color(cxl.fg_color);
    set_bg_color(cxl.bg_color);
    move_cursor(start_x, start_y);
    putchar(cxl.char_value);
}

void draw_cixl_s(const int start_x, const int start_y, char *str, unsigned const int size, const CIXL_Color fg_color,
                 const CIXL_Color bg_color, const CIXL_StyleOpts decoration)
{
    set_fg_color(fg_color);
    set_bg_color(bg_color);
    move_cursor(start_x, start_y);
    puts(str);
}

static CIXL_RenderDevice VT_RENDER_DEVICE = {draw_cixl, draw_cixl_s};
static const char        HEADER_S[44]     = "[Ruzzie Termlib ANSI VT Demo & Test program]";
static const char        INFO_LINE_S[27]  = "            press x to exit";


#define DEMO_VT_MAX_INPUT_BUFFER_SIZE 80
static char INPUT_BUFFER[DEMO_VT_MAX_INPUT_BUFFER_SIZE];//arbitrary size, what if someone copy and pastes stuff....?
static int  INPUT_BUFFER_SIZE             = 0;
CIXL_Cxl    PLAYER                        = {'@', CIXL_Color_White_Bright, CIXL_Color_Black, 0};

CIXL_Game *GAME;

char         STATS_PER_SECONDS_S[54];

void update(const CIXL_GameTime *game_time, int *shared_state)
{
    while (_kbhit() && (INPUT_BUFFER_SIZE < DEMO_VT_MAX_INPUT_BUFFER_SIZE)) //check for keys in input buffer
    {
        INPUT_BUFFER[INPUT_BUFFER_SIZE++] = (char) _getch();
    }

    if (INPUT_BUFFER_SIZE != 0)
    {
        cixl_put_horiz_s(0, 12, INPUT_BUFFER, CIXL_Color_Magenta, CIXL_Color_Green, 0);
        INPUT_BUFFER_SIZE = 0;
        if (INPUT_BUFFER[0] == 'x')
        {
            GAME->f_exit_game();
        }
    }

    sprintf(STATS_PER_SECONDS_S, "[%u](s:%i)|[elms:%lu][t_ticks:%lu][lag:%i][step:%i]", game_time->current_fps,
            (game_time->is_running_slowly), game_time->elapsed_game_time_ms, game_time->total_game_time_ticks,
            game_time->frame_lag, game_time->step_count);

    cixl_put_horiz_s(0, 0, STATS_PER_SECONDS_S, 0, CIXL_Color_Grey, 0);
}

void draw(const CIXL_GameTime *game_time, int *shared_state)
{
    if (cixl_render() > 0) //only flush when there is new data
    {
        fflush(stdout);
    }
}

int main(void)
{
    char clock_info_s[48];

    GAME = cixl_game_create(CLOCKS_PER_SEC);
    #ifdef __DOS__
    //For now since custom interrupt timers are not (yet?) implemented, set dos to a target time rate of 18 fps
    GAME->is_fixed_time_step         = true;
    GAME->target_elapsed_time_millis = 56;//18fps
    #else
    GAME->is_fixed_time_step         = false;
    GAME->target_elapsed_time_millis = 16;//60fps
    #endif
    GAME->max_elapsed_time_millis = 500;

    GAME->f_update_game = update;
    GAME->f_draw_game   = draw;
    cixl_game_init(NULL);
    cixl_init_render_device(&VT_RENDER_DEVICE);

    hide_cursor();
    //set_video_mode();
    cls();
    move_cursor(0, 0);


    cixl_put(0, 12, PLAYER);
    cixl_put_horiz_s(0, 1, HEADER_S, CIXL_Color_White_Bright, CIXL_Color_Black, 0);
    cixl_put_horiz_s(0, 2, INFO_LINE_S, CIXL_Color_White_Bright, CIXL_Color_Black, 0);

    sprintf(clock_info_s, "cps: %lu beginclock:%lu", CLOCKS_PER_SEC, clock());
    cixl_put_horiz_s(0, 3, clock_info_s, CIXL_Color_White_Bright, CIXL_Color_Black, 0);

    {
        //Print color line
        int color_x;
        int color_y;
        for (color_x = 0; color_x < 16; color_x++)
        {
            for (color_y = 0; color_y < 8; color_y++)
            {
                CIXL_Cxl *c = malloc(sizeof(CIXL_Cxl));
                c->char_value = '#';
                c->fg_color   = color_x;
                c->bg_color   = 7 - color_y;
                c->style_opts = 0;

                cixl_puti((TERM_WIDTH / 2) + color_x, color_y + 4, (int32_t *) c);
            }
        }
    }

    cixl_render();   // first render
    fflush(stdout);  // flush output after first render

    cixl_game_run();//Run the gameloop

    //printf("loop count: [%i]\r\n", total_loop_count);
    show_cursor();
    //reset_video_mode();
    //Cleanup
    printf("\033[0m");
    fflush(stdout);
    return 1;
}

