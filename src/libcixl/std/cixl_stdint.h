#ifndef LIBCIXL_CIXL_STDINT_H
#define LIBCIXL_CIXL_STDINT_H
#include <stdint.h>

/*Each compiler is free to choose appropriate size for its own hardware with
restrictions that short and int are atleast 16 bits and longs are atleast 32 bits and size of
short < int < long.*/

typedef signed char         int8_t;
typedef unsigned char       uint8_t;
typedef short               int16_t;
typedef unsigned short      uint16_t;

#endif //LIBCIXL_CIXL_STDINT_H

