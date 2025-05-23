/* GnuTLS glue for GNU Emacs.
   Copyright (C) 2010-2025 Free Software Foundation, Inc.

This file is part of GNU Emacs.

GNU Emacs is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.  */

#ifndef EMACS_GNUTLS_DEFINED
#define EMACS_GNUTLS_DEFINED

#ifdef HAVE_GNUTLS
#include <gnutls/gnutls.h>
#include <gnutls/x509.h>

#if 0x030000 <= GNUTLS_VERSION_NUMBER
# define HAVE_GNUTLS3
# include <gnutls/crypto.h>
#endif

#include "lisp.h"

/* This limits the attempts to handshake per process (connection).  It
   should work out to about one minute in asynchronous cases. */
#define GNUTLS_EMACS_HANDSHAKES_LIMIT 6000

typedef enum
{
  /* Initialization stages.  */
  GNUTLS_STAGE_EMPTY = 0,
  GNUTLS_STAGE_CRED_ALLOC,
  GNUTLS_STAGE_FILES,
  GNUTLS_STAGE_CALLBACKS,
  GNUTLS_STAGE_INIT,
  GNUTLS_STAGE_PRIORITY,
  GNUTLS_STAGE_CRED_SET,

  /* Handshake stages.  */
  GNUTLS_STAGE_HANDSHAKE_CANDO = GNUTLS_STAGE_CRED_SET,
  GNUTLS_STAGE_TRANSPORT_POINTERS_SET,
  GNUTLS_STAGE_HANDSHAKE_TRIED,

  GNUTLS_STAGE_READY
} gnutls_initstage_t;

#define GNUTLS_EMACS_ERROR_NOT_LOADED (GNUTLS_E_APPLICATION_ERROR_MIN + 1)
#define GNUTLS_EMACS_ERROR_INVALID_TYPE GNUTLS_E_APPLICATION_ERROR_MIN

#define GNUTLS_INITSTAGE(proc) (XPROCESS (proc)->gnutls_initstage)

#define GNUTLS_PROCESS_USABLE(proc) \
  (GNUTLS_INITSTAGE (proc) >= GNUTLS_STAGE_READY)

#define GNUTLS_LOG(level, max, string)				\
  do {								\
    if ((level) <= (max))					\
      gnutls_log_function (level, "(Emacs) " string);		\
  } while (false)

#define GNUTLS_LOG2(level, max, string, extra)			\
  do {								\
    if ((level) <= (max))					\
      gnutls_log_function2 (level, "(Emacs) " string, extra);	\
  } while (false)

#define GNUTLS_LOG2i(level, max, string, extra)			\
  do {								\
    if ((level) <= (max))					\
      message ("gnutls.c: [%d] %s %d", level, string, extra);	\
  } while (false)

extern ptrdiff_t
emacs_gnutls_write (struct Lisp_Process *proc, const char *buf, ptrdiff_t nbyte);
extern ptrdiff_t
emacs_gnutls_read (struct Lisp_Process *proc, char *buf, ptrdiff_t nbyte);

extern ptrdiff_t emacs_gnutls_record_check_pending (gnutls_session_t state);
#ifdef WINDOWSNT
extern void emacs_gnutls_transport_set_errno (gnutls_session_t state, int err);
extern int w32_gnutls_rnd (gnutls_rnd_level_t, void *, size_t);
#endif
extern Lisp_Object emacs_gnutls_deinit (Lisp_Object);
extern int gnutls_try_handshake (struct Lisp_Process *p);
extern Lisp_Object gnutls_verify_boot (Lisp_Object proc, Lisp_Object proplist);

#endif

extern void syms_of_gnutls (void);

#endif
