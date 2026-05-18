#!/usr/bin/env perl
use strict;
use warnings;
use v5.10.1;

use Time::Str qw[];
use Benchmark qw[:hireswallclock];

my $time = Time::Str::str2time('2012-12-24T12:30:45.123456+01:00');

my @Formats = qw(
  ASN1GT
  ECMAScript
  RFC2616
  RFC2822
  RFC3339
  RFC4287
  W3CDTF
);

printf "\nTime::Str::IMPLEMENTATION: %s\n", Time::Str::IMPLEMENTATION;

my %Inputs;

say "-" x 50;

foreach my $format (@Formats) {
  my $string = Time::Str::time2str($time, format => $format);
  printf "%-10s '%s'\n", $format, $string;
  $Inputs{$format} = $string;
}

$Inputs{DateTime} = $Inputs{RFC3339};

say "-" x 50, "\n";

Benchmark::cmpthese( -10, {
  map {
    my ($fmt, $s) = ($_, $Inputs{$_});
    $fmt => sub { Time::Str::str2time($s, format => $fmt) };
  } keys %Inputs
});

