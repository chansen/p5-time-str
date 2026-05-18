#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

use Benchmark   qw[:hireswallclock];
use Time::HiRes qw[];
use Time::Str   qw[];

my $now = Time::HiRes::time;

printf "\nTime::Str::IMPLEMENTATION: %s\n", Time::Str::IMPLEMENTATION;

say "-" x 50;
say "Time: ", Time::Str::time2str($now);
say "-" x 50, "\n\n";

my %Benchmarks = (
  'gmtime' => sub {
    my $s = scalar gmtime $now;
  },
  'T::Str' => sub {
    my $s = Time::Str::time2str($now);
  },
);

eval {
  require DateTime;
  require DateTime::Format::ISO8601;
  my $dt     = DateTime->from_epoch(epoch => $now);
  my $format = DateTime::Format::ISO8601->new;
  $Benchmarks{'DT::F::ISO8601'} = sub {
    my $s = $format->format_datetime($dt);
  };
};

eval {
  require DateTime;
  require DateTime::Format::RFC3339;
  my $dt     = DateTime->from_epoch(epoch => $now);
  my $format = DateTime::Format::RFC3339->new;
  $Benchmarks{'DT::F::RFC3339'} = sub {
    my $s = $format->format_datetime($dt);
  };
};

eval {
  require Time::Moment;
  my $tm = Time::Moment->from_epoch($now);
  $Benchmarks{'T::Moment'} = sub {
    my $s = $tm->to_string;
  };
};

eval {
  require Time::Piece;
  my $tp = Time::Piece->gmtime($now);
  $Benchmarks{'T::Piece'} = sub {
    my $s = $tp->strftime('%Y%m%dT%H%M%S%z');
  };
};

Benchmark::cmpthese(-10, \%Benchmarks);

__END__

Perl v5.42 (M1 Pro)

                    Rate DT::F::ISO8601 DT::F::RFC3339 T::Piece T::Moment gmtime T::Str
DT::F::ISO8601   11911/s             --           -93%     -94%     -100%  -100%  -100%
DT::F::RFC3339  171086/s          1336%             --     -12%      -94%   -94%   -98%
T::Piece        193544/s          1525%            13%       --      -93%   -94%   -97%
T::Moment      2970987/s         24843%          1637%    1435%        --    -0%   -61%
gmtime         2981133/s         24928%          1642%    1440%        0%     --   -61%
T::Str         7582012/s         63556%          4332%    3817%      155%   154%     --
