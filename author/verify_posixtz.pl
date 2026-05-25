#!/usr/bin/env perl
#
#  Verification of Time::TZif::POSIX against DateTime::TimeZone::SystemV.
#
#  Both modules parse the same POSIX TZ string.  For each test point
#  we compare offset_for_utc and offset_for_local.
#
#  DateTime::TimeZone::SystemV resolves overlaps to the numerically
#  lower offset (post-transition / standard) and throws on gaps.
#  We configure Time::TZif::POSIX with gap_policy=>'reject' and
#  overlap_policy=>'later' to match.
#
use strict;
use warnings;
use v5.10;

use DateTime::TimeZone::SystemV  qw[];
use Time::Moment                 qw[];
use Time::TZif::POSIX            qw[];

my @tests = (
  {
    # US Eastern - spring forward Mar 2nd Sun, fall back Nov 1st Sun
    posix_tz => 'EST5EDT,M3.2.0,M11.1.0',
    times    => [ qw( 2030-01-15T12:00:00Z
                      2030-06-15T12:00:00Z
                      2030-03-10T06:59:59Z
                      2030-03-10T07:00:00Z
                      2030-03-10T07:00:01Z
                      2030-03-10T08:00:00Z
                      2030-11-03T05:59:59Z
                      2030-11-03T06:00:00Z
                      2030-11-03T06:00:01Z
                      2030-11-03T07:00:00Z
                      2030-12-31T23:59:59Z
                      2031-01-01T00:00:00Z
                      2035-03-11T07:00:00Z
                      2035-11-04T06:00:00Z
                      2040-03-11T07:00:00Z
                      2040-11-04T06:00:00Z
                      2045-03-12T07:00:00Z
                      2045-11-05T06:00:00Z ) ],
  },
  {
    # Central European - last Sunday Mar/Oct, transition at /2 and /3
    posix_tz => 'CET-1CEST,M3.5.0/2,M10.5.0/3',
    times    => [ qw( 2030-01-15T12:00:00Z
                      2030-07-15T12:00:00Z
                      2030-03-31T00:59:59Z
                      2030-03-31T01:00:00Z
                      2030-03-31T01:00:01Z
                      2030-03-31T02:00:00Z
                      2030-10-27T00:59:59Z
                      2030-10-27T01:00:00Z
                      2030-10-27T01:00:01Z
                      2030-10-27T02:00:00Z
                      2035-03-25T01:00:00Z
                      2035-10-28T01:00:00Z
                      2040-03-25T01:00:00Z
                      2040-10-28T01:00:00Z
                      2045-03-26T01:00:00Z
                      2045-10-29T01:00:00Z ) ],
  },
  {
    # New Zealand - southern hemisphere, DST Sep-Apr
    posix_tz => 'NZST-12NZDT,M9.5.0,M4.1.0/3',
    times    => [ qw( 2030-01-15T00:00:00Z
                      2030-07-15T00:00:00Z
                      2030-09-29T13:59:59Z
                      2030-09-29T14:00:00Z
                      2030-09-29T14:00:01Z
                      2031-04-06T13:59:59Z
                      2031-04-06T14:00:00Z
                      2031-04-06T14:00:01Z
                      2030-12-31T23:59:59Z
                      2031-01-01T00:00:00Z
                      2035-09-30T14:00:00Z
                      2035-04-01T14:00:00Z
                      2040-09-30T14:00:00Z
                      2040-04-01T14:00:00Z ) ],
  },
  {
    # Fixed offset UTC+5
    posix_tz => '<+05>-5',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-31T23:59:59Z
                      2035-07-04T00:00:00Z
                      2040-01-01T00:00:00Z ) ],
  },
  {
    # Fixed offset UTC-3
    posix_tz => '<-03>3',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-31T23:59:59Z
                      2040-06-15T12:00:00Z ) ],
  },
  {
    # UTC
    posix_tz => 'UTC0',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2045-12-31T23:59:59Z ) ],
  },
  {
    # UK - GMT/BST, last Sunday Mar at 01:00 UT, last Sunday Oct
    posix_tz => 'GMT0BST,M3.5.0/1,M10.5.0',
    times    => [ qw( 2030-03-31T00:59:59Z
                      2030-03-31T01:00:00Z
                      2030-03-31T01:00:01Z
                      2030-10-27T00:59:59Z
                      2030-10-27T01:00:00Z
                      2030-10-27T01:00:01Z
                      2030-10-27T02:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-15T12:00:00Z ) ],
  },
  {
    # Australia Eastern - southern hemisphere, Oct-Apr
    posix_tz => 'AEST-10AEDT,M10.1.0,M4.1.0/3',
    times    => [ qw( 2030-01-15T00:00:00Z
                      2030-07-15T00:00:00Z
                      2030-10-06T15:59:59Z
                      2030-10-06T16:00:00Z
                      2030-10-06T16:00:01Z
                      2031-04-06T15:59:59Z
                      2031-04-06T16:00:00Z
                      2031-04-06T16:00:01Z
                      2030-12-31T23:59:59Z
                      2031-01-01T00:00:00Z ) ],
  },
  {
    # India - fixed +05:30 with minutes in offset
    posix_tz => 'IST-5:30',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-31T23:59:59Z
                      2040-01-01T00:00:00Z ) ],
  },
  {
    # Newfoundland - half-hour offset with DST, transition at 00:01
    posix_tz => 'NST3:30NDT,M3.2.0/0:01,M11.1.0/0:01',
    times    => [ qw( 2030-01-15T12:00:00Z
                      2030-06-15T12:00:00Z
                      2030-03-10T03:30:59Z
                      2030-03-10T03:31:00Z
                      2030-03-10T03:31:01Z
                      2030-11-03T03:30:59Z
                      2030-11-03T03:31:00Z
                      2030-11-03T03:31:01Z
                      2035-03-11T03:31:00Z
                      2035-11-04T03:31:00Z ) ],
  },
  {
    # Chatham Islands - +12:45/+13:45
    posix_tz => '<+1245>-12:45<+1345>,M9.5.0/2:45,M4.1.0/3:45',
    times    => [ qw( 2030-01-15T00:00:00Z
                      2030-07-15T00:00:00Z
                      2030-09-29T14:00:00Z
                      2031-04-06T14:00:00Z
                      2030-12-31T23:59:59Z ) ],
  },
  {
    # US Central
    posix_tz => 'CST6CDT,M3.2.0,M11.1.0',
    times    => [ qw( 2030-01-15T12:00:00Z
                      2030-06-15T12:00:00Z
                      2030-03-10T07:59:59Z
                      2030-03-10T08:00:00Z
                      2030-11-03T06:59:59Z
                      2030-11-03T07:00:00Z
                      2035-03-11T08:00:00Z
                      2040-11-04T07:00:00Z ) ],
  },
  {
    # US Mountain
    posix_tz => 'MST7MDT,M3.2.0,M11.1.0',
    times    => [ qw( 2030-03-10T08:59:59Z
                      2030-03-10T09:00:00Z
                      2030-11-03T07:59:59Z
                      2030-11-03T08:00:00Z ) ],
  },
  {
    # US Pacific
    posix_tz => 'PST8PDT,M3.2.0,M11.1.0',
    times    => [ qw( 2030-03-10T09:59:59Z
                      2030-03-10T10:00:00Z
                      2030-11-03T08:59:59Z
                      2030-11-03T09:00:00Z ) ],
  },
  {
    # Arizona - fixed MST, no DST
    posix_tz => 'MST7',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-31T23:59:59Z ) ],
  },
  {
    # Japan - fixed JST
    posix_tz => 'JST-9',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2045-12-31T23:59:59Z ) ],
  },
  {
    # Korea - fixed KST
    posix_tz => 'KST-9',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2045-06-15T12:00:00Z ) ],
  },
  {
    # Iran - +03:30/+04:30
    posix_tz => '<+0330>-3:30<+0430>,M3.3.0/0,M9.3.6/0',
    times    => [ qw( 2030-01-15T00:00:00Z
                      2030-06-15T00:00:00Z
                      2030-03-16T20:30:00Z
                      2030-09-20T19:30:00Z
                      2035-03-16T20:30:00Z
                      2035-09-21T19:30:00Z ) ],
  },
  {
    # Chile - southern hemisphere, first Sat Sep/Apr at 24:00
    posix_tz => '<-04>4<-03>,M9.1.6/24,M4.1.6/24',
    times    => [ qw( 2030-01-15T00:00:00Z
                      2030-07-15T00:00:00Z
                      2030-09-07T04:00:00Z
                      2031-04-05T03:00:00Z
                      2030-12-31T23:59:59Z ) ],
  },
  {
    # Paraguay - southern hemisphere
    posix_tz => '<-04>4<-03>,M10.1.0/0,M3.4.0/0',
    times    => [ qw( 2030-01-15T00:00:00Z
                      2030-07-15T00:00:00Z
                      2030-10-06T04:00:00Z
                      2031-03-23T03:00:00Z ) ],
  },
  {
    # Hawaii - fixed HST
    posix_tz => 'HST10',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-31T23:59:59Z ) ],
  },
  {
    # Fixed UTC+12
    posix_tz => '<+12>-12',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-31T23:59:59Z ) ],
  },
  {
    # Samoa - +13/+14
    posix_tz => '<+13>-13<+14>,M9.5.0/3,M4.1.0/4',
    times    => [ qw( 2030-01-15T00:00:00Z
                      2030-07-15T00:00:00Z
                      2030-09-29T14:00:00Z
                      2031-04-06T14:00:00Z ) ],
  },
  {
    # Year boundary - southern hemisphere across new year
    posix_tz => 'NZST-12NZDT,M9.5.0,M4.1.0/3',
    times    => [ qw( 2030-12-31T11:00:00Z
                      2030-12-31T12:00:00Z
                      2031-01-01T00:00:00Z
                      2031-01-01T12:00:00Z
                      2034-12-31T12:00:00Z
                      2035-01-01T00:00:00Z
                      2039-12-31T12:00:00Z
                      2040-01-01T00:00:00Z
                      2044-12-31T12:00:00Z
                      2045-01-01T00:00:00Z ) ],
  },
  {
    # Nepal - +05:45 with seconds-level offset precision
    posix_tz => '<+0545>-5:45',
    times    => [ qw( 2030-01-01T00:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-31T23:59:59Z ) ],
  },
  {
    # Eastern European - EET/EEST
    posix_tz => 'EET-2EEST,M3.5.0/3,M10.5.0/4',
    times    => [ qw( 2030-03-31T00:59:59Z
                      2030-03-31T01:00:00Z
                      2030-10-27T00:59:59Z
                      2030-10-27T01:00:00Z
                      2030-06-15T12:00:00Z
                      2030-12-15T12:00:00Z ) ],
  },
  {
    # Western European - WET/WEST (Portugal)
    posix_tz => 'WET0WEST,M3.5.0/1,M10.5.0',
    times    => [ qw( 2030-03-31T00:59:59Z
                      2030-03-31T01:00:00Z
                      2030-10-27T00:59:59Z
                      2030-10-27T01:00:00Z ) ],
  },
);

