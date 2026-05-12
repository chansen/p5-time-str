#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tstr_parsed.h"
#include "tstr_format.h"
#include "tstr_calendar.h"
#include "tstr_sv.h"
#include "tstr_regexp.h"

#define DEFAULT_PIVOT_YEAR 1950

static inline bool valid_hms(int h, int m, int s) {
  return h >= 0 && h <= 23
      && m >= 0 && m <= 59
      && s >= 0 && (s <= 59 || (s == 60 && h == 23 && m == 59));
}

static void validate_parsed(pTHX_ const tstr_parsed_t *p) {
  if (!tstr_calendar_valid_ymd(p->year, p->month, p->day))
    croak("Unable to parse: date is out of range");

  if ((p->flags & TSTR_PARSED_HAS_DAY_NAME) &&
      tstr_calendar_ymd_to_dow(p->year, p->month, p->day) != p->day_name)
    croak("Unable to parse: day name does not match date");

  if (p->flags & TSTR_PARSED_HAS_MERIDIEM) {
    if (p->hour < 1 || p->hour > 12)
      croak("Unable to parse: hour is out of range for 12-hour clock");
  }

  if (p->flags & TSTR_PARSED_HAS_TIME) {
    int h = p->hour;
    if (p->flags & TSTR_PARSED_HAS_MERIDIEM)
      h = p->hour % 12 + p->meridiem;
    if (!valid_hms(h, p->minute, p->second))
      croak("Unable to parse: time of day is out of range");
  }
}

void tstr_parse(pTHX_ SV *input, tstr_format_t fmt, int pivot_year,
                REGEXP **regexps, tstr_sv_keys_t *keys, tstr_parsed_t *p) {
  REGEXP *rx = regexps[fmt];
  char *s;
  STRLEN slen;

  if (!rx)
    croak("panic: no regexp for format '%s'", tstr_format_name(fmt));

  s = SvPV(input, slen);
  if (!pregexec(rx, s, s + slen, s, 0, input, 1))
    croak("Unable to parse: string does not match the %s format",
          tstr_format_name(fmt));

  if (pivot_year < 0)
    pivot_year = DEFAULT_PIVOT_YEAR;

  tstr_regexp_extract(aTHX_ rx, p, fmt, pivot_year, keys);
  validate_parsed(aTHX_ p);
}
