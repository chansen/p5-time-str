#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tstr_sv.h"
#include "tstr_parsed.h"
#include "tstr_format.h"
#include "tstr_token_parse.h"

static bool fetch_cap_pv(pTHX_ REGEXP *rx, SV *namesv,
                         const char **sp, STRLEN *lenp) {
  SV *val = reg_named_buff_fetch(rx, namesv, 0);
  if (val && SvOK(val)) {
    sv_2mortal(val);
    *sp = SvPV_const(val, *lenp);
    return true;
  }
  if (val)
    SvREFCNT_dec(val);
  return false;
}

void tstr_regexp_extract(pTHX_ REGEXP *rx, tstr_parsed_t *p,
                         tstr_format_t fmt, int pivot_year,
                         tstr_sv_keys_t *keys) {
  const char *s;
  STRLEN len;
  int v;

#define CAP_PV(field) fetch_cap_pv(aTHX_ rx, keys->k_##field, &s, &len)

  Zero(p, 1, tstr_parsed_t);

  if (!CAP_PV(year))
    croak("panic: regexp matched but no 'year' capture");
  if (!tstr_token_parse_year(s, len, &v))
    croak("Unable to parse: year is invalid");
  if (len == 2)
    tstr_parsed_set_year2(p, v, pivot_year);
  else
    tstr_parsed_set_year4(p, v);

  if (CAP_PV(month)) {
    if (!tstr_token_parse_month(s, len, &v))
      croak("Unable to parse: month is invalid");
    tstr_parsed_set_month(p, v);
  } else {
    p->month = 1;
  }

  if (CAP_PV(day)) {
    if (!tstr_token_parse_day(s, len, &v))
      croak("Unable to parse: day is invalid");
    tstr_parsed_set_day(p, v);
  } else {
    p->day = 1;
  }

  if (CAP_PV(day_name)) {
    if (!tstr_token_parse_day_name(s, len, &v))
      croak("Unable to parse: day name is invalid");
    tstr_parsed_set_day_name(p, v);
  }

  if (CAP_PV(hour)) {
    if (!tstr_token_parse_hour(s, len, &v))
      croak("Unable to parse: hour is invalid");
    tstr_parsed_set_hour(p, v);

    if (CAP_PV(meridiem)) {
      if (!tstr_token_parse_meridiem(s, len, &v))
        croak("Unable to parse: meridiem is invalid");
      tstr_parsed_set_meridiem(p, v);
    }

    if (CAP_PV(minute)) {
      if (!tstr_token_parse_minute(s, len, &v))
        croak("Unable to parse: minute is invalid");
      tstr_parsed_set_minute(p, v);
    }

    if (CAP_PV(second)) {
      if (!tstr_token_parse_second(s, len, &v))
        croak("Unable to parse: second is invalid");
      tstr_parsed_set_second(p, v);
    }

    {
      int nanos;
      if (CAP_PV(fraction)) {
        if (!tstr_token_parse_fraction(s, len, &nanos))
          croak("Unable to parse: fraction is invalid");
        tstr_parsed_set_fraction(p, nanos);
      }
    }

    if (CAP_PV(tz_offset)) {
      if (!tstr_token_parse_tz_offset(s, len, &v))
        croak("Unable to parse: timezone offset is invalid");
      tstr_parsed_set_offset(p, v);
    }

    if (CAP_PV(tz_utc))
      tstr_parsed_set_tz_utc(p, s, len);

    if (CAP_PV(tz_abbrev))
      tstr_parsed_set_tz_abbrev(p, s, len);

    if (CAP_PV(tz_annotation))
      tstr_parsed_set_tz_annotation(p, s, len);
  }

  /* RFC2616 implies GMT */
  if (fmt == TSTR_FORMAT_RFC2616 && !(p->flags & TSTR_PARSED_HAS_TZ_UTC))
    tstr_parsed_set_tz_utc(p, "GMT", 3);

#undef CAP_PV
}
