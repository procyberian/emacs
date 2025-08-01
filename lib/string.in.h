/* A GNU-like <string.h>.

   Copyright (C) 1995-1996, 2001-2025 Free Software Foundation, Inc.

   This file is free software: you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License as
   published by the Free Software Foundation; either version 2.1 of the
   License, or (at your option) any later version.

   This file is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

#if __GNUC__ >= 3
@PRAGMA_SYSTEM_HEADER@
#endif
@PRAGMA_COLUMNS@

#if defined _@GUARD_PREFIX@_ALREADY_INCLUDING_STRING_H
/* Special invocation convention:
   - On OS X/NetBSD we have a sequence of nested includes
       <string.h> -> <strings.h> -> "string.h"
     In this situation system _chk variants due to -D_FORTIFY_SOURCE
     might be used after any replacements defined here.  */

#@INCLUDE_NEXT@ @NEXT_STRING_H@

#else
/* Normal invocation convention.  */

#ifndef _@GUARD_PREFIX@_STRING_H

#define _@GUARD_PREFIX@_ALREADY_INCLUDING_STRING_H

/* The include_next requires a split double-inclusion guard.  */
#@INCLUDE_NEXT@ @NEXT_STRING_H@

#undef _@GUARD_PREFIX@_ALREADY_INCLUDING_STRING_H

#ifndef _@GUARD_PREFIX@_STRING_H
#define _@GUARD_PREFIX@_STRING_H

/* This file uses _GL_ATTRIBUTE_DEALLOC, _GL_ATTRIBUTE_MALLOC,
   _GL_ATTRIBUTE_NOTHROW, _GL_ATTRIBUTE_PURE, GNULIB_POSIXCHECK,
   HAVE_RAW_DECL_*.  */
#if !_GL_CONFIG_H_INCLUDED
 #error "Please include config.h first."
#endif

/* NetBSD 5.0 mis-defines NULL.  */
#include <stddef.h>

#if @GNULIB_STRERROR_L@
/* Get locale_t.  */
# include <locale.h>
#endif

/* MirBSD defines mbslen as a macro.  */
#if @GNULIB_MBSLEN@ && defined __MirBSD__
# include <wchar.h>
#endif

/* NetBSD 5.0 declares strsignal in <unistd.h>, not in <string.h>.  */
/* But in any case avoid namespace pollution on glibc systems.  */
#if (@GNULIB_STRSIGNAL@ || defined GNULIB_POSIXCHECK) && defined __NetBSD__ \
    && ! defined __GLIBC__
# include <unistd.h>
#endif

/* AIX 7.2 and Android 13 declare ffsl and ffsll in <strings.h>, not in
   <string.h>.  */
/* But in any case avoid namespace pollution on glibc systems.  */
#if ((@GNULIB_FFSL@ || @GNULIB_FFSLL@ || defined GNULIB_POSIXCHECK) \
     && (defined _AIX || defined __ANDROID__)) \
    && ! defined __GLIBC__
# include <strings.h>
#endif

/* _GL_ATTRIBUTE_DEALLOC (F, I) declares that the function returns pointers
   that can be freed by passing them as the Ith argument to the
   function F.  */
#ifndef _GL_ATTRIBUTE_DEALLOC
# if __GNUC__ >= 11 && !defined __clang__
#  define _GL_ATTRIBUTE_DEALLOC(f, i) __attribute__ ((__malloc__ (f, i)))
# else
#  define _GL_ATTRIBUTE_DEALLOC(f, i)
# endif
#endif

/* _GL_ATTRIBUTE_DEALLOC_FREE declares that the function returns pointers that
   can be freed via 'free'; it can be used only after declaring 'free'.  */
/* Applies to: functions.  Cannot be used on inline functions.  */
#ifndef _GL_ATTRIBUTE_DEALLOC_FREE
# if defined __cplusplus && defined __GNUC__ && !defined __clang__
/* Work around GCC bug <https://gcc.gnu.org/bugzilla/show_bug.cgi?id=108231> */
#  define _GL_ATTRIBUTE_DEALLOC_FREE \
     _GL_ATTRIBUTE_DEALLOC ((void (*) (void *)) free, 1)
# else
#  define _GL_ATTRIBUTE_DEALLOC_FREE \
     _GL_ATTRIBUTE_DEALLOC (free, 1)
# endif
#endif

/* _GL_ATTRIBUTE_MALLOC declares that the function returns a pointer to freshly
   allocated memory.  */
/* Applies to: functions.  */
#ifndef _GL_ATTRIBUTE_MALLOC
# if __GNUC__ >= 3 || defined __clang__
#  define _GL_ATTRIBUTE_MALLOC __attribute__ ((__malloc__))
# else
#  define _GL_ATTRIBUTE_MALLOC
# endif
#endif

/* _GL_ATTRIBUTE_NONNULL_IF_NONZERO (NP, NI) declares that the argument NP
   (a pointer) must not be NULL if the argument NI (an integer) is != 0.  */
/* Applies to: functions.  */
#ifndef _GL_ATTRIBUTE_NONNULL_IF_NONZERO
# if __GNUC__ >= 15 && !defined __clang__
#  define _GL_ATTRIBUTE_NONNULL_IF_NONZERO(np, ni) \
     __attribute__ ((__nonnull_if_nonzero__ (np, ni)))
# else
#  define _GL_ATTRIBUTE_NONNULL_IF_NONZERO(np, ni)
# endif
#endif

/* _GL_ATTRIBUTE_NOTHROW declares that the function does not throw exceptions.
 */
#ifndef _GL_ATTRIBUTE_NOTHROW
# if defined __cplusplus
#  if (__GNUC__ + (__GNUC_MINOR__ >= 8) > 2) || __clang_major__ >= 4
#   if __cplusplus >= 201103L
#    define _GL_ATTRIBUTE_NOTHROW noexcept (true)
#   else
#    define _GL_ATTRIBUTE_NOTHROW throw ()
#   endif
#  else
#   define _GL_ATTRIBUTE_NOTHROW
#  endif
# else
#  if (__GNUC__ + (__GNUC_MINOR__ >= 3) > 3) || defined __clang__
#   define _GL_ATTRIBUTE_NOTHROW __attribute__ ((__nothrow__))
#  else
#   define _GL_ATTRIBUTE_NOTHROW
#  endif
# endif
#endif

/* The __attribute__ feature is available in gcc versions 2.5 and later.
   The attribute __pure__ was added in gcc 2.96.  */
#ifndef _GL_ATTRIBUTE_PURE
# if __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 96) || defined __clang__
#  define _GL_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define _GL_ATTRIBUTE_PURE /* empty */
# endif
#endif

/* The definitions of _GL_FUNCDECL_RPL etc. are copied here.  */

/* The definition of _GL_ARG_NONNULL is copied here.  */

/* The definition of _GL_WARN_ON_USE is copied here.  */


/* Make _GL_ATTRIBUTE_DEALLOC_FREE work, even though <stdlib.h> may not have
   been included yet.  */
#if @GNULIB_FREE_POSIX@
# if (@REPLACE_FREE@ && !defined free \
      && !(defined __cplusplus && defined GNULIB_NAMESPACE))
/* We can't do '#define free rpl_free' here.  */
#  if defined __cplusplus && (__GLIBC__ + (__GLIBC_MINOR__ >= 14) > 2)
_GL_EXTERN_C void rpl_free (void *) _GL_ATTRIBUTE_NOTHROW;
#  else
_GL_EXTERN_C void rpl_free (void *);
#  endif
#  undef _GL_ATTRIBUTE_DEALLOC_FREE
#  define _GL_ATTRIBUTE_DEALLOC_FREE _GL_ATTRIBUTE_DEALLOC (rpl_free, 1)
# else
#  if defined _MSC_VER && !defined free
_GL_EXTERN_C
#   if defined _DLL
     __declspec (dllimport)
#   endif
     void __cdecl free (void *);
#  else
#   if defined __cplusplus && (__GLIBC__ + (__GLIBC_MINOR__ >= 14) > 2)
_GL_EXTERN_C void free (void *) _GL_ATTRIBUTE_NOTHROW;
#   else
_GL_EXTERN_C void free (void *);
#   endif
#  endif
# endif
#else
# if defined _MSC_VER && !defined free
_GL_EXTERN_C
#   if defined _DLL
     __declspec (dllimport)
#   endif
     void __cdecl free (void *);
# else
#  if defined __cplusplus && (__GLIBC__ + (__GLIBC_MINOR__ >= 14) > 2)
_GL_EXTERN_C void free (void *) _GL_ATTRIBUTE_NOTHROW;
#  else
_GL_EXTERN_C void free (void *);
#  endif
# endif
#endif


