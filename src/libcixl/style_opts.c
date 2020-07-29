#include "style_opts.h"
CIXL_StyleOpts CIXL_from_style(CIXL_Style style_flags)
{
    return (CIXL_StyleOpts) style_flags;
}

CIXL_Style CIXL_to_styleflags(CIXL_StyleOpts style_opts)
{
    return (CIXL_Style) style_opts;
}