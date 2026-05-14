#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"

%%{
  machine rfc3339;
  include tstr_common "tstr_common.rl";

  ZoneOffset = [+\-] digit{2} [:] digit{2};

  main :=
        (digit{4})   >mark %set_year
  [\-]  (digit{2})   >mark %set_month
  [\-]  (digit{2})   >mark %set_day
  [Tt ] (digit{2})   >mark %set_hour
  [:]   (digit{2})   >mark %set_minute
  [:]   (digit{2})   >mark %set_second ([.] (digit{1,9}) >mark %set_fraction)?
  (     ZoneOffset  >mark %set_tz_offset
      | [Zz]        >mark %set_tz_utc
  )
  ;
}%%

%% write data;

tstr_parse_result_t tstr_cparse_rfc3339(const char* p,
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

  return (cs >= rfc3339_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
