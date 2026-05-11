#ifndef TSTR_TOKEN_PARSE_H
#define TSTR_TOKEN_PARSE_H

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

bool tstr_token_parse_day(const char* src, size_t len, int* day);
bool tstr_token_parse_day_name(const char* src, size_t len, int* day);
bool tstr_token_parse_meridiem(const char* src, size_t len, int* day);
bool tstr_token_parse_month(const char* src, size_t len, int* month);
bool tstr_token_parse_tz_offset(const char* src, size_t len, int* offset);

#endif /* TSTR_TOKEN_PARSE_H */
