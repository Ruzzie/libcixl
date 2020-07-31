#pragma warning (disable : 4068 )
#pragma clang diagnostic push
#pragma ide diagnostic ignored "readability-avoid-const-params-in-decls"

#ifndef LIBCIXL_CONSOLE_H
#define LIBCIXL_CONSOLE_H

#include "std/cixl_stdbool.h"
#include "config.h"

#include "cxl.h"
#include "colors.h"

#define TERM_WIDTH 80
#define TERM_HEIGHT 25
#define TERM_AREA (TERM_WIDTH * TERM_HEIGHT)

typedef struct CIXL_RenderDevice
{
    void (*f_draw_cxl)(const int start_x, const int start_y, const CIXL_Cxl cixl);

    void
    (*f_draw_cxl_s)(const int start_x, const int start_y, char *str, const unsigned int size, const CIXL_Color fg_color,
                    const CIXL_Color bg_color, const CIXL_StyleOpts decoration);
} CIXL_RenderDevice;


#ifdef __cplusplus
extern "C" {
#endif


#ifdef WITH_INTERNALS_VISIBLE

void buffer_swap_and_clear_is_dirty(const int index);

bool buffer_put_current(const int index, const CIXL_Cxl cixl);

CIXL_Cxl buffer_pick_current(const int index);

CIXL_Cxl buffer_pick_next(const int index, int *out_is_dirty);

bool buffer_put_next(const int index, const CIXL_Cxl cixl);

bool buffer_get_cixl_state(const int index, CIXL_Cxl *out_current, CIXL_Cxl *out_next, int *out_is_dirty);

bool cxl_is_out_of_drawing_area(const int x, const int y, const int num_chars);

int cxl_index_for_xy(int x, int y);

#endif

CIXLLIB_API void cixl_init_render_device(CIXL_RenderDevice *device);

CIXLLIB_API bool cixl_put(const int x, const int y, const CIXL_Cxl cxl);

CIXLLIB_API bool cixl_puti(const int x, const int y, int32_t *cxl);

CIXLLIB_API void
cixl_put_horiz_s(const int start_x, const int y, const char *str, const CIXL_Color fg_color, const CIXL_Color bg_color,
                 const CIXL_StyleOpts decoration);

CIXLLIB_API CIXL_Cxl cixl_pick(const int x, const int y);

CIXLLIB_API bool cixl_clear(const int x, const int y);

CIXLLIB_API void cixl_clear_area(const int x, const int y, const int w, const int h);

CIXLLIB_API void cixl_reset();

CIXLLIB_API int cixl_render();

#ifdef __cplusplus
} /* End of extern "C" */
#endif


#endif //LIBCIXL_CONSOLE_H

#pragma clang diagnostic pop
