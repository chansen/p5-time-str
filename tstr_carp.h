#ifndef TSTR_CARP_H
#define TSTR_CARP_H

#include <stdarg.h>

static inline void tstr_carp_croak(pTHX_ const char *msg) {
  dSP;
  PUSHMARK(SP);
  mXPUSHs(newSVpv(msg, 0));
  PUTBACK;
  call_pv("Carp::croak", G_DISCARD);
  croak("Time::Str panic: unexpected return from Carp::croak");
}

static inline void tstr_carp_croakf(pTHX_ const char *fmt, ...) {
  dSP;
  va_list ap;
  SV *msg;

  va_start(ap, fmt);
  msg = vnewSVpvf(fmt, &ap);
  va_end(ap);

  PUSHMARK(SP);
  mXPUSHs(msg);
  PUTBACK;
  call_pv("Carp::croak", G_DISCARD);
  croak("Time::Str panic: unexpected return from Carp::croak");
}

#define tstr_croak(msg)       tstr_carp_croak(aTHX_ msg)
#define tstr_croakf(fmt, ...) tstr_carp_croakf(aTHX_ fmt, __VA_ARGS__)

#endif /* TSTR_CARP_H */
