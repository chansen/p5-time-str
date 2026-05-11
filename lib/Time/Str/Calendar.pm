package Time::Str::Calendar;
use strict;
use warnings;
use v5.10;

use Exporter qw[import];

our @EXPORT_OK   = qw[ leap_year
                       month_days
                       valid_ymd
                       ymd_to_dow
                       ymd_to_rdn
                       rdn_to_ymd
                       rdn_to_dow
                       resolve_century ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

BEGIN {
  our $VERSION = '0.09';

  my $xs_loaded = exists &Time::Str::Calendar::leap_year;
  eval {
    require XSLoader; XSLoader::load('Time::Str', $VERSION);
    $xs_loaded = 1;
  } unless ($xs_loaded or $ENV{TIME_STR_PP});

  unless ($xs_loaded) {
    require Carp; Carp->import(qw(croak));
    eval sprintf <<'EOC', __FILE__;
# line 33 %s

sub RDN_MIN () {       1 }  # 0001-01-01
sub RDN_MAX () { 3652059 }  # 9999-12-31

sub leap_year {
  @_ == 1 or croak q/Usage: leap_year(year)/;
  my ($y) = @_;
  return (($y & 3) == 0 && ($y %% 100 != 0 || $y %% 400 == 0));
}

sub month_days {
  @_ == 2 or croak q/Usage: month_days(year, month)/;
  my ($y, $m) = @_;

  ($m >= 1 && $m <= 12)
    or croak q/Parameter 'month' is out of range [1, 12]/;

  return 29 if $m == 2 && leap_year($y);
  return (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$m];
}

sub valid_ymd {
  @_ == 3 or croak q/Usage: valid_ymd(year, month, day)/;
  my ($y, $m, $d) = @_;
  return ($y >= 1 && $y <= 9999)
      && ($m >= 1 && $m <= 12)
      && ($d >= 1 && ($d <= 28 || $d <= month_days($y, $m)));
}

sub ymd_to_rdn {
  @_ == 3 or croak q/Usage: ymd_to_rdn(year, month, day)/;
  my ($y, $m, $d) = @_;

  ($y >= 1 && $y <= 9999)
    or croak q/Parameter 'year' is out of range [1, 9999]/;
  ($m >= 1 && $m <= 12)
    or croak q/Parameter 'month' is out of range [1, 12]/;
  ($d >= 1 && $d <= 31)
    or croak q/Parameter 'day' is out of range [1, 31]/;

  use integer;
  if ($m < 3) {
    $y--, $m += 12;
  }
  return ((1461 * $y) >> 2) - $y / 100 + $y / 400
    + $d + ((979 * $m - 2918) >> 5) - 306;
}

sub rdn_to_ymd {
  @_ == 1 or croak q/Usage: rdn_to_ymd(rdn)/;
  my ($rdn) = @_;

  ($rdn >= RDN_MIN && $rdn <= RDN_MAX)
    or croak q/Parameter 'rdn' is out of range/;

  use integer;
  my $Z = $rdn + 306;
  my $H = 100 * $Z - 25;
  my $A = $H / 3652425;
  my $B = $A - ($A >> 2);
  my $y = (100 * $B + $H) / 36525;
  my $C = $B + $Z - ((1461 * $y) >> 2);
  my $m = (535 * $C + 48950) >> 14;
  my $d = $C - ((979 * $m - 2918) >> 5);
  if ($m > 12) {
    $y++, $m -= 12;
  }
  return ($y, $m, $d);
}

sub rdn_to_dow {
  @_ == 1 or croak q/Usage: rdn_to_dow(rdn)/;
  my ($rdn) = @_;

  ($rdn >= RDN_MIN && $rdn <= RDN_MAX)
    or croak q/Parameter 'rdn' is out of range/;
  return 1 + ($rdn + 6) %% 7;
}

{
  my @DayOffset = (0, 6, 2, 1, 4, 6, 2, 4, 0, 3, 5, 1, 3);
  sub ymd_to_dow {
    @_ == 3 or croak q/Usage: ymd_to_dow(year, month, day)/;
    my ($y, $m, $d) = @_;

    ($y >= 1 && $y <= 9999)
      or croak q/Parameter 'year' is out of range [1, 9999]/;
    ($m >= 1 && $m <= 12)
      or croak q/Parameter 'month' is out of range [1, 12]/;
    ($d >= 1 && $d <= 31)
      or croak q/Parameter 'day' is out of range [1, 31]/;

    use integer;
    if ($m < 3) {
      $y--;
    }
    return 1 + ($y + $y/4 - $y/100 + $y/400 + $DayOffset[$m] + $d) %% 7;
  }
}

sub resolve_century {
  @_ == 2 or croak q/Usage: resolve_century(year, pivot_year)/;
  my ($year, $pivot_year) = @_;

  ($year >= 0 && $year <= 99)
    or croak q/Parameter 'year' is out of range [0, 99]/;
  ($pivot_year >= 0 && $pivot_year <= 9899)
    or croak q/Parameter 'pivot_year' is out of range [0, 9899]/;

  use integer;
  my $century = $pivot_year / 100;
  my $base = $century * 100;
  my $pivot_offset = $pivot_year - $base;

  my $resolved = $base + $year;
  if ($year < $pivot_offset) {
    $resolved += 100;
  }
  return $resolved;
}
EOC
    die $@ if $@;
  }
}

1;
