package Time::Str;
use strict;
use warnings;
use v5.10.1;

our @EXPORT_OK   = qw[ time2str str2time str2date ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Exporter qw[import];

BEGIN {
  our $VERSION = '0.09';

  my @import;
  my $implementation = 'PP';

  eval {
    require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);
    $implementation = 'XS';
  } unless $ENV{TIME_STR_PP};

  if (!defined &Time::Str::time2str) {
    push @import, 'time2str';
  }

  if (!defined &Time::Str::str2time) {
    push @import, 'str2time';
  }

  if (!defined &Time::Str::str2date) {
    push @import, 'str2date';
  }

  if (@import) {
    require Time::Str::PP;
    Time::Str::PP->import(@import);
  }
  
  *IMPLEMENTATION = sub () { $implementation };
}

sub MIN_TIME () { -62135596800 } # 0001-01-01T00:00:00Z
sub MAX_TIME () { 253402300799 } # 9999-12-31T23:59:59Z

1;
