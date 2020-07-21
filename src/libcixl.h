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

#define TERM_WIDTH 80
#define TERM_HEIGHT 25
#define TERM_AREA (TERM_WIDTH * TERM_HEIGHT)

typedef unsigned char byte;
typedef byte          State;
typedef byte          Color;
typedef byte          FontDecoration;

typedef struct Cixl
{
    char           char_value;
    Color          fg_color;
    Color          bg_color;
    FontDecoration decoration;
}                     Cixl;

#ifdef __cplusplus
const Cixl CIXL_EMPTY{0, 0, 0, 0};
#else
const Cixl CIXL_EMPTY;
#endif

typedef struct RenderDevice
{
    void (*f_draw_cixl)(const int start_x, const int start_y, const Cixl cixl);

    void (*f_draw_cixl_s)(const int start_x, const int start_y, char *str, const int size, const Color fg_color,
                          const Color bg_color, const FontDecoration decoration);
} RenderDevice;

#ifndef __cplusplus
typedef enum
{
    false, true
} bool;
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if defined(WIN32)
# define CIXLLIB_API __declspec(dllexport)
#else
# define CIXLLIB_API
#endif

#ifdef WITH_INTERNALS_VISIBLE

void buffer_swap_and_clear_is_dirty(const int index);

bool buffer_put_current(const int index, const Cixl cixl);

Cixl buffer_pick_current(const int index);

Cixl buffer_pick_next(const int index, int *out_is_dirty);

bool buffer_put_next(const int index, const Cixl cixl);

bool buffer_get_cixl_state(const int index, Cixl *out_current, Cixl *out_next, int *out_is_dirty);

bool cixl_is_out_of_drawing_area(const int x, const int y, const int num_chars);

int cixl_index_for_xy(int x, int y);

#endif

CIXLLIB_API void cixl_init(RenderDevice *device);

CIXLLIB_API bool cixl_put(const int x, const int y, const Cixl cixl);

CIXLLIB_API bool cixl_puti(const int x, const int y, int *cixl);

CIXLLIB_API void cixl_puts(const int start_x, const int y, const char *str, const int size, const Color fg_color,
                           const Color bg_color, const FontDecoration decoration);

CIXLLIB_API Cixl cixl_pick(const int x, const int y);

CIXLLIB_API int cixl_pack(Cixl *cixel);

CIXLLIB_API Cixl *cixl_unpack(int *cixel_ptr);

CIXLLIB_API void cixl_reset();

CIXLLIB_API int cixl_render();

#ifdef __cplusplus
} /* End of extern "C" */
#endif
#endif

#pragma clang diagnostic pop
