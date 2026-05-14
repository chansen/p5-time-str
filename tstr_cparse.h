#ifndef TSTR_CPARSE_H
#define TSTR_CPARSE_H

#include <stddef.h>
#include "tstr_format.h"
#include "tstr_parse_result.h"
#include "tstr_parsed.h"

tstr_parse_result_t tstr_cparse_rfc3339(const char *p,
                                        size_t len,
                                        tstr_parsed_t *parsed);
tstr_parse_result_t tstr_cparse_ecmascript(const char *p,
                                           size_t len,
                                           tstr_parsed_t *parsed);
tstr_parse_result_t tstr_cparse_rfc2822(const char *p,
                                        size_t len,
                                        tstr_parsed_t *parsed);

static inline tstr_parse_result_t tstr_cparse_dispatch(const char *s,
                                                       size_t len,
                                                       tstr_format_t fmt,
                                                       tstr_parsed_t *parsed) {
  switch (fmt) {
    case TSTR_FORMAT_RFC3339:
      return tstr_cparse_rfc3339(s, len, parsed);
    case TSTR_FORMAT_ECMASCRIPT:
      return tstr_cparse_ecmascript(s, len, parsed);
    case TSTR_FORMAT_RFC2822:
      return tstr_cparse_rfc2822(s, len, parsed);
    default:
      return TSTR_PARSE_NOMATCH;
  }
}

#endif /* TSTR_CPARSE_H */
