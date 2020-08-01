#ifndef LIBCIXL_CIXL_STDLIB_H
#define LIBCIXL_CIXL_STDLIB_H
#include <stdlib.h>

void* cixl_mem_alloc(size_t count, size_t size)
{
    return calloc(count, size);
}

void cixl_mem_free(void* block)
{
    free(block);
}

#endif //LIBCIXL_CIXL_STDLIB_H
