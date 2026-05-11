#!perl
use strict;
use warnings;

use Test::More;

use lib 't';
use Util qw[throws_ok];

BEGIN {
  use_ok('Time::Str::Calendar', qw[ valid_ymd
                                    ymd_to_dow
                                    ymd_to_rdn
                                    resolve_century ]);
}

# valid_ymd

throws_ok { valid_ymd() }
  qr/^Usage: valid_ymd/,
  'valid_ymd: no arguments';

ok(valid_ymd(2024,  1,  1), 'valid_ymd: 2024-01-01');
ok(valid_ymd(2024,  6, 15), 'valid_ymd: 2024-06-15');
ok(valid_ymd(2024, 12, 31), 'valid_ymd: 2024-12-31');

# year boundaries
ok( valid_ymd(   1,  1,  1), 'valid_ymd: 0001-01-01');
ok( valid_ymd(9999, 12, 31), 'valid_ymd: 9999-12-31');
ok(!valid_ymd(   0,  1,  1), 'valid_ymd: year 0');
ok(!valid_ymd(10000, 1,  1), 'valid_ymd: year 10000');

# month boundaries
ok( valid_ymd(2024,  1, 15), 'valid_ymd: month 1');
ok( valid_ymd(2024, 12, 15), 'valid_ymd: month 12');
ok(!valid_ymd(2024,  0, 15), 'valid_ymd: month 0');
ok(!valid_ymd(2024, 13, 15), 'valid_ymd: month 13');

# day boundaries
ok( valid_ymd(2024,  1,  1), 'valid_ymd: day 1');
ok(!valid_ymd(2024,  1,  0), 'valid_ymd: day 0');

# days per month (non-leap year)
{
  my %mdays = (
     1 => 31,  2 => 28,  3 => 31,  4 => 30,
     5 => 31,  6 => 30,  7 => 31,  8 => 31,
     9 => 30, 10 => 31, 11 => 30, 12 => 31,
  );
  foreach my $m (sort { $a <=> $b } keys %mdays) {
    my $last = $mdays{$m};
    ok( valid_ymd(2023, $m, $last),     "valid_ymd: 2023-$m-$last (last day)");
    ok(!valid_ymd(2023, $m, $last + 1), "valid_ymd: 2023-$m-" . ($last + 1) . " (too many)");
  }
}

# leap year: Feb 29
ok( valid_ymd(2024, 2, 29), 'valid_ymd: 2024-02-29 (leap year)');
ok(!valid_ymd(2023, 2, 29), 'valid_ymd: 2023-02-29 (non-leap year)');
ok( valid_ymd(2000, 2, 29), 'valid_ymd: 2000-02-29 (divisible by 400)');
ok(!valid_ymd(1900, 2, 29), 'valid_ymd: 1900-02-29 (divisible by 100, not 400)');
ok(!valid_ymd(2100, 2, 29), 'valid_ymd: 2100-02-29 (divisible by 100, not 400)');
ok( valid_ymd(2400, 2, 29), 'valid_ymd: 2400-02-29 (divisible by 400)');

# ymd_to_rdn

throws_ok { ymd_to_rdn() }
  qr/^Usage: ymd_to_rdn/,
  'ymd_to_rdn: no arguments';

is(ymd_to_rdn(   1,  1,  1),      1, 'ymd_to_rdn: 0001-01-01');
is(ymd_to_rdn(   1,  1,  2),      2, 'ymd_to_rdn: 0001-01-02');
is(ymd_to_rdn(   1, 12, 31),    365, 'ymd_to_rdn: 0001-12-31');
is(ymd_to_rdn(   2,  1,  1),    366, 'ymd_to_rdn: 0002-01-01');
is(ymd_to_rdn(1858, 11, 17), 678576, 'ymd_to_rdn: 1858-11-17 (MJD epoch)');
is(ymd_to_rdn(1970,  1,  1), 719163, 'ymd_to_rdn: 1970-01-01 (Unix epoch)');
is(ymd_to_rdn(2000,  1,  1), 730120, 'ymd_to_rdn: 2000-01-01');
is(ymd_to_rdn(2024, 12, 24), 739244, 'ymd_to_rdn: 2024-12-24');

