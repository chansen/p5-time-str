#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

use Benchmark         qw[:hireswallclock];
use Getopt::Long      qw[GetOptions];
use Time::Str         qw[str2time time2str];
use Time::TZif::POSIX qw[];

my $POSIX_TZ = 'CET-1CEST,M3.5.0/2,M10.5.0/3';

GetOptions('tz-string=s' => \$POSIX_TZ)
  or die "Usage: $0 [--tz-string TZ] [timestamp]\n";

my $time = str2time(shift @ARGV // '2024-12-24T12:30:45Z');

say 'Time: ', time2str($time), " POSIX TZ: ${POSIX_TZ}";

my (%UTC_Bench, %Local_Bench);

# Time::TZif::POSIX
{
  my $tz = Time::TZif::POSIX->new(tz_string => $POSIX_TZ);
  $UTC_Bench{'Time::TZif::POSIX'} = sub {
    $tz->offset_for_utc($time);
  };
  $Local_Bench{'Time::TZif::POSIX'} = sub {
    $tz->offset_for_local($time);
  };
}

# DateTime::TimeZone::SystemV
eval {
  require DateTime;
  require DateTime::TimeZone::SystemV;
  my $tz = DateTime::TimeZone::SystemV->new(recipe => $POSIX_TZ);
  my $dt = DateTime->from_epoch(epoch => $time);
  $UTC_Bench{'DateTime::TimeZone::SystemV'} = sub {
    $tz->offset_for_datetime($dt);
  };
  $Local_Bench{'DateTime::TimeZone::SystemV'} = sub {
    $tz->offset_for_local_datetime($dt);
  };
};

say "\nUTC offset - UTC";
say "-" x 80;

Benchmark::cmpthese(-10, \%UTC_Bench);

say "\nUTC offset - Local";
say "-" x 80;

Benchmark::cmpthese(-10, \%Local_Bench);

__END__

Perl v5.42 (M1 Pro)

Time: 2024-12-24T12:30:45Z POSIX TZ: CET-1CEST,M3.5.0/2,M10.5.0/3

UTC offset - UTC
--------------------------------------------------------------------------------
                                 Rate DateTime::TimeZone::SystemV Time::TZif::POSIX
DateTime::TimeZone::SystemV   19212/s                          --              -99%
Time::TZif::POSIX           1452298/s                       7459%                --

UTC offset - Local
--------------------------------------------------------------------------------
                                Rate DateTime::TimeZone::SystemV Time::TZif::POSIX
DateTime::TimeZone::SystemV   9594/s                          --              -99%
Time::TZif::POSIX           725505/s                       7462%                --
