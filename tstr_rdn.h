#ifndef TSTR_RDN_H
#define TSTR_RDN_H

#include <stdint.h>

#define TSTR_RDN_UNIX_EPOCH 719163 // 1970-01-01

static inline int tstr_rdn_dow(uint32_t rdn) {
  return 1 + (rdn + 6) % 7;
}

static inline void tstr_rdn_to_ymd(uint32_t rdn, int* yp, int* mp, int* dp) {
  uint32_t Z, H, A, B, y, C, m, d;

  Z = rdn + 306;
  H = 100 * Z - 25;
  A = H / 3652425;
  B = A - A / 4;
  y = (100 * B + H) / 36525;
  C = B + Z - (1461 * y) / 4;
  m = (535 * C + 48950) >> 14;
  d = C - ((979 * m - 2918) >> 5);

  if (m > 12)
    y++, m -= 12;

  if (yp)
    *yp = (int)y;
  if (mp)
    *mp = (int)m;
  if (dp)
    *dp = (int)d;
}

#endif /* TSTR_RDN_H */
