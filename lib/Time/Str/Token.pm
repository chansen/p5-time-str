package Time::Str::Token;
use strict;
use warnings;
use v5.10;

use Exporter qw[import];
use Carp     qw[croak];

our $VERSION     = '0.08';
our @EXPORT_OK   = qw[ parse_day
                       parse_day_name
                       parse_month
                       parse_meridiem
                       parse_tz_offset ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

{
  my %DayMap = (
    '01' =>  1,  '1' =>  1,  '1st' =>  1,
    '02' =>  2,  '2' =>  2,  '2nd' =>  2,
    '03' =>  3,  '3' =>  3,  '3rd' =>  3,
    '04' =>  4,  '4' =>  4,  '4th' =>  4,
    '05' =>  5,  '5' =>  5,  '5th' =>  5,
    '06' =>  6,  '6' =>  6,  '6th' =>  6,
    '07' =>  7,  '7' =>  7,  '7th' =>  7,
    '08' =>  8,  '8' =>  8,  '8th' =>  8,
    '09' =>  9,  '9' =>  9,  '9th' =>  9,
                '10' => 10, '10th' => 10,
                '11' => 11, '11th' => 11,
                '12' => 12, '12th' => 12,
                '13' => 13, '13th' => 13,
                '14' => 14, '14th' => 14,
                '15' => 15, '15th' => 15,
                '16' => 16, '16th' => 16,
                '17' => 17, '17th' => 17,
                '18' => 18, '18th' => 18,
                '19' => 19, '19th' => 19,
                '20' => 20, '20th' => 20,
                '21' => 21, '21st' => 21,
                '22' => 22, '22nd' => 22,
                '23' => 23, '23rd' => 23,
                '24' => 24, '24th' => 24,
                '25' => 25, '25th' => 25,
                '26' => 26, '26th' => 26,
                '27' => 27, '27th' => 27,
                '28' => 28, '28th' => 28,
                '29' => 29, '29th' => 29,
                '30' => 30, '30th' => 30,
                '31' => 31, '31st' => 31,
  );

  sub parse_day {
    @_ == 1 or croak q/Usage: parse_day(string)/;
    return $DayMap{ lc shift } // croak q/Unable to parse: day is invalid/;
  }
}

{
  my %MonthMap = (
    '01' =>  1,  '1' =>  1, 'i'    =>  1, 'jan' =>  1, 'january'   =>  1,
    '02' =>  2,  '2' =>  2, 'ii'   =>  2, 'feb' =>  2, 'february'  =>  2,
    '03' =>  3,  '3' =>  3, 'iii'  =>  3, 'mar' =>  3, 'march'     =>  3,
    '04' =>  4,  '4' =>  4, 'iv'   =>  4, 'apr' =>  4, 'april'     =>  4,
    '05' =>  5,  '5' =>  5, 'v'    =>  5, 'may' =>  5,
    '06' =>  6,  '6' =>  6, 'vi'   =>  6, 'jun' =>  6, 'june'      =>  6,
    '07' =>  7,  '7' =>  7, 'vii'  =>  7, 'jul' =>  7, 'july'      =>  7,
    '08' =>  8,  '8' =>  8, 'viii' =>  8, 'aug' =>  8, 'august'    =>  8,
    '09' =>  9,  '9' =>  9, 'ix'   =>  9, 'sep' =>  9, 'september' =>  9, 'sept' => 9,
                '10' => 10, 'x'    => 10, 'oct' => 10, 'october'   => 10,
                '11' => 11, 'xi'   => 11, 'nov' => 11, 'november'  => 11,
                '12' => 12, 'xii'  => 12, 'dec' => 12, 'december'  => 12,
  );

  sub parse_month {
    @_ == 1 or croak q/Usage: parse_month(string)/;
    return $MonthMap{ lc shift } // croak q/Unable to parse: month is invalid/;
  }
}

{
  my %DayNameMap = (
    'mon' => 1, 'monday'    => 1,
    'tue' => 2, 'tuesday'   => 2, 'tues'  => 2,
    'wed' => 3, 'wednesday' => 3,
    'thu' => 4, 'thursday'  => 4, 'thurs' => 4,
    'fri' => 5, 'friday'    => 5,
    'sat' => 6, 'saturday'  => 6,
    'sun' => 7, 'sunday'    => 7,
  );

  sub parse_day_name {
    @_ == 1 or croak q/Usage: parse_day_name(string)/;
    return $DayNameMap{ lc shift } // croak q/Unable to parse: day name is invalid/;
  }
}

{
  my %MeridiemMap = (
    'am' =>  0, 'a.m.' =>  0,
    'pm' => 12, 'p.m.' => 12,
  );

  sub parse_meridiem {
    @_ == 1 or croak q/Usage: parse_meridiem(string)/;
    return $MeridiemMap{ lc shift } // croak q/Unable to parse: meridiem is invalid/;
  }
}

{
  # Fast path for whole-hour offsets
  my %OffsetMap = (
    '-09' => -9*60, '-0900' => -9*60, '-09:00' => -9*60,
    '-08' => -8*60, '-0800' => -8*60, '-08:00' => -8*60,
    '-07' => -7*60, '-0700' => -7*60, '-07:00' => -7*60,
    '-06' => -6*60, '-0600' => -6*60, '-06:00' => -6*60,
    '-05' => -5*60, '-0500' => -5*60, '-05:00' => -5*60,
    '-04' => -4*60, '-0400' => -4*60, '-04:00' => -4*60,
    '-03' => -3*60, '-0300' => -3*60, '-03:00' => -3*60,
    '-02' => -2*60, '-0200' => -2*60, '-02:00' => -2*60,
    '-01' => -1*60, '-0100' => -1*60, '-01:00' => -1*60,
    '+00' =>  0*60, '+0000' =>  0*60, '+00:00' =>  0*60,
    '+01' =>  1*60, '+0100' =>  1*60, '+01:00' =>  1*60,
    '+02' =>  2*60, '+0200' =>  2*60, '+02:00' =>  2*60,
    '+03' =>  3*60, '+0300' =>  3*60, '+03:00' =>  3*60,
    '+04' =>  4*60, '+0400' =>  4*60, '+04:00' =>  4*60,
    '+05' =>  5*60, '+0500' =>  5*60, '+05:00' =>  5*60,
    '+06' =>  6*60, '+0600' =>  6*60, '+06:00' =>  6*60,
    '+07' =>  7*60, '+0700' =>  7*60, '+07:00' =>  7*60,
    '+08' =>  8*60, '+0800' =>  8*60, '+08:00' =>  8*60,
    '+09' =>  9*60, '+0900' =>  9*60, '+09:00' =>  9*60,
  );

  # ±H ±HH ±HHMM ±H:MM ±HH:MM
  my $Offset_Rx = qr{
    \A
      (?<sign> [+-])
      (?:
          (?:
            (?<hour> [0-9]{2}) (?<minute> [0-9]{2})
          )
        |
          (?:
            (?<hour> [0-9]{1,2}) (?: [:] (?<minute> [0-9]{2}) )?
          )
      )
    \z
  }x;

  sub parse_tz_offset {
    @_ == 1 or croak q/Usage: parse_tz_offset(string)/;
    my $string = shift;

    return $OffsetMap{$string} // do {
      ($string =~ $Offset_Rx)
        or croak q/Unable to parse: timezone offset is invalid/;

      my $h = $+{hour};
      my $m = $+{minute} // 0;
      ($h <= 23 && $m <= 59)
        or croak q/Unable to parse: timezone offset is out of range/;

      my $offset = $h * 60 + $m;
      if ($+{sign} eq '-') {
        $offset *= -1;
      }
      $offset;
    };
  }
}

1;
