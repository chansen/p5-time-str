#!/usr/bin/env perl
#
#  Verification of Time::TZif against DateTime::TimeZone::Tzfile using
#  the same TZif file from Time::OlsonTZ::Data for both modules.
#
#  Time::TZif is configured with reject/later to match the behaviour of
#  DateTime::TimeZone::Tzfile, which throws an exception for gap times
#  and resolves overlaps to the later (post-transition) offset.
#
#  All canonical Olson zone names are tested.  For each zone, 48
#  half-hour steps from every transition time are probed and the two
#  modules compared.
#
use strict;
use warnings;
use v5.10;

use DateTime::TimeZone::Tzfile  qw[];
use Time::OlsonTZ::Data         qw[ olson_canonical_names
                                    olson_tzfile 
                                    olson_version ];
use Time::Moment                qw[];
use Time::TZif                  qw[];

printf "IANA time zone database vesion: %s\n", olson_version();

my $total_tested     = 0;
my $total_mismatches = 0;
my $total_zones      = 0;
my @failed_zones;

foreach my $TZID (sort keys %{olson_canonical_names()}) {
  my $filename = olson_tzfile($TZID);
  $total_zones++;

  my $tz1 = DateTime::TimeZone::Tzfile->new(filename => $filename);
  my $tz2 = Time::TZif->new(
    filename       => $filename,
    gap_policy     => 'reject',
    overlap_policy => 'later',
  );

  my $times = $tz2->{times}; # ooups, hack

  my @mismatches;
  my $tested = 0;
  my $max = @$times;

  for (my $i = 0; $i < $max; $i++) {
    for (my $j = -24; $j < 24; $j++) {
      my $epoch = $times->[$i] + ($j * 1800);

      my $tm = Time::Moment->from_epoch($epoch);

      my ($o1, $o2);
      my $e1 = !eval { $o1 = $tz2->offset_for_local($epoch);        1 };
      my $e2 = !eval { $o2 = $tz1->offset_for_local_datetime($tm);  1 };

      # Both raised an exception, skip
      next if $e1 && $e2;

      # One raised an exception, the other didn't
      if ($e1 || $e2) {
        push @mismatches, sprintf "    GAP DISAGREE i:%d epoch:%d tzif:%s dt:%s",
          $i, $epoch, ($e1 ? 'croaked' : $o1), ($e2 ? 'croaked' : $o2);
        next;
      }

      $tested++;
      next if $o1 == $o2;
      push @mismatches, sprintf "    MISMATCH i:%d epoch:%d o1:%d o2:%d diff:%d",
        $i, $epoch, $o1, $o2, $o1 - $o2;
    }
  }

  $total_tested     += $tested;
  $total_mismatches += scalar @mismatches;

  if (@mismatches) {
    push @failed_zones, $TZID;
    say "\n=== $TZID === tested=$tested mismatches=" . scalar @mismatches;
    say @mismatches;
  }
}

say "\n" . "=" x 60;
printf "Zones: %d  Tested: %d  Mismatches: %d  Failed: %d\n",
  $total_zones, $total_tested, $total_mismatches, scalar @failed_zones;
say "All zones passed." unless @failed_zones;

