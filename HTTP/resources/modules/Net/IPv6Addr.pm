package Net::IPv6Addr;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Carp;
use Net::IPv4Addr;

BEGIN {
    eval { 
	require Math::BigInt;
	require Math::Base85;
    };
}

=pod

=head1 NAME

Net::IPv6Addr -- check validity of IPv6 addresses

=head1 SYNOPSIS

    use Net::IPv6Addr;

    Net::IPv6Addr::ipv6_parse($addr);
    $x = new Net::IPv6Addr("dead:beef:cafe:babe::f0ad");
    print $x->to_string_preferred(), "\n";

=head1 DESCRIPTION

C<Net::IPv6Addr> checks strings for valid IPv6 addresses, as
specified in RFC1884.  You throw possible addresses at it, it
either accepts them or throws an exception.

If C<Math::Base85> is installed, then this module is able to process
addresses formatted in the style referenced by RFC1924.

The public interface of this module is rather small.

=cut

@ISA = qw(Exporter);

@EXPORT = qw();
@EXPORT_OK = qw();

$VERSION = '0.2';

# We get these formats from rfc1884:
#
#	preferred form: x:x:x:x:x:x:x:x
# 
#	zero-compressed form: the infamous double-colon.  
#	Too many pattern matches to describe in this margin.
#
#	mixed IPv4/IPv6 format: x:x:x:x:x:x:d.d.d.d
#
#	mixed IPv4/IPv6 with compression: ::d.d.d.d or ::FFFF:d.d.d.d
#
# And we get these from rfc1924:
#
#	base-85-encoded: [0-9A-Za-z!#$%&()*+-;<=>?@^_`{|}~]{20}
#

my %ipv6_patterns = (
    'preferred' => [
	qr/^(?:[a-f0-9]{1,4}:){7}[a-f0-9]{1,4}$/i,
	\&ipv6_parse_preferred,
    ],
    'compressed' => [		## No, this isn't pretty.
	qr/^[a-f0-9]{0,4}::$/i,
	qr/^:(?::[a-f0-9]{1,4}){1,6}$/i,
	qr/^(?:[a-f0-9]{1,4}:){1,6}:$/i,
	qr/^(?:[a-f0-9]{1,4}:)(?::[a-f0-9]{1,4}){1,6}$/i,
	qr/^(?:[a-f0-9]{1,4}:){2}(?::[a-f0-9]{1,4}){1,5}$/i,
	qr/^(?:[a-f0-9]{1,4}:){3}(?::[a-f0-9]{1,4}){1,4}$/i,
	qr/^(?:[a-f0-9]{1,4}:){4}(?::[a-f0-9]{1,4}){1,3}$/i,
	qr/^(?:[a-f0-9]{1,4}:){5}(?::[a-f0-9]{1,4}){1,2}$/i,
	qr/^(?:[a-f0-9]{1,4}:){6}(?::[a-f0-9]{1,4})$/i,
	\&ipv6_parse_compressed,
    ],
    'ipv4' => [
	qr/^(?:0:){5}ffff:(?:\d{1,3}\.){3}\d{1,3}$/i,
	qr/^(?:0:){6}(?:\d{1,3}\.){3}\d{1,3}$/,
	\&ipv6_parse_ipv4,
    ],
    'ipv4 compressed' => [
	qr/^::(?:ffff:)?(?:\d{1,3}\.){3}\d{1,3}$/i,
	\&ipv6_parse_ipv4_compressed,
    ],
); 

# base-85
if (defined $Math::Base85::base85_digits) {
    my $digits;
    ($digits = $Math::Base85::base85_digits) =~ s/-//;
    my $x = "[" . $digits . "-]";
    my $n = "{20}";
    $ipv6_patterns{'base85'} = [
	qr/$x$n/,
	\&ipv6_parse_base85,
    ];
}

=pod

=head1 new

=head2 Parameters

A string to be interpreted as an IPv6 address.

=head2 Returns

A C<Net::IPv6Addr> object if successful.

=head2 Notes

