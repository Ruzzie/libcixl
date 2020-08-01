#include "std/cixl_stdtime.h"
#include "std/cixl_stdbool.h"
#include "std/cixl_sleep.h"
#include "std/cixl_math.h"
#include "game.h"

#include "console.h"

bool GAME_SHOULD_EXIT = false;

int cixl_game_exit()
{
    GAME_SHOULD_EXIT = true;
    return 1;
}

CIXL_Game INITIAL_GAME  = {true, 16, 500, CLOCKS_PER_SEC, cixl_game_exit, NULL, NULL};
CIXL_Game *CURRENT_GAME = &INITIAL_GAME;

#ifndef __cplusplus
CIXL_GameTime CURRENT_GAME_TIME   = {0, 0, 0, false, 0, 0, 0};
#endif

/// Reference to the shared game state. This is passed through to the update and draw methods.
CIXL_TYPED_GAME_STATE(CIXL_GAME_STATE_TYPE, SHARED_GAME_STATE_PTR) = NULL;

bool          GAME_IS_INITIALIZED = false;

clock_t PREVIOUS_TICKS                 = 0;
clock_t ACCUMULATED_ELAPSED_TIME_TICKS = 0;
clock_t TARGET_ELAPSED_TIME_TICKS      = 16;
clock_t MAX_ELAPSED_TIME_TICKS         = 500;
int     UPDATE_FRAME_LAG               = 0;

inline clock_t ms_to_ticks(const unsigned int ms, const clock_t clocks_per_second)
{
    return (clock_t) ((ms / 1000.0) * clocks_per_second);
}

inline unsigned int ticks_to_ms(const clock_t ticks, const clock_t clocks_per_second)
{
    return (ticks * 1000) / clocks_per_second;
}

CIXL_Game *cixl_game_create(clock_t clocks_per_second)
{
    CURRENT_GAME->clocks_per_second = clocks_per_second;
    return CURRENT_GAME;
}

int cixl_game_init(void *shared_state_ptr)
{
    if (CURRENT_GAME == NULL)
    {
        return -2;
    }

    if (CURRENT_GAME->target_elapsed_time_millis > 0)
    {
        TARGET_ELAPSED_TIME_TICKS = ms_to_ticks(CURRENT_GAME->target_elapsed_time_millis,
                                                CURRENT_GAME->clocks_per_second);
    }

    if (CURRENT_GAME->max_elapsed_time_millis > 0)
    {
        MAX_ELAPSED_TIME_TICKS = ms_to_ticks(CURRENT_GAME->max_elapsed_time_millis, CURRENT_GAME->clocks_per_second);
    }
    SHARED_GAME_STATE_PTR = shared_state_ptr;
    GAME_IS_INITIALIZED   = true;
    return 1;
}

static unsigned int FRAMES_COUNTER  = 0;
static clock_t      FPS_TIMER_TICKS = 0;

static inline void fps_counter_update(CIXL_GameTime *game_time)
{
    FPS_TIMER_TICKS += game_time->elapsed_game_time_ticks;

    if (FPS_TIMER_TICKS > CURRENT_GAME->clocks_per_second) // Reset after 1 second
    {
        game_time->current_fps = FRAMES_COUNTER;
        FRAMES_COUNTER = 0;
        FPS_TIMER_TICKS -= CURRENT_GAME->clocks_per_second;
    }
}

static void cixl_game_do_update(CIXL_GameTime *game_time, void *shared_state)
{
    fps_counter_update(game_time);

    if (CURRENT_GAME->f_update_game != NULL)
    {
        CURRENT_GAME->f_update_game(game_time, shared_state);
    }
}

static void cixl_game_do_draw(CIXL_GameTime *game_time, void *shared_state)
{
    ++FRAMES_COUNTER;

    if (CURRENT_GAME->f_draw_game != NULL)
    {
        CURRENT_GAME->f_draw_game(game_time, shared_state);
    }
}

