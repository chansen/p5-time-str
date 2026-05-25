package Time::TZif::POSIX;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.86';

use Carp                qw[croak];
use Time::Str::Calendar qw[leap_year
                           month_days
                           ymd_to_dow 
                           yd_to_md 
                           rdn_to_ymd];
use Time::Str::Time     qw[timegm_modern];
use Time::Str::Util     qw[upper_bound];

my %ValidPolicy = (
  earlier => 1, later => 1, std => 1, dst => 1, reject => 1
);

use constant RDN_UNIX_EPOCH => 719163; # 1970-01-01

# POSIX TZ string (IEEE Std 1003.1)
#
#   std offset [dst [offset] , start [/time] , end [/time]]
#
# Examples:
#   EST5EDT,M3.2.0,M11.1.0          US Eastern
#   CET-1CEST,M3.5.0/2,M10.5.0/3    Central European
#   <+05>-5                         Fixed UTC+5
#   NZST-12NZDT,M9.5.0,M4.1.0/3     New Zealand
#
my $POSIX_TZ_Rx = qr{
  (?(DEFINE)
    (?<Name>   [A-Za-z]{3,} | [<][A-Za-z0-9+-]{3,}[>] )
    (?<Offset> [+-]? [0-9]{1,2} (?: [:][0-9]{2} (?: [:][0-9]{2} )? )? )
    (?<Time>   [+-]? [0-9]{1,3} (?: [:][0-9]{2} (?: [:][0-9]{2} )? )? )
    (?<Rule>   M [0-9]{1,2} [.] [1-5] [.] [0-6]
             | J [0-9]{1,3}
             |   [0-9]{1,3} )
  )

  \A
        (?<std_name>   (?&Name))         (?<std_offset> (?&Offset))
  (?:
        (?<dst_name>   (?&Name))         (?<dst_offset> (?&Offset) )?
    [,] (?<rule_start> (?&Rule)) (?: [/] (?<time_start> (?&Time))  )?
    [,] (?<rule_end>   (?&Rule)) (?: [/] (?<time_end>   (?&Time))  )?
  )?
  \z
}x;

my $Rule_Rx = qr{
  \A
  (?:
      M (?<month> [0-9]{1,2}) [.] (?<week> [1-5]) [.] (?<wday> [0-6])
    | J (?<jday>  [0-9]{1,3})
    |   (?<nday>  [0-9]{1,3})
  )
  \z
}x;

sub new {
  (@_ & 1 && @_ >= 3) or croak q/Usage: Time::TZif::POSIX->new(tz_string => $string)/;
  my ($class, %p) = @_;

  my ($tz_string, $gap_policy, $overlap_policy);

  while (my ($key, $v) = each %p) {
    if ($key eq 'tz_string') {
      $tz_string = $v;
    }
    elsif ($key eq 'gap_policy') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'gap_policy'/;
      $gap_policy = $v;
    }
    elsif ($key eq 'overlap_policy') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'overlap_policy'/;
      $overlap_policy = $v;
    }
    else {
      croak qq/Unrecognised named parameter: '$key'/;
    }
  }

  (defined $tz_string)
    or croak q/Parameter 'tz_string' is required/;

  $gap_policy     //= 'reject';
  $overlap_policy //= 'reject';

  my $self = bless {
    tz_string      => $tz_string,
    gap_policy     => $gap_policy,
    overlap_policy => $overlap_policy,
  }, $class;

  $self->_parse($tz_string);
  return $self;
}

sub tz_string      { $_[0]->{tz_string}      }
sub gap_policy     { $_[0]->{gap_policy}     }
sub overlap_policy { $_[0]->{overlap_policy} }