Throws an exception if the string isn't a valid address.

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $maybe_ip = shift;
    my $parser = ipv6_chkip($maybe_ip);
    if (ref $parser ne 'CODE') {
	croak __PACKAGE__, "::new -- invalid IPv6 address $maybe_ip";
    }
    my @hexadecets = $parser->($maybe_ip);
    my $self = \@hexadecets;
    bless $self, $class;
    return $self;
}

=pod

=head1 ipv6_parse

=head2 Parameters

A string containing an IPv6 address string.  Optionally, it may
also include a C</> character, and a numeric prefix length, in that
order.

	-or-

An IPv6 address string.  Optionally, a numeric prefix length.

=head2 Returns

What you gave it, more or less, if it does parse out correctly.

=head2 Notes

Throws an exception on malformed input.  This is not an object
method or class method; it's just a subroutine.

=cut

sub ipv6_parse
{
    my ($ip, $pfx);
    if (@_ == 2) {
	($ip, $pfx) = @_;
    } else {
	($ip, $pfx) = split(m!/!, $_[0])
    }

    unless (ipv6_chkip($ip)) {
	croak __PACKAGE__, "::ipv6_parse -- invalid IPv6 address $ip\n";
    }

    $pfx =~ s/\s+//g if defined($pfx);

    if (defined $pfx) {
	if ($pfx =~ /^\d+$/) {
	    if (($pfx < 0)  || ($pfx > 128)) {
		croak __PACKAGE__, "::ipv6_parse -- invalid prefix length $pfx\n";
	    }
	} else {
	    croak __PACKAGE__, "::ipv6_parse -- non-numeric prefix length $pfx\n";
	}
    } else {
	return $ip;
    }
    wantarray ? ($ip, $pfx) : "$ip/$pfx";
}

=pod

=head1 is_ipv6

=head2 Parameters

A string containing an IPv6 address string.  Optionally, it may
also include a C</> character, and a numeric prefix length, in that
order.

	-or-

An IPv6 address string.  Optionally, a numeric prefix length.

=head2 Returns

What you gave it, more or less, if it does parse out correctly,
otherwise returns undef.
=head2 Notes

This is not an object method or class method; it is just a subroutine.

=cut

sub is_ipv6
{
    my ($ip, $pfx);
    if (@_ == 2) {
	($ip, $pfx) = @_;
    } else {
	($ip, $pfx) = split(m!/!, $_[0])
    }

    unless (ipv6_chkip($ip)) {
	return undef;
    }

    if (defined $pfx) {
        $pfx =~ s/s+//g;
	if ($pfx =~ /^\d+$/) {
	    if (($pfx < 0)  || ($pfx > 128)) {
               return undef;
	    }
	} else {
            return undef;
	}
    } else {
	return $ip;
    }
    wantarray ? ($ip, $pfx) : "$ip/$pfx";
}

=pod

=head1 ipv6_chkip

=head2 Parameters

An IPv6 address string.

=head2 Returns

Something true if it's a valid address; something false otherwise.

=cut

sub ipv6_chkip
{
    my $ip = shift; 
    my ($pattern, $parser);
    my @patlist;

    $parser = undef;

TYPE:
    for my $k (keys %ipv6_patterns) {
	@patlist = @{$ipv6_patterns{$k}};
PATTERN:
	for my $pattern (@patlist) {
	    last PATTERN if (ref($pattern) eq 'CODE');
	    if ($ip =~ $pattern) {
		$parser = $patlist[-1];
		last TYPE;
	    }
	}
    }
    return $parser;
}

sub ipv6_parse_preferred
{
    my $ip = shift;
    my @patterns = @{$ipv6_patterns{'preferred'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    croak __PACKAGE__, "::ipv6_parse_preferred -- invalid address";
	}
	last if ($ip =~ $p);
    }
    my @pieces = split(/:/, $ip);
    splice(@pieces, 8);
    return map { hex } @pieces;
}

