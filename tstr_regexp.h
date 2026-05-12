#ifndef TSTR_REGEXP_H
#define TSTR_REGEXP_H

#include "tstr_sv.h"
#include "tstr_parsed.h"
#include "tstr_format.h"

void tstr_regexp_extract(pTHX_ REGEXP *rx, tstr_parsed_t *p,
                         tstr_format_t fmt, int pivot_year,
                         tstr_sv_keys_t *keys);

#endif /* TSTR_REGEXP_H */