/* Declarations for ISO C N3322.  */
#if defined __GNUC__ && __GNUC__ >= 15 && !defined __clang__
# ifndef memcpy
_GL_EXTERN_C void *memcpy (void *__dest, const void *__src, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (2, 3);
# endif
# ifndef memccpy
_GL_EXTERN_C void *memccpy (void *__dest, const void *__src, int __c, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 4)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (2, 4);
# endif
# ifndef memmove
_GL_EXTERN_C void *memmove (void *__dest, const void *__src, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (2, 3);
# endif
# ifndef strncpy
_GL_EXTERN_C char *strncpy (char *__dest, const char *__src, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (2, 3);
# endif
# ifndef strndup
_GL_EXTERN_C char *strndup (const char *__s, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 2);
# endif
# ifndef strncat
_GL_EXTERN_C char *strncat (char *__dest, const char *__src, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ARG_NONNULL ((1)) _GL_ATTRIBUTE_NONNULL_IF_NONZERO (2, 3);
# endif
# ifndef memcmp
_GL_EXTERN_C int memcmp (const void *__s1, const void *__s2, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (2, 3);
# endif
# ifndef strncmp
_GL_EXTERN_C int strncmp (const char *__s1, const char *__s2, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (2, 3);
# endif
# if !defined memchr && !defined __cplusplus
_GL_EXTERN_C void *memchr (const void *__s, int __c, size_t __n)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3);
_GL_EXTERN_C void *memrchr (const void *__s, int __c, size_t __n)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3);
# endif
# ifndef memset
_GL_EXTERN_C void *memset (void *__s, int __c, size_t __n)
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
  _GL_ATTRIBUTE_NOTHROW
#  endif
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3);
# endif
# ifndef memset_explicit
_GL_EXTERN_C void *memset_explicit (void *__s, int __c, size_t __n)
  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3);
# endif
#endif


/* Clear a block of memory.  The compiler will not delete a call to
   this function, even if the block is dead after the call.  */
#if @GNULIB_EXPLICIT_BZERO@
# if ! @HAVE_EXPLICIT_BZERO@
_GL_FUNCDECL_SYS (explicit_bzero, void,
                  (void *__dest, size_t __n), _GL_ARG_NONNULL ((1)));
# endif
_GL_CXXALIAS_SYS (explicit_bzero, void, (void *__dest, size_t __n));
_GL_CXXALIASWARN (explicit_bzero);
#elif defined GNULIB_POSIXCHECK
# undef explicit_bzero
# if HAVE_RAW_DECL_EXPLICIT_BZERO
_GL_WARN_ON_USE (explicit_bzero, "explicit_bzero is unportable - "
                 "use gnulib module explicit_bzero for portability");
# endif
#endif


/* Find the index of the least-significant set bit.  */
#if @GNULIB_FFSL@
# if !@HAVE_FFSL@
_GL_FUNCDECL_SYS (ffsl, int, (long int i), );
# endif
_GL_CXXALIAS_SYS (ffsl, int, (long int i));
_GL_CXXALIASWARN (ffsl);
#elif defined GNULIB_POSIXCHECK
# undef ffsl
# if HAVE_RAW_DECL_FFSL
_GL_WARN_ON_USE (ffsl, "ffsl is not portable - use the ffsl module");
# endif
#endif


/* Find the index of the least-significant set bit.  */
#if @GNULIB_FFSLL@
# if @REPLACE_FFSLL@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define ffsll rpl_ffsll
#  endif
_GL_FUNCDECL_RPL (ffsll, int, (long long int i), );
_GL_CXXALIAS_RPL (ffsll, int, (long long int i));
# else
#  if !@HAVE_FFSLL@
_GL_FUNCDECL_SYS (ffsll, int, (long long int i), );
#  endif
_GL_CXXALIAS_SYS (ffsll, int, (long long int i));
# endif
_GL_CXXALIASWARN (ffsll);
#elif defined GNULIB_POSIXCHECK
# undef ffsll
# if HAVE_RAW_DECL_FFSLL
_GL_WARN_ON_USE (ffsll, "ffsll is not portable - use the ffsll module");
# endif
#endif


#if @GNULIB_MDA_MEMCCPY@
/* On native Windows, map 'memccpy' to '_memccpy', so that -loldnames is not
   required.  In C++ with GNULIB_NAMESPACE, avoid differences between
   platforms by defining GNULIB_NAMESPACE::memccpy always.  */
# if defined _WIN32 && !defined __CYGWIN__
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef memccpy
#   define memccpy _memccpy
#  endif
_GL_CXXALIAS_MDA (memccpy, void *,
                  (void *dest, const void *src, int c, size_t n));
# else
_GL_CXXALIAS_SYS (memccpy, void *,
                  (void *dest, const void *src, int c, size_t n));
# endif
_GL_CXXALIASWARN (memccpy);
#endif


/* Return the first instance of C within N bytes of S, or NULL.  */
#if @GNULIB_MEMCHR@
# if @REPLACE_MEMCHR@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef memchr
#   define memchr rpl_memchr
#  endif
_GL_FUNCDECL_RPL (memchr, void *, (void const *__s, int __c, size_t __n),
                                  _GL_ATTRIBUTE_PURE
                                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3));
_GL_CXXALIAS_RPL (memchr, void *, (void const *__s, int __c, size_t __n));
# else
  /* On some systems, this function is defined as an overloaded function:
       extern "C" { const void * std::memchr (const void *, int, size_t); }
       extern "C++" { void * std::memchr (void *, int, size_t); }  */
_GL_CXXALIAS_SYS_CAST2 (memchr,
                        void *, (void const *__s, int __c, size_t __n),
                        void const *, (void const *__s, int __c, size_t __n));
# endif
# if ((__GLIBC__ == 2 && __GLIBC_MINOR__ >= 10) && !defined __UCLIBC__) \
     && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4) \
         || defined __clang__)
_GL_CXXALIASWARN1 (memchr, void *,
                   (void *__s, int __c, size_t __n)
                   _GL_ATTRIBUTE_NOTHROW);
_GL_CXXALIASWARN1 (memchr, void const *,
                   (void const *__s, int __c, size_t __n)
                   _GL_ATTRIBUTE_NOTHROW);
# elif __GLIBC__ >= 2
_GL_CXXALIASWARN (memchr);
# endif
#elif defined GNULIB_POSIXCHECK
# undef memchr
/* Assume memchr is always declared.  */
_GL_WARN_ON_USE (memchr, "memchr has platform-specific bugs - "
                 "use gnulib module memchr for portability" );
#endif

/* Return the first occurrence of NEEDLE in HAYSTACK.  */
#if @GNULIB_MEMMEM@
# if @REPLACE_MEMMEM@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define memmem rpl_memmem
#  endif
_GL_FUNCDECL_RPL (memmem, void *,
                  (void const *__haystack, size_t __haystack_len,
                   void const *__needle, size_t __needle_len),
                  _GL_ATTRIBUTE_PURE
                  _GL_ARG_NONNULL ((1, 3)));
_GL_CXXALIAS_RPL (memmem, void *,
                  (void const *__haystack, size_t __haystack_len,
                   void const *__needle, size_t __needle_len));
# else
#  if ! @HAVE_DECL_MEMMEM@
_GL_FUNCDECL_SYS (memmem, void *,
                  (void const *__haystack, size_t __haystack_len,
                   void const *__needle, size_t __needle_len),
                  _GL_ATTRIBUTE_PURE
                  _GL_ARG_NONNULL ((1, 3)));
#  endif
_GL_CXXALIAS_SYS (memmem, void *,
                  (void const *__haystack, size_t __haystack_len,
                   void const *__needle, size_t __needle_len));
# endif
_GL_CXXALIASWARN (memmem);
#elif defined GNULIB_POSIXCHECK
# undef memmem
# if HAVE_RAW_DECL_MEMMEM
_GL_WARN_ON_USE (memmem, "memmem is unportable and often quadratic - "
                 "use gnulib module memmem-simple for portability, "
                 "and module memmem for speed" );
# endif
#endif

/* Copy N bytes of SRC to DEST, return pointer to bytes after the
   last written byte.  */
#if @GNULIB_MEMPCPY@
# if @REPLACE_MEMPCPY@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef mempcpy
#   define mempcpy rpl_mempcpy
#  endif
_GL_FUNCDECL_RPL (mempcpy, void *,
                  (void *restrict __dest, void const *restrict __src,
                   size_t __n),
                  _GL_ARG_NONNULL ((1, 2)));
