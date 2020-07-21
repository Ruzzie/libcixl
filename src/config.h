/*! \file
 * \brief Definitions of export prefixes for multiple platforms
 * \author Dorus Verhoeckx
 * \date 2020
 * \copyright Dorus Verhoeckx or https://unlicense.org/ or  https://mit-license.org/
 * document with https://www.doxygen.nl/manual/docblocks.html#cppblock
 * */
#ifndef LIBCIXL_CONFIG_H
#define LIBCIXL_CONFIG_H

/* DLL export */
#ifndef CIXLLIB_API
#ifdef LIBCIXL_STATIC
#define CIXLLIB_API
#elif defined _WIN32 || defined WIN32 || defined __CYGWIN__ || defined __MINGW32__
#ifdef LIBCIXL_EXPORTS
#ifdef __GNUC__
#define CIXLLIB_API __attribute__((dllexport))
#else
#define CIXLLIB_API __declspec(dllexport)
#endif  // __GNUC__
#else
#ifdef __GNUC__
#define CIXLLIB_API __attribute__((dllimport))
#else
#define CIXLLIB_API __declspec(dllimport)
#endif  // __GNUC__
#endif  // LIBCIXL_EXPORTS
#elif __GNUC__ >= 4
#define CIXLLIB_API __attribute__((visibility("default")))
#else
#define CIXLLIB_API
#endif
#endif  // CIXLLIB_API

#ifndef CIXLLIB_CAPI
#ifdef __cplusplus
#define CIXLLIB_CAPI extern "C" CIXLLIB_API
#else
#define CIXLLIB_CAPI CIXLLIB_API
#endif  // __cplusplus
#endif  // CIXLLIB_CAPI


// Private hidden symbols.
#if __GNUC__ >= 4
#define CIXL_PRIVATE __attribute__((visibility("hidden")))
#else
#define CIXL_PRIVATE
#endif  // __GNUC__ >= 4

// Cross platform deprecation.
#ifdef CIXL_IGNORE_DEPRECATED
#define CIXL_DEPRECATED(msg)
#define CIXL_DEPRECATED_NOMESSAGE
#elif defined(__cplusplus) && __cplusplus >= 201402L && !defined(__clang__)
#define CIXL_DEPRECATED(msg) [[deprecated(msg)]]
#define CIXL_DEPRECATED_NOMESSAGE [[deprecated]]
#elif defined(_MSC_VER)
#define CIXL_DEPRECATED(msg) __declspec(deprecated(msg))
#define CIXL_DEPRECATED_NOMESSAGE __declspec(deprecated)
#elif defined(__GNUC__)
#define CIXL_DEPRECATED(msg) __attribute__((deprecated(msg)))
#define CIXL_DEPRECATED_NOMESSAGE __attribute__((deprecated))
#else
#define CIXL_DEPRECATED(msg)
#define CIXL_DEPRECATED_NOMESSAGE
#endif

// Tells GCC the these functions are like printf.
#ifdef __GNUC__
#define CIXLLIB_FORMAT(str_index, first_arg) __attribute__((format(printf, str_index, first_arg)))
#else
#define CIXLLIB_FORMAT(str_index, first_arg)
#endif

#if defined(__cplusplus) && __cplusplus >= 201703L && !defined(__clang__)
#define CIXL_NODISCARD [[nodiscard]]
#elif defined(_MSC_VER)
#define CIXL_NODISCARD
#elif defined(__GNUC__)
#define CIXL_NODISCARD __attribute__((warn_unused_result))
#else
#define CIXL_NODISCARD
#endif

#endif //LIBCIXL_CONFIG_H
