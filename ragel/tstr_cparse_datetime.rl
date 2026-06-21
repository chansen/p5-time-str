#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"

%%{
  machine datetime;
  include tstr_common "tstr_common.rl";

  action mark_sep {
    sep_char = fc;
  }

  action check_sep {
    fc == sep_char
  }

  action mark_day {
    mark_day = fpc;
  }

  action restore_mark_day {
    mark = mark_day;
  }
  DayNameShort      = 'Mon'i | 'Tue'i | 'Tues'i | 'Wed'i | 'Thu'i | 'Thurs'i |'
                       Fri'i | 'Sat'i | 'Sun'i;
  DayNameLong       = 'Monday'i | 'Tuesday'i | 'Wednesday'i | 'Thursday'i |
                      'Friday'i | 'Saturday'i | 'Sunday'i;
  DayName           = DayNameShort | DayNameLong;

  MonthNameShort    = 'Jan'i | 'Feb'i | 'Mar'i | 'Apr'i | 'May'i | 'Jun'i |
                      'Jul'i | 'Aug'i | 'Sep'i | 'Sept'i | 'Oct'i | 'Nov'i | 'Dec'i;
  MonthNameLong     = 'January'i | 'February'i | 'March'i | 'April'i | 'May'i |
                      'June'i | 'July'i | 'August'i | 'September'i | 'October'i |
                      'November'i | 'December'i;
  MonthName         = MonthNameShort | MonthNameLong;

  MonthRoman        = 'I'i | 'II'i | 'III'i | 'IV'i | 'V'i | 'VI'i |
                      'VII'i | 'VIII'i | 'IX'i | 'X'i | 'XI'i | 'XII'i;
  MonthTextual      = MonthName | MonthRoman;

  OrdinalSuffix     = 'st'i | 'nd'i | 'rd'i | 'th'i;

  Meridiem          = [AaPp] ( [Mm] | '.' [Mm] '.');

  year              = digit{4} >mark %set_year;
  day_num           = digit{1,2} >mark %set_day;
  day_opt_ord       = (digit{1,2} OrdinalSuffix?) >mark_day %restore_mark_day %set_day;

  month_any         = (MonthName | digit{1,2}) >mark %set_month;
  month_name        = MonthName >mark %set_month;
  month_textual     = MonthTextual >mark %set_month;

  date_delim_ymd    = year       [\-./] >mark_sep month_any     [\-./] when check_sep day_num;
  date_delim_dmy    = day_num    [\-./] >mark_sep month_textual [\-./] when check_sep year;
  date_delim_mdy    = month_name [\-./] >mark_sep day_num       [\-./] when check_sep year;
  date_delimited    = date_delim_ymd | date_delim_dmy | date_delim_mdy;

  sp                = ' ';

  date_space_dmy    = day_opt_ord [.]? sp month_textual [.,]? sp year;
  date_space_mdy    = month_name [.,]? sp day_opt_ord [,]? sp year;
  date_spaced       = date_space_dmy | date_space_mdy;

  date_compact_ymd  = year month_name day_num;
  date_compact_dmy  = day_num month_textual year;
  date_compact      = date_compact_ymd | date_compact_dmy;

  date              = date_delimited | date_spaced | date_compact;

  hour              = digit{1,2} >mark %set_hour;
  minute            = digit{2} >mark %set_minute;
  second            = digit{2} >mark %set_second;
  fraction          = digit{1,9} >mark %set_fraction;
  meridiem          = Meridiem >mark %set_meridiem;

  time_merdiem      = hour sp? meridiem;
  time_hms          = hour ':' minute (':' second ([.,] fraction)?)? (sp? meridiem)?;
  time              = time_hms | time_merdiem;
  time_sep          = (sp ('at'i sp)?) | (',' sp) | [Tt];

  Comment           = '(' [^()]+ ')';
  Annotation        = '[' [^\[\]]+ ']';

  TimeZoneOffset    = [+\-] (digit{4} | digit{2}   (':' digit{2})?);
  TimeZoneOffsetUTC = [+\-] (digit{4} | digit{1,2} (':' digit{2})?);
  TimeZoneUTC       = 'UTC' | 'GMT';
  TimeZoneZulu      = [Zz];
  TimeZoneAbbrev    = upper (upper | lower) upper{1,4} - TimeZoneUTC;

  tz_offset         = TimeZoneOffset >mark %set_tz_offset;
  tz_utc            = TimeZoneUTC >mark %set_tz_utc (TimeZoneOffsetUTC >mark %set_tz_offset)?;
  tz_zulu           = TimeZoneZulu >mark %set_tz_utc;
  tz_abbrev         = TimeZoneAbbrev >mark %set_tz_abbrev;

  timezone          = tz_offset | tz_utc | tz_zulu | tz_abbrev;

  annotation        = Annotation+ >mark %set_tz_annotation;

  main :=
  (DayName >mark %set_day_name [.]?[,]? sp)?
  date (time_sep time (sp? timezone annotation? (sp Comment)?)?)?
  ;
}%%

%% write data;

tstr_parse_result_t tstr_cparse_datetime(const char* p,
                                         size_t len,
                                         tstr_parsed_t* parsed) {
  int cs, v;
  const char* pe = p + len;
  const char* eof = pe;
  const char* mark = NULL;
  const char* mark_day = NULL;
  tstr_parse_result_t result = TSTR_PARSE_OK;
  char sep_char = 0;

  (void)tstr_parsed_init(parsed);

  %% write init;
  %% write exec;

  if (result != TSTR_PARSE_OK)
    return result;

  return (cs >= datetime_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