_GL_CXXALIAS_RPL (mempcpy, void *,
                  (void *restrict __dest, void const *restrict __src,
                   size_t __n));
# else
#  if !@HAVE_MEMPCPY@
_GL_FUNCDECL_SYS (mempcpy, void *,
                  (void *restrict __dest, void const *restrict __src,
                   size_t __n),
                  _GL_ARG_NONNULL ((1, 2)));
#  endif
_GL_CXXALIAS_SYS (mempcpy, void *,
                  (void *restrict __dest, void const *restrict __src,
                   size_t __n));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (mempcpy);
# endif
#elif defined GNULIB_POSIXCHECK
# undef mempcpy
# if HAVE_RAW_DECL_MEMPCPY
_GL_WARN_ON_USE (mempcpy, "mempcpy is unportable - "
                 "use gnulib module mempcpy for portability");
# endif
#endif

/* Search backwards through a block for a byte (specified as an int).  */
#if @GNULIB_MEMRCHR@
# if ! @HAVE_DECL_MEMRCHR@
_GL_FUNCDECL_SYS (memrchr, void *, (void const *, int, size_t),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3));
# endif
  /* On some systems, this function is defined as an overloaded function:
       extern "C++" { const void * std::memrchr (const void *, int, size_t); }
       extern "C++" { void * std::memrchr (void *, int, size_t); }  */
_GL_CXXALIAS_SYS_CAST2 (memrchr,
                        void *, (void const *, int, size_t),
                        void const *, (void const *, int, size_t));
# if ((__GLIBC__ == 2 && __GLIBC_MINOR__ >= 10) && !defined __UCLIBC__) \
     && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4) \
         || defined __clang__)
_GL_CXXALIASWARN1 (memrchr, void *,
                   (void *, int, size_t)
                   _GL_ATTRIBUTE_NOTHROW);
_GL_CXXALIASWARN1 (memrchr, void const *,
                   (void const *, int, size_t)
                   _GL_ATTRIBUTE_NOTHROW);
# elif __GLIBC__ >= 2
_GL_CXXALIASWARN (memrchr);
# endif
#elif defined GNULIB_POSIXCHECK
# undef memrchr
# if HAVE_RAW_DECL_MEMRCHR
_GL_WARN_ON_USE (memrchr, "memrchr is unportable - "
                 "use gnulib module memrchr for portability");
# endif
#endif

/* Overwrite a block of memory.  The compiler will not optimize
   effects away, even if the block is dead after the call.  */
#if @GNULIB_MEMSET_EXPLICIT@
# if @REPLACE_MEMSET_EXPLICIT@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef memset_explicit
#   define memset_explicit rpl_memset_explicit
#  endif
_GL_FUNCDECL_RPL (memset_explicit, void *,
                  (void *__dest, int __c, size_t __n),
                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3));
_GL_CXXALIAS_RPL (memset_explicit, void *, (void *__dest, int __c, size_t __n));
# else
#  if !@HAVE_MEMSET_EXPLICIT@
_GL_FUNCDECL_SYS (memset_explicit, void *,
                  (void *__dest, int __c, size_t __n),
                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 3));
#  endif
_GL_CXXALIAS_SYS (memset_explicit, void *, (void *__dest, int __c, size_t __n));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (memset_explicit);
# endif
#elif defined GNULIB_POSIXCHECK
# undef memset_explicit
# if HAVE_RAW_DECL_MEMSET_EXPLICIT
_GL_WARN_ON_USE (memset_explicit, "memset_explicit is unportable - "
                 "use gnulib module memset_explicit for portability");
# endif
#endif

/* Find the first occurrence of C in S.  More efficient than
   memchr(S,C,N), at the expense of undefined behavior if C does not
   occur within N bytes.  */
#if @GNULIB_RAWMEMCHR@
# if ! @HAVE_RAWMEMCHR@
_GL_FUNCDECL_SYS (rawmemchr, void *, (void const *__s, int __c_in),
                                     _GL_ATTRIBUTE_PURE
                                     _GL_ARG_NONNULL ((1)));
# endif
  /* On some systems, this function is defined as an overloaded function:
       extern "C++" { const void * std::rawmemchr (const void *, int); }
       extern "C++" { void * std::rawmemchr (void *, int); }  */
_GL_CXXALIAS_SYS_CAST2 (rawmemchr,
                        void *, (void const *__s, int __c_in),
                        void const *, (void const *__s, int __c_in));
# if ((__GLIBC__ == 2 && __GLIBC_MINOR__ >= 10) && !defined __UCLIBC__) \
     && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4) \
         || defined __clang__)
_GL_CXXALIASWARN1 (rawmemchr, void *,
                   (void *__s, int __c_in)
                   _GL_ATTRIBUTE_NOTHROW);
_GL_CXXALIASWARN1 (rawmemchr, void const *,
                   (void const *__s, int __c_in)
                   _GL_ATTRIBUTE_NOTHROW);
# else
_GL_CXXALIASWARN (rawmemchr);
# endif
#elif defined GNULIB_POSIXCHECK
# undef rawmemchr
# if HAVE_RAW_DECL_RAWMEMCHR
_GL_WARN_ON_USE (rawmemchr, "rawmemchr is unportable - "
                 "use gnulib module rawmemchr for portability");
# endif
#endif

/* Copy SRC to DST, returning the address of the terminating '\0' in DST.  */
#if @GNULIB_STPCPY@
# if @REPLACE_STPCPY@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef stpcpy
#   define stpcpy rpl_stpcpy
#  endif
_GL_FUNCDECL_RPL (stpcpy, char *,
                  (char *restrict __dst, char const *restrict __src),
                  _GL_ARG_NONNULL ((1, 2)));
_GL_CXXALIAS_RPL (stpcpy, char *,
                  (char *restrict __dst, char const *restrict __src));
# else
#  if !@HAVE_STPCPY@
_GL_FUNCDECL_SYS (stpcpy, char *,
                  (char *restrict __dst, char const *restrict __src),
                  _GL_ARG_NONNULL ((1, 2)));
#  endif
_GL_CXXALIAS_SYS (stpcpy, char *,
                  (char *restrict __dst, char const *restrict __src));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (stpcpy);
# endif
#elif defined GNULIB_POSIXCHECK
# undef stpcpy
# if HAVE_RAW_DECL_STPCPY
_GL_WARN_ON_USE (stpcpy, "stpcpy is unportable - "
                 "use gnulib module stpcpy for portability");
# endif
#endif

/* Copy no more than N bytes of SRC to DST, returning a pointer past the
   last non-NUL byte written into DST.  */
#if @GNULIB_STPNCPY@
# if @REPLACE_STPNCPY@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef stpncpy
#   define stpncpy rpl_stpncpy
#  endif
_GL_FUNCDECL_RPL (stpncpy, char *,
                  (char *restrict __dst, char const *restrict __src,
                   size_t __n),
                  _GL_ARG_NONNULL ((1, 2)));
_GL_CXXALIAS_RPL (stpncpy, char *,
                  (char *restrict __dst, char const *restrict __src,
                   size_t __n));
# else
#  if ! @HAVE_STPNCPY@
_GL_FUNCDECL_SYS (stpncpy, char *,
                  (char *restrict __dst, char const *restrict __src,
                   size_t __n),
                  _GL_ARG_NONNULL ((1, 2)));
#  endif
_GL_CXXALIAS_SYS (stpncpy, char *,
                  (char *restrict __dst, char const *restrict __src,
                   size_t __n));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (stpncpy);
# endif
#elif defined GNULIB_POSIXCHECK
# undef stpncpy
# if HAVE_RAW_DECL_STPNCPY
_GL_WARN_ON_USE (stpncpy, "stpncpy is unportable - "
                 "use gnulib module stpncpy for portability");
# endif
#endif

#if defined GNULIB_POSIXCHECK
/* strchr() does not work with multibyte strings if the locale encoding is
   GB18030 and the character to be searched is a digit.  */
# undef strchr
/* Assume strchr is always declared.  */
_GL_WARN_ON_USE_CXX (strchr,
                     const char *, char *, (const char *, int),
                     "strchr cannot work correctly on character strings "
                     "in some multibyte locales - "
                     "use mbschr if you care about internationalization");
#endif

/* Find the first occurrence of C in S or the final NUL byte.  */
#if @GNULIB_STRCHRNUL@
# if @REPLACE_STRCHRNUL@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define strchrnul rpl_strchrnul
#  endif
_GL_FUNCDECL_RPL (strchrnul, char *, (const char *__s, int __c_in),
                                     _GL_ATTRIBUTE_PURE
                                     _GL_ARG_NONNULL ((1)));