sub ipv6_parse_compressed
{
    my $ip = shift;
    my @patterns = @{$ipv6_patterns{'compressed'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    croak __PACKAGE__, "::ipv6_parse_compressed -- invalid address";
	}
	last if ($ip =~ $p);
    }
    my $colons;
    $colons = ($ip =~ tr/:/:/);
    my $expanded = ':' x (9 - $colons);
    $ip =~ s/::/$expanded/;
    my @pieces = split(/:/, $ip, 8);
    return map { hex } @pieces;
}

sub ipv6_parse_ipv4
{
    my $ip = shift;
    my @patterns = @{$ipv6_patterns{'ipv4'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    croak __PACKAGE__, "::ipv6_parse_ipv4 -- invalid address";
	}
	last if ($ip =~ $p);
    }
    my @result;
    my $v4addr;
    my @v6pcs = split(/:/, $ip);
    $v4addr = $v6pcs[-1];
    splice(@v6pcs, 6);
    push @result, map { hex } @v6pcs;
    Net::IPv4Addr::ipv4_parse($v4addr);
    my @v4pcs = split(/\./, $v4addr);
    push @result, unpack("n", pack("CC", @v4pcs[0,1]));
    push @result, unpack("n", pack("CC", @v4pcs[2,3]));
    return @result;
}

sub ipv6_parse_ipv4_compressed
{
    my $ip = shift;
    my @patterns = @{$ipv6_patterns{'ipv4 compressed'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    croak __PACKAGE__, "::ipv6_parse_ipv4_compressed -- invalid address";
	}
	last if ($ip =~ $p);
    }
    my @result;
    my $v4addr;
    my $colons;
    $colons = ($ip =~ tr/:/:/);
    my $expanded = ':' x (8 - $colons);
    $ip =~ s/::/$expanded/;
    my @v6pcs = split(/:/, $ip, 7);
    $v4addr = $v6pcs[-1];
    splice(@v6pcs, 6);
    push @result, map { hex } @v6pcs;
    Net::IPv4Addr::ipv4_parse($v4addr);
    my @v4pcs = split(/\./, $v4addr);
    splice(@v4pcs, 4);
    push @result, unpack("n", pack("CC", @v4pcs[0,1]));
    push @result, unpack("n", pack("CC", @v4pcs[2,3]));
    return @result;
}

sub ipv6_parse_base85
{
    croak __PACKAGE__, "::ipv6_parse_base85 -- Math::Base85 not loaded" unless defined $Math::Base85::base85_digits;
    my $ip = shift;
    my $r;
    my @patterns = @{$ipv6_patterns{'base85'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    croak __PACKAGE__, "::ipv6_parse_base85 -- invalid address";
	}
	last if ($ip =~ $p);
    }
    my $bigint = Math::Base85::from_base85($ip);
    my @result;
    while ($bigint > 0) {
	$r = $bigint & 0xffff;
	unshift @result, sprintf("%d", $r);
	$bigint = $bigint >> 16;
    }
    foreach $r ($#result+1..7) {
        $result[$r] = 0;
    }
    return @result;
}

=pod

=head1 to_string_preferred

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

The IPv6 address, formatted in the "preferred" way (as detailed by
RFC1884).

=head2 Notes

Invalid input will generate an exception.

=cut

sub to_string_preferred
{
    my $self = shift;
    if (ref $self eq __PACKAGE__) {
	return join(":", map { sprintf("%x", $_) } @$self);
    } 
    return Net::IPv6Addr->new($self)->to_string_preferred();
}

=pod

=head1 to_string_compressed

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

The IPv6 address in "compresed" format (as detailed by RFC1884).

=head2 Notes

Invalid input will generate an exception.

=cut

sub to_string_compressed
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_compressed();
    }
    my $expanded = join(":", map { sprintf("%x", $_) } @$self);
    $expanded =~ s/^0:/:/;
    $expanded =~ s/:0/:/g;
    if ($expanded =~ s/:::::::/_/ or
	$expanded =~ s/::::::/_/ or
	$expanded =~ s/:::::/_/ or
	$expanded =~ s/::::/_/ or
	$expanded =~ s/:::/_/ or
	$expanded =~ s/::/_/
        ) {
        $expanded =~ s/:(?=:)/:0/g;
	$expanded =~ s/^:(?=[0-9a-f])/0:/;
	$expanded =~ s/([0-9a-f]):$/$1:0/;
	$expanded =~ s/_/::/;
    }
    return $expanded;
}

