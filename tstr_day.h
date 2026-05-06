#ifndef TSTR_DAY_H
#define TSTR_DAY_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include "tstr_packed_alpha.h"

typedef enum {
  TSTR_DAY_UNKNOWN = 0,
  TSTR_DAY_MON,
  TSTR_DAY_TUE,
  TSTR_DAY_WED,
  TSTR_DAY_THU,
  TSTR_DAY_FRI,
  TSTR_DAY_SAT,
  TSTR_DAY_SUN,
} tstr_day_t;

static inline tstr_day_t tstr_day_from_packed_alpha(uint64_t packed) {
  switch (packed) {
    case TSTR_PACKED_ALPHA3('M','o','n'):
    case TSTR_PACKED_ALPHA6('M','o','n','d','a','y'):
      return TSTR_DAY_MON;
    case TSTR_PACKED_ALPHA3('T','u','e'):
    case TSTR_PACKED_ALPHA4('T','u','e','s'):
    case TSTR_PACKED_ALPHA7('T','u','e','s','d','a','y'):
      return TSTR_DAY_TUE;
    case TSTR_PACKED_ALPHA3('W','e','d'):
    case TSTR_PACKED_ALPHA9('W','e','d','n','e','s','d','a','y'):
      return TSTR_DAY_WED;
    case TSTR_PACKED_ALPHA3('T','h','u'):
    case TSTR_PACKED_ALPHA5('T','h','u','r','s'):
    case TSTR_PACKED_ALPHA8('T','h','u','r','s','d','a','y'):
      return TSTR_DAY_THU;
    case TSTR_PACKED_ALPHA3('F','r','i'):
    case TSTR_PACKED_ALPHA6('F','r','i','d','a','y'):
      return TSTR_DAY_FRI;
    case TSTR_PACKED_ALPHA3('S','a','t'):
    case TSTR_PACKED_ALPHA8('S','a','t','u','r','d','a','y'):
      return TSTR_DAY_SAT;
    case TSTR_PACKED_ALPHA3('S','u','n'):
    case TSTR_PACKED_ALPHA6('S','u','n','d','a','y'):
      return TSTR_DAY_SUN;
    default:
      return TSTR_DAY_UNKNOWN;
  }
}

static inline tstr_day_t tstr_day_from_string(const char* src,
                                              size_t len) {
  uint64_t packed;

  if (!len || tstr_packed_alpha_encode(src, len, &packed) != len)
    return TSTR_DAY_UNKNOWN;
  return tstr_day_from_packed_alpha(packed);
}

/*
 * Check if the given day-of-week matches the date (y, m, d).
 * Based on Tomohiko Sakamoto's algorithm with a Monday-based
 * offset table. Assumes m is 1-12 and d is valid.
 */
static inline bool tstr_day_valid_ymd(tstr_day_t day, int y, int m, int d) {
  static const int kDayOffset[13] = {
    0, 6, 2, 1, 4, 6, 2, 4, 0, 3, 5, 1, 3
  };

  if (y < 1 || m < 1 || m > 12 || d < 1 || d > 31)
    return false;

  if (m < 3)
    y--;

  return day == 1 + (y + y/4 - y/100 + y/400 + kDayOffset[m] + d) % 7;
}

#endif /* TSTR_DAY_H */
