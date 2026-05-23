#!/usr/bin/env perl
#
#  Verification of Time::TZif croak/later policies against
#  DateTime::TimeZone.
#
#  DateTime::TimeZone throws an exception for gap times and
#  resolves overlaps to the later (post-transition) offset.
#
#  Usage:
#    perl verify_datetime.pl [--tzdir /path/to/zoneinfo] [TZID ...]
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

use Getopt::Long                qw[GetOptions];
use DateTime::TimeZone          qw[];
use DateTime::TimeZone::Catalog qw[];
use Time::Moment                qw[];
use Time::TZif                  qw[];
use Util                        qw[find_tzdir tzdb_version];

my $TZDIR;

GetOptions('tzdir=s' => \$TZDIR)
  or die "Usage: $0 [--tzdir DIR] [TZID ...]\n";

$TZDIR //= find_tzdir();

my @TZIDS = @ARGV ? @ARGV : qw[ America/New_York
                                Australia/Lord_Howe
                                Europe/Stockholm ];

printf "IANA time zone database vesion: %s\n", 
  tzdb_version($TZDIR) // 'unknown';

printf "DateTime::TimeZone IANA time zone database vesion: %s\n", 
  DateTime::TimeZone::Catalog->OlsonVersion;

foreach my $TZID (@TZIDS) {
  my $filename = "${TZDIR}/${TZID}";
  unless (-f $filename) {
    say "\n=== $TZID === (skipped, file not found)";
    next;
  }

  say "\n=== $TZID ===";

  my $tz1 = DateTime::TimeZone->new(name => $TZID);
  my $tz2 = Time::TZif->new(
    filename       => $filename,
    gap_policy     => 'reject',
    overlap_policy => 'later',
  );

  my @times = $tz2->transitions_times;

  my @mismatches;
  my $tested = 0;
  my $max = @times;

  for (my $i = 0; $i < $max; $i++) {
    for (my $j = -24; $j < 24; $j++) {
      my $epoch = $times[$i] + ($j * 1800);

      my $tm = Time::Moment->from_epoch($epoch);

      my ($o1, $o2);
      my $e1 = !eval { $o1 = $tz2->offset_for_local($epoch);        1 };
      my $e2 = !eval { $o2 = $tz1->offset_for_local_datetime($tm);  1 };
 
      # Both raised an exception, skip
      next if $e1 && $e2;
 
      # One raised an exception, the other didn't
      if ($e1 || $e2) {
        push @mismatches, sprintf "    GAP DISAGREE i:%d epoch:%d tzif:%s dt:%s\n",
          $i, $epoch, ($e1 ? 'croaked' : $o1), ($e2 ? 'croaked' : $o2);
        next;
      }

      $tested++;
      next if $o1 == $o2;
      push @mismatches, sprintf "    MISMATCH i:%d epoch:%d o1:%d o2:%d diff:%d\n",
        $i, $epoch, $o1, $o2, $o1 - $o2;
    }
  }

  printf "  tested=%d mismatches=%d\n", $tested, scalar @mismatches;
  say @mismatches if @mismatches;
}

