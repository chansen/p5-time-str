package Time::Str::PP;
use strict;
use warnings;
use v5.10;

our @EXPORT_OK = qw[ time2str str2time str2date ];

our @CARP_NOT = qw[Time::Str::Token];

use Exporter qw[import];
use Carp     qw[croak];

use Time::Str::Token    qw[ parse_day
                            parse_day_name
                            parse_month
                            parse_meridiem
                            parse_tz_offset ];
use Time::Str::Calendar qw[ valid_ymd
                            ymd_to_dow
                            resolve_century ];

BEGIN {
  if ($^V ge v5.40) {
    builtin->import(qw(floor));
  }
  else {
    require POSIX; POSIX->import(qw(floor));
  }
}

sub MIN_TIME () { -62135596800 } # 0001-01-01T00:00:00Z
sub MAX_TIME () { 253402300799 } # 9999-12-31T23:59:59Z

sub NANOS_PER_SECOND  () { 1_000_000_000 }

BEGIN {
  *DEFAULT_PRECISION = (length pack('F', 0) > 8) ? sub () {9} : sub () {6};
}

sub DEFAULT_PIVOT_YEAR () { 1950 }

sub valid_hms {
    my ($h, $m, $s) = @_;
    return ($h >= 0 && $h <= 23
         && $m >= 0 && $m <= 59
         && $s >= 0 && ($s <= 59 || ($s == 60 && $h == 23 && $m == 59)));
}

my %CanonicalFormatName = (
  ansic      => 'ANSIC',
  asn1gt     => 'ASN.1 GeneralizedTime',
  asn1ut     => 'ASN.1 UTCTime',
  clf        => 'Common Log Format',
  datetime   => 'DateTime',
  ecmascript => 'ECMAScript',
  gitdate    => 'GitDate',
  iso8601    => 'ISO 8601',
  iso9075    => 'ISO 9075',
  rfc2616    => 'RFC 2616',
  rfc2822    => 'RFC 2822',
  rfc2822fws => 'RFC 2822 (Folding WS)',
  rfc3339    => 'RFC 3339',
  rfc3501    => 'RFC 3501',
  rfc4287    => 'RFC 4287',
  rfc5280    => 'RFC 5280',
  rfc5545    => 'RFC 5545',
  rfc9557    => 'RFC 9557',
  rubydate   => 'RubyDate',
  unixdate   => 'UnixDate',
  unixstamp  => 'UnixStamp',
  w3cdtf     => 'W3CDTF',
);

my (%RegexpMap, $RFC2616_Rx, $RFC3339_Rx);

BEGIN {
  require Time::Str::Regexp;
  %RegexpMap = Time::Str::Regexp::mapping();

  $RFC2616_Rx = $RegexpMap{rfc2616};
  $RFC3339_Rx = $RegexpMap{rfc3339};

  my %aliases = (
    atom       => 'rfc4287',
    ctime      => 'ansic',
    email      => 'rfc2822',
    generic    => 'datetime',
    git        => 'gitdate',
    http       => 'rfc2616',
    ical       => 'rfc5545',
    imap       => 'rfc3501',
    imf        => 'rfc2822',
    ixdtf      => 'rfc9557',
    javascript => 'ecmascript',
    rfc5322    => 'rfc2822',
    rfc7231    => 'rfc2616',
    rfc9051    => 'rfc3501',
    ruby       => 'rubydate',
    sql        => 'iso9075',
    unix       => 'unixdate',
    w3c        => 'w3cdtf',
    x509       => 'rfc5280',
  );

  while (my ($alias, $to) = each %aliases) {
    $RegexpMap{$alias} = $RegexpMap{$to};
    $CanonicalFormatName{$alias} = $CanonicalFormatName{$to};
  }
}

