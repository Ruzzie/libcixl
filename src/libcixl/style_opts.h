#ifndef LIBCIXL_STYLE_OPTS_H
#define LIBCIXL_STYLE_OPTS_H

#include "std/cixl_stdint.h"
#include "config.h"

typedef uint8_t CIXL_StyleOpts;

//! \brief Represents the cxl character styles, this is a bit-flag, so multiple styles can be combined
typedef enum CIXL_Style
{
    //! \brief  All attributes off
    none = 0,

    //! \brief  As with faint, the color change is a PC (SCO / CGA) invention.
    bold = 1,

    //! \brief  aka Dim (with a saturated color). May be implemented as a light font weight like bold.
    faint = 2,

    //! \brief  Not widely supported. Sometimes treated as inverse or blink.
    italic = 4,

    //! \brief  Style extensions exist for Kitty, VTE, mintty and iTerm2
    underline = 8,

    //! \brief  Invert, Reverse video. swap foreground and background colors, aka invert; inconsistent emulation
    invert = 16,

    //! \brief  aka Strike, characters legible but marked as if for deletion.
    crossed_out = 32,

    //! \brief  Fraktur
    fraktur = 64,

    //! \brief  Double-underline
    double_underline = 128,
    //10 Primary Font, 11-19 Alternative font n

    //! \brief  Overline
    overlined = 255
}               CIXL_Style;

#ifdef __cplusplus
extern "C" {
#endif

CIXL_StyleOpts CIXL_from_style(CIXL_Style style_flags);

CIXL_Style CIXL_to_styleflags(CIXL_StyleOpts style_opts);

#ifdef __cplusplus
} /* End of extern "C" */
#endif
#endif //LIBCIXL_STYLE_OPTS_H