sub _parse_offset {
  my ($str) = @_;
  $str =~ /\A ([+-]?) ([0-9]{1,2}) (?: [:]([0-9]{2}) (?: [:]([0-9]{2}) )? )? \z/x
    or croak qq/Unable to parse POSIX TZ string: invalid offset '$str'/;
  my ($h, $m, $s) = ($2, $3 // 0, $4 // 0);
  ($h <= 24 && $m <= 59 && $s <= 59)
    or croak qq/Unable to parse POSIX TZ string: offset time is out of range: $str/;
  my $secs = $h * 3600 + $m * 60 + $s;
  return ($1 eq '-') ? -$secs : $secs;
}

sub _parse_rule_time {
  my ($str) = @_;
  $str =~ /\A ([+-]?) ([0-9]{1,3}) (?: [:]([0-9]{2}) (?: [:]([0-9]{2}) )? )? \z/x
    or croak qq/Unable to parse POSIX TZ string: invalid rule time '$str'/;
  my ($h, $m, $s) = ($2, $3 // 0, $4 // 0);
  ($h <= 167 && $m <= 59 && $s <= 59)
    or croak qq/Unable to parse POSIX TZ string: rule time is out of range: $str/;
  my $secs = $h * 3600 + $m * 60 + $s;
  return ($1 eq '-') ? -$secs : $secs;
}

sub _parse_rule {
  my ($rule_str, $time_str) = @_;

  my $time = defined $time_str ? _parse_rule_time($time_str) : 7200;

  $rule_str =~ $Rule_Rx
    or croak qq/Unable to parse POSIX TZ string: invalid rule '$rule_str'/;

  if (exists $+{month}) {
    my ($m, $w, $d) = @+{qw(month week wday)};
    ($m >= 1 && $m <= 12)
      or croak qq/Unable to parse POSIX TZ string: rule month out of range [1, 12]: $m/;
    return { type => 'M', m => $m, w => $w, d => $d, time => $time };
  }
  elsif (exists $+{jday}) {
    my $jday = $+{jday};
    ($jday >= 1 && $jday <= 365)
      or croak qq/Unable to parse POSIX TZ string: Julian day out of range [1, 365]: $jday/;
    return { type => 'J', day => $jday, time => $time };
  }
  else {
    my $nday = $+{nday};
    ($nday >= 0 && $nday <= 365)
      or croak qq/Unable to parse POSIX TZ string: zero-based day out of range [0, 365]: $nday/;
    return { type => 'N', day => $nday, time => $time };
  }
}

sub _parse {
  my ($self, $str) = @_;

  $str =~ $POSIX_TZ_Rx
    or croak qq/Unable to parse POSIX TZ string: '$str'/;

  my %m = %+;

  (my $std_name = $m{std_name}) =~ s/[<>]//g;
  my $std_offset = -_parse_offset($m{std_offset});

  ($std_offset >= -86400 && $std_offset <= 86400)
    or croak qq/Unable to parse POSIX TZ string: standard offset out of range: $std_offset/;

  $self->{std_type} = [$std_offset, 0, $std_name];

  return unless defined $m{dst_name};

  (my $dst_name = $m{dst_name}) =~ s/[<>]//g;

  my $dst_offset = defined $m{dst_offset}
    ? -_parse_offset($m{dst_offset})
    : $std_offset + 3600;

  ($dst_offset >= -86400 && $dst_offset <= 86400)
    or croak qq/Unable to parse POSIX TZ string: daylight offset out of range: $dst_offset/;

  $self->{dst_type}  = [$dst_offset, 1, $dst_name];
  $self->{dst_start} = _parse_rule($m{rule_start}, $m{time_start});
  $self->{dst_end}   = _parse_rule($m{rule_end},   $m{time_end});

  # Precompute the type sequence for the 3-year transition window.
  # For a given POSIX TZ string, DST start always falls before or
  # after DST end within each year (northern vs southern hemisphere).
  # This order never changes between years, so we determine it once
  # here and reuse the fixed type array in _transitions_for_time().
  # A leap year is used to avoid day-of-year overflow with n=365 rules.
  my ($t0, $t1) = $self->_transitions_for_year(2024);
  if ($t0 <= $t1) {
    # Northern: start < end -> types alternate dst, std
    $self->{types_3y} = [$self->{std_type},
                         ($self->{dst_type}, $self->{std_type}) x 3];
  }
  else {
    # Southern: end < start -> types alternate std, dst
    $self->{types_3y} = [$self->{dst_type},
                         ($self->{std_type}, $self->{dst_type}) x 3];
  }
}

# Returns day-of-month for the w-th occurrence of ISO weekday $dow
# (1=Mon..7=Sun) in the given month. $week=5 means last occurrence.
sub _nth_wday_of_month {
  my ($year, $month, $week, $dow) = @_;

  my $mdays = month_days($year, $month);

  if ($week == 5) {
    my $last_dow = ymd_to_dow($year, $month, $mdays);
    return $mdays - ($last_dow - $dow) % 7;
  }

  my $first_dow = ymd_to_dow($year, $month, 1);
  return 1 + ($dow - $first_dow) % 7 + ($week - 1) * 7;
}

# Resolves a transition rule to a UTC epoch for the given year.
# $offset is the UTC offset in effect before the transition (wall clock).
sub _rule_to_epoch {
  my ($self, $rule, $year, $offset) = @_;

  my ($month, $day);

  if ($rule->{type} eq 'M') {
    my $iso_dow = $rule->{d} == 0 ? 7 : $rule->{d};
    $month = $rule->{m};
    $day   = _nth_wday_of_month($year, $month, $rule->{w}, $iso_dow);
  }
  elsif ($rule->{type} eq 'J') {
    my $doy = $rule->{day};
    $doy++ if $doy >= 60 && leap_year($year);
    ($month, $day) = yd_to_md($year, $doy);
  }
  else {
    ($month, $day) = yd_to_md($year, $rule->{day} + 1);
  }

  # rule time is wall clock; subtract offset to convert to UTC
  return timegm_modern(0, 0, 0, $day, $month, $year) + $rule->{time} - $offset;
}

sub _transitions_for_year {
  my ($self, $year) = @_;

  my $t_start = $self->_rule_to_epoch(
    $self->{dst_start}, $year, $self->{std_type}[0]);
  my $t_end = $self->_rule_to_epoch(
    $self->{dst_end}, $year, $self->{dst_type}[0]);

  return ($t_start, $t_end);
}

sub _epoch_to_year {
  my ($epoch) = @_;
  use integer;
  my $days = $epoch / 86400;
  $days-- if $epoch < 0 && $epoch % 86400;
  my ($year) = rdn_to_ymd($days + RDN_UNIX_EPOCH);
  return $year;
}

# Returns (\@times, \@types) for the 3-year window around $time.
sub _transitions_for_time {
  my ($self, $time) = @_;

  my $year = _epoch_to_year($time);

  my @times;
  for my $y ($year - 1, $year, $year + 1) {
    my ($t_start, $t_end) = $self->_transitions_for_year($y);
    if ($t_start <= $t_end) {
      push @times, $t_start, $t_end;
    }
    else {
      push @times, $t_end, $t_start;
    }
  }

  return (\@times, $self->{types_3y});
}

sub _type_for_utc {
  my ($self, $time) = @_;

  return $self->{std_type} unless exists $self->{dst_start};

  my ($times, $types) = $self->_transitions_for_time($time);

  return $types->[ upper_bound($times, $time) ];
}

sub offset_for_utc {
  @_ == 2 or croak q/Usage: $tz->offset_for_utc($time)/;
  my ($self, $time) = @_;
  return $self->_type_for_utc($time)->[0];
}

sub type_info_for_utc {
  @_ == 2 or croak q/Usage: $tz->type_info_for_utc($time)/;
  my ($self, $time) = @_;
  return @{$self->_type_for_utc($time)};
}

sub offset_for_local {
  @_ >= 2 or croak q/Usage: $tz->offset_for_local($time, %opts)/;
  my $type = &_resolve_local;
  return $type->[0];
}

sub type_info_for_local {
  @_ >= 2 or croak q/Usage: $tz->type_info_for_local($time, %opts)/;
  my $type = &_resolve_local;
  return @$type;
}

sub _resolve_local {
  ((@_ & 1) == 0 && @_ >= 2) or croak q/Usage: $tz->offset_for_local($time, %opts)/;
  my ($self, $time, %p) = @_;

  my ($gap_policy, $overlap_policy);

  while (my ($key, $v) = each %p) {
    if ($key eq 'gap_policy') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'gap_policy'/;
      $gap_policy = $v;
    }
    elsif ($key eq 'overlap_policy') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'overlap_policy'/;
      $overlap_policy = $v;
    }
    else {
      croak qq/Unrecognised named parameter: '$key'/;
    }
  }

  return $self->{std_type} unless exists $self->{dst_start};

  my ($times, $types) = $self->_transitions_for_time($time);

  return $types->[0] unless @$times;

  my $result_idx = 0;

  for (my $i = 0; $i < @$times; $i++) {
    my $boundary = $time - $times->[$i];
    my $prev     = $types->[$i];
    my $next     = $types->[$i + 1];
    my $prev_off = $prev->[0];
    my $next_off = $next->[0];

    if ($prev_off < $next_off) {
      # Spring forward: gap in [prev_off, next_off)
      if ($prev_off <= $boundary && $boundary < $next_off) {
        $gap_policy //= $self->{gap_policy};
        return _apply_policy($gap_policy, $prev, $next,
          'Unable to resolve local time: non-existing time (gap)');
      }
      $result_idx = $i + 1 if $boundary >= $next_off;
    }
    elsif ($prev_off > $next_off) {
      # Fall back: overlap in [next_off, prev_off)
      if ($next_off <= $boundary && $boundary < $prev_off) {
        $overlap_policy //= $self->{overlap_policy};
        return _apply_policy($overlap_policy, $prev, $next,
          'Unable to resolve local time: ambiguous time (overlap)');
      }
      $result_idx = $i + 1 if $boundary >= $prev_off;
    }
    else {
      $result_idx = $i + 1 if $boundary >= $prev_off;
    }
  }

  return $types->[$result_idx];
}

sub _apply_policy {
  my ($policy, $prev, $next, $message) = @_;

  if    ($policy eq 'earlier') { return $prev }
  elsif ($policy eq 'later')   { return $next }
  elsif ($policy eq 'std') {
    return $prev->[1] ? $next : $prev;
  }
  elsif ($policy eq 'dst') {
    return $prev->[1] ? $prev : $next;
  }
  else {
    croak $message;
  }
}

1;
