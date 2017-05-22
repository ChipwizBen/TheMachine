package Net::IP::XS;

use warnings;
use strict;

use 5.006;

use Math::BigInt;
use Tie::Simple;

our $VERSION = '0.19';

our $IP_NO_OVERLAP      = 0;
our $IP_PARTIAL_OVERLAP = 1;
our $IP_A_IN_B_OVERLAP  = -1;
our $IP_B_IN_A_OVERLAP  = -2;
our $IP_IDENTICAL       = -3;

our @EXPORT_OK = qw(Error
                    Errno
                    ip_iptobin
                    ip_bintoip
                    ip_iplengths
                    ip_bintoint
                    ip_inttobin
                    ip_expand_address
                    ip_is_ipv4
                    ip_is_ipv6
                    ip_get_version
                    ip_get_mask
                    ip_last_address_bin
                    ip_splitprefix
                    ip_is_valid_mask
                    ip_bincomp
                    ip_binadd
                    ip_get_prefix_length
                    ip_compress_v4_prefix
                    ip_is_overlap
                    ip_check_prefix
                    ip_range_to_prefix
                    ip_get_embedded_ipv4
                    ip_aggregate
                    ip_prefix_to_range
                    ip_reverse
                    ip_normalize
                    ip_compress_address
                    ip_iptype
                    ip_auth
                    ip_normal_range
                    $IP_NO_OVERLAP
                    $IP_PARTIAL_OVERLAP
                    $IP_A_IN_B_OVERLAP
                    $IP_B_IN_A_OVERLAP
                    $IP_IDENTICAL);

our %EXPORT_TAGS = (PROC => [@EXPORT_OK]);

use overload (
    '+'    => 'ip_add_num',
    'bool' => sub { @_ },
);

use base qw(DynaLoader Exporter);
__PACKAGE__->bootstrap($VERSION);

our $ERROR;
our $ERRNO;

BEGIN {
    tie $ERROR, 'Tie::Simple', 1, FETCH => \&ip_get_Error,
                                  STORE => \&ip_set_Error;
    tie $ERRNO, 'Tie::Simple', 1, FETCH => \&ip_get_Errno,
                                  STORE => \&ip_set_Errno;
};

our %IPv4ranges = (
    '00000000'                 => 'PRIVATE',     # 0/8
    '00001010'                 => 'PRIVATE',     # 10/8
    '01111111'                 => 'PRIVATE',     # 127.0/8
    '101011000001'             => 'PRIVATE',     # 172.16/12
    '1100000010101000'         => 'PRIVATE',     # 192.168/16
    '1010100111111110'         => 'RESERVED',    # 169.254/16
    '110000000000000000000010' => 'RESERVED',    # 192.0.2/24
    '1110'                     => 'RESERVED',    # 224/4
    '11110'                    => 'RESERVED',    # 240/5
    '11111'                    => 'RESERVED',    # 248/5
);

our %IPv6ranges = (
    '00000000'   => 'RESERVED',                  # ::/8
    '00000001'   => 'RESERVED',                  # 0100::/8
    '0000001'    => 'RESERVED',                  # 0200::/7
    '000001'     => 'RESERVED',                  # 0400::/6
    '00001'      => 'RESERVED',                  # 0800::/5
    '0001'       => 'RESERVED',                  # 1000::/4
    '001'        => 'GLOBAL-UNICAST',            # 2000::/3
    '010'        => 'RESERVED',                  # 4000::/3
    '011'        => 'RESERVED',                  # 6000::/3
    '100'        => 'RESERVED',                  # 8000::/3
    '101'        => 'RESERVED',                  # A000::/3
    '110'        => 'RESERVED',                  # C000::/3
    '1110'       => 'RESERVED',                  # E000::/4
    '11110'      => 'RESERVED',                  # F000::/5
    '111110'     => 'RESERVED',                  # F800::/6
    '1111101'    => 'RESERVED',                  # FA00::/7
    '1111110'    => 'UNIQUE-LOCAL-UNICAST',      # FC00::/7
    '111111100'  => 'RESERVED',                  # FE00::/9
    '1111111010' => 'LINK-LOCAL-UNICAST',        # FE80::/10
    '1111111011' => 'RESERVED',                  # FEC0::/10
    '11111111'   => 'MULTICAST',                 # FF00::/8
    '00100000000000010000110110111000' => 'RESERVED',    # 2001:DB8::/32

    '0' x 96 => 'IPV4COMP',                              # ::/96
    ('0' x 80) . ('1' x 16) => 'IPV4MAP',                # ::FFFF:0:0/96

    '0' x 128         => 'UNSPECIFIED',                  # ::/128
    ('0' x 127) . '1' => 'LOOPBACK'                      # ::1/128
);