# consecutive days across month boundary
is(ymd_to_rdn(2024, 1, 31) + 1, ymd_to_rdn(2024, 2, 1),
  'ymd_to_rdn: Jan 31 + 1 = Feb 1');

# consecutive days across leap day
is(ymd_to_rdn(2024, 2, 29) + 1, ymd_to_rdn(2024, 3, 1),
  'ymd_to_rdn: Feb 29 + 1 = Mar 1 (leap year)');

# consecutive days across year boundary
is(ymd_to_rdn(2024, 12, 31) + 1, ymd_to_rdn(2025, 1, 1),
  'ymd_to_rdn: Dec 31 + 1 = Jan 1 next year');

# leap year has 366 days
is(ymd_to_rdn(2025, 1, 1) - ymd_to_rdn(2024, 1, 1), 366,
  'ymd_to_rdn: 2024 has 366 days');

# non-leap year has 365 days
is(ymd_to_rdn(2024, 1, 1) - ymd_to_rdn(2023, 1, 1), 365,
  'ymd_to_rdn: 2023 has 365 days');

throws_ok { ymd_to_rdn(0, 1, 1) }
  qr/Parameter 'year' is out of range/,
  'ymd_to_rdn: year 0';

throws_ok { ymd_to_rdn(10000, 1, 1) }
  qr/Parameter 'year' is out of range/,
  'ymd_to_rdn: year 10000';

throws_ok { ymd_to_rdn(2024, 0, 1) }
  qr/Parameter 'month' is out of range/,
  'ymd_to_rdn: month 0';

throws_ok { ymd_to_rdn(2024, 13, 1) }
  qr/Parameter 'month' is out of range/,
  'ymd_to_rdn: month 13';

throws_ok { ymd_to_rdn(2024, 1, 0) }
  qr/Parameter 'day' is out of range/,
  'ymd_to_rdn: day 0';

throws_ok { ymd_to_rdn(2024, 1, 32) }
  qr/Parameter 'day' is out of range/,
  'ymd_to_rdn: day 32';

# ymd_to_dow

throws_ok { ymd_to_dow() }
  qr/^Usage: ymd_to_dow/,
  'ymd_to_dow: no arguments';

# known days (1=Mon .. 7=Sun)
{
  my %known = (
    '2024-12-23' => [2024, 12, 23, 1], # Monday
    '2024-12-24' => [2024, 12, 24, 2], # Tuesday
    '2024-12-25' => [2024, 12, 25, 3], # Wednesday
    '2024-12-26' => [2024, 12, 26, 4], # Thursday
    '2024-12-27' => [2024, 12, 27, 5], # Friday
    '2024-12-28' => [2024, 12, 28, 6], # Saturday
    '2024-12-29' => [2024, 12, 29, 7], # Sunday
  );
  foreach my $label (sort keys %known) {
    my ($y, $m, $d, $dow) = @{$known{$label}};
    is(ymd_to_dow($y, $m, $d), $dow, "ymd_to_dow: $label = $dow");
  }
}

# epoch dates
is(ymd_to_dow(1970,  1,  1), 4, 'ymd_to_dow: 1970-01-01 (Thursday)');
is(ymd_to_dow(2000,  1,  1), 6, 'ymd_to_dow: 2000-01-01 (Saturday)');
is(ymd_to_dow(   1,  1,  1), 1, 'ymd_to_dow: 0001-01-01 (Monday)');

# leap day
is(ymd_to_dow(2024,  2, 29), 4, 'ymd_to_dow: 2024-02-29 (Thursday)');
is(ymd_to_dow(2000,  2, 29), 2, 'ymd_to_dow: 2000-02-29 (Tuesday)');

