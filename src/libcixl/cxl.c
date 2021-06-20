#include "cxl.h"

#ifndef __cplusplus
const CIXL_Cxl CXL_EMPTY = {0, 8, 0, 0};
#endif

int32_t cixl_pack_cxl(const CIXL_Cxl *cxl)
{
    int32_t value = (unsigned char) cxl->char_value;
    value |= (cxl->fg_color) << 8;
    value |= (cxl->bg_color) << 12;
    value |=  (((int32_t) cxl->style_opts) << 16);

    return value;
    //return *(int32_t *) (cxl);
}

void cixl_unpack_cxl(const int32_t *cxl_ptr,  CIXL_Cxl *output)
{
    int32_t        int_val = *cxl_ptr;
    const char           cv      = (char) (int_val & 0x0000FF);
    const CIXL_Color     fg      = (uint8_t) ((int_val & 0x000F00) >> 8);
    const CIXL_Color     bg      = (uint8_t) ((int_val & 0x00F000) >> 12);
    const CIXL_StyleOpts st      = (uint8_t) ((int_val & 0xFF0000) >> 16);

    output->char_value = cv;
    output->fg_color = fg;
    output->bg_color = bg;
    output->style_opts = st;

    //return value;
}
