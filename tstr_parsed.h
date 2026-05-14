#ifndef TSTR_PARSED_H
#define TSTR_PARSED_H

#include <stdint.h>
#include "tstr_format.h"

enum {
  TSTR_PARSED_HAS_TIME          = (1 << 0),
  TSTR_PARSED_HAS_MINUTE        = (1 << 1),
  TSTR_PARSED_HAS_SECOND        = (1 << 2),
  TSTR_PARSED_HAS_NANOSECOND    = (1 << 3),
  TSTR_PARSED_HAS_OFFSET        = (1 << 4),
  TSTR_PARSED_HAS_TZ_UTC        = (1 << 5),
  TSTR_PARSED_HAS_TZ_ABBREV     = (1 << 6),
  TSTR_PARSED_HAS_TZ_ANNOTATION = (1 << 7),
  TSTR_PARSED_HAS_DAY_NAME      = (1 << 8),
  TSTR_PARSED_HAS_MERIDIEM      = (1 << 9),
  TSTR_PARSED_HAS_MONTH         = (1 << 10),
  TSTR_PARSED_HAS_DAY           = (1 << 11),
  TSTR_PARSED_HAS_YEAR2         = (1 << 12)
};

#define TSTR_NANOS_PER_SECOND 1000000000

typedef struct {
  int year;
  int month;
  int day;
  int hour;
  int minute;
  int second;
  int nanosecond;
  int offset;
  int day_name;
  int meridiem;
  unsigned int flags;
  const char *tz_utc;
  const char *tz_abbrev;
  const char *tz_annotation;
  STRLEN tz_utc_len;
  STRLEN tz_abbrev_len;
  STRLEN tz_annotation_len;
} tstr_parsed_t;

static inline void tstr_parsed_set_year4(tstr_parsed_t *p, int v) {
  p->year = v;
}

static inline void tstr_parsed_set_year2(tstr_parsed_t *p, int v) {
  p->year = v;
  p->flags |= TSTR_PARSED_HAS_YEAR2;
}

static inline void tstr_parsed_set_month(tstr_parsed_t *p, int v) {
  p->month = v;
  p->flags |= TSTR_PARSED_HAS_MONTH;
}

static inline void tstr_parsed_set_day(tstr_parsed_t *p, int v) {
  p->day = v;
  p->flags |= TSTR_PARSED_HAS_DAY;
}

static inline void tstr_parsed_set_day_name(tstr_parsed_t *p, int v) {
  p->day_name = v;
  p->flags |= TSTR_PARSED_HAS_DAY_NAME;
}

static inline void tstr_parsed_set_hour(tstr_parsed_t *p, int v) {
  p->hour = v;
  p->flags |= TSTR_PARSED_HAS_TIME;
}

static inline void tstr_parsed_set_meridiem(tstr_parsed_t *p, int v) {
  p->meridiem = v;
  p->flags |= TSTR_PARSED_HAS_MERIDIEM;
}

static inline void tstr_parsed_set_minute(tstr_parsed_t *p, int v) {
  p->minute = v;
  p->flags |= TSTR_PARSED_HAS_MINUTE;
}

static inline void tstr_parsed_set_second(tstr_parsed_t *p, int v) {
  p->second = v;
  p->flags |= TSTR_PARSED_HAS_SECOND;
}

static inline void tstr_parsed_set_nanosecond(tstr_parsed_t *p, int v) {
  p->nanosecond = v;
  p->flags |= TSTR_PARSED_HAS_NANOSECOND;
}

static inline void tstr_parsed_set_offset(tstr_parsed_t *p, int v) {
  p->offset = v;
  p->flags |= TSTR_PARSED_HAS_OFFSET;
}

static inline void tstr_parsed_set_tz_utc(tstr_parsed_t *p, const char *s, STRLEN len) {
  p->tz_utc = s;
  p->tz_utc_len = len;
  p->flags |= TSTR_PARSED_HAS_TZ_UTC;
  if (!(p->flags & TSTR_PARSED_HAS_OFFSET)) {
    p->offset = 0;
    p->flags |= TSTR_PARSED_HAS_OFFSET;
  }
}

static inline void tstr_parsed_set_tz_abbrev(tstr_parsed_t *p, const char *s, STRLEN len) {
  p->tz_abbrev = s;
  p->tz_abbrev_len = len;
  p->flags |= TSTR_PARSED_HAS_TZ_ABBREV;
}

static inline void tstr_parsed_set_tz_annotation(tstr_parsed_t *p, const char *s, STRLEN len) {
  p->tz_annotation = s;
  p->tz_annotation_len = len;
  p->flags |= TSTR_PARSED_HAS_TZ_ANNOTATION;
}

static inline void tstr_parsed_set_fraction(tstr_parsed_t *p, int nanos) {
  if (p->flags & TSTR_PARSED_HAS_SECOND) {
    p->nanosecond = nanos;
    p->flags |= TSTR_PARSED_HAS_NANOSECOND;
  } else if (p->flags & TSTR_PARSED_HAS_MINUTE) {
    uint64_t total_ns = (uint64_t)nanos * 60;
    p->second = (int)(total_ns / TSTR_NANOS_PER_SECOND);
    p->flags |= TSTR_PARSED_HAS_SECOND;
    nanos = (int)(total_ns % TSTR_NANOS_PER_SECOND);
    if (nanos) {
      p->nanosecond = nanos;
      p->flags |= TSTR_PARSED_HAS_NANOSECOND;
    }
  } else {
    uint64_t total_ns = (uint64_t)nanos * 3600;
    int min, sec;
    min = (int)(total_ns / ((uint64_t)60 * TSTR_NANOS_PER_SECOND));
    p->minute = min;
    p->flags |= TSTR_PARSED_HAS_MINUTE;
    total_ns -= (uint64_t)min * 60 * TSTR_NANOS_PER_SECOND;
    sec = (int)(total_ns / TSTR_NANOS_PER_SECOND);
    nanos = (int)(total_ns % TSTR_NANOS_PER_SECOND);
    if (sec || nanos) {
      p->second = sec;
      p->flags |= TSTR_PARSED_HAS_SECOND;
      if (nanos) {
        p->nanosecond = nanos;
        p->flags |= TSTR_PARSED_HAS_NANOSECOND;
      }
    }
  }
}

#endif /* TSTR_PARSED_H */
