#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"

%%{
  machine rfc2822;
  include tstr_common "tstr_common.rl";
  
  DayName        = 'Mon'i | 'Tue'i | 'Wed'i | 'Thu'i | 'Fri'i | 'Sat'i | 'Sun'i;
  MonthName      = 'Jan'i | 'Feb'i | 'Mar'i | 'Apr'i | 'May'i | 'Jun'i |
                   'Jul'i | 'Aug'i | 'Sep'i | 'Oct'i | 'Nov'i | 'Dec'i;
  TimeZoneOffset = [+\-] digit{4};
  TimeZoneUTC    = 'UT' | 'UTC' | 'GMT';
  TimeZoneAbbrev = upper (upper | lower) upper{1,4} - TimeZoneUTC;

  main :=
  ( DayName >mark %set_day_name [,][ ] )?
      digit{1,2}  >mark %set_day
  [ ] MonthName   >mark %set_month
  [ ] digit{4}    >mark %set_year
  [ ] digit{2}    >mark %set_hour
  [:] digit{2}    >mark %set_minute ([:] digit{2} >mark %set_second)?
  [ ]
  (     TimeZoneOffset  >mark %set_tz_offset
      | TimeZoneUTC     >mark %set_tz_utc
      | TimeZoneAbbrev  >mark %set_tz_abbrev
  )
  ([ ] '(' (any - [()])+ ')')?
  ;
}%%

%% write data;

tstr_parse_result_t tstr_cparse_rfc2822(const char* p,
                                        size_t len,
                                        tstr_parsed_t* parsed) {
  int cs, v;
  const char* pe = p + len;
  const char* eof = pe;
  const char* mark = NULL;
  tstr_parse_result_t result = TSTR_PARSE_OK;

  memset(parsed, 0, sizeof(*parsed));

  %% write init;
  %% write exec;

  if (result != TSTR_PARSE_OK)
    return result;

  return (cs >= rfc2822_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
