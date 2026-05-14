#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"

%%{
  machine ecmascript;
  include tstr_common "tstr_common.rl";
  
  DayName        = 'Mon' | 'Tue' | 'Wed' | 'Thu' | 'Fri' | 'Sat' | 'Sun';
  MonthName      = 'Jan' | 'Feb' | 'Mar' | 'Apr' | 'May' | 'Jun' |
                   'Jul' | 'Aug' | 'Sep' | 'Oct' | 'Nov' | 'Dec';
  TimeZoneOffset = [+\-] digit{4};
  TimeZoneUTC    = 'UTC' | 'GMT';

  main :=
      DayName    >mark %set_day_name
  [ ] MonthName  >mark %set_month
  [ ] digit{2}   >mark %set_day
  [ ] digit{4}   >mark %set_year
  [ ] digit{2}   >mark %set_hour
  [:] digit{2}   >mark %set_minute
  [:] digit{2}   >mark %set_second
  [ ] (TimeZoneUTC >mark %set_tz_utc)? (TimeZoneOffset >mark %set_tz_offset)
  ([ ] '(' (any - [()])+ ')')?
  ;
}%%

%% write data;

tstr_parse_result_t tstr_cparse_ecmascript(const char* p,
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

  return (cs >= ecmascript_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
