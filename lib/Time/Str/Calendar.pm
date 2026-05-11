package Time::Str::Calendar;
use strict;
use warnings;
use v5.10;

use Exporter qw[import];
use Carp     qw[croak];

our $VERSION     = '0.08';
our @EXPORT_OK   = qw[ valid_ymd
                       ymd_to_dow
                       ymd_to_rdn
                       resolve_century ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub leap_year {
  my ($y) = @_;
  return (($y & 3) == 0 && ($y % 100 != 0 || $y % 400 == 0));
}

# 1 <= $m <= 12
sub month_days {
  my ($y, $m) = @_;
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
    return 1 + ($y + $y/4 - $y/100 + $y/400 + $DayOffset[$m] + $d) % 7;
  }
}

sub resolve_century {
  @_ == 2 or croak q/Usage: resolve_century(year, pivot_year)/;
  my ($year, $pivot_year) = @_;

  ($year >= 0 && $year <= 99)
    or croak q/Parameter 'year' is out of range [1, 99]/;
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

1;
