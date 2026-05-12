package Time::Str::Token;
use strict;
use warnings;
use v5.10;

our $VERSION     = '0.09';
our @EXPORT_OK   = qw[ parse_day
                       parse_day_name
                       parse_month
                       parse_meridiem
                       parse_tz_offset ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Exporter qw[import];

BEGIN {
  require Time::Str;
  unless (exists &Time::Str::Token::parse_day) {
    require Time::Str::PP;
    *parse_day       = \&Time::Str::PP::Token::parse_day;
    *parse_day_name  = \&Time::Str::PP::Token::parse_day_name;
    *parse_month     = \&Time::Str::PP::Token::parse_month;
    *parse_meridiem  = \&Time::Str::PP::Token::parse_meridiem;
    *parse_tz_offset = \&Time::Str::PP::Token::parse_tz_offset;
  }
}

1;
