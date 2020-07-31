#include "std/cixl_stdint.h"
#include "console.h"

#ifndef NULL
#ifdef __cplusplus
#define NULL 0
#else
#define NULL ((void *)0)
#endif
#endif

inline bool cxl_is_out_of_drawing_area(const int x, const int y, const int num_chars)
{
    if (x < 0 || ((x + num_chars) > TERM_WIDTH || (x + num_chars) < 0 || y >= TERM_HEIGHT || y < 0))
    {
        return true;
    }
    else
    {
        return false;
    }
}

inline int cxl_index_for_xy(const int x, const int y)
{
    /* https://stackoverflow.com/questions/8591762/ifdef-debug-with-cmake-independent-from-platform */
#if !defined(NDEBUG)
    if (x >= TERM_WIDTH)
    {
        return -1;
    }
#endif
    return (TERM_WIDTH * y) + x;
}

typedef uint8_t CIXL_CxlState;

static const uint8_t STATE_IS_DIRTY_FLAG  = 0x0002;
static const uint8_t STATE_A_IS_NEXT      = 0x0000;
static const uint8_t STATE_FIRST_BIT_MASK = 0x0001;

static inline bool state_is_dirty(const CIXL_CxlState state)
{
    return (bool) (state & STATE_IS_DIRTY_FLAG) == STATE_IS_DIRTY_FLAG;
}

static inline bool state_a_is_next(const CIXL_CxlState state)
{
    return (bool) (state & STATE_FIRST_BIT_MASK) == STATE_A_IS_NEXT;
}

typedef CIXL_Cxl      FRAMEBUFFER[TERM_AREA];
typedef CIXL_CxlState STATE_BUFFER[TERM_AREA];
typedef struct CIXL_DoubleFramebuffer
{
    FRAMEBUFFER  buffer_a;
    FRAMEBUFFER  buffer_b;
    STATE_BUFFER state_buffer;
}                     CIXL_DoubleFramebuffer;

/*The main buffer*/
static CIXL_DoubleFramebuffer SCREEN_BUFFER;

inline void buffer_swap_and_clear_is_dirty(const int index)
{
    static const uint8_t one = 1;

    if (index < TERM_AREA)
    {
        CIXL_CxlState *state = &SCREEN_BUFFER.state_buffer[index];
        *state ^= one; /* Swap current <-> next, flip first bit*/
        *state &= one; /* Clear is dirty flag, set second bit on 0 and keep first bit*/
    }
}

inline void buffer_clear_is_dirty(const int index)
{
    static const uint8_t one = 1;

    CIXL_CxlState *state = &SCREEN_BUFFER.state_buffer[index];
    *state &= one; /* Clear is dirty flag, set second bit on 0 and keep first bit*/
}

CIXL_Cxl buffer_pick_current(const int index)
{
    if (index < TERM_AREA)
    {
        CIXL_CxlState state = SCREEN_BUFFER.state_buffer[index];
        return (state_a_is_next(state) ? SCREEN_BUFFER.buffer_b : SCREEN_BUFFER.buffer_a)[index];
    }
    else
    {
        return (CXL_EMPTY);
    }
}

bool buffer_put_current(const int index, const CIXL_Cxl cxl)
{
    if (index < TERM_AREA)
    {
        CIXL_CxlState current_state = SCREEN_BUFFER.state_buffer[index];
        if (state_a_is_next(current_state))
        {
            SCREEN_BUFFER.buffer_b[index] = cxl;
        }
        else
        {
            SCREEN_BUFFER.buffer_a[index] = cxl;
        }
        return true;
    }
    else
    {
        return false;
    }
}

bool SCREEN_BUFFER_IS_DIRTY          = false;

inline bool buffer_put_next(const int index, const CIXL_Cxl cxl)
{
    if (index >= TERM_AREA)
    {
        return false;
    }
    else
    {
        CIXL_CxlState *state = &(SCREEN_BUFFER.state_buffer[index]);
        (state_a_is_next(*state) ? SCREEN_BUFFER.buffer_a : SCREEN_BUFFER.buffer_b)[index] = cxl;

        /*Set State to IsDirty*/
        *state |= STATE_IS_DIRTY_FLAG;
        SCREEN_BUFFER_IS_DIRTY = true;
        return true;
    }
}

/*! get the the cixl that should be rendered in the next render cycle
 *! \param out_is_dirty indicates whether the cixl is dirty, when NULL it will not be set
 * */
CIXL_Cxl buffer_pick_next(const int index, int *out_is_dirty)
{
    if (index < TERM_AREA)
    {
        CIXL_CxlState current_state = SCREEN_BUFFER.state_buffer[index];

        if (out_is_dirty != NULL)
        {
            *out_is_dirty = state_is_dirty(current_state) ? 1 : 0;
        }

        return (state_a_is_next(current_state) ? SCREEN_BUFFER.buffer_a : SCREEN_BUFFER.buffer_b)[index];
    }
    else
    {
        return CXL_EMPTY;
    }
}