sub Error       { $ERROR }
sub Errno       { $ERRNO }

sub ip_bintoint { Math::BigInt->new(ip_bintoint_str($_[0]))        }
sub ip_inttobin { ip_inttobin_str(Math::BigInt->new($_[0]), $_[1]) }

sub binip       { $_[0]->{'binip'}     }
sub last_bin    { $_[0]->{'last_bin'}  }
sub version     { $_[0]->{'ipversion'} }
sub error       { $_[0]->{'error'}     }
sub errno       { $_[0]->{'errno'}     }
sub prefixlen   { $_[0]->{'prefixlen'} }
sub ip          { $_[0]->{'ip'}        }
sub is_prefix   { $_[0]->{'is_prefix'} }
sub binmask     { $_[0]->{'binmask'}   }

sub size        { Math::BigInt->new(size_str($_[0]))     }
sub intip       { Math::BigInt->new(intip_str($_[0]))    }
sub last_int    { Math::BigInt->new(last_int_str($_[0])) }

sub auth 
{
    my ($self) = shift;

    return ($self->{auth}) if defined($self->{auth});

    my $auth = ip_auth($self->ip, $self->version);

    if (!$auth) {
        $self->{error} = $ERROR;
        $self->{errno} = $ERRNO;
        return;
    }

    $self->{auth} = $auth;

    return ($self->{auth});
}

sub ip_auth 
{
    my ($ip, $ip_version) = (@_);

    if (not $ip_version) {
        $ERROR = "Cannot determine IP version for $ip";
        $ERRNO = 101;
        return;
    }

    if ($ip_version != 4) {
        $ERROR = "Cannot get auth information: Not an IPv4 address";
        $ERRNO = 308;
        return;
    }

    require IP::Authority;

    my $reg = new IP::Authority;

    return ($reg->inet_atoauth($ip));
}

1;

__END__

=head1 NAME

Net::IP::XS - IPv4/IPv6 address library

=head1 SYNOPSIS

  use Net::IP::XS;

  my $ip = new Net::IP::XS ('193.0.1/24') or die (Net::IP::XS::Error());
  print ("IP  : ".$ip->ip()."\n");
  print ("Sho : ".$ip->short()."\n");
  print ("Bin : ".$ip->binip()."\n");
  print ("Int : ".$ip->intip()."\n");
  print ("Mask: ".$ip->mask()."\n");
  print ("Last: ".$ip->last_ip()."\n");
  print ("Len : ".$ip->prefixlen()."\n");
  print ("Size: ".$ip->size()."\n");
  print ("Type: ".$ip->iptype()."\n");
  print ("Rev:  ".$ip->reverse_ip()."\n");

=head1 DESCRIPTION

An XS (C) implementation of L<Net::IP|Net::IP>. See
L<Net::IP|Net::IP>'s documentation (as at version 1.25) for the
functions and methods that are available.

=head1 DIFFERENCES BETWEEN NET::IP AND NET::IP::XS

=over 4

=item Exports

Nothing is exported by default.

=item Error messages

In some instances this won't set error codes or messages where
C<Net::IP> would, though it should be mostly the same.

=item Object-oriented interface

The object-oriented interface uses function calls and hashref lookups
internally, such that subclassing C<Net::IP::XS> will not have the
same effect as it does with C<Net::IP>.

=item ip_auth

Returns C<undef> on failure, instead of dying.

=item ip_binadd

Returns C<undef> if either of the bitstring arguments is more than 128
characters in length.

Any character of the bitstring that is not a 0 is treated as a 1. The
C<Net::IP> version returns different results for different digits, and
treats non-digits as 0.

=item ip_bintoint

The integer returned will be at most ((1 << 128) - 1) (i.e. the
largest possible IPv6 address). C<Net::IP> handles bitstrings of
arbitrary length.