=pod

=head1 to_string_ipv4

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

The IPv6 address in IPv4 format (as detailed by RFC1884).

=head2 Notes

Invalid input (such as an address that was not originally IPv4)
will generate an exception.

=cut

sub to_string_ipv4
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_ipv4();
    }
    if ($self->[0] | $self->[1] | $self->[2] | $self->[3] | $self->[4]) {
	croak __PACKAGE__, "::to_string_ipv4 -- not originally an IPv4 address";
    }
    if (($self->[5] != 0xffff) && $self->[5]) {
	croak __PACKAGE__, "::to_string_ipv4 -- not originally an IPv4 address";
    }
    my $v6part = join(':', map { sprintf("%x", $_) } @$self[0..5]);
    my $v4part = join('.', $self->[6] >> 8, $self->[6] & 0xff, $self->[7] >> 8,  $self->[7] & 0xff);
    return "$v6part:$v4part";
}

=pod

=head1 to_string_ipv4_compressed

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

The IPv6 address in compressed IPv4 format (as detailed by RFC1884).

=head2 Notes

Invalid input (such as an address that was not originally IPv4)
will generate an exception.

=cut

sub to_string_ipv4_compressed
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_ipv4_compressed();
    }
    if ($self->[0] | $self->[1] | $self->[2] | $self->[3] | $self->[4]) {
	croak __PACKAGE__, "::to_string_ipv4 -- not originally an IPv4 address";
    }
    if (($self->[5] != 0xffff) && $self->[5]) {
	croak __PACKAGE__, "::to_string_ipv4 -- not originally an IPv4 address";
    }
    my $v6part;
    if ($self->[5]) {
	$v6part = sprintf("::%x", $self->[5]);
    } else {
	$v6part = ":";
    }
    my $v4part = join('.', $self->[6] >> 8, $self->[6] & 0xff, $self->[7] >> 8,  $self->[7] & 0xff);
    return "$v6part:$v4part";
}


=pod

=head1 to_string_base85

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

The IPv6 address in the style detailed by RFC1924.

=head2 Notes

Invalid input will generate an exception.

=cut

sub to_string_base85
{
    croak __PACKAGE__, "::to_string_base85 -- Math::Base85 not loaded" unless defined $Math::Base85::base85_digits;
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_base85();
    }
    my $bigint = new Math::BigInt("0");
    for my $i (@{$self}[0..6]) {
	$bigint = $bigint + $i;
	$bigint = $bigint << 16;
    }
    $bigint = $bigint + $self->[7];
    return Math::Base85::to_base85($bigint);
}

=pod

=head1 to_bigint

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

The BigInt representation of IPv6 address.

=head2 Notes

Invalid input will generate an exception.

=cut

sub to_bigint
{
    croak __PACKAGE__, "::to_bigint -- Math::BigInt not loaded" unless defined &Math::BigInt::new;
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_bigint();
    }
    my $bigint = new Math::BigInt("0");
    for my $i (@{$self}[0..6]) {
	$bigint = $bigint + $i;
	$bigint = $bigint << 16;
    }
    $bigint = $bigint + $self->[7];
    $bigint =~ s/\+//;
    return  $bigint;
}

=pod

=head1 to_array

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

An array [0..7] of 16 bit hexadecimal numbers.

=head2 Notes

Invalid input will generate an exception.

=cut

sub to_array
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_array();
    }
    return map {sprintf "%04x", $_} @$self;
}
=pod

=head1 to_intarray

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

An array [0..7] of decimal numbers.

=head2 Notes

Invalid input will generate an exception.

=cut

sub to_intarray
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_intarray();
    }
    return @$self;
}

=pod

=head1 to_string_ip6_int

=head2 Parameters

If used as an object method, none; if used as a plain old subroutine,
an IPv6 address string in any format.

=head2 Returns

