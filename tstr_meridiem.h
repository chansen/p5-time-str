#ifndef TSTR_MERIDIEM_H
#define TSTR_MERIDIEM_H

#include <stddef.h>
#include <stdbool.h>

typedef enum {
  TSTR_MERIDIEM_UNKNOWN = 0,
  TSTR_MERIDIEM_ANTE,
  TSTR_MERIDIEM_POST,
} tstr_meridiem_t;

/*
 * Parse a meridiem indicator: AM, PM (case-insensitive), with or
 * without periods (e.g. "am", "PM", "a.m.", "P.M.").
 *
 * Returns TSTR_MERIDIEM_ANTE, TSTR_MERIDIEM_POST, or
 * TSTR_MERIDIEM_UNKNOWN if the input is not recognized.
 */
static inline tstr_meridiem_t tstr_meridiem_from_string(const char *src,
                                                        size_t len) {
  unsigned char a, m;

  if (len == 2) {
    a = src[0];
    m = src[1];
  } else if (len == 4) {
    if (src[1] != '.' || src[3] != '.')
      return TSTR_MERIDIEM_UNKNOWN;
    a = src[0];
    m = src[2];
  } else {
    return TSTR_MERIDIEM_UNKNOWN;
  }

  if ((m | 0x20) != 'm')
    return TSTR_MERIDIEM_UNKNOWN;

  if ((a | 0x20) == 'a')
    return TSTR_MERIDIEM_ANTE;
  if ((a | 0x20) == 'p')
    return TSTR_MERIDIEM_POST;
  return TSTR_MERIDIEM_UNKNOWN;
}

static inline int tstr_meridiem_valid_hour(tstr_meridiem_t m, int hour) {
  return m != TSTR_MERIDIEM_UNKNOWN && hour >= 1 && hour <= 12;
}

static inline int tstr_meridiem_to_24h(tstr_meridiem_t m, int hour) {
  if (!tstr_meridiem_valid_hour(m, hour))
    return -1;
  if (m == TSTR_MERIDIEM_ANTE)
    return hour == 12 ? 0 : hour;
  return hour == 12 ? 12 : hour + 12;
}

#endif /* TSTR_MERIDIEM_H */
