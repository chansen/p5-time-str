#!/usr/bin/env perl
use strict;
use warnings;
use v5.10.1;

use Time::Str qw[];
use Benchmark qw[:hireswallclock];

printf "\nTime::Str::IMPLEMENTATION: %s\n", Time::Str::IMPLEMENTATION;

my $Input = '2012-12-24T12:30:45.123456+01:00';

say "-" x 50;
say "String: $Input";
say "-" x 50, "\n\n";

my %Benchmarks = (
  'T::Str' => sub {
    my $t = Time::Str::str2time($Input);
  },
);

eval {
  require DateTime::Format::ISO8601;
  my $format = DateTime::Format::ISO8601->new;
  $Benchmarks{'DT::F::ISO8601'} = sub {
    my $dt = $format->parse_datetime($Input);
  };
};

eval {
  require DateTime::Format::RFC3339;
  my $format = DateTime::Format::RFC3339->new;
  $Benchmarks{'DT::F::RFC3339'} = sub {
    my $dt = $format->parse_datetime($Input);
  };
};

eval {
  require Date::Parse;
  $Benchmarks{'D::Parse'} = sub {
    my $t = Date::Parse::str2time($Input);
  };
};

eval {
  require Time::Piece;
  Time::Piece->VERSION('1.41'); # Added support for %f (parsed, but discarded)
  $Benchmarks{'T::Piece'} = sub {
    my $tp = Time::Piece->strptime($Input, '%Y-%m-%dT%H:%M:%S.%f%z');
  };
};

eval {
  require Time::Moment;
  $Benchmarks{'T::Moment'} = sub {
    my $tm = Time::Moment->from_string($Input);
  };
};

Benchmark::cmpthese(-10, \%Benchmarks);

__END__

Perl v5.42 (M1 Pro)

                    Rate DT::F::ISO8601 DT::F::RFC3339 D::Parse T::Piece T::Moment T::Str
DT::F::ISO8601   19649/s             --           -33%     -81%     -97%     -100%  -100%
DT::F::RFC3339   29267/s            49%             --     -72%     -96%      -99%  -100%
D::Parse        106132/s           440%           263%       --     -86%      -98%   -99%
T::Piece        775222/s          3845%          2549%     630%       --      -85%   -92%
T::Moment      5166956/s         26197%         17554%    4768%     567%        --   -46%
T::Str         9487759/s         48187%         32317%    8840%    1124%       84%     --
