package Time::Str;
use strict;
use warnings;
use v5.10.1;

use Exporter qw[import];

BEGIN {
  our $VERSION     = '0.60';
  our @EXPORT_OK   = qw[ str2date
                         str2time
                         time2str ];
  our %EXPORT_TAGS = ( all => \@EXPORT_OK );

  my $xs_loaded = 0;
  eval {
    require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);
    $xs_loaded = 1;
  } unless $ENV{TIME_STR_PP};

  unless ($xs_loaded) {
    require Time::Str::PP;
    Time::Str::PP->import(@EXPORT_OK);
  }

  eval sprintf <<'EOC', $xs_loaded ? 'XS' : 'PP';
sub IMPLEMENTATION () { '%s' }
EOC
  die $@ if $@;
}

sub MIN_TIME () { -62135596800 } # 0001-01-01T00:00:00Z
sub MAX_TIME () { 253402300799 } # 9999-12-31T23:59:59Z

1;
