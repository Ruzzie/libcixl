#ifndef LIBCIXL_CIXL_MATH_H
#define LIBCIXL_CIXL_MATH_H

#ifdef __cplusplus
extern "C" {
#endif

inline int cixl_min(int a, int b) {
    return (a > b ) ? b : a;
}

inline int cixl_max(int a, int b)
{
    return (a > b ) ? a : b;
}

#ifdef __cplusplus
} /* End of extern "C" */
#endif

#endif //LIBCIXL_CIXL_MATH_H