_GL_CXXALIAS_RPL (strchrnul, char *,
                  (const char *str, int ch));
# else
#  if ! @HAVE_STRCHRNUL@
_GL_FUNCDECL_SYS (strchrnul, char *, (char const *__s, int __c_in),
                                     _GL_ATTRIBUTE_PURE
                                     _GL_ARG_NONNULL ((1)));
#  endif
  /* On some systems, this function is defined as an overloaded function:
       extern "C++" { const char * std::strchrnul (const char *, int); }
       extern "C++" { char * std::strchrnul (char *, int); }  */
_GL_CXXALIAS_SYS_CAST2 (strchrnul,
                        char *, (char const *__s, int __c_in),
                        char const *, (char const *__s, int __c_in));
# endif
# if ((__GLIBC__ == 2 && __GLIBC_MINOR__ >= 10) && !defined __UCLIBC__) \
     && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4) \
         || defined __clang__)
_GL_CXXALIASWARN1 (strchrnul, char *,
                   (char *__s, int __c_in)
                   _GL_ATTRIBUTE_NOTHROW);
_GL_CXXALIASWARN1 (strchrnul, char const *,
                   (char const *__s, int __c_in)
                   _GL_ATTRIBUTE_NOTHROW);
# elif __GLIBC__ >= 2
_GL_CXXALIASWARN (strchrnul);
# endif
#elif defined GNULIB_POSIXCHECK
# undef strchrnul
# if HAVE_RAW_DECL_STRCHRNUL
_GL_WARN_ON_USE (strchrnul, "strchrnul is unportable - "
                 "use gnulib module strchrnul for portability");
# endif
#endif

/* Duplicate S, returning an identical malloc'd string.  */
#if @GNULIB_STRDUP@
# if @REPLACE_STRDUP@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strdup
#   define strdup rpl_strdup
#  endif
_GL_FUNCDECL_RPL (strdup, char *,
                  (char const *__s),
                  _GL_ARG_NONNULL ((1))
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE);
_GL_CXXALIAS_RPL (strdup, char *, (char const *__s));
# elif defined _WIN32 && !defined __CYGWIN__
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strdup
#   define strdup _strdup
#  endif
_GL_CXXALIAS_MDA (strdup, char *, (char const *__s));
# else
#  if defined __cplusplus && defined GNULIB_NAMESPACE && defined strdup
    /* strdup exists as a function and as a macro.  Get rid of the macro.  */
#   undef strdup
#  endif
#  if (!@HAVE_DECL_STRDUP@ || (__GNUC__ >= 11 && !defined __clang__)) \
      && !defined strdup
#   if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
_GL_FUNCDECL_SYS (strdup, char *,
                  (char const *__s),
                  _GL_ARG_NONNULL ((1))
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE)
                  _GL_ATTRIBUTE_NOTHROW;
#   else
_GL_FUNCDECL_SYS (strdup, char *,
                  (char const *__s),
                  _GL_ARG_NONNULL ((1))
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE);
#   endif
#  endif
_GL_CXXALIAS_SYS (strdup, char *, (char const *__s));
# endif
_GL_CXXALIASWARN (strdup);
#else
# if (__GNUC__ >= 11 && !defined __clang__) && !defined strdup
/* For -Wmismatched-dealloc: Associate strdup with free or rpl_free.  */
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
_GL_FUNCDECL_SYS (strdup, char *,
                  (char const *__s),
                  _GL_ARG_NONNULL ((1))
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE)
                  _GL_ATTRIBUTE_NOTHROW;
#  else
_GL_FUNCDECL_SYS (strdup, char *,
                  (char const *__s),
                  _GL_ARG_NONNULL ((1))
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE);
#  endif
# endif
# if defined GNULIB_POSIXCHECK
#  undef strdup
#  if HAVE_RAW_DECL_STRDUP
_GL_WARN_ON_USE (strdup, "strdup is unportable - "
                 "use gnulib module strdup for portability");
#  endif
# elif @GNULIB_MDA_STRDUP@
/* On native Windows, map 'creat' to '_creat', so that -loldnames is not
   required.  In C++ with GNULIB_NAMESPACE, avoid differences between
   platforms by defining GNULIB_NAMESPACE::strdup always.  */
#  if defined _WIN32 && !defined __CYGWIN__
#   if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#    undef strdup
#    define strdup _strdup
#   endif
_GL_CXXALIAS_MDA (strdup, char *, (char const *__s));
#  else
#   if defined __cplusplus && defined GNULIB_NAMESPACE && defined strdup
#    undef strdup
#   endif
_GL_CXXALIAS_SYS (strdup, char *, (char const *__s));
#  endif
_GL_CXXALIASWARN (strdup);
# endif
#endif

/* Append no more than N characters from SRC onto DEST.  */
#if @GNULIB_STRNCAT@
# if @REPLACE_STRNCAT@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strncat
#   define strncat rpl_strncat
#  endif
_GL_FUNCDECL_RPL (strncat, char *,
                  (char *restrict dest, const char *restrict src, size_t n),
                  _GL_ARG_NONNULL ((1))
                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (2, 3));
_GL_CXXALIAS_RPL (strncat, char *,
                  (char *restrict dest, const char *restrict src, size_t n));
# else
_GL_CXXALIAS_SYS (strncat, char *,
                  (char *restrict dest, const char *restrict src, size_t n));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (strncat);
# endif
#elif defined GNULIB_POSIXCHECK
# undef strncat
# if HAVE_RAW_DECL_STRNCAT
_GL_WARN_ON_USE (strncat, "strncat is unportable - "
                 "use gnulib module strncat for portability");
# endif
#endif

/* Return a newly allocated copy of at most N bytes of STRING.  */
#if @GNULIB_STRNDUP@
# if @REPLACE_STRNDUP@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strndup
#   define strndup rpl_strndup
#  endif
_GL_FUNCDECL_RPL (strndup, char *,
                  (char const *__s, size_t __n),
                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 2)
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE);
_GL_CXXALIAS_RPL (strndup, char *, (char const *__s, size_t __n));
# else
#  if !@HAVE_DECL_STRNDUP@ \
      || ((__GNUC__ >= 11 && !defined __clang__) && !defined strndup)
#   if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
_GL_FUNCDECL_SYS (strndup, char *,
                  (char const *__s, size_t __n),
                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 2)
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE)
                  _GL_ATTRIBUTE_NOTHROW;
#   else
_GL_FUNCDECL_SYS (strndup, char *,
                  (char const *__s, size_t __n),
                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 2)
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE);
#   endif
#  endif
_GL_CXXALIAS_SYS (strndup, char *, (char const *__s, size_t __n));
# endif
_GL_CXXALIASWARN (strndup);
#else
# if (__GNUC__ >= 11 && !defined __clang__) && !defined strndup
/* For -Wmismatched-dealloc: Associate strndup with free or rpl_free.  */
#  if __GLIBC__ + (__GLIBC_MINOR__ >= 2) > 2
_GL_FUNCDECL_SYS (strndup, char *,
                  (char const *__s, size_t __n),
                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 2)
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE)
                  _GL_ATTRIBUTE_NOTHROW;
#  else
_GL_FUNCDECL_SYS (strndup, char *,
                  (char const *__s, size_t __n),
                  _GL_ATTRIBUTE_NONNULL_IF_NONZERO (1, 2)
                  _GL_ATTRIBUTE_MALLOC _GL_ATTRIBUTE_DEALLOC_FREE);
#  endif
# endif
# if defined GNULIB_POSIXCHECK
#  undef strndup
#  if HAVE_RAW_DECL_STRNDUP
_GL_WARN_ON_USE (strndup, "strndup is unportable - "
                 "use gnulib module strndup for portability");
#  endif
# endif
#endif

/* Find the length (number of bytes) of STRING, but scan at most
   MAXLEN bytes.  If no '\0' terminator is found in that many bytes,
   return MAXLEN.  */
#if @GNULIB_STRNLEN@
# if @REPLACE_STRNLEN@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strnlen
#   define strnlen rpl_strnlen
#  endif
_GL_FUNCDECL_RPL (strnlen, size_t, (char const *__s, size_t __maxlen),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1)));
_GL_CXXALIAS_RPL (strnlen, size_t, (char const *__s, size_t __maxlen));
# else
#  if ! @HAVE_DECL_STRNLEN@
_GL_FUNCDECL_SYS (strnlen, size_t, (char const *__s, size_t __maxlen),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1)));
#  endif
_GL_CXXALIAS_SYS (strnlen, size_t, (char const *__s, size_t __maxlen));
# endif
_GL_CXXALIASWARN (strnlen);
#elif defined GNULIB_POSIXCHECK
# undef strnlen
# if HAVE_RAW_DECL_STRNLEN
_GL_WARN_ON_USE (strnlen, "strnlen is unportable - "
                 "use gnulib module strnlen for portability");
