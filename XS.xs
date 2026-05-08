#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tstr_param.h"
#include "tstr_format.h"
#include "tstr_datetime.h"
#include "tstr_time2str.h"

#if NVSIZE > 8
# define DEFAULT_PRECISION 9
#else
# define DEFAULT_PRECISION 6
#endif

#define NANOS_PER_SECOND   1000000000
#define MIN_EPOCH          INT64_C(-62135596800)   // 0001-01-01T00:00:00Z
#define MAX_EPOCH          INT64_C(253402300799)   // 9999-12-31T23:59:59Z
#define EPOCH_20500101     INT64_C(2524608000)     // 2050-01-01T00:00:00Z

MODULE = Time::Str  PACKAGE = Time::Str

void
time2str(...)
  PREINIT:
    dXSTARG;
    int64_t epoch;
    int32_t offset = 0;
    int32_t nanosecond = -1;
    int precision = -1;
    tstr_format_t fmt = TSTR_FORMAT_RFC3339;
    tstr_datetime_t dt;
    int i;
  PPCODE:
    if (items < 1 || !(items & 1))
      croak("Usage: time2str(time [, format => 'RFC3339' ])");

    epoch = (int64_t)SvNV(ST(0));

    for (i = 1; i < items; i += 2) {
      const char *key;
      STRLEN klen;
      SV *val;

      key = SvPV_const(ST(i), klen);
      val = ST(i + 1);

      switch (tstr_param_from_string(key, klen)) {
        case TSTR_PARAM_FORMAT: {
          const char *fstr;
          STRLEN flen;
          fstr = SvPV_const(val, flen);
          fmt = tstr_format_from_string(fstr, flen);
          if (fmt == TSTR_FORMAT_UNKNOWN)
            croak("Parameter 'format' is unknown: '%"SVf"'", val);
          break;
        }
        case TSTR_PARAM_OFFSET:
          offset = (int32_t)SvIV(val);
          if (offset < -1439 || offset > 1439)
            croak("Parameter 'offset' is out of range [-1439, 1439]");
          break;
        case TSTR_PARAM_PRECISION:
          precision = (int)SvIV(val);
          if (precision < 0 || precision > 9)
            croak("Parameter 'precision' is out of range [0, 9]");
          break;
        case TSTR_PARAM_NANOSECOND:
          nanosecond = (int32_t)SvIV(val);
          if (nanosecond < 0 || nanosecond > 999999999)
            croak("Parameter 'nanosecond' is out of range [0, 999_999_999]");
          break;
        default:
          croak("Unrecognised named parameter: '%"SVf"'", ST(i));
      }
    }

    if (epoch < MIN_EPOCH || epoch > MAX_EPOCH)
      croak("Parameter 'time' is out of range");

    if (nanosecond < 0 && SvNOK(ST(0))) {
      NV t = SvNV(ST(0));
      NV sec = Perl_floor(t);
      NV fr = t - sec;
      int scale_exp = (precision >= 0) ? precision : DEFAULT_PRECISION;
      NV scale = Perl_pow(10.0, (NV)scale_exp);

      fr = Perl_floor(fr * scale + 0.5) / scale;
      nanosecond = (int32_t)Perl_floor(fr * NANOS_PER_SECOND + 0.5);
      epoch = (int64_t)sec;

      if (nanosecond >= NANOS_PER_SECOND) {
        nanosecond -= NANOS_PER_SECOND;
        epoch++;
      }
    }

    if (nanosecond < 0)
      nanosecond = 0;

    if (offset) {
      int64_t local = epoch + (int64_t)offset * 60;
      if (local < MIN_EPOCH || local > MAX_EPOCH)
        croak("Parameter 'time' is out of range for the given offset");
    }

    if (fmt == TSTR_FORMAT_RFC5280) {
      fmt = (epoch < EPOCH_20500101) ? TSTR_FORMAT_ASN1UT : TSTR_FORMAT_ASN1GT;
      nanosecond = 0;
      offset = 0;
      precision = -1;
    }

    tstr_datetime_from_epoch(&dt, epoch, offset, nanosecond);

    (void)SvUPGRADE(TARG, SVt_PV);
    (void)SvGROW(TARG, 30);
    SvCUR_set(TARG, 0);
    SvPOK_only(TARG);

    if (!tstr_time2str(aTHX_ TARG, &dt, precision, fmt))
      croak("Parameter 'format' does not support time2str");
    PUSHTARG;