sub str2date {
  @_ & 1 or croak q/Usage: str2date(string [, format => 'RFC3339' ])/;
  my ($string, %p) = @_;

  my ($format, $regexp, $pivot_year) = ('rfc3339', $RFC3339_Rx);

  while (my ($name, $v) = each %p) {
    if ($name eq 'format') {
      $format = lc $v;
      $regexp = $RegexpMap{$format};
      (defined $regexp)
        or croak qq/Parameter 'format' is unknown: '$v'/;
    }
    elsif ($name eq 'pivot_year') {
      $pivot_year = $v;
      ($pivot_year >= 0 && $pivot_year <= 9899)
        or croak q/Parameter 'pivot_year' is out of range [0, 9899]/;
    }
    else {
      croak qq/Unrecognised named parameter: '$name'/;
    }
  }

  (defined $string && $string =~ $regexp)
    or croak qq/Unable to parse: string does not match the $CanonicalFormatName{$format} format/;

  my %r = %+;

  if (length $r{year} == 2) {
    $r{year} = resolve_century($r{year}, $pivot_year // DEFAULT_PIVOT_YEAR);
  }

  if (exists $r{month}) {
    $r{month} = parse_month($r{month});
  }

  if (exists $r{day}) {
    $r{day} = parse_day($r{day});
  }

  valid_ymd($r{year}, $r{month} // 1, $r{day} // 1)
    or croak q/Unable to parse: date is out of range/;

  if (exists $r{day_name}) {
    my $dow = parse_day_name(delete $r{day_name});

    ($dow == ymd_to_dow($r{year}, $r{month} // 1, $r{day} // 1))
      or croak q/Unable to parse: day name does not match date/;
  }

  if (exists $r{hour}) {

    if (exists $r{meridiem}) {
      my $meridiem = parse_meridiem(delete $r{meridiem}); 
      my $hour     = $r{hour};

      ($hour >= 1 && $hour <= 12)
        or croak q/Unable to parse: hour is out of range for 12-hour clock/;

      $r{hour} = ($hour == 12 ? $meridiem : $hour + $meridiem);
    }

    valid_hms($r{hour}, $r{minute} // 0, $r{second} // 0)
      or croak q/Unable to parse: time of day is out of range/;

    if (exists $r{fraction}) {
      my $f = delete $r{fraction};
      my $ns = $f * (10 ** (9 - length $f));

      if (exists $r{second}) {
        # HH.MM.SS.fraction
        $r{nanosecond} = $ns;
      }
      elsif (exists $r{minute}) {
        # HH.MM.fraction
        my $total_ns = $ns * 60;
        $r{second} = int($total_ns / NANOS_PER_SECOND);
        my $nsec = $total_ns % NANOS_PER_SECOND;
        if ($nsec != 0) {
          $r{nanosecond} = $nsec;
        }
      }
      else {
        # HH.fraction
        my $total_ns = $ns * 3600;
        my $min = int($total_ns / (60 * NANOS_PER_SECOND));
        $r{minute} = $min;
        $total_ns -= $min * 60 * NANOS_PER_SECOND;
        my $sec = int($total_ns / NANOS_PER_SECOND);
        my $nsec = $total_ns % NANOS_PER_SECOND;
        if ($sec != 0 || $nsec != 0) {
          $r{second} = $sec;
          if ($nsec != 0) {
            $r{nanosecond} = $nsec;
          }
        }
      }
    }

    if (exists $r{tz_offset}) {
      $r{tz_offset} = parse_tz_offset($r{tz_offset});
    }

    if (exists $r{tz_utc}) {
      $r{tz_offset} //= 0;
    }
  }

  if ($regexp == $RFC2616_Rx && !$r{tz_utc}) {
    $r{tz_utc} = 'GMT';
    $r{tz_offset} = 0;
  }

  {
    local @r{qw(tz_utc tz_abbrev tz_annotation)};
    $_ += 0 for values %r;
  }
  return wantarray ? %r : \%r;
}

sub str2time {
  @_ & 1 or croak q/Usage: str2time(string [, format => 'RFC3339' ])/;
  my ($string, %p) = @_;

  my $precision;

  if (exists $p{precision}) {
    $precision = delete $p{precision};
    ($precision >= 0 && $precision <= 9)
      or croak q/Parameter 'precision' is out of range [0, 9]/;
  }

  my $r = str2date($string, %p);

  (exists $r->{tz_offset})
    or croak q/Unable to convert: timestamp string without a UTC designator or numeric offset/;

  my ($Y, $M, $D, $h, $m, $s) = @$r{qw(year month day hour minute second)};
  $m //= 0;
  $s //= 0;

  my $rdn = do {
    use integer;
    if ($M < 3) {
      $Y--, $M += 12;
    }
    (1461 * $Y) / 4 - $Y / 100 + $Y / 400
      + $D + ((979 * $M - 2918) >> 5) - 306;
  };
  my $sod  = ($h * 60 + $m) * 60 + $s;
  my $time = ($rdn - 719163) * 86400 + $sod - $r->{tz_offset} * 60;
  if (exists $r->{nanosecond}) {
    my $scale    = 10 ** ($precision // DEFAULT_PRECISION);
    my $fraction = int($r->{nanosecond} * $scale / NANOS_PER_SECOND);
    $time += $fraction / $scale;
  }
  return $time;
}

{
  my @DoW = qw[Sun Mon Tue Wed Thu Fri Sat];
  my @MoY = qw[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec];

  sub format_offset_basic {
    my ($offset, $zulu) = @_;

    if ($offset == 0) {
      return $zulu;
    }
    else {
      my $sign = $offset < 0 ? -1 : 1;
      my $min  = abs $offset;
      return sprintf '%+.4d', $sign * int($min / 60) * 100 + $min % 60;
    }
  }

  sub format_offset_extended {
    my ($offset, $zulu) = @_;

    if ($offset == 0) {
      return $zulu;
    }
    else {
      my $sign = $offset < 0 ? ord '-' : ord '+';
      my $min  = abs $offset;
      return sprintf '%c%.2d:%.2d', $sign, int($min / 60), $min % 60;
    }
  }

  sub format_ASN1UT {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_basic($offset, 'Z');
    return sprintf '%02d%02d%02d%02d%02d%02d%s',
      ($year + 1900) % 100, $mon + 1, $mday, $hour, $min, $sec, $zstr;
  }

  sub format_ASN1GT {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_basic($offset, 'Z');
    return sprintf '%04d%02d%02d%02d%02d%02d%s%s',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $fraction, $zstr;
  }
  
  sub format_CLF {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%02d/%s/%04d:%02d:%02d:%02d%s %s',
      $mday, $MoY[$mon], $year + 1900, $hour, $min, $sec, $fraction, $zstr;
  }

  sub format_RFC2616 {
    my ($time, $offset) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    return sprintf '%s, %02d %s %04d %02d:%02d:%02d GMT',
      $DoW[$wday], $mday, $MoY[$mon], $year + 1900, $hour, $min, $sec;
  }

  sub format_RFC2822 {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%s, %d %s %04d %02d:%02d:%02d %s',
      $DoW[$wday], $mday, $MoY[$mon], $year + 1900, $hour, $min, $sec, $zstr;
  }
  
  sub format_RFC3501 {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%02d-%s-%04d %02d:%02d:%02d %s',
      $mday, $MoY[$mon], $year + 1900, $hour, $min, $sec, $zstr;
  }

  sub format_RFC3339 {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_extended($offset, 'Z');
    return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%s%s',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $fraction, $zstr;
  }

  sub TIME_20500101 () { 2524608000 }

  sub format_RFC5280 {
    my ($time) = @_;

    if ($time < TIME_20500101) {
      return format_ASN1UT($time, 0);
    }
    else {
      return format_ASN1GT($time, 0, '');
    }
  }

  sub format_RFC5545 {
    my ($time) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    return sprintf '%04d%02d%02dT%02d%02d%02dZ',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec;
  }

  sub format_ISO9075 {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_extended($offset, '+00:00');
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d%s %s',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $fraction, $zstr;
  }

  sub format_ECMAScript {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%s %s %02d %04d %02d:%02d:%02d GMT%s',
      $DoW[$wday], $MoY[$mon], $mday, $year + 1900, $hour, $min, $sec, $zstr;
  }

  sub format_ANSIC {
    my ($time) = @_;
    return scalar gmtime $time;
  }

  sub format_UnixDate {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, 'UTC');
    return sprintf '%s %s %2d %02d:%02d:%02d %s %04d',
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $zstr, $year + 1900;
  }

  sub format_UnixStamp {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, 'UTC');
    return sprintf '%s %s %2d %02d:%02d:%02d%s %s %04d',
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $fraction, $zstr, $year + 1900;
  }

  sub format_RubyDate {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%s %s %02d %02d:%02d:%02d %s %04d',
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $zstr, $year + 1900;
  }

  sub format_GitDate {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%s %s %d %02d:%02d:%02d %04d %s',
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $year + 1900, $zstr;
  }
}

my %FormatMap = (
  ansic      => \&format_ANSIC,
  asn1gt     => \&format_ASN1GT,
  asn1ut     => \&format_ASN1UT,
  atom       => \&format_RFC3339,
  clf        => \&format_CLF,
  ctime      => \&format_ANSIC,
  ecmascript => \&format_ECMAScript,
  email      => \&format_RFC2822,
  git        => \&format_GitDate,
  gitdate    => \&format_GitDate,
  http       => \&format_RFC2616,
  ical       => \&format_RFC5545,
  imap       => \&format_RFC3501,
  imf        => \&format_RFC2822,
  iso8601    => \&format_RFC3339,
  iso9075    => \&format_ISO9075,
  ixdtf      => \&format_RFC3339,
  javascript => \&format_ECMAScript,
  rfc2616    => \&format_RFC2616,
  rfc2822    => \&format_RFC2822,
  rfc2822fws => \&format_RFC2822,
  rfc3339    => \&format_RFC3339,
  rfc3501    => \&format_RFC3501,
  rfc4287    => \&format_RFC3339,
  rfc5280    => \&format_RFC5280,
  rfc5322    => \&format_RFC2822,
  rfc5545    => \&format_RFC5545,
  rfc7231    => \&format_RFC2616,
  rfc9051    => \&format_RFC3501,
  rfc9557    => \&format_RFC3339,
  ruby       => \&format_RubyDate,
  rubydate   => \&format_RubyDate,
  sql        => \&format_ISO9075,
  unix       => \&format_UnixDate,
  unixdate   => \&format_UnixDate,
  unixstamp  => \&format_UnixStamp,
  w3c        => \&format_RFC3339,
  w3cdtf     => \&format_RFC3339,
  x509       => \&format_RFC5280,
);

sub time2str {
  @_ & 1 or croak(q/Usage: time2str(time [, format => 'RFC3339' ])/);
  my ($time, %p) = @_;

  # Rejects NaN and Inf
  ($time >= MIN_TIME && $time < MAX_TIME + 1)
    or croak q/Parameter 'time' is out of range/;

  my ($formatter, $offset, $precision, $nanosecond) = (\&format_RFC3339, 0);

  while (my ($name, $v) = each %p) {
    if ($name eq 'format') {
      $formatter = $FormatMap{lc $v};
      (defined $formatter)
        or croak qq/Parameter 'format' is unknown: '$v'/;
    }
    elsif ($name eq 'precision') {
      $precision = $v;
      ($precision >= 0 && $precision <= 9)
        or croak q/Parameter 'precision' is out of range [0, 9]/;
    }
    elsif ($name eq 'nanosecond') {
      $nanosecond = $v;
      ($nanosecond >= 0 && $nanosecond <= 999_999_999)
        or croak q/Parameter 'nanosecond' is out of range [0, 999_999_999]/;
    }
    elsif ($name eq 'offset') {
      $offset = $v;
      ($offset >= -1439 && $offset <= 1439)
        or croak q/Parameter 'offset' is out of range [-1439, 1439]/;
    }
    else {
      croak qq/Unrecognised named parameter: '$name'/;
    }
  }

  if (!defined $nanosecond && int $time != $time) {
    my $sec   = floor($time);
    my $frac  = $time - $sec;
    my $scale = 10 ** ($precision // DEFAULT_PRECISION);

    $time = $sec;
    $frac = floor($frac * $scale + 0.5) / $scale;
    $nanosecond = floor($frac * NANOS_PER_SECOND + 0.5);

    if ($nanosecond >= NANOS_PER_SECOND) {
      $nanosecond -= NANOS_PER_SECOND;
      $time++;
    }
  }

  if ($offset) {
    my $local_time = $time + $offset * 60;

    # Most string formats cannot represent years outside 0001-9999;
    # an offset may shift a valid timestamp beyond that range
    ($local_time >= MIN_TIME && $local_time <= MAX_TIME)
      or croak q/Parameter 'time' is out of range for the given offset/;
  }

  my $fraction = '';
  if (defined $nanosecond || defined $precision) {

    if (!defined $precision) {
      if ($nanosecond == 0) {
        $precision = 0;
      }
      elsif (($nanosecond % 1_000_000) == 0) {
        $precision = 3;
      }
      elsif (($nanosecond % 1_000) == 0) {
        $precision = 6;
      }
      else {
        $precision = 9;
      }
    }

    if ($precision != 0) {
      $nanosecond //= 0;
      $fraction = sprintf '.%.*d',
        $precision, int($nanosecond / (10 ** (9 - $precision)));
    }
  }
  return $formatter->($time, $offset, $fraction);
}

1;