# endif
#endif

#if defined GNULIB_POSIXCHECK
/* strcspn() assumes the second argument is a list of single-byte characters.
   Even in this simple case, it does not work with multibyte strings if the
   locale encoding is GB18030 and one of the characters to be searched is a
   digit.  */
# undef strcspn
/* Assume strcspn is always declared.  */
_GL_WARN_ON_USE (strcspn, "strcspn cannot work correctly on character strings "
                 "in multibyte locales - "
                 "use mbscspn if you care about internationalization");
#endif

/* Find the first occurrence in S of any character in ACCEPT.  */
#if @GNULIB_STRPBRK@
# if ! @HAVE_STRPBRK@
_GL_FUNCDECL_SYS (strpbrk, char *, (char const *__s, char const *__accept),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1, 2)));
# endif
  /* On some systems, this function is defined as an overloaded function:
       extern "C" { const char * strpbrk (const char *, const char *); }
       extern "C++" { char * strpbrk (char *, const char *); }  */
_GL_CXXALIAS_SYS_CAST2 (strpbrk,
                        char *, (char const *__s, char const *__accept),
                        const char *, (char const *__s, char const *__accept));
# if ((__GLIBC__ == 2 && __GLIBC_MINOR__ >= 10) && !defined __UCLIBC__) \
     && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4) \
         || defined __clang__)
_GL_CXXALIASWARN1 (strpbrk, char *,
                   (char *__s, char const *__accept)
                   _GL_ATTRIBUTE_NOTHROW);
_GL_CXXALIASWARN1 (strpbrk, char const *,
                   (char const *__s, char const *__accept)
                   _GL_ATTRIBUTE_NOTHROW);
# elif __GLIBC__ >= 2
_GL_CXXALIASWARN (strpbrk);
# endif
# if defined GNULIB_POSIXCHECK
/* strpbrk() assumes the second argument is a list of single-byte characters.
   Even in this simple case, it does not work with multibyte strings if the
   locale encoding is GB18030 and one of the characters to be searched is a
   digit.  */
#  undef strpbrk
_GL_WARN_ON_USE_CXX (strpbrk,
                     const char *, char *, (const char *, const char *),
                     "strpbrk cannot work correctly on character strings "
                     "in multibyte locales - "
                     "use mbspbrk if you care about internationalization");
# endif
#elif defined GNULIB_POSIXCHECK
# undef strpbrk
# if HAVE_RAW_DECL_STRPBRK
_GL_WARN_ON_USE_CXX (strpbrk,
                     const char *, char *, (const char *, const char *),
                     "strpbrk is unportable - "
                     "use gnulib module strpbrk for portability");
# endif
#endif

#if defined GNULIB_POSIXCHECK
/* strspn() assumes the second argument is a list of single-byte characters.
   Even in this simple case, it cannot work with multibyte strings.  */
# undef strspn
/* Assume strspn is always declared.  */
_GL_WARN_ON_USE (strspn, "strspn cannot work correctly on character strings "
                 "in multibyte locales - "
                 "use mbsspn if you care about internationalization");
#endif

#if defined GNULIB_POSIXCHECK
/* strrchr() does not work with multibyte strings if the locale encoding is
   GB18030 and the character to be searched is a digit.  */
# undef strrchr
/* Assume strrchr is always declared.  */
_GL_WARN_ON_USE_CXX (strrchr,
                     const char *, char *, (const char *, int),
                     "strrchr cannot work correctly on character strings "
                     "in some multibyte locales - "
                     "use mbsrchr if you care about internationalization");
#endif

/* Search the next delimiter (char listed in DELIM) starting at *STRINGP.
   If one is found, overwrite it with a NUL, and advance *STRINGP
   to point to the next char after it.  Otherwise, set *STRINGP to NULL.
   If *STRINGP was already NULL, nothing happens.
   Return the old value of *STRINGP.

   This is a variant of strtok() that is multithread-safe and supports
   empty fields.

   Caveat: It modifies the original string.
   Caveat: These functions cannot be used on constant strings.
   Caveat: The identity of the delimiting character is lost.
   Caveat: It doesn't work with multibyte strings unless all of the delimiter
           characters are ASCII characters < 0x30.

   See also strtok_r().  */
#if @GNULIB_STRSEP@
# if ! @HAVE_STRSEP@
_GL_FUNCDECL_SYS (strsep, char *,
                  (char **restrict __stringp, char const *restrict __delim),
                  _GL_ARG_NONNULL ((1, 2)));
# endif
_GL_CXXALIAS_SYS (strsep, char *,
                  (char **restrict __stringp, char const *restrict __delim));
_GL_CXXALIASWARN (strsep);
# if defined GNULIB_POSIXCHECK
#  undef strsep
_GL_WARN_ON_USE (strsep, "strsep cannot work correctly on character strings "
                 "in multibyte locales - "
                 "use mbssep if you care about internationalization");
# endif
#elif defined GNULIB_POSIXCHECK
# undef strsep
# if HAVE_RAW_DECL_STRSEP
_GL_WARN_ON_USE (strsep, "strsep is unportable - "
                 "use gnulib module strsep for portability");
# endif
#endif

#if @GNULIB_STRSTR@
# if @REPLACE_STRSTR@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define strstr rpl_strstr
#  endif
_GL_FUNCDECL_RPL (strstr, char *, (const char *haystack, const char *needle),
                                  _GL_ATTRIBUTE_PURE
                                  _GL_ARG_NONNULL ((1, 2)));
_GL_CXXALIAS_RPL (strstr, char *, (const char *haystack, const char *needle));
# else
  /* On some systems, this function is defined as an overloaded function:
       extern "C++" { const char * strstr (const char *, const char *); }
       extern "C++" { char * strstr (char *, const char *); }  */
_GL_CXXALIAS_SYS_CAST2 (strstr,
                        char *, (const char *haystack, const char *needle),
                        const char *, (const char *haystack, const char *needle));
# endif
# if ((__GLIBC__ == 2 && __GLIBC_MINOR__ >= 10) && !defined __UCLIBC__) \
     && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4) \
         || defined __clang__)
_GL_CXXALIASWARN1 (strstr, char *,
                   (char *haystack, const char *needle)
                   _GL_ATTRIBUTE_NOTHROW);
_GL_CXXALIASWARN1 (strstr, const char *,
                   (const char *haystack, const char *needle)
                   _GL_ATTRIBUTE_NOTHROW);
# elif __GLIBC__ >= 2
_GL_CXXALIASWARN (strstr);
# endif
#elif defined GNULIB_POSIXCHECK
/* strstr() does not work with multibyte strings if the locale encoding is
   different from UTF-8:
   POSIX says that it operates on "strings", and "string" in POSIX is defined
   as a sequence of bytes, not of characters.  */
# undef strstr
/* Assume strstr is always declared.  */
_GL_WARN_ON_USE (strstr, "strstr is quadratic on many systems, and cannot "
                 "work correctly on character strings in most "
                 "multibyte locales - "
                 "use mbsstr if you care about internationalization, "
                 "or use strstr if you care about speed");
#endif

/* Find the first occurrence of NEEDLE in HAYSTACK, using case-insensitive
   comparison.  */
#if @GNULIB_STRCASESTR@
# if @REPLACE_STRCASESTR@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define strcasestr rpl_strcasestr
#  endif
_GL_FUNCDECL_RPL (strcasestr, char *,
                  (const char *haystack, const char *needle),
                  _GL_ATTRIBUTE_PURE
                  _GL_ARG_NONNULL ((1, 2)));
_GL_CXXALIAS_RPL (strcasestr, char *,
                  (const char *haystack, const char *needle));
# else
#  if ! @HAVE_STRCASESTR@
_GL_FUNCDECL_SYS (strcasestr, char *,
                  (const char *haystack, const char *needle),
                  _GL_ATTRIBUTE_PURE
                  _GL_ARG_NONNULL ((1, 2)));
#  endif
  /* On some systems, this function is defined as an overloaded function:
       extern "C++" { const char * strcasestr (const char *, const char *); }
       extern "C++" { char * strcasestr (char *, const char *); }  */
_GL_CXXALIAS_SYS_CAST2 (strcasestr,
                        char *, (const char *haystack, const char *needle),
                        const char *, (const char *haystack, const char *needle));