The reverse-address pointer as defined by RFC1886.

=head2 Notes

Invalid input will generate an exception.

=cut

sub to_string_ip6_int
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_ip6_int();
    }
    my $hexdigits = sprintf("%04x" x 8, @$self);
    my @nibbles = ('INT', 'IP6', split(//, $hexdigits));
    my $ptr = join('.', reverse @nibbles);
    return $ptr . ".";
}


=pod

=head1 in_network_of_size

=head2 Parameters

If used as an object method, network size in bits

If used as a plain old subroutine, an IPv6 address string in any format
and network size in bits. Network size may be given with / notation.

=head2 Returns

Network IPv6Addr of given size.

=head2 Notes

Invalid input will generate an exception.

=cut

sub in_network_of_size
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
      if ($self =~ m!(.+)/(.+)!) {
	unshift @_, $2;
	return Net::IPv6Addr->new($1)->in_network_of_size(@_)->to_string_preferred;
      }
      return Net::IPv6Addr->new($self)->in_network_of_size(@_)->to_string_preferred;
    }
    my $netsize = shift;
    if (!defined $netsize) {
      croak __PACKAGE__, "::in_network_of_size -- not network size given";
    }
    $netsize =~ s!/!!;
    if ($netsize !~ /^\d+$/ or $netsize < 0 or $netsize > 128) {
      croak __PACKAGE__, "::in_network_of_size -- not valid network size $netsize";
    }
    my @parts = @$self;
    my $i = $netsize / 16;
    unless ($i == 8) { # netsize was 128 bits; the whole address
      my $j = $netsize % 16;
      $parts[$i] &= unpack("C4",pack("B16", '1' x $j . '0000000000000000'));
      foreach $j (++$i..$#parts) {
	$parts[$j] = 0;
      }
    }
    return Net::IPv6Addr->new(join(':', @parts));
}

=pod

=head1 in_network

=head2 Parameters

If used as an object method, network and its size in bits

If used as a plain old subroutine, an IPv6 address string in any format
network address string and size in bits.
Network size may be given with / notation.

=head2 Returns

Something true, if address is member of the network, false otherwise.

=head2 Notes

Invalid input will generate an exception.

=cut

sub in_network
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
      return Net::IPv6Addr->new($self)->in_network(@_);
    }
    my ($net,$netsize) = (@_);
    if ($net =~ m!/!) {
      $net =~ s!(.*)/(.*)!$1!;
      $netsize = $2;
    }
    unless (defined $netsize) {
      croak __PACKAGE__, "::in_network -- not enough parameters";
    }
    $netsize =~ s!/!!;
    if ($netsize !~ /^\d+$/ or $netsize < 0 or $netsize > 128) {
      croak __PACKAGE__, "::in_network -- not valid network size $netsize";
    }
    my @s = $self->in_network_of_size($netsize)->to_intarray;
    $net = Net::IPv6Addr->new($net) unless (ref $net);
    my @n = $net->in_network_of_size($netsize)->to_intarray;
    my $i = int($netsize / 16);
    $i++;
    $i = $#s if ($i > $#s);
    for (0..$i) {
      return 0 unless ($s[$_] == $n[$_]);
    }
    return 1;
}


1;
__END__

=pod

=head1 BUGS

probably exist in this module.  Please report them.

=head1 AUTHOR

Tony Monroe E<lt>tmonroe plus perl at nog dot netE<gt>.

The module's interface probably looks like it vaguely resembles
Net::IPv4Addr by Francis J. Lacoste E<lt>francis dot lacoste at
iNsu dot COME<gt>.

Some fixes and subroutines from Jyrki Soini E<lt>jyrki dot soini
at sonera dot comE<gt>.

=head1 HISTORY

This was originally written to simplify the task of maintaining
DNS records after I set myself up with Freenet6.  Interesting that
there's really only one DNS-related subroutine in here.

=head1 SEE ALSO

RFC1884, RFC1886, RFC1924, L<perl>, L<Net::IPv4Addr>, L<Math::Base85>,
L<Math::BigInt>

=cut
