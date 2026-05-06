#ifndef TSTR_MONTH_H
#define TSTR_MONTH_H

#include <stddef.h>
#include <stdint.h>
#include "tstr_packed_alpha.h"

typedef enum {
  TSTR_MONTH_UNKNOWN = 0,
  TSTR_MONTH_JAN,
  TSTR_MONTH_FEB,
  TSTR_MONTH_MAR,
  TSTR_MONTH_APR,
  TSTR_MONTH_MAY,
  TSTR_MONTH_JUN,
  TSTR_MONTH_JUL,
  TSTR_MONTH_AUG,
  TSTR_MONTH_SEP,
  TSTR_MONTH_OCT,
  TSTR_MONTH_NOV,
  TSTR_MONTH_DEC,
} tstr_month_t;

static inline tstr_month_t tstr_month_from_packed_alpha(uint64_t packed) {
  switch (packed) {
    case TSTR_PACKED_ALPHA1('I'):
    case TSTR_PACKED_ALPHA3('J','a','n'):
    case TSTR_PACKED_ALPHA7('J','a','n','u','a','r','y'):
      return TSTR_MONTH_JAN;
    case TSTR_PACKED_ALPHA2('I','I'):
    case TSTR_PACKED_ALPHA3('F','e','b'):
    case TSTR_PACKED_ALPHA8('F','e','b','r','u','a','r','y'):
      return TSTR_MONTH_FEB;
    case TSTR_PACKED_ALPHA3('I','I','I'):
    case TSTR_PACKED_ALPHA3('M','a','r'):
    case TSTR_PACKED_ALPHA5('M','a','r','c','h'):
      return TSTR_MONTH_MAR;
    case TSTR_PACKED_ALPHA2('I','V'):
    case TSTR_PACKED_ALPHA3('A','p','r'):
    case TSTR_PACKED_ALPHA5('A','p','r','i','l'):
      return TSTR_MONTH_APR;
    case TSTR_PACKED_ALPHA1('V'):
    case TSTR_PACKED_ALPHA3('M','a','y'):
      return TSTR_MONTH_MAY;
    case TSTR_PACKED_ALPHA2('V','I'):
    case TSTR_PACKED_ALPHA3('J','u','n'):
    case TSTR_PACKED_ALPHA4('J','u','n','e'):
      return TSTR_MONTH_JUN;
    case TSTR_PACKED_ALPHA3('V','I','I'):
    case TSTR_PACKED_ALPHA3('J','u','l'):
    case TSTR_PACKED_ALPHA4('J','u','l','y'):
      return TSTR_MONTH_JUL;
    case TSTR_PACKED_ALPHA4('V','I','I','I'):
    case TSTR_PACKED_ALPHA3('A','u','g'):
    case TSTR_PACKED_ALPHA6('A','u','g','u','s','t'):
      return TSTR_MONTH_AUG;
    case TSTR_PACKED_ALPHA2('I','X'):
    case TSTR_PACKED_ALPHA3('S','e','p'):
    case TSTR_PACKED_ALPHA4('S','e','p','t'):
    case TSTR_PACKED_ALPHA9('S','e','p','t','e','m','b','e','r'):
      return TSTR_MONTH_SEP;
    case TSTR_PACKED_ALPHA1('X'):
    case TSTR_PACKED_ALPHA3('O','c','t'):
    case TSTR_PACKED_ALPHA7('O','c','t','o','b','e','r'):
      return TSTR_MONTH_OCT;
    case TSTR_PACKED_ALPHA2('X','I'):
    case TSTR_PACKED_ALPHA3('N','o','v'):
    case TSTR_PACKED_ALPHA8('N','o','v','e','m','b','e','r'):
      return TSTR_MONTH_NOV;
    case TSTR_PACKED_ALPHA3('X','I','I'):
    case TSTR_PACKED_ALPHA3('D','e','c'):
    case TSTR_PACKED_ALPHA8('D','e','c','e','m','b','e','r'):
      return TSTR_MONTH_DEC;
    default:
      return TSTR_MONTH_UNKNOWN;
  }
}

static inline tstr_month_t tstr_month_from_string(const char* src,
                                                   size_t len) {
  uint64_t packed;

  if (!len || tstr_packed_alpha_encode(src,len,&packed) != len)
    return TSTR_MONTH_UNKNOWN;
  return tstr_month_from_packed_alpha(packed);
}

#endif /* TSTR_MONTH_H */
