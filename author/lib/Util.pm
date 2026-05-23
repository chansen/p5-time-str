package Util;
use strict;
use warnings;
use v5.10;

use Carp     qw[croak];
use Exporter qw[import];

our @EXPORT_OK = qw[ find_tzdir
                     tzdb_version ];

# Directories to probe, in order of preference.
# Covers Linux, macOS, FreeBSD, Solaris, and Cygwin.
my @TZDIR_CANDIDATES = qw(
  /usr/share/zoneinfo
  /usr/lib/zoneinfo
  /usr/share/lib/zoneinfo
  /etc/zoneinfo
  /usr/share/zoneinfo.default
);

sub find_tzdir {
  # Honour explicit override
  return $ENV{TZDIR} if defined $ENV{TZDIR} && -d $ENV{TZDIR};

  for my $dir (@TZDIR_CANDIDATES) {
    return $dir if -d $dir && -f "$dir/UTC";
  }

  # macOS: /var/db/timezone/zoneinfo is a symlink to the active version
  my $macos = '/var/db/timezone/zoneinfo';
  return $macos if -d $macos && -f "$macos/UTC";

  croak "Unable to locate zoneinfo directory; set TZDIR environment variable";
}

sub tzdb_version {
  my $dir = @_ ? $_[0] : find_tzdir();

  # 1. tzdata.zi header: "# version 2024a"
  my $zi = "$dir/tzdata.zi";
  if (-f $zi) {
    open my $fh, '<', $zi or croak "Cannot open $zi: $!";
    my $line = <$fh>;
    close $fh;
    if (defined $line && $line =~ /^#\s*version\s+(\S+)/) {
      return $1;
    }
  }

  # 2. +VERSION file (present in some distributions)
  my $vfile = "$dir/+VERSION";
  if (-f $vfile) {
    open my $fh, '<', $vfile or croak "Cannot open $vfile: $!";
    my $line = <$fh>;
    close $fh;
    if (defined $line) {
      chomp $line;
      return $line if $line =~ /\S/;
    }
  }

  # 3. Debian/Ubuntu: dpkg tzdata package version (e.g., "2024a-0ubuntu0.22.04.1")
  if (-x '/usr/bin/dpkg-query') {
    my $out = `dpkg-query -W -f='\${Version}' tzdata 2>/dev/null`;
    if (defined $out && $out =~ /^(\d{4}[a-z]\w*)/) {
      return $1;
    }
  }

  # 4. Red Hat/Fedora: rpm tzdata package version
  if (-x '/usr/bin/rpm') {
    my $out = `rpm -q --qf '%{VERSION}' tzdata 2>/dev/null`;
    if (defined $out && $out =~ /^(\d{4}[a-z]\w*)/) {
      return $1;
    }
  }

  return undef;
}

1;

__END__

=head1 NAME

Util - Locate zoneinfo directory and detect IANA tzdb version

=head1 SYNOPSIS

    use Util qw[find_tzdir tzdb_version];

    my $tzdir   = find_tzdir();        # /usr/share/zoneinfo
    my $version = tzdb_version();      # 2024a
    my $version = tzdb_version($dir);  # from a specific directory

=head1 DESCRIPTION

Shared utility for author/development scripts. Not installed with the
distribution.

=head2 find_tzdir

Returns the path to the system's zoneinfo directory. Checks C<$TZDIR>,
then probes a list of well-known paths (Linux, macOS, FreeBSD, Solaris,
Cygwin). Croaks if no valid directory is found.

=head2 tzdb_version

    my $version = tzdb_version();
    my $version = tzdb_version($tzdir);

Returns the IANA Time Zone Database version string (e.g., C<"2024a">),
or C<undef> if it cannot be determined. Detection methods, in order:

=over 4

=item 1. C<tzdata.zi> header (C<# version 2024a>)

=item 2. C<+VERSION> file

=item 3. C<dpkg-query> for the C<tzdata> package (Debian/Ubuntu)

=item 4. C<rpm -q> for the C<tzdata> package (Red Hat/Fedora)

=back

=cut
