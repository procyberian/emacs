/* Read symbolic links into a buffer without size limitation, relative to fd.

   Copyright (C) 2011-2025 Free Software Foundation, Inc.

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

/* Written by Paul Eggert, Bruno Haible, and Jim Meyering.  */

#ifndef _GL_CAREADLINKAT_H
#define _GL_CAREADLINKAT_H

/* This file uses HAVE_READLINKAT.  */
#if !_GL_CONFIG_H_INCLUDED
 #error "Please include config.h first."
#endif

#include <fcntl.h>
#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif


struct allocator;

/* Assuming the current directory is FD, get the symbolic link value
   of FILENAME as a null-terminated string and put it into a buffer.
   If FD is AT_FDCWD, FILENAME is interpreted relative to the current
   working directory, as in openat.

   If the link is small enough to fit into BUFFER put it there.
   BUFFER's size is BUFFER_SIZE, and BUFFER can be null
   if BUFFER_SIZE is zero.

   If the link is not small, put it into a dynamically allocated
   buffer managed by ALLOC.  It is the caller's responsibility to free
   the returned value if it is nonnull and is not BUFFER.

   The PREADLINKAT function specifies how to read links.  It operates
   like POSIX readlinkat()
   <https://pubs.opengroup.org/onlinepubs/9699919799/functions/readlink.html>
   but can assume that its first argument is the same as FD.

   If successful, return the buffer address; otherwise return NULL and
   set errno.  */

char *careadlinkat (int fd, char const *filename,
                    char *restrict buffer, size_t buffer_size,
                    struct allocator const *alloc,
                    ssize_t (*preadlinkat) (int, char const *,
                                            char *, size_t));

/* Suitable value for careadlinkat's FD argument.  */
#if HAVE_READLINKAT
/* AT_FDCWD is declared in <fcntl.h>.  */
#else
/* Define AT_FDCWD independently, so that the careadlinkat module does
   not depend on the fcntl-h module.  We might as well use the same value
   as fcntl-h.  */
# ifndef AT_FDCWD
#  define AT_FDCWD (-3041965)
# endif
#endif


#ifdef __cplusplus
}
#endif

#endif /* _GL_CAREADLINKAT_H */
