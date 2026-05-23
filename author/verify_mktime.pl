#!/usr/bin/env perl
#
#  Verification of Time::TZif std/dst policies against POSIX::mktime
#  with explicit tm_isdst values (0 = standard time, 1 = daylight saving).
#
#  We only compare epochs where Time::TZif's is_dst flag matches the
#  isdst being tested. Unambiguous times with a mismatched isdst are
#  skipped because mktime's behaviour in that case is to apply the
#  "wrong" offset and normalise - producing a different time_t that
#  doesn't reflect a real disagreement about the timezone rules.
#
#  Known residual mismatches (historical data discrepancies, not
#  algorithm bugs):
#
#    Europe/Stockholm (~1945-09-30, wartime DST)
#      mktime and TZif disagree by 3600s on a historical war-time
#      transition where the DST structure is unusual.
#
#    Australia/Lord_Howe (early transitions, 1981-1985)
#      mktime and TZif disagree by ±1800s (the 30-minute DST offset).
#      The is_dst labelling of the two sides of these early overlap
#      transitions differs between the system's mktime and the TZif
#      file. Later transitions (post-1985) match perfectly.
#
#  Usage:
#    perl verify_mktime.pl [--tzdir /path/to/zoneinfo] [TZID ...]
#
#  Defaults to /usr/share/zoneinfo and a built-in set of zones if no
#  arguments are provided.
#
use strict;
use warnings;
use v5.10;

BEGIN {
  require FindBin;
  require lib;
  lib->import(qq[$FindBin::Bin/lib]);
}

use Getopt::Long  qw[GetOptions];
use POSIX         qw[mktime];
use Time::TZif    qw[];
use Util          qw[find_tzdir tzdb_version];

my $TZDIR;

GetOptions('tzdir=s' => \$TZDIR)
  or die "Usage: $0 [--tzdir DIR] [TZID ...]\n";

$TZDIR //= find_tzdir();

printf "IANA time zone database vesion: %s\n", 
  tzdb_version($TZDIR) // 'unknown';

my @TZIDS = @ARGV ? @ARGV : qw[ America/New_York
                                Australia/Lord_Howe
                                Europe/Stockholm ];

foreach my $TZID (@TZIDS) {
  my $filename = "${TZDIR}/${TZID}";
  unless (-f $filename) {
    say "\n=== $TZID === (skipped, file not found)";
    next;
  }

  say "\n=== $TZID ===";

  $ENV{TZ} = $TZID;

  for my $isdst (0, 1) {
    my $policy = $isdst ? 'dst' : 'std';

    my $tz = Time::TZif->new(
      filename       => $filename,
      gap_policy     => $policy,
      overlap_policy => $policy,
    );

    my $times = $tz->{times}; # ooups, hack

    my @mismatches;
    my $tested = 0;
    my $max = @$times;

    for (my $i = 0; $i < $max; $i++) {
      for (my $j = -24; $j < 24; $j++) {
        my $epoch = $times->[$i] + ($j * 1800);

        my @gm = gmtime($epoch);
        my ($o, $is_dst) = $tz->type_info_for_local($epoch);
        next unless $is_dst == $isdst;

        my $t1 = $epoch - $o;
        my $t2 = mktime(@gm[0..5], 0, 0, $isdst);

        $tested++;
        next unless defined $t2;
        next if $t1 == $t2;
        push @mismatches, sprintf "    MISMATCH i:%d isdst:%d epoch:%d t1:%d t2:%d diff:%d\n",
          $i, $isdst, $epoch, $t1, $t2, $t1 - $t2;
      }
    }

    printf "  isdst=%d (%s/%s) tested=%d mismatches=%d\n",
      $isdst, $policy, $policy, $tested, scalar @mismatches;
    say @mismatches if @mismatches;
  }
}