# endif
# if ((__GLIBC__ == 2 && __GLIBC_MINOR__ >= 10) && !defined __UCLIBC__) \
     && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4) \
         || defined __clang__)
_GL_CXXALIASWARN1 (strcasestr, char *,
                   (char *haystack, const char *needle)
                   _GL_ATTRIBUTE_NOTHROW);
_GL_CXXALIASWARN1 (strcasestr, const char *,
                   (const char *haystack, const char *needle)
                   _GL_ATTRIBUTE_NOTHROW);
# elif __GLIBC__ >= 2
_GL_CXXALIASWARN (strcasestr);
# endif
#elif defined GNULIB_POSIXCHECK
/* strcasestr() does not work with multibyte strings:
   It is a glibc extension, and glibc implements it only for unibyte
   locales.  */
# undef strcasestr
# if HAVE_RAW_DECL_STRCASESTR
_GL_WARN_ON_USE (strcasestr, "strcasestr does work correctly on character "
                 "strings in multibyte locales - "
                 "use mbscasestr if you care about "
                 "internationalization, or use c-strcasestr if you want "
                 "a locale independent function");
# endif
#endif

/* Parse S into tokens separated by characters in DELIM.
   If S is NULL, the saved pointer in SAVE_PTR is used as
   the next starting point.  For example:
        char s[] = "-abc-=-def";
        char *sp;
        x = strtok_r(s, "-", &sp);      // x = "abc", sp = "=-def"
        x = strtok_r(NULL, "-=", &sp);  // x = "def", sp = NULL
        x = strtok_r(NULL, "=", &sp);   // x = NULL
                // s = "abc\0-def\0"

   This is a variant of strtok() that is multithread-safe.

   For the POSIX documentation for this function, see:
   https://pubs.opengroup.org/onlinepubs/9699919799/functions/strtok.html

   Caveat: It modifies the original string.
   Caveat: These functions cannot be used on constant strings.
   Caveat: The identity of the delimiting character is lost.
   Caveat: It doesn't work with multibyte strings unless all of the delimiter
           characters are ASCII characters < 0x30.

   See also strsep().  */
#if @GNULIB_STRTOK_R@
# if @REPLACE_STRTOK_R@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strtok_r
#   define strtok_r rpl_strtok_r
#  endif
_GL_FUNCDECL_RPL (strtok_r, char *,
                  (char *restrict s, char const *restrict delim,
                   char **restrict save_ptr),
                  _GL_ARG_NONNULL ((2, 3)));
_GL_CXXALIAS_RPL (strtok_r, char *,
                  (char *restrict s, char const *restrict delim,
                   char **restrict save_ptr));
# else
#  if @UNDEFINE_STRTOK_R@ || defined GNULIB_POSIXCHECK
#   undef strtok_r
#  endif
#  if ! @HAVE_DECL_STRTOK_R@
_GL_FUNCDECL_SYS (strtok_r, char *,
                  (char *restrict s, char const *restrict delim,
                   char **restrict save_ptr),
                  _GL_ARG_NONNULL ((2, 3)));
#  endif
_GL_CXXALIAS_SYS (strtok_r, char *,
                  (char *restrict s, char const *restrict delim,
                   char **restrict save_ptr));
# endif
_GL_CXXALIASWARN (strtok_r);
# if defined GNULIB_POSIXCHECK
_GL_WARN_ON_USE (strtok_r, "strtok_r cannot work correctly on character "
                 "strings in multibyte locales - "
                 "use mbstok_r if you care about internationalization");
# endif
#elif defined GNULIB_POSIXCHECK
# undef strtok_r
# if HAVE_RAW_DECL_STRTOK_R
_GL_WARN_ON_USE (strtok_r, "strtok_r is unportable - "
                 "use gnulib module strtok_r for portability");
# endif
#endif


/* The following functions are not specified by POSIX.  They are gnulib
   extensions.  */

#if @GNULIB_STR_STARTSWITH@
/* Returns true if STRING starts with PREFIX.
   Returns false otherwise.  */
_GL_EXTERN_C bool str_startswith (const char *string, const char *prefix)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
#endif

#if @GNULIB_STR_ENDSWITH@
/* Returns true if STRING ends with SUFFIX.
   Returns false otherwise.  */
_GL_EXTERN_C bool str_endswith (const char *string, const char *prefix)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
#endif

#if @GNULIB_MBSLEN@
/* Return the number of multibyte characters in the character string STRING.
   This considers multibyte characters, unlike strlen, which counts bytes.  */
# ifdef __MirBSD__  /* MirBSD defines mbslen as a macro.  Override it.  */
#  undef mbslen
# endif
# if @HAVE_MBSLEN@  /* AIX, OSF/1, MirBSD define mbslen already in libc.  */
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define mbslen rpl_mbslen
#  endif
_GL_FUNCDECL_RPL (mbslen, size_t, (const char *string),
                                  _GL_ATTRIBUTE_PURE
                                  _GL_ARG_NONNULL ((1)));
_GL_CXXALIAS_RPL (mbslen, size_t, (const char *string));
# else
_GL_FUNCDECL_SYS (mbslen, size_t, (const char *string),
                                  _GL_ATTRIBUTE_PURE
                                  _GL_ARG_NONNULL ((1)));
_GL_CXXALIAS_SYS (mbslen, size_t, (const char *string));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (mbslen);
# endif
#endif

#if @GNULIB_MBSNLEN@
/* Return the number of multibyte characters in the character string starting
   at STRING and ending at STRING + LEN.  */
_GL_EXTERN_C size_t mbsnlen (const char *string, size_t len)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1));
#endif

#if @GNULIB_MBSCHR@
/* Locate the first single-byte character C in the character string STRING,
   and return a pointer to it.  Return NULL if C is not found in STRING.
   Unlike strchr(), this function works correctly in multibyte locales with
   encodings such as GB18030.  */
# if defined __hpux
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define mbschr rpl_mbschr /* avoid collision with HP-UX function */
#  endif
_GL_FUNCDECL_RPL (mbschr, char *, (const char *string, int c),
                                  _GL_ATTRIBUTE_PURE
                                  _GL_ARG_NONNULL ((1)));
_GL_CXXALIAS_RPL (mbschr, char *, (const char *string, int c));
# else
_GL_FUNCDECL_SYS (mbschr, char *, (const char *string, int c),
                                  _GL_ATTRIBUTE_PURE
                                  _GL_ARG_NONNULL ((1)));
_GL_CXXALIAS_SYS (mbschr, char *, (const char *string, int c));
# endif
_GL_CXXALIASWARN (mbschr);
#endif

#if @GNULIB_MBSRCHR@
/* Locate the last single-byte character C in the character string STRING,
   and return a pointer to it.  Return NULL if C is not found in STRING.
   Unlike strrchr(), this function works correctly in multibyte locales with
   encodings such as GB18030.  */
# if defined __hpux || defined __INTERIX
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define mbsrchr rpl_mbsrchr /* avoid collision with system function */
#  endif
_GL_FUNCDECL_RPL (mbsrchr, char *, (const char *string, int c),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1)));
_GL_CXXALIAS_RPL (mbsrchr, char *, (const char *string, int c));
# else
_GL_FUNCDECL_SYS (mbsrchr, char *, (const char *string, int c),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1)));
_GL_CXXALIAS_SYS (mbsrchr, char *, (const char *string, int c));
# endif
_GL_CXXALIASWARN (mbsrchr);
#endif

#if @GNULIB_MBSSTR@
/* Find the first occurrence of the character string NEEDLE in the character
   string HAYSTACK.  Return NULL if NEEDLE is not found in HAYSTACK.
   Unlike strstr(), this function works correctly in multibyte locales with
   encodings different from UTF-8.  */
_GL_EXTERN_C char * mbsstr (const char *haystack, const char *needle)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
# ifndef _GL_NO_CONST_GENERICS
/* Don't silently convert a 'const char *' to a 'char *'.  Programmers want
   compiler warnings for 'const' related mistakes.  */
#  ifdef __cplusplus
extern "C++" { /* needed for AIX */
template <typename T>
  T * mbsstr_template (T* haystack, const char *needle);
template <>
  inline char * mbsstr_template (char *haystack, const char *needle)
  { return mbsstr (haystack, needle); }
template <>
  inline const char * mbsstr_template (const char *haystack, const char *needle)
  { return mbsstr (haystack, needle); }
}
#   undef mbsstr
#   define mbsstr mbsstr_template
#  elif !defined mbsstr
#   if ((__GNUC__ + (__GNUC_MINOR__ >= 9) > 4) || (__clang_major__ >= 3) \
        || defined __ICC  || defined __TINYC__ \
        || (__STDC_VERSION__ >= 201112L && !(defined __GNUC__ || defined __clang__)))
