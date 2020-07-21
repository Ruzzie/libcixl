#pragma warning (disable : 4068 )
#pragma clang diagnostic push
#pragma ide diagnostic ignored "readability-avoid-const-params-in-decls"

/*! \file
 * \brief Simple Terminal Text library
 * \author Dorus Verhoeckx
 * \date 2020
 * \copyright Dorus Verhoeckx or https://unlicense.org/ or  https://mit-license.org/
 * document with https://www.doxygen.nl/manual/docblocks.html#cppblock
 * */

#ifndef LIBCIXL_H
#define LIBCIXL_H

#include "config.h"

#define TERM_WIDTH 80
#define TERM_HEIGHT 25
#define TERM_AREA (TERM_WIDTH * TERM_HEIGHT)

typedef unsigned char CIXL_byte_t;
typedef CIXL_byte_t   CIXL_Color;
typedef CIXL_byte_t   CIXL_StyleOpts;

typedef struct CIXL_Cxl
{
    char           char_value;
    CIXL_Color     fg_color;
    CIXL_Color     bg_color;
    CIXL_StyleOpts decoration;
}                     CIXL_Cxl;

#ifdef __cplusplus
const CIXL_Cxl CXL_EMPTY{0, 0, 0, 0};
#else
const CIXL_Cxl CXL_EMPTY;
#endif

typedef struct CIXL_RenderDevice
{
    void (*f_draw_cxl)(const int start_x, const int start_y, const CIXL_Cxl cixl);

    void (*f_draw_cxl_s)(const int start_x, const int start_y, char *str, const int size, const CIXL_Color fg_color,
                         const CIXL_Color bg_color, const CIXL_StyleOpts decoration);
} CIXL_RenderDevice;

#ifndef __cplusplus
typedef enum
{
    false, true
} bool;
#endif

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

CIXLLIB_API void cixl_init(CIXL_RenderDevice *device);

CIXLLIB_API bool cixl_put(const int x, const int y, const CIXL_Cxl cxl);

CIXLLIB_API bool cixl_puti(const int x, const int y, int *cxl);

CIXLLIB_API void cixl_puts(const int start_x, const int y, const char *str, const int size, const CIXL_Color fg_color,
                           const CIXL_Color bg_color, const CIXL_StyleOpts decoration);

CIXLLIB_API CIXL_Cxl cixl_pick(const int x, const int y);

CIXLLIB_API int cixl_pack(CIXL_Cxl *cxl);

CIXLLIB_API CIXL_Cxl *cixl_unpack(int *cxl_ptr);

CIXLLIB_API void cixl_reset();

CIXLLIB_API int cixl_render();

#ifdef __cplusplus
} /* End of extern "C" */
#endif
#endif

#pragma clang diagnostic pop
