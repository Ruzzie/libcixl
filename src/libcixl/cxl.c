#include "cxl.h"
#ifndef __cplusplus
const CIXL_Cxl CXL_EMPTY = {0, 8, 0, 0};
#endif

int32_t cixl_pack_cxl(const CIXL_Cxl *cxl)
{
    return *(int *) (cxl);
}

CIXL_Cxl *cixl_unpack_cxl(int32_t *cxl_ptr)
{
    return (CIXL_Cxl *) cxl_ptr;
}
