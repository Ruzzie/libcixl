#pragma warning (disable : 4068 )
#pragma clang diagnostic push
#pragma ide diagnostic ignored "readability-avoid-const-params-in-decls"
#ifndef LIBCIXL_GAME_H
#define LIBCIXL_GAME_H
#include "std/cixl_stdtime.h"
#include "config.h"

typedef struct CIXL_GameTime
{
    /*! \brief Total accumulated time in (clocks) Ticks that the game is running.*/
    unsigned long total_game_time_ticks;

    /*! \brief Elapsed time in (clocks) Ticks since last update.*/
    unsigned long elapsed_game_time_ticks;

    /*! \brief Elapsed time in milliseconds since last update.*/
    unsigned long elapsed_game_time_ms;

    /*! \brief Indicates if there is lag*/
    bool is_running_slowly;

    /*! \brief Current frames per second.*/
    unsigned int current_fps;

    int frame_lag;
    int step_count;
} CIXL_GameTime;

typedef struct CIXL_Game
{
    /*! \brief Whether to advance the game at a fixed or variable(as fast as possible)..*/
    bool is_fixed_time_step;

    /*! \brief The target of time per tick to achieve, this is effectively the 1/fps in millis.*/
    unsigned int target_elapsed_time_millis; //16.6667 ms, 60fps

    /*! \brief The maximum amount of time we will frame-skip over and only perform Update calls with no Draw calls.*/
    unsigned int max_elapsed_time_millis;//500;

    clock_t clocks_per_second;

    /*! \brief To signal exit to the game this method can be called. This should call cixl_game_exit; When created with default, it is automatically set to that.*/
    int (*f_exit_game)();

    /*! \brief This method is called multiple times per second, and is used to update your game state (checking for collisions, gathering input, playing audio, etc.).*/
    void (*f_update_game)(const CIXL_GameTime *game_time, void *shared_state);

    /*! \brief This method is called multiple times per second, and is used to update drawing logic. At the end of each draw, the screen buffer will be rendered to the screen.*/
    void (*f_draw_game)(const CIXL_GameTime *game_time, void *shared_state);
} CIXL_Game;

#ifdef __cplusplus
extern "C" {
#endif

#ifdef WITH_INTERNALS_VISIBLE
int cixl_game_tick(CIXL_GameTime *game_time, void *shared_state, const bool *should_exit);
clock_t ms_to_ticks(const unsigned int ms, const clock_t clocks_per_second);
unsigned int ticks_to_ms(const clock_t ticks, const clock_t clocks_per_second);

extern struct CIXL_GameTime CURRENT_GAME_TIME;
#endif

CIXLLIB_API CIXL_Game *cixl_game_default();
CIXLLIB_API int cixl_game_init(CIXL_Game *game, void *shared_state);
CIXLLIB_API int cixl_game_run();

#ifdef __cplusplus
} /* End of extern "C" */
#endif

#endif //LIBCIXL_GAME_H

#pragma clang diagnostic pop