my $total_tested     = 0;
my $total_mismatches = 0;
my @failed;

for my $t (@tests) {
  my $posix_tz = $t->{posix_tz};

  my $tz = Time::TZif::POSIX->new(
    tz_string      => $posix_tz,
    gap_policy     => 'reject',
    overlap_policy => 'later',
  );

  my $dt = DateTime::TimeZone::SystemV->new(
    recipe => $posix_tz,
    system => 'tzfile3',
  );

  my @mismatches;
  my $tested = 0;

  for my $ts (@{$t->{times}}) {
    my $tm = Time::Moment->from_string($ts);
    my $epoch = $tm->epoch;

    my $u1 = $tz->offset_for_utc($epoch);
    my $u2 = $dt->offset_for_datetime($tm);

    if ($u1 != $u2) {
      push @mismatches, sprintf "    UTC   %s  tz:%d dt:%d diff:%d", 
        $ts, $u1, $u2, $u1 - $u2;
    }

    my ($l1, $l2);
    my $e1 = !eval { $l1 = $tz->offset_for_local($epoch);       1 };
    my $e2 = !eval { $l2 = $dt->offset_for_local_datetime($tm); 1 };

    # Both raised an exception, skip
    next if $e1 && $e2;

    # One raised an exception, the other didn't
    if ($e1 || $e2) {
      push @mismatches, sprintf "    GAP   %s  tz:%s dt:%s",
        $ts, ($e1 ? 'croaked' : $l1), ($e2 ? 'croaked' : $l2);
      next;
    }

    $tested++;
    next if $l1 == $l2;

    push @mismatches, sprintf "    LOCAL %s  tz:%d dt:%d diff:%d", 
      $ts, $l1, $l2, $l1 - $l2;
  }

  $total_tested += $tested;
  $total_mismatches += @mismatches;

  if (@mismatches) {
    push @failed, $posix_tz;
    printf "\n=== %s === tested=%d mismatches=%d\n",
      $posix_tz, $tested, scalar @mismatches;
    say for @mismatches;
  }
}

print "\n", "=" x 50, "\n";
printf "Strings: %d  Tested: %d  Mismatches: %d  Failed: %d\n",
  scalar @tests, $total_tested, $total_mismatches, scalar @failed;
say "All passed." unless @failed;