static inline CIXL_Cxl buffer_pick_next_optimized(const int index)
{
    CIXL_CxlState current_state = SCREEN_BUFFER.state_buffer[index];
    return (state_a_is_next(current_state) ? SCREEN_BUFFER.buffer_a : SCREEN_BUFFER.buffer_b)[index];
}

inline bool buffer_get_cixl_state(const int index, CIXL_Cxl *out_current, CIXL_Cxl *out_next, int *out_is_dirty)
{
    if (index < TERM_AREA)
    {
        CIXL_CxlState current_state = SCREEN_BUFFER.state_buffer[index];
        if (state_a_is_next(current_state))
        {
            *out_current = SCREEN_BUFFER.buffer_b[index];
            *out_next    = SCREEN_BUFFER.buffer_a[index];
        }
        else
        {
            *out_current = SCREEN_BUFFER.buffer_a[index];
            *out_next    = SCREEN_BUFFER.buffer_b[index];
        }

        *out_is_dirty = state_is_dirty(current_state) ? 1 : 0;
        return true;
    }
    else
    {
        return false;
    }
}

static inline bool cxl_equals(const CIXL_Cxl *left, const CIXL_Cxl *right)
{
    if (left == NULL && right == NULL)
    {
        return true;
    }

    if (left != NULL && right == NULL)
    {
        return false;
    }

    if (left == NULL && right != NULL)
    {
        return false;
    }

    return left->char_value == right->char_value && left->fg_color == right->fg_color &&
           left->bg_color == right->bg_color && left->style_opts == right->style_opts;
}

static inline bool cxl_style_equals(const CIXL_Cxl *left, const CIXL_Cxl *right)
{
    return left->fg_color == right->fg_color && left->bg_color == right->bg_color &&
           left->style_opts == right->style_opts;
}

bool cixl_put(const int x, const int y, const CIXL_Cxl cxl)
{
    if (cxl_is_out_of_drawing_area(x, y, 1) == true)
    {
        return false;
    }
    else
    { /* need braces for compatibility */
        int index = cxl_index_for_xy(x, y);

        CIXL_Cxl current_cxl;
        CIXL_Cxl next_cxl;
        int      is_dirty;

        if ((buffer_get_cixl_state(index, &current_cxl, &next_cxl, &is_dirty)) == false)
        {
            return false;
        }

        if (cxl_equals(&next_cxl, &cxl))
        {
            /*the next Cxl to be rendered is the same as the given cxl, so do nothing*/
            return false;
        }

        if (is_dirty == true)
        {
            /*The next Cxl to be drawn is already dirty, so just overwrite it*/
            bool res;
            res = buffer_put_next(index, cxl);

            //When the next Cxl was the same as the previous one, clear the is dirty flag
            if (cxl_equals(&cxl, &current_cxl))
            {
                /*
                  For example: draw 'a', draw 'b' render, draw 'a', draw 'b', render
                   that should not result is redraws, since 'b' was the end result before each render cycle*/
                buffer_clear_is_dirty(index);
            }
            return res;
        }

        if (cxl_equals(&cxl, &current_cxl))
        {
            buffer_clear_is_dirty(index);
            return false;
        }

        return buffer_put_next(index, cxl);
    }
}

bool cixl_puti(const int x, const int y, int32_t *cxl)
{
    return cixl_put(x, y, *cixl_unpack_cxl(cxl));
}

// secure strlen
// \return The length of the string (excluding the terminating 0) limited by 'maxsize'
/*
static inline unsigned int c_strnlen_s(const char *str, size_t maxsize)
{
    const char *s;
    for (s = str; *s && maxsize--; ++s);
    return (unsigned int) (s - str);
}
*/

void
cixl_put_horiz_s(const int start_x, const int y, const char *str, const CIXL_Color fg_color, const CIXL_Color bg_color,
                 const CIXL_StyleOpts decoration)
{
    int        x       = start_x;
    unsigned   maxsize = TERM_WIDTH;
    const char *s;

    //safe strlen and and copy combined
    for (s = str; *s && maxsize--; ++s)
    {
        CIXL_Cxl cxl_to_add;
        cxl_to_add.char_value = *s;
        cxl_to_add.fg_color   = fg_color;
        cxl_to_add.bg_color   = bg_color;
        cxl_to_add.style_opts = decoration;
        cixl_put(x++, y, cxl_to_add);
    }
}

CIXL_Cxl cixl_pick(const int x, const int y)
{
    if (cxl_is_out_of_drawing_area(x, y, 1))
    {
        return CXL_EMPTY;
    }
    else /* always else block needed for compatibility with wcc */
    {
        int index = cxl_index_for_xy(x, y);

        if (state_is_dirty(SCREEN_BUFFER.state_buffer[index]))
        {
            return buffer_pick_next(index, NULL);
        }
        else
        {
            return buffer_pick_current(index);
        }
    }
}