# consistency with ymd_to_rdn: dow = ((rdn + 6) % 7) + 1
foreach my $date ([2024, 1,   1], [2024, 3, 1], [2024,  6, 15],
                  [2024, 12, 31], [   1, 1, 1], [9999, 12, 31]) {
  my ($y, $m, $d) = @$date;
  my $rdn = ymd_to_rdn($y, $m, $d);
  my $dow_from_rdn = (($rdn + 6) % 7) + 1;
  is(ymd_to_dow($y, $m, $d), $dow_from_rdn,
    "ymd_to_dow: $y-$m-$d consistent with ymd_to_rdn");
}

throws_ok { ymd_to_dow(0, 1, 1) }
  qr/Parameter 'year' is out of range/,
  'ymd_to_dow: year 0';

throws_ok { ymd_to_dow(10000, 1, 1) }
  qr/Parameter 'year' is out of range/,
  'ymd_to_dow: year 10000';

throws_ok { ymd_to_dow(2024, 0, 1) }
  qr/Parameter 'month' is out of range/,
  'ymd_to_dow: month 0';

throws_ok { ymd_to_dow(2024, 13, 1) }
  qr/Parameter 'month' is out of range/,
  'ymd_to_dow: month 13';

throws_ok { ymd_to_dow(2024, 1, 0) }
  qr/Parameter 'day' is out of range/,
  'ymd_to_dow: day 0';

throws_ok { ymd_to_dow(2024, 1, 32) }
  qr/Parameter 'day' is out of range/,
  'ymd_to_dow: day 32';

# resolve_century

throws_ok { resolve_century() }
  qr/^Usage: resolve_century/,
  'resolve_century: no arguments';

# pivot 1950
is(resolve_century( 0, 1950), 2000, 'resolve_century: 00 pivot 1950');
is(resolve_century(24, 1950), 2024, 'resolve_century: 24 pivot 1950');
is(resolve_century(49, 1950), 2049, 'resolve_century: 49 pivot 1950');
is(resolve_century(50, 1950), 1950, 'resolve_century: 50 pivot 1950');
is(resolve_century(99, 1950), 1999, 'resolve_century: 99 pivot 1950');

# pivot 2000
is(resolve_century( 0, 2000), 2000, 'resolve_century: 00 pivot 2000');
is(resolve_century(50, 2000), 2050, 'resolve_century: 50 pivot 2000');
is(resolve_century(99, 2000), 2099, 'resolve_century: 99 pivot 2000');

# pivot 2050
is(resolve_century( 0, 2050), 2100, 'resolve_century: 00 pivot 2050');
is(resolve_century(49, 2050), 2149, 'resolve_century: 49 pivot 2050');
is(resolve_century(50, 2050), 2050, 'resolve_century: 50 pivot 2050');
is(resolve_century(99, 2050), 2099, 'resolve_century: 99 pivot 2050');

# pivot 0
is(resolve_century( 0,    0),   0, 'resolve_century: 00 pivot 0');
is(resolve_century(99,    0),  99, 'resolve_century: 99 pivot 0');

# pivot at maximum
is(resolve_century( 0, 9899), 9900, 'resolve_century: 00 pivot 9899');
is(resolve_century(98, 9899), 9998, 'resolve_century: 98 pivot 9899');
is(resolve_century(99, 9899), 9899, 'resolve_century: 99 pivot 9899');

throws_ok { resolve_century(-1, 1950) }
  qr/Parameter 'year' is out of range/,
  'resolve_century: year -1';

throws_ok { resolve_century(100, 1950) }
  qr/Parameter 'year' is out of range/,
  'resolve_century: year 100';

throws_ok { resolve_century(0, -1) }
  qr/Parameter 'pivot_year' is out of range/,
  'resolve_century: pivot_year -1';

throws_ok { resolve_century(0, 9900) }
  qr/Parameter 'pivot_year' is out of range/,
  'resolve_century: pivot_year 9900';

done_testing();