=item ip_compress_address

Returns C<undef> if the IPv6 address argument is invalid.

=item ip_compress_v4_prefix

Returns C<undef> if the C<len> argument is negative or greater than
32.

=item ip_expand_address

Does not set C<Error> or C<Errno> where there is a problem with an
embedded IPv4 address within an IPv6 address. 

Returns the zero IP address if the empty string is provided. The
C<Net::IP> version returns C<undef>. 

Returns a full IPv6 address if a partial address is provided (e.g.
returns 'ffff:ffff:0000:0000:0000:0000:0000:0000' if 'ffff:ffff' is
provided).  The C<Net::IP> version returns the partial address. 

Returns C<undef> on an invalid IPv4/IPv6 address. The C<Net::IP>
version returns the zero address for IPv4 and whatever was provided
for IPv6.

=item ip_get_mask

The mask returned will always have a length equal to the number of
bits in an address of the specified IP version (e.g. an IPv4 mask will
always comprise 32 characters). The C<Net::IP> version will return a
longer mask when the C<len> argument is larger than the number of bits
in the specified IP version. 

If a negative C<len> is provided, it will be treated as zero.

=item ip_inttobin

The bitstring returned will always be either 32 or 128 characters in
length, and it returns C<undef> if the integer argument would require
more than 128 characters to represent as a bitstring. If an invalid
version is provided, the returned bitstring will be 128 characters in
length. The C<Net::IP> version handles arbitrary integers and expands
to accommodate those integers, regardless of the version argument.
Also, if an invalid version is provided, the returned bitstring is
only as long as is necessary to accommodate the bitstring.

=item ip_iptobin

Returns C<undef> on an invalid IPv4/IPv6 address.

=item ip_last_address_bin

Returns an empty string if an invalid version (i.e. not 4 or 6) is
provided. If the bitstring provided is longer than the number of bits
in the specified version, then only the first 32/128 bits will be used
in determining the last address. If the C<len> provided is invalid
(negative or more than 32/128 depending on the version), it will be
treated as the maximum length of the specified version.

=item ip_normalize

For the 'plus' style of string (e.g. '1.0.0.0 + 255'), whitespace
between the plus character and the parts before and after it is
optional. In the C<Net::IP> version, there has to be some whitespace
before and after the plus character. Also, C<undef> will be returned
if the part after the plus sign is not a number. The C<Net::IP> version
will return two copies of the single address in this instance.

For the 'prefix range' style of string (e.g. '1.0.0.0/8'), the part
after the slash must be a number. If it is not, C<undef> will be
returned. The C<Net::IP> version will return two copies of the single
address in this instance.

=item ip_range_to_prefix

Returns C<undef> if the version argument is invalid.

=item ip_reverse

The C<len> argument determines the length of the reverse domain -
e.g., if the arguments are '127.0.0.1', '16' and '4', the reverse
domain will be '0.127.in-addr.arpa.'. The C<Net::IP> version does not
take the C<len> argument into account for IPv4 addresses. For IPv6
addresses, a compressed IP address string may be provided.

=item ip_splitprefix

Returns C<undef> unless the first component of the string is less than
or equal to 64 characters in length. The C<Net::IP> version handles
strings of arbitrary length.

=item prefix

Returns a string with a prefix length of zero (e.g. '127.0.0.1/0')
where C<prefixlen> is not defined in the object. The C<Net::IP>
version will not include any prefix length in the returned string
(e.g. '127.0.0.1/').

=back

=head1 AUTHOR

Tom Harrison, C<< <tomhrr@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ip-xs at rt.cpan.org>, 
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IP-XS>.

=head1 ACKNOWLEDGEMENTS

Manuel Valente (C<< <manuel.valente@gmail.com> >>) and the other
authors of L<Net::IP|Net::IP>.

=head1 SEE ALSO

L<Net::IP|Net::IP>, L<IP::Authority|IP::Authority>.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010-2016 Tom Harrison <tomhrr@cpan.org>.

Original inet_pton4 and inet_pton6 functions are copyright (C) 2006 
Free Software Foundation.

Original interface, and the auth and ip_auth functions, are copyright
(C) 1999-2002 RIPE NCC.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301 USA.

=cut