#    define mbsstr(h,n) \
       _Generic ((h), \
                 char const *: (char const *) mbsstr ((h), (n)), \
                 default     :                mbsstr ((h), (n)))
#   endif
#  endif
# endif
#endif

#if @GNULIB_MBSCASECMP@
/* Compare the character strings S1 and S2, ignoring case, returning less than,
   equal to or greater than zero if S1 is lexicographically less than, equal to
   or greater than S2.
   Note: This function may, in multibyte locales, return 0 for strings of
   different lengths!
   Unlike strcasecmp(), this function works correctly in multibyte locales.  */
_GL_EXTERN_C int mbscasecmp (const char *s1, const char *s2)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
#endif

#if @GNULIB_MBSNCASECMP@
/* Compare the initial segment of the character string S1 consisting of at most
   N characters with the initial segment of the character string S2 consisting
   of at most N characters, ignoring case, returning less than, equal to or
   greater than zero if the initial segment of S1 is lexicographically less
   than, equal to or greater than the initial segment of S2.
   Note: This function may, in multibyte locales, return 0 for initial segments
   of different lengths!
   Unlike strncasecmp(), this function works correctly in multibyte locales.
   But beware that N is not a byte count but a character count!  */
_GL_EXTERN_C int mbsncasecmp (const char *s1, const char *s2, size_t n)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
#endif

#if @GNULIB_MBSPCASECMP@
/* Compare the initial segment of the character string STRING consisting of
   at most mbslen (PREFIX) characters with the character string PREFIX,
   ignoring case.  If the two match, return a pointer to the first byte
   after this prefix in STRING.  Otherwise, return NULL.
   Note: This function may, in multibyte locales, return non-NULL if STRING
   is of smaller length than PREFIX!
   Unlike strncasecmp(), this function works correctly in multibyte
   locales.  */
_GL_EXTERN_C char * mbspcasecmp (const char *string, const char *prefix)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
# ifndef _GL_NO_CONST_GENERICS
/* Don't silently convert a 'const char *' to a 'char *'.  Programmers want
   compiler warnings for 'const' related mistakes.  */
#  ifdef __cplusplus
extern "C++" { /* needed for AIX */
template <typename T>
  T * mbspcasecmp_template (T* string, const char *prefix);
template <>
  inline char * mbspcasecmp_template (char *string, const char *prefix)
  { return mbspcasecmp (string, prefix); }
template <>
  inline const char * mbspcasecmp_template (const char *string, const char *prefix)
  { return mbspcasecmp (string, prefix); }
}
#   undef mbspcasecmp
#   define mbspcasecmp mbspcasecmp_template
#  elif !defined mbspcasecmp
#   if ((__GNUC__ + (__GNUC_MINOR__ >= 9) > 4) || (__clang_major__ >= 3) \
        || defined __ICC  || defined __TINYC__ \
        || (__STDC_VERSION__ >= 201112L && !(defined __GNUC__ || defined __clang__)))
#    define mbspcasecmp(s,p) \
       _Generic ((s), \
                 char const *: (char const *) mbspcasecmp ((s), (p)), \
                 default     :                mbspcasecmp ((s), (p)))
#   endif
#  endif
# endif
#endif

#if @GNULIB_MBSCASESTR@
/* Find the first occurrence of the character string NEEDLE in the character
   string HAYSTACK, using case-insensitive comparison.
   Note: This function may, in multibyte locales, return success even if
   strlen (haystack) < strlen (needle) !
   Unlike strcasestr(), this function works correctly in multibyte locales.  */
_GL_EXTERN_C char * mbscasestr (const char *haystack, const char *needle)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
# ifndef _GL_NO_CONST_GENERICS
/* Don't silently convert a 'const char *' to a 'char *'.  Programmers want
   compiler warnings for 'const' related mistakes.  */
#  ifdef __cplusplus
extern "C++" { /* needed for AIX */
template <typename T>
  T * mbscasestr_template (T* haystack, const char *needle);
template <>
  inline char * mbscasestr_template (char *haystack, const char *needle)
  { return mbscasestr (haystack, needle); }
template <>
  inline const char * mbscasestr_template (const char *haystack, const char *needle)
  { return mbscasestr (haystack, needle); }
}
#   undef mbscasestr
#   define mbscasestr mbscasestr_template
#  elif !defined mbscasestr
#   if ((__GNUC__ + (__GNUC_MINOR__ >= 9) > 4) || (__clang_major__ >= 3) \
        || defined __ICC  || defined __TINYC__ \
        || (__STDC_VERSION__ >= 201112L && !(defined __GNUC__ || defined __clang__)))
#    define mbscasestr(h,n) \
       _Generic ((h), \
                 char const *: (char const *) mbscasestr ((h), (n)), \
                 default     :                mbscasestr ((h), (n)))
#   endif
#  endif
# endif
#endif

#if @GNULIB_MBSCSPN@
/* Find the first occurrence in the character string STRING of any character
   in the character string ACCEPT.  Return the number of bytes from the
   beginning of the string to this occurrence, or to the end of the string
   if none exists.
   Unlike strcspn(), this function works correctly in multibyte locales.  */
_GL_EXTERN_C size_t mbscspn (const char *string, const char *accept)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
#endif

#if @GNULIB_MBSPBRK@
/* Find the first occurrence in the character string STRING of any character
   in the character string ACCEPT.  Return the pointer to it, or NULL if none
   exists.
   Unlike strpbrk(), this function works correctly in multibyte locales.  */
# if defined __hpux
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define mbspbrk rpl_mbspbrk /* avoid collision with HP-UX function */
#  endif
_GL_FUNCDECL_RPL (mbspbrk, char *, (const char *string, const char *accept),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1, 2)));
_GL_CXXALIAS_RPL (mbspbrk, char *, (const char *string, const char *accept));
# else
_GL_FUNCDECL_SYS (mbspbrk, char *, (const char *string, const char *accept),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1, 2)));
_GL_CXXALIAS_SYS (mbspbrk, char *, (const char *string, const char *accept));
# endif
_GL_CXXALIASWARN (mbspbrk);
#endif

#if @GNULIB_MBSSPN@
/* Find the first occurrence in the character string STRING of any character
   not in the character string REJECT.  Return the number of bytes from the
   beginning of the string to this occurrence, or to the end of the string
   if none exists.
   Unlike strspn(), this function works correctly in multibyte locales.  */
_GL_EXTERN_C size_t mbsspn (const char *string, const char *reject)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
#endif

#if @GNULIB_MBSSEP@
/* Search the next delimiter (multibyte character listed in the character
   string DELIM) starting at the character string *STRINGP.
   If one is found, overwrite it with a NUL, and advance *STRINGP to point
   to the next multibyte character after it.  Otherwise, set *STRINGP to NULL.
   If *STRINGP was already NULL, nothing happens.
   Return the old value of *STRINGP.

   This is a variant of mbstok_r() that supports empty fields.

   Caveat: It modifies the original string.
   Caveat: These functions cannot be used on constant strings.
   Caveat: The identity of the delimiting character is lost.

   See also mbstok_r().  */
_GL_EXTERN_C char * mbssep (char **stringp, const char *delim)
     _GL_ARG_NONNULL ((1, 2));
#endif

#if @GNULIB_MBSTOK_R@
/* Parse the character string STRING into tokens separated by characters in
   the character string DELIM.
   If STRING is NULL, the saved pointer in SAVE_PTR is used as
   the next starting point.  For example:
        char s[] = "-abc-=-def";
        char *sp;
        x = mbstok_r(s, "-", &sp);      // x = "abc", sp = "=-def"
        x = mbstok_r(NULL, "-=", &sp);  // x = "def", sp = NULL
        x = mbstok_r(NULL, "=", &sp);   // x = NULL
                // s = "abc\0-def\0"

   Caveat: It modifies the original string.
   Caveat: These functions cannot be used on constant strings.
   Caveat: The identity of the delimiting character is lost.

   See also mbssep().  */
_GL_EXTERN_C char * mbstok_r (char *restrict string, const char *delim,
                              char **save_ptr)
     _GL_ARG_NONNULL ((2, 3));
#endif

#if @GNULIB_MBS_STARTSWITH@
/* Returns true if STRING starts with PREFIX.
   Returns false otherwise.  */
_GL_EXTERN_C bool mbs_startswith (const char *string, const char *prefix)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
/* No extra code is needed for multibyte locales for this function.  */
# define mbs_startswith str_startswith
#endif

