#ifndef LIBCIXL_CIXL_SLEEP_H
#define LIBCIXL_CIXL_SLEEP_H

#ifdef __WATCOMC__
#include <i86.h>
void cixl_sleep_ms(unsigned int milliseconds)
{
    delay(milliseconds);
}
#endif

#ifdef WIN32
#include <Windows.h>
void cixl_sleep_ms(unsigned int milliseconds)
{
    Sleep(milliseconds);
}
#endif

#endif //LIBCIXL_CIXL_SLEEP_H

