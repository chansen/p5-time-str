package Time::TZif;
use strict;
use warnings;
use v5.10;

use Carp qw[croak];

our $VERSION = '0.85';

my %ValidPolicy = (
  earlier => 1, later => 1, std => 1, dst => 1, croak => 1
);

use constant TZIF_MAGIC           =>  0x545A6966;
use constant TZIF_MAX_TRANSITIONS =>  2400;

use constant HAS_QUAD => eval { my $x = pack('q>', 0); 1 };

sub new {
  (@_ & 1 && @_ >= 3) or croak q/Usage: Time::TZif->new(filename => $filename)/;
  my ($class, %p) = @_;

  my ($filename, $on_gap, $on_overlap);

  while (my ($name, $v) = each %p) {
    if ($name eq 'filename') {
      $filename = $v;
    }
    elsif ($name eq 'on_gap') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'on_gap'/;
      $on_gap = $v;
    }
    elsif ($name eq 'on_overlap') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'on_overlap'/;
      $on_overlap = $v;
    }
    else {
      croak qq/Unrecognised named parameter: '$name'/;
    }
  }

  (defined $filename)
    or croak q/Parameter 'filename' is required/;

  $on_gap     //= 'croak';
  $on_overlap //= 'croak';

  open(my $fh, '<:raw', $filename)
    or croak qq/Unable to parse TZif: could not open '$filename': '$!'/;

  my $self = bless {
    filename   => $filename,
    on_gap     => $on_gap,
    on_overlap => $on_overlap,
  }, $class;

  $self->_parse($fh);
  close($fh);
  return $self;
}

sub filename   { $_[0]->{filename}   }
sub on_gap     { $_[0]->{on_gap}     }
sub on_overlap { $_[0]->{on_overlap} }

sub _readn {
  my ($fh, $len) = @_;
  my $got = read($fh, my $buf, $len);
  (defined $got)
    or croak qq/Unable to parse TZif: could not read from filehandle: '$!'/;
  ($got == $len)
    or croak qq/Unable to parse TZif: premature end of data (got: $got, expected: $len)/;
  return $buf;
}

sub _parse {
  my ($self, $fh) = @_;

  my ($magic, $version, @counts) = unpack('N a x15 N6', _readn($fh, 44));

  ($magic == TZIF_MAGIC)
    or croak q/Unable to parse TZif: not a TZif file/;

  my ($isutcnt, $isstdcnt, $leapcnt, $timecnt, $typecnt, $charcnt) = @counts;

  if (HAS_QUAD && ($version eq '2' || $version eq '3')) {
    # Skip v1 data block
    my $v1_size = $timecnt * 4
                + $timecnt
                + $typecnt * 6
                + $charcnt
                + $leapcnt * 8
                + $isstdcnt
                + $isutcnt;

    _readn($fh, $v1_size) if $v1_size;

    # Parse v2/v3 header
    ($magic, $version, @counts) = unpack('N a x15 N6', _readn($fh, 44));

    ($magic == TZIF_MAGIC)
      or croak q/Unable to parse TZif: invalid v2\/v3 header/;

    ($isutcnt, $isstdcnt, $leapcnt, $timecnt, $typecnt, $charcnt) = @counts;

    $self->_parse_data($fh, $timecnt, $typecnt, $charcnt,
                       $leapcnt, $isstdcnt, $isutcnt, 8);

    # Read POSIX TZ string footer
    my $nl = _readn($fh, 1);
    ($nl eq "\n")
      or croak q/Unable to parse TZif: expected newline before POSIX TZ string/;

    my $posix_tz = '';
    while (1) {
      my $byte = eval { _readn($fh, 1) };
      last unless defined $byte;
      last if $byte eq "\n";
      $posix_tz .= $byte;
    }
    $self->{posix_tz} = $posix_tz if length $posix_tz;
  }
  else {
    $self->_parse_data($fh, $timecnt, $typecnt, $charcnt,
                       $leapcnt, $isstdcnt, $isutcnt, 4);
  }
}

