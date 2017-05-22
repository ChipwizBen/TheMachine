package Net::SFTP::Foreign::Buffer;

our $VERSION = '1.68_05';

use strict;
use warnings;
no warnings 'uninitialized';

use Carp;

use constant HAS_QUADS => do {
    local $@;
    local $SIG{__DIE__};
    no warnings;
    eval q{
        pack(Q => 0x1122334455667788) eq "\x11\x22\x33\x44\x55\x66\x77\x88"
    }
};

sub new {
    my $class = shift;
    my $data = '';
    @_ and put(\$data, @_);
    bless \$data, $class;
}

sub make { bless \$_[1], $_[0] }

sub bytes { ${$_[0]} }

sub get_int8 {
    length ${$_[0]} >=1 or return undef;
    unpack(C => substr(${$_[0]}, 0, 1, ''));
}

sub get_int16 {
    length ${$_[0]} >=2 or return undef;
    unpack(n => substr(${$_[0]}, 0, 2, ''));
}

sub get_int32 {
    length ${$_[0]} >=4 or return undef;
    unpack(N => substr(${$_[0]}, 0, 4, ''));
}

sub get_int32_untaint {
    my ($v) = substr(${$_[0]}, 0, 4, '') =~ /(.*)/s;
    get_int32(\$v);
}

sub get_int64_quads {
    length ${$_[0]} >= 8 or return undef;
    unpack Q => substr(${$_[0]}, 0, 8, '')
}

sub get_int64_no_quads {
    length ${$_[0]} >= 8 or return undef;
    my ($big, $small) = unpack(NN => substr(${$_[0]}, 0, 8, ''));
    if ($big) {
	# too big for an integer, try to handle it as a float:
	my $high = $big * 4294967296;
	my $result = $high + $small;
	unless ($result - $high == $small) {
	    # too big event for a float, use a BigInt;
	    require Math::BigInt;
	    $result = Math::BigInt->new($big);
	    $result <<= 32;
	    $result += $small;
	}
	return $result;
    }
    return $small;
}

*get_int64 = (HAS_QUADS ? \&get_int64_quads : \&get_int64_no_quads);

sub get_int64_untaint {
    my ($v) = substr(${$_[0]}, 0, 8, '') =~ /(.*)/s;
    get_int64(\$v);
}

sub get_str {
    my $self = shift;
    length $$self >=4 or return undef;
    my $len = unpack(N => substr($$self, 0, 4, ''));
    length $$self >=$len or return undef;
    substr($$self, 0, $len, '');
}

sub get_str_list {
    my $self = shift;
    my @a;
    if (my $n = $self->get_int32) {
        for (1..$n) {
            my $str = $self->get_str;
            last unless defined $str;
            push @a, $str;
        }
    }
    return @a;
}

sub get_attributes { Net::SFTP::Foreign::Attributes->new_from_buffer($_[0]) }


sub skip_bytes { substr(${$_[0]}, 0, $_[1], '') }

sub skip_str {
    my $self = shift;
    my $len = $self->get_int32;
    substr($$self, 0, $len, '');
}

sub put_int8 { ${$_[0]} .= pack(C => $_[1]) }

sub put_int32 { ${$_[0]} .= pack(N => $_[1]) }

sub put_int64_quads { ${$_[0]} .= pack(Q => $_[1]) }

sub put_int64_no_quads {
    if ($_[1] >= 4294967296) {
	my $high = int ( $_[1] / 4294967296);
	my $low = int ($_[1] - $high * 4294967296);
	${$_[0]} .= pack(NN => $high, $low)
    }
    else {
	${$_[0]} .= pack(NN => 0, $_[1])
    }
}

*put_int64 = (HAS_QUADS ? \&put_int64_quads : \&put_int64_no_quads);

sub put_str {
    utf8::downgrade($_[1]) or croak "UTF8 data reached the SFTP buffer";
    ${$_[0]} .= pack(N => length($_[1])) . $_[1]
}

sub put_char { ${$_[0]} .= $_[1] }

sub _attrs_as_buffer {
    my $attrs = shift;
    my $ref = ref $attrs;
    Net::SFTP::Foreign::Attributes->isa($ref)
	    or croak("Object of class Net::SFTP::Foreign::Attributes "
		     . "expected, $ref found");
    $attrs->as_buffer;
}

sub put_attributes { ${$_[0]} .= ${_attrs_as_buffer $_[1]} }

my %unpack = ( int8 => \&get_int8,
	       int32 => \&get_int32,
	       int64 => \&get_int64,
	       str => \&get_str,
	       attr => \&get_attributtes );

sub get {
    my $buf = shift;
    map { $unpack{$_}->($buf) } @_;
}

my %pack = ( int8 => sub { pack C => $_[0] },
	     int32 => sub { pack N => $_[0] },
	     int64 => sub {
		 if (HAS_QUADS) {
		     return pack(Q => $_[0])
		 }
		 else {
		     if ($_[0] >= 4294967296) {
			 my $high = int ( $_[0] / 4294967296);
			 my $low = int ($_[0] - $high * 4294967296);
			 return pack(NN => $high, $low)
		     }
		     else {
			 return pack(NN => 0, $_[0])
		     }
		 }
	     },
	     str => sub { pack(N => length($_[0])), $_[0] },
	     char => sub { $_[0] },
	     attr => sub { ${_attrs_as_buffer $_[0]} } );

sub put {
    my $buf =shift;
    @_ & 1 and croak "bad number of arguments for put (@_)";
    my @parts;
    while (@_) {
	my $type = shift;
	my $value = shift;
        my $packer = $pack{$type} or Carp::confess("internal error: bad packing type '$type'");
	push @parts, $packer->($value)
    }
    $$buf.=join('', @parts);
}

1;
__END__

=head1 NAME

Net::SFTP::Foreign::Buffer - Read/write buffer class

=head1 SYNOPSIS

    use Net::SFTP::Foreign::Buffer;
    my $buffer = Net::SFTP::Foreign::Buffer->new;

=head1 DESCRIPTION

I<Net::SFTP::Foreign::Buffer> provides read/write buffer functionality for
SFTP.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SFTP::Foreign manpage for author, copyright, and
license information.

=cut
