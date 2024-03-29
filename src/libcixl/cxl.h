/*! \file
 * \brief Cxl module.
 * A Cxl is a character pixel, with a foreground, background color and some style_opts options.
 * \author Dorus Verhoeckx
 * \date 2020
 * \copyright Dorus Verhoeckx or https://unlicense.org/ or  https://mit-license.org/
 * */
#ifndef LIBCIXL_CXL_H
#define LIBCIXL_CXL_H

#include "std/cixl_stdint.h"
#include "config.h"
#include "colors.h"
#include "style_opts.h"

typedef struct CIXL_Cxl
{
    char           char_value: 8;
    CIXL_Color     fg_color: 4;
    CIXL_Color     bg_color: 4;
    CIXL_StyleOpts style_opts: 8;
} CIXL_Cxl;

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
const CIXL_Cxl CXL_EMPTY{0, 0, 0, 0};
#else
extern const struct CIXL_Cxl CXL_EMPTY;
#endif

CIXLLIB_API int32_t cixl_pack_cxl(const CIXL_Cxl *cxl);

CIXLLIB_API CIXL_Cxl cixl_unpack_cxl(const int32_t *cxl_ptr);

#ifdef __cplusplus
} /* End of extern "C" */
#endif

#endif //LIBCIXL_CXL_H