#if @GNULIB_MBS_ENDSWITH@
/* Returns true if STRING ends with SUFFIX.
   Returns false otherwise.
   Unlike str_endswith(), this function works correctly in multibyte locales.
 */
_GL_EXTERN_C bool mbs_endswith (const char *string, const char *suffix)
     _GL_ATTRIBUTE_PURE
     _GL_ARG_NONNULL ((1, 2));
#endif

/* Map any int, typically from errno, into an error message.  */
#if @GNULIB_STRERROR@
# if @REPLACE_STRERROR@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strerror
#   define strerror rpl_strerror
#  endif
_GL_FUNCDECL_RPL (strerror, char *, (int), );
_GL_CXXALIAS_RPL (strerror, char *, (int));
# else
_GL_CXXALIAS_SYS (strerror, char *, (int));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (strerror);
# endif
#elif defined GNULIB_POSIXCHECK
# undef strerror
/* Assume strerror is always declared.  */
_GL_WARN_ON_USE (strerror, "strerror is unportable - "
                 "use gnulib module strerror to guarantee non-NULL result");
#endif

/* Map any int, typically from errno, into an error message.  Multithread-safe.
   Uses the POSIX declaration, not the glibc declaration.  */
#if @GNULIB_STRERROR_R@
# if @REPLACE_STRERROR_R@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strerror_r
#   define strerror_r rpl_strerror_r
#  endif
_GL_FUNCDECL_RPL (strerror_r, int, (int errnum, char *buf, size_t buflen),
                                   _GL_ARG_NONNULL ((2)));
_GL_CXXALIAS_RPL (strerror_r, int, (int errnum, char *buf, size_t buflen));
# else
#  if !@HAVE_DECL_STRERROR_R@
_GL_FUNCDECL_SYS (strerror_r, int, (int errnum, char *buf, size_t buflen),
                                   _GL_ARG_NONNULL ((2)));
#  endif
_GL_CXXALIAS_SYS (strerror_r, int, (int errnum, char *buf, size_t buflen));
# endif
# if __GLIBC__ >= 2 && @HAVE_DECL_STRERROR_R@
_GL_CXXALIASWARN (strerror_r);
# endif
#elif defined GNULIB_POSIXCHECK
# undef strerror_r
# if HAVE_RAW_DECL_STRERROR_R
_GL_WARN_ON_USE (strerror_r, "strerror_r is unportable - "
                 "use gnulib module strerror_r-posix for portability");
# endif
#endif

/* Map any int, typically from errno, into an error message.
   With locale_t argument.  */
#if @GNULIB_STRERROR_L@
# if @REPLACE_STRERROR_L@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strerror_l
#   define strerror_l rpl_strerror_l
#  endif
_GL_FUNCDECL_RPL (strerror_l, char *, (int errnum, locale_t locale),
                                                   _GL_ARG_NONNULL ((2)));
_GL_CXXALIAS_RPL (strerror_l, char *, (int errnum, locale_t locale));
# else
#  if !@HAVE_STRERROR_L@
_GL_FUNCDECL_SYS (strerror_l, char *, (int errnum, locale_t locale),
                                                   _GL_ARG_NONNULL ((2)));
#  endif
_GL_CXXALIAS_SYS (strerror_l, char *, (int errnum, locale_t locale));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (strerror_l);
# endif
#elif defined GNULIB_POSIXCHECK
# undef strerror_l
# if HAVE_RAW_DECL_STRERROR_L
_GL_WARN_ON_USE (strerror_l, "strerror_l is unportable - "
                 "use gnulib module strerror_l for portability");
# endif
#endif

/* Map any int, typically from errno, into an error message.  Multithread-safe,
   with locale_t argument.
   Not portable! Only provided by gnulib.  */
#if @GNULIB_STRERROR_L@
_GL_FUNCDECL_SYS (strerror_l_r, int,
                  (int errnum, char *buf, size_t buflen, locale_t locale),
                  _GL_ARG_NONNULL ((2, 4)));
#endif

/* Return the name of the system error code ERRNUM.  */
#if @GNULIB_STRERRORNAME_NP@
# if @REPLACE_STRERRORNAME_NP@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   undef strerrorname_np
#   define strerrorname_np rpl_strerrorname_np
#  endif
_GL_FUNCDECL_RPL (strerrorname_np, const char *, (int errnum), );
_GL_CXXALIAS_RPL (strerrorname_np, const char *, (int errnum));
# else
#  if !@HAVE_STRERRORNAME_NP@
_GL_FUNCDECL_SYS (strerrorname_np, const char *, (int errnum), );
#  endif
_GL_CXXALIAS_SYS (strerrorname_np, const char *, (int errnum));
# endif
# if __GLIBC__ >= 2
_GL_CXXALIASWARN (strerrorname_np);
# endif
#elif defined GNULIB_POSIXCHECK
# undef strerrorname_np
# if HAVE_RAW_DECL_STRERRORNAME_NP
_GL_WARN_ON_USE (strerrorname_np, "strerrorname_np is unportable - "
                 "use gnulib module strerrorname_np for portability");
# endif
#endif

/* Return an abbreviation string for the signal number SIG.  */
#if @GNULIB_SIGABBREV_NP@
# if ! @HAVE_SIGABBREV_NP@
_GL_FUNCDECL_SYS (sigabbrev_np, const char *, (int sig), );
# endif
_GL_CXXALIAS_SYS (sigabbrev_np, const char *, (int sig));
_GL_CXXALIASWARN (sigabbrev_np);
#elif defined GNULIB_POSIXCHECK
# undef sigabbrev_np
# if HAVE_RAW_DECL_SIGABBREV_NP
_GL_WARN_ON_USE (sigabbrev_np, "sigabbrev_np is unportable - "
                 "use gnulib module sigabbrev_np for portability");
# endif
#endif

/* Return an English description string for the signal number SIG.  */
#if @GNULIB_SIGDESCR_NP@
# if ! @HAVE_SIGDESCR_NP@
_GL_FUNCDECL_SYS (sigdescr_np, const char *, (int sig), );
# endif
_GL_CXXALIAS_SYS (sigdescr_np, const char *, (int sig));
_GL_CXXALIASWARN (sigdescr_np);
#elif defined GNULIB_POSIXCHECK
# undef sigdescr_np
# if HAVE_RAW_DECL_SIGDESCR_NP
_GL_WARN_ON_USE (sigdescr_np, "sigdescr_np is unportable - "
                 "use gnulib module sigdescr_np for portability");
# endif
#endif

#if @GNULIB_STRSIGNAL@
# if @REPLACE_STRSIGNAL@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define strsignal rpl_strsignal
#  endif
_GL_FUNCDECL_RPL (strsignal, char *, (int __sig), );
_GL_CXXALIAS_RPL (strsignal, char *, (int __sig));
# else
#  if ! @HAVE_DECL_STRSIGNAL@
_GL_FUNCDECL_SYS (strsignal, char *, (int __sig), );
#  endif
/* Need to cast, because on Cygwin 1.5.x systems, the return type is
   'const char *'.  */
_GL_CXXALIAS_SYS_CAST (strsignal, char *, (int __sig));
# endif
_GL_CXXALIASWARN (strsignal);
#elif defined GNULIB_POSIXCHECK
# undef strsignal
# if HAVE_RAW_DECL_STRSIGNAL
_GL_WARN_ON_USE (strsignal, "strsignal is unportable - "
                 "use gnulib module strsignal for portability");
# endif
#endif

#if @GNULIB_STRVERSCMP@
# if @REPLACE_STRVERSCMP@
#  if !(defined __cplusplus && defined GNULIB_NAMESPACE)
#   define strverscmp rpl_strverscmp
#  endif
_GL_FUNCDECL_RPL (strverscmp, int, (const char *, const char *),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1, 2)));
_GL_CXXALIAS_RPL (strverscmp, int, (const char *, const char *));
# else
#  if !@HAVE_STRVERSCMP@
_GL_FUNCDECL_SYS (strverscmp, int, (const char *, const char *),
                                   _GL_ATTRIBUTE_PURE
                                   _GL_ARG_NONNULL ((1, 2)));
#  endif
_GL_CXXALIAS_SYS (strverscmp, int, (const char *, const char *));
# endif
_GL_CXXALIASWARN (strverscmp);
#elif defined GNULIB_POSIXCHECK
# undef strverscmp
# if HAVE_RAW_DECL_STRVERSCMP
_GL_WARN_ON_USE (strverscmp, "strverscmp is unportable - "
                 "use gnulib module strverscmp for portability");
# endif
#endif


#endif /* _@GUARD_PREFIX@_STRING_H */
#endif /* _@GUARD_PREFIX@_STRING_H */
#endif
