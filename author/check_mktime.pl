#!/usr/bin/env perl
#
#  Brute-force search for the Time::TZif gap/overlap policy combination
#  that matches POSIX::mktime with tm_isdst = -1 (system decides).
#
#  For each zone, every combination of gap policy (earlier, std) and
#  overlap policy (earlier, later, std, dst) is tested against mktime.
#  The test probes 48 half-hour steps centred on each transition time
#  and compares the UTC epoch produced by Time::TZif::offset_for_local
#  with the one returned by mktime for the same broken-down local time.
#
#  A mismatch count of 0 indicates a perfect policy match for that zone.
#  The behaviour of mktime with tm_isdst = -1 is unspecified by the C
#  standard and varies across platforms, so no single policy combination
#  is guaranteed to produce 0 mismatches on all systems.
#
#  Usage:
#    perl check_mktime.pl [--tzdir DIR] [TZID ...]
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

my @TZIDS = @ARGV ? @ARGV : qw[Europe/Stockholm America/New_York Australia/Lord_Howe];

foreach my $TZID (@TZIDS) {
  my $filename = "${TZDIR}/${TZID}";
  unless (-f $filename) {
    say "\n=== $TZID === (skipped, file not found)";
    next;
  }

  say "\n=== $TZID ===";

  $ENV{TZ} = $TZID;

  for my $pg (qw(earlier std)) {
    for my $po (qw(earlier later std dst)) {
      my $tz = Time::TZif->new(
        filename       => $filename,
        gap_policy     => $pg,
        overlap_policy => $po,
      );

      my $times = $tz->{times}; # ooups, hack

      my $mismatches = 0;
      my $max = @$times;

      for (my $i = 0; $i < $max; $i++) {
        for (my $j = -24; $j < 24; $j++) {
          my $epoch = $times->[$i] + ($j * 1800);

          my @lt = gmtime($epoch);
          my $t1 = $epoch - $tz->offset_for_local($epoch);
          my $t2 = mktime(@lt[0..5]);

          next unless defined $t2;
          next if $t1 == $t2;
          $mismatches++;
        }
      }

      printf "  gap=%-8s overlap=%-8s mismatches=%d\n", $pg, $po, $mismatches;
    }
  }
}

__END__

Linux (glibc):

=== Europe/Stockholm ===
  gap=earlier  overlap=earlier  mismatches=0
  gap=earlier  overlap=later    mismatches=119
  gap=earlier  overlap=std      mismatches=118
  gap=earlier  overlap=dst      mismatches=1
  gap=std      overlap=earlier  mismatches=0
  gap=std      overlap=later    mismatches=119
  gap=std      overlap=std      mismatches=118
  gap=std      overlap=dst      mismatches=1

=== US/Eastern ===
  gap=earlier  overlap=earlier  mismatches=0
  gap=earlier  overlap=later    mismatches=235
  gap=earlier  overlap=std      mismatches=234
  gap=earlier  overlap=dst      mismatches=1
  gap=std      overlap=earlier  mismatches=0
  gap=std      overlap=later    mismatches=235
  gap=std      overlap=std      mismatches=234
  gap=std      overlap=dst      mismatches=1

=== Australia/Lord_Howe ===
  gap=earlier  overlap=earlier  mismatches=0
  gap=earlier  overlap=later    mismatches=62
  gap=earlier  overlap=std      mismatches=60
  gap=earlier  overlap=dst      mismatches=2
  gap=std      overlap=earlier  mismatches=0
  gap=std      overlap=later    mismatches=62
  gap=std      overlap=std      mismatches=60
  gap=std      overlap=dst      mismatches=2


macOS (BSD libc):

=== Europe/Stockholm ===
  gap=earlier  overlap=earlier  mismatches=37
  gap=earlier  overlap=later    mismatches=105
  gap=earlier  overlap=std      mismatches=105
  gap=earlier  overlap=dst      mismatches=37
  gap=std      overlap=earlier  mismatches=41
  gap=std      overlap=later    mismatches=109
  gap=std      overlap=std      mismatches=109
  gap=std      overlap=dst      mismatches=41

=== US/Eastern ===
  gap=earlier  overlap=earlier  mismatches=56
  gap=earlier  overlap=later    mismatches=178
  gap=earlier  overlap=std      mismatches=178
  gap=earlier  overlap=dst      mismatches=56
  gap=std      overlap=earlier  mismatches=56
  gap=std      overlap=later    mismatches=178
  gap=std      overlap=std      mismatches=178
  gap=std      overlap=dst      mismatches=56

=== Australia/Lord_Howe ===
  gap=earlier  overlap=earlier  mismatches=7
  gap=earlier  overlap=later    mismatches=61
  gap=earlier  overlap=std      mismatches=61
  gap=earlier  overlap=dst      mismatches=7
  gap=std      overlap=earlier  mismatches=7
  gap=std      overlap=later    mismatches=61
  gap=std      overlap=std      mismatches=61
  gap=std      overlap=dst      mismatches=7

