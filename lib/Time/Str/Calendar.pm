package Time::Str::Calendar;
use strict;
use warnings;
use v5.10.1;

our $VERSION     = '0.09';
our @EXPORT_OK   = qw[ leap_year
                       month_days
                       valid_ymd
                       ymd_to_dow
                       ymd_to_rdn
                       rdn_to_ymd
                       rdn_to_dow
                       resolve_century ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Exporter qw[import];

BEGIN {
  require Time::Str;
  unless (exists &Time::Str::Calendar::leap_year) {
    require Time::Str::PP;
    *leap_year       = \&Time::Str::PP::Calendar::leap_year;
    *month_days      = \&Time::Str::PP::Calendar::month_days;
    *valid_ymd       = \&Time::Str::PP::Calendar::valid_ymd;
    *ymd_to_dow      = \&Time::Str::PP::Calendar::ymd_to_dow;
    *ymd_to_rdn      = \&Time::Str::PP::Calendar::ymd_to_rdn;
    *rdn_to_ymd      = \&Time::Str::PP::Calendar::rdn_to_ymd;
    *rdn_to_dow      = \&Time::Str::PP::Calendar::rdn_to_dow;
    *resolve_century = \&Time::Str::PP::Calendar::resolve_century;
  }
}

1;
