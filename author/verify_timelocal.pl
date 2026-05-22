#!/usr/bin/env perl
#
#  Verification of Time::TZif earlier/earlier policies against
#  Time::Local::timelocal_posix.
#
#  Time::Local folds gap times back into the pre-transition period and
#  resolves overlaps to the earlier (pre-transition) offset.
#
#  Known residual mismatches:
#
#    Australia/Lord_Howe (30-minute DST transitions)
#      Time::Local's overlap detection uses a hardcoded SECS_PER_HOUR
#      (3600s) probe, which overshoots Lord Howe's 30-minute DST
#      change, causing incorrect resolution at overlap boundaries.
#
#  Usage:
#    perl verify_timelocal.pl [--tzdir /path/to/zoneinfo] [TZID ...]
#
#  Defaults to /usr/share/zoneinfo and a built-in set of zones if no
#  arguments are provided.
#
use strict;
use warnings;
use v5.10;

use Getopt::Long  qw[GetOptions];
use Time::Local   qw[timelocal_posix];
use Time::TZif    qw[];

my $TZDIR = '/usr/share/zoneinfo';

GetOptions('tzdir=s' => \$TZDIR)
  or die "Usage: $0 [--tzdir DIR] [TZID ...]\n";

my @TZIDS = @ARGV ? @ARGV : qw[Europe/Stockholm US/Eastern Australia/Lord_Howe];

foreach my $TZID (@TZIDS) {
  my $filename = "${TZDIR}/${TZID}";
  unless (-f $filename) {
    say "\n=== $TZID === (skipped, file not found)";
    next;
  }

  say "\n=== $TZID ===";

  $ENV{TZ} = $TZID;

  my $tz = Time::TZif->new(
    filename       => $filename,
    gap_policy     => 'earlier',
    overlap_policy => 'earlier',
  );

  my $times = $tz->{times}; # ooups, hack

  my @mismatches;
  my $tested = 0;
  my $max = @$times;

  for (my $i = 0; $i < $max; $i++) {
    for (my $j = -24; $j < 24; $j++) {
      my $epoch = $times->[$i] + ($j * 1800);

      my @gm = gmtime($epoch);
      my $o  = $tz->offset_for_local($epoch);

      my $t1 = $epoch - $o;
      my $t2 = timelocal_posix(@gm[0..5]);

      $tested++;
      next if $t1 == $t2;
      push @mismatches, sprintf "    MISMATCH i:%d epoch:%d t1:%d t2:%d diff:%d\n",
        $i, $epoch, $t1, $t2, $t1 - $t2;
    }
  }

  printf "  tested=%d mismatches=%d\n", $tested, scalar @mismatches;
  say @mismatches if @mismatches;
}

