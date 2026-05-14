#ifndef TSTR_PARSE_RESULT_H
#define TSTR_PARSE_RESULT_H

#include <stddef.h>

typedef enum {
  TSTR_PARSE_OK = 0,
  TSTR_PARSE_NOMATCH,
  TSTR_PARSE_ERR_YEAR,
  TSTR_PARSE_ERR_MONTH,
  TSTR_PARSE_ERR_DAY,
  TSTR_PARSE_ERR_DAY_NAME,
  TSTR_PARSE_ERR_HOUR,
  TSTR_PARSE_ERR_MINUTE,
  TSTR_PARSE_ERR_SECOND,
  TSTR_PARSE_ERR_FRACTION,
  TSTR_PARSE_ERR_OFFSET,
  TSTR_PARSE_ERR_MERIDIEM,
} tstr_parse_result_t;

static inline const char* tstr_parse_error_message(tstr_parse_result_t err) {
  switch (err) {
    case TSTR_PARSE_ERR_YEAR:
      return "year is invalid";
    case TSTR_PARSE_ERR_MONTH:
      return "month is invalid";
    case TSTR_PARSE_ERR_DAY:
      return "day is invalid";
    case TSTR_PARSE_ERR_DAY_NAME:
      return "day name is invalid";
    case TSTR_PARSE_ERR_HOUR:
      return "hour is invalid";
    case TSTR_PARSE_ERR_MINUTE:
      return "minute is invalid";
    case TSTR_PARSE_ERR_SECOND:
      return "second is invalid";
    case TSTR_PARSE_ERR_FRACTION:
      return "fraction is invalid";
    case TSTR_PARSE_ERR_OFFSET:
      return "timezone offset is invalid";
    case TSTR_PARSE_ERR_MERIDIEM:
      return "meridiem is invalid";
    default:
      return NULL;
  }
}

#endif /* TSTR_PARSE_RESULT_H */
