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