int cixl_game_tick(CIXL_GameTime *game_time, void *shared_state, const bool *should_exit)
{
    //Inspired by MonoGame Tick (https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Game.cs)
    //clock();

    goto RetryTick;
    RetryTick:
    {
        clock_t current_ticks = clock();//Current Ticks

        // Advance the accumulated elapsed time.
        ACCUMULATED_ELAPSED_TIME_TICKS += current_ticks - PREVIOUS_TICKS;
        PREVIOUS_TICKS        = current_ticks;

        if ((CURRENT_GAME->is_fixed_time_step == true) && ACCUMULATED_ELAPSED_TIME_TICKS < TARGET_ELAPSED_TIME_TICKS)
        {
            // Sleep for as long as possible without overshooting the update time.
            // We may overshoot a bit. TODO: Tweak sleep time
            clock_t sleep_time = ticks_to_ms(TARGET_ELAPSED_TIME_TICKS - ACCUMULATED_ELAPSED_TIME_TICKS,
                                             CURRENT_GAME->clocks_per_second);
            cixl_sleep_ms(cixl_max(1, sleep_time));

            // Keep looping until it's time to perform the next update
            goto RetryTick;
        }
    }

    // Do not allow any update to take longer than our maximum (MAX_ELAPSED_TIME_TICKS).
    if (ACCUMULATED_ELAPSED_TIME_TICKS > MAX_ELAPSED_TIME_TICKS)
    {
        ACCUMULATED_ELAPSED_TIME_TICKS = MAX_ELAPSED_TIME_TICKS;
    }

    if (CURRENT_GAME->is_fixed_time_step)
    {
        int step_count;
        step_count = 0;
        game_time->elapsed_game_time_ticks = TARGET_ELAPSED_TIME_TICKS;
        game_time->elapsed_game_time_ms    = ticks_to_ms(TARGET_ELAPSED_TIME_TICKS, CURRENT_GAME->clocks_per_second);

        // Perform as many full fixed length time steps as we can.
        while (ACCUMULATED_ELAPSED_TIME_TICKS >= TARGET_ELAPSED_TIME_TICKS && ((*should_exit) != true))
        {
            game_time->total_game_time_ticks += TARGET_ELAPSED_TIME_TICKS;
            ACCUMULATED_ELAPSED_TIME_TICKS -= TARGET_ELAPSED_TIME_TICKS;
            ++step_count;

            game_time->step_count = step_count;
            cixl_game_do_update(game_time, shared_state);
        }

        //Every update after the first accumulates lag
        UPDATE_FRAME_LAG += cixl_max(0, step_count - 1);

        //If we think we are running slowly, wait until the lag clears before resetting it
        if (game_time->is_running_slowly == true)
        {
            if (UPDATE_FRAME_LAG == 0)
            {
                game_time->is_running_slowly = false;
            }
        }
        else if (UPDATE_FRAME_LAG >= 5)
        {
            //If we lag more than 5 frames, start thinking we are running slowly
            game_time->is_running_slowly = true;
        }

        //Every time we just do one update and one draw, then we are not running slowly, so decrease the lag
        if (step_count == 1 && UPDATE_FRAME_LAG > 0)
        {
            --UPDATE_FRAME_LAG;
        }

        // Draw needs to know the total elapsed time
        // that occurred for the fixed length updates.
        game_time->elapsed_game_time_ticks = TARGET_ELAPSED_TIME_TICKS * step_count;
        game_time->elapsed_game_time_ms    = ticks_to_ms(game_time->elapsed_game_time_ticks,
                                                         CURRENT_GAME->clocks_per_second);
        game_time->frame_lag               = UPDATE_FRAME_LAG;
    }
    else
    {
        // Perform a single variable length update aka. as fast as possible
        game_time->elapsed_game_time_ticks = ACCUMULATED_ELAPSED_TIME_TICKS;
        game_time->elapsed_game_time_ms    = ticks_to_ms(ACCUMULATED_ELAPSED_TIME_TICKS,
                                                         CURRENT_GAME->clocks_per_second);

        game_time->total_game_time_ticks += ACCUMULATED_ELAPSED_TIME_TICKS;

        ACCUMULATED_ELAPSED_TIME_TICKS = 0;

        cixl_game_do_update(game_time, shared_state);
    }

    //Do Draw
    cixl_game_do_draw(game_time, shared_state);
    return 1;
}

int cixl_game_run()
{
    if (!GAME_IS_INITIALIZED)
    {
        return -2;
    }

    PREVIOUS_TICKS = clock();//INITIALIZE TO CURRENT TIME;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfor-loop-analysis"
    while (!GAME_SHOULD_EXIT)
    {
        cixl_game_tick(&CURRENT_GAME_TIME, SHARED_GAME_STATE_PTR, &GAME_SHOULD_EXIT);
    }
    return 1;
#pragma clang diagnostic pop
}