sub _parse_data {
  my ($self, $fh, $timecnt, $typecnt, $charcnt,
      $leapcnt, $isstdcnt, $isutcnt, $time_size) = @_;

  ($typecnt >= 1)
    or croak q/Unable to parse TZif: must have at least one type/;
  ($timecnt <= TZIF_MAX_TRANSITIONS)
    or croak qq/Unable to parse TZif: too many transitions: $timecnt (max: @{[TZIF_MAX_TRANSITIONS]})/;

  my $time_fmt = ($time_size == 8) ? 'q>' : 'l>';

  # Transition times
  my @times = unpack("(${time_fmt})*", _readn($fh, $timecnt * $time_size));

  # Transition type indices
  my @type_indices = unpack('C*', _readn($fh, $timecnt));

  foreach my $idx (@type_indices) {
    ($idx < $typecnt)
      or croak qq/Unable to parse TZif: invalid type index: $idx (max: @{[$typecnt - 1]})/;
  }

  # Type info records: 6 bytes each (offset[4] + dst[1] + abbridx[1])
  my @types;
  for (my $i = 0; $i < $typecnt; $i++) {
    my ($offset, $dst, $abbridx) = unpack 'l> C C', _readn($fh, 6);

    ($offset > -86400 && $offset < 86400)
      or croak qq/Unable to parse TZif: invalid UTC offset: $offset/;
    ($dst == 0 || $dst == 1)
      or croak qq/Unable to parse TZif: invalid DST flag: $dst/;
    ($abbridx < $charcnt)
      or croak qq/Unable to parse TZif: invalid abbreviation index: $abbridx/;

    $types[$i] = [$offset, $dst, $abbridx];
  }

  # Abbreviation characters (NUL-terminated strings)
  my $abbr_buf = _readn($fh, $charcnt);
  my %abbrs;
  {
    my $pos = 0;
    foreach my $str (split /\x00/, $abbr_buf, -1) {
      $abbrs{$pos} = $str;
      $pos += 1 + length $str;
    }
  }

  # Skip remaining: leap seconds, std/wall, ut/local indicators
  my $leap_rec_size = ($time_size == 8) ? 12 : 8;
  my $skip = $leapcnt * $leap_rec_size + $isstdcnt + $isutcnt;
  _readn($fh, $skip) if $skip;

  # Resolve abbreviation indices to strings
  foreach my $type (@types) {
    $type->[2] = $abbrs{ $type->[2] } // '';
  }

  # Find first standard (non-DST) type as the default for pre-transition times
  my $first_std = $types[0];
  foreach my $type (@types) {
    if (!$type->[1]) {
      $first_std = $type;
      last;
    }
  }

  # Build resolved type array with sentinel:
  #   types[0]   = default type (first standard type)
  #   types[i+1] = type that takes effect at transition times[i]
  my @resolved = ($first_std);
  foreach my $idx (@type_indices) {
    push @resolved, $types[$idx];
  }

  $self->{times} = \@times;
  $self->{types} = \@resolved;
}

sub _lower_bound {
  my ($array, $value, $lo, $hi) = @_;

  $lo //= 0;
  $hi //= @$array;
  while ($lo < $hi) {
    my $mid = ($lo + $hi) >> 1;
    if   ($array->[$mid] < $value) { $lo = $mid + 1 }
    else                           { $hi = $mid     }
  }
  return $lo;
}

sub _upper_bound {
  my ($array, $value, $lo, $hi) = @_;

  $lo //= 0;
  $hi //= @$array;
  while ($lo < $hi) {
    my $mid = ($lo + $hi) >> 1;
    if   ($array->[$mid] <= $value) { $lo = $mid + 1 }
    else                            { $hi = $mid     }
  }
  return $lo;
}

sub offset_for_utc {
  @_ == 2 or croak q/Usage: $tz->offset_for_utc($time)/;
  my ($self, $time) = @_;
  return $self->{types}[ _upper_bound($self->{times}, $time) ][0];
}

sub type_info_for_utc {
  @_ == 2 or croak q/Usage: $tz->type_info_for_utc($time)/;
  my ($self, $time) = @_;
  my $type = $self->{types}[ _upper_bound($self->{times}, $time) ];
  return @$type;
}

sub offset_for_local {
  @_ >= 2 or croak q/Usage: $tz->offset_for_local($time, %opts)/;
  return (&_resolve_local)[0];
}

sub type_info_for_local {
  @_ >= 2 or croak q/Usage: $tz->type_info_for_local($time, %opts)/;
  return &_resolve_local;
}

sub _resolve_local {
  ((@_ & 1) == 0 && @_ >= 2) or croak q/Usage: $tz->offset_for_local($time, %opts)/;
  my ($self, $time, %p) = @_;

  my ($on_gap, $on_overlap);

  while (my ($name, $v) = each %p) {
    if ($name eq 'on_gap') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'on_gap'/;
      $on_gap = $v;
    }
    elsif ($name eq 'on_overlap') {
      (defined $v && exists $ValidPolicy{$v})
        or croak qq/Invalid policy value for the parameter 'on_overlap'/;
      $on_overlap = $v;
    }
    else {
      croak qq/Unrecognised named parameter: '$name'/;
    }
  }

  my $times = $self->{times};
  my $types = $self->{types};

  # No transitions
  return @{ $types->[0] } unless @$times;

  # Find transitions within ±24 hours of the local time.
  # Since UTC offsets are bounded by (-86400, 86400), any transition
  # that could affect this local time must fall within this range.
  my $lo = _lower_bound($times, $time - 86400);
  my $hi = _upper_bound($times, $time + 86400, $lo);

  # No transitions nearby
  return @{ $types->[$lo] } if $lo >= $hi;

  my $result_idx = $lo;

  for (my $i = $lo; $i < $hi; $i++) {
    my $boundary = $time - $times->[$i];
    my $prev     = $types->[$i];
    my $next     = $types->[$i + 1];
    my $prev_off = $prev->[0];
    my $next_off = $next->[0];

    if ($prev_off < $next_off) {
      # Spring forward: gap in [T + prev_off, T + next_off)
      if ($prev_off <= $boundary && $boundary < $next_off) {
        return @{ _apply_policy($on_gap // $self->{on_gap}, $prev, $next,
          'Unable to resolve local time: non-existing time (gap)') };
      }
      $result_idx = $i + 1 if $boundary >= $next_off;
    }
    elsif ($prev_off > $next_off) {
      # Fall back: overlap in [T + next_off, T + prev_off)
      if ($next_off <= $boundary && $boundary < $prev_off) {
        return @{ _apply_policy($on_overlap // $self->{on_overlap}, $prev, $next,
          'Unable to resolve local time: ambiguous time (overlap)') };
      }
      $result_idx = $i + 1 if $boundary >= $prev_off;
    }
    else {
      $result_idx = $i + 1 if $boundary >= $prev_off;
    }
  }

  return @{ $types->[$result_idx] };
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
