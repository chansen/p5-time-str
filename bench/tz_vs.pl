#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

use Benchmark     qw[:hireswallclock];
use Getopt::Long  qw[GetOptions];
use Time::Str     qw[str2time time2str];
use Time::TZif    qw[];

my $TZDIR = '/usr/share/zoneinfo';
my $TZID  = 'Europe/Stockholm';

GetOptions('tzdir=s' => \$TZDIR, 'tzid=s' => \$TZID)
  or die "Usage: $0 [--tzdir DIR] [--tzid TZID] [timestamp]\n";

my $time     = str2time(shift @ARGV // '2024-12-24T12:30:45Z');
my $filename = "${TZDIR}/${TZID}";

say 'Time: ', time2str($time), " TZID: ${TZID}";

my (%UTC_Bench, %Local_Bench);

# Time::TZif
{
  my $tz = Time::TZif->new(filename => $filename);
  $UTC_Bench{'Time::TZif'} = sub {
    $tz->offset_for_utc($time);
  };
  $Local_Bench{'Time::TZif'} = sub {
    $tz->offset_for_local($time);
  };
}

# DateTime::TimeZone
eval {
  require DateTime;
  require DateTime::TimeZone;
  my $tz = DateTime::TimeZone->new(name => $TZID);
  my $dt = DateTime->from_epoch(epoch => $time);
  $UTC_Bench{'DateTime'} = sub {
    $tz->offset_for_datetime($dt);
  };
  $Local_Bench{'DateTime'} = sub {
    $tz->offset_for_local_datetime($dt);
  };
};

# DateTime::TimeZone::Tzfile
eval {
  require DateTime;
  require DateTime::TimeZone::Tzfile;
  my $tz = DateTime::TimeZone::Tzfile->new($filename);
  my $dt = DateTime->from_epoch(epoch => $time);
  $UTC_Bench{'DateTime::Tzfile'} = sub {
    $tz->offset_for_datetime($dt);
  };
  $Local_Bench{'DateTime::Tzfile'} = sub {
    $tz->offset_for_local_datetime($dt);
  };
};

# DateTime::Lite::TimeZone
eval {
  require DateTime::Lite;
  require DateTime::Lite::TimeZone;
  my $tz = DateTime::Lite::TimeZone->new(name => $TZID);
  my $dt = DateTime::Lite->from_epoch(epoch => $time);
  $UTC_Bench{'DateTime::Lite'} = sub {
    $tz->offset_for_datetime($dt);
  };
  $Local_Bench{'DateTime::Lite'} = sub {
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

Time: 2024-12-24T12:30:45Z TZID: Europe/Stockholm

UTC offset - UTC
--------------------------------------------------------------------------------
                      Rate DateTime::Lite   DateTime DateTime::Tzfile Time::TZif
DateTime::Lite     76853/s             --       -88%             -90%       -99%
DateTime          657902/s           756%         --             -13%       -88%
DateTime::Tzfile  754143/s           881%        15%               --       -86%
Time::TZif       5278211/s          6768%       702%             600%         --

UTC offset - Local
--------------------------------------------------------------------------------
                      Rate DateTime::Lite DateTime::Tzfile   DateTime Time::TZif
DateTime::Lite     75487/s             --             -88%       -88%       -96%
DateTime::Tzfile  605619/s           702%               --        -7%       -68%
DateTime          653492/s           766%               8%         --       -66%
Time::TZif       1903376/s          2421%             214%       191%         --