bool cixl_clear(const int x, const int y)
{
    return cixl_put(x, y, CXL_EMPTY);
}

void cixl_clear_area(const int x, const int y, const int w, const int h)
{
    int       tmp_x = x;
    int       tmp_y;
    const int max_x = x + w;
    const int max_y = y + h;

    for (; tmp_x <= max_x; ++tmp_x)
    {
        for (tmp_y = y; tmp_y <= max_y; ++tmp_y)
        {
            cixl_clear(tmp_x, tmp_y);
        }
    }
}

void cixl_reset()
{
    int i = 0;
    while (i < TERM_AREA)
    {
        SCREEN_BUFFER.state_buffer[i] = 0;
        SCREEN_BUFFER.buffer_a[i]     = CXL_EMPTY;
        SCREEN_BUFFER.buffer_b[i]     = CXL_EMPTY;
        ++i;
    }
}

static inline void c_str_terminate(char *src, const unsigned int size)
{
    src[size] = '\0';
}

static CIXL_RenderDevice RENDER_DEVICE;
static bool              INITIALIZED = false;
static char              LINE_BUFFER[TERM_WIDTH + 1];

void cixl_init_render_device(CIXL_RenderDevice *device)
{
    RENDER_DEVICE = *device;
    INITIALIZED   = true;
}

static inline int
render_flush_line_buffer(const int x, const int y, const CIXL_Cxl last_cxl, unsigned int *line_buffer_size)
{
    int draw_call_count = 0;

    //check the line buffer and Draw a single cxl, or a str
    if ((*line_buffer_size) == 1)
    {
        RENDER_DEVICE.f_draw_cxl(x, y, last_cxl);
        (*line_buffer_size) = 0;
        return ++draw_call_count;
    }

    if ((*line_buffer_size) > 1)
    {
        /* //TODO: check for unexpected size condition in calling method
        */
        c_str_terminate(LINE_BUFFER, *line_buffer_size);
        RENDER_DEVICE.f_draw_cxl_s(x, y, &LINE_BUFFER[0], (*line_buffer_size), last_cxl.fg_color, last_cxl.bg_color,
                                   last_cxl.style_opts);
        (*line_buffer_size) = 0;
        return ++draw_call_count;
    }

    return draw_call_count;
}

int cixl_render()
{
    if (SCREEN_BUFFER_IS_DIRTY == false)
    {
        return 0;
    }

    if (!INITIALIZED)
    {
        return -2;
    }
    {
        int draw_call_count = 0;
        int i               = 0;
        int y               = -1;
        int x;

        int          prev_written_idx = -2;
        unsigned int line_buffer_size = 0;
        int          draw_x           = 0;
        int          draw_y           = 0;

        CIXL_Cxl last_cxl = CXL_EMPTY;

        while (i < TERM_AREA)
        {
            x = i % TERM_WIDTH;
            if (x == 0)
            {
                ++y;
            }
            {//:{}(for OpenWatcom compatibility)
                CIXL_CxlState current_state = SCREEN_BUFFER.state_buffer[i];

                bool continuation_on_same_line_has_ended = prev_written_idx != i - 1 && i > 0;

                if (continuation_on_same_line_has_ended ||
                    line_buffer_size == TERM_WIDTH) //not at start:check if continuation on same line has stopped,or EOL
                {
                    draw_call_count += render_flush_line_buffer(draw_x, draw_y, last_cxl, &line_buffer_size);
                }

                /*When the state IsDirty an put cxl in line-buffer to prepare for draw*/
                if (state_is_dirty(current_state))
                {
                    bool is_continuation_on_same_line = prev_written_idx == i - 1 && i > 0;

                    CIXL_Cxl next_cxl_to_draw = buffer_pick_next_optimized(i);

                    //Same line continuation, different styles, flush buffer to a draw call
                    if (is_continuation_on_same_line && !cxl_style_equals(&next_cxl_to_draw, &last_cxl))
                    {
                        draw_call_count += render_flush_line_buffer(draw_x, draw_y, last_cxl, &line_buffer_size);
                    }

                    if (line_buffer_size == 0) // line buffer is empty, remember x and y, where it al began
                    {
                        draw_x = x;
                        draw_y = y;
                    }

                    LINE_BUFFER[line_buffer_size++] = next_cxl_to_draw.char_value;

                    last_cxl = next_cxl_to_draw;//remember this

                    buffer_swap_and_clear_is_dirty(i);//done with this cxl

                    prev_written_idx = i;
                }
            }

            ++i;
        }


        if (line_buffer_size > 0)
        { //flush buffer with remaining cxl s
            draw_call_count += render_flush_line_buffer(draw_x, draw_y, last_cxl, &line_buffer_size);
        }

        SCREEN_BUFFER_IS_DIRTY = false;
        return draw_call_count;
    }
}
