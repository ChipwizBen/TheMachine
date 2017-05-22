package Net::SFTP::Foreign::Attributes;

our $VERSION = '1.68_05';

use strict;
use warnings;
use Carp;

use Net::SFTP::Foreign::Constants qw( :att );
use Net::SFTP::Foreign::Buffer;

sub new {
    my $class = shift;
    return bless { flags => 0}, $class;
}

sub new_from_stat {
    if (@_ > 1) {
	my ($class, undef, undef, $mode, undef,
	    $uid, $gid, undef, $size, $atime, $mtime) = @_;
	my $self = $class->new;

	$self->set_perm($mode);
	$self->set_ugid($uid, $gid);
	$self->set_size($size);
	$self->set_amtime($atime, $mtime);
	return $self;
    }
    return undef;
}

sub new_from_buffer {
    my ($class, $buf) = @_;
    my $self = $class->new;
    my $flags = $self->{flags} = $buf->get_int32_untaint;

    if ($flags & SSH2_FILEXFER_ATTR_SIZE) {
	$self->{size} = $buf->get_int64_untaint;
    }

    if ($flags & SSH2_FILEXFER_ATTR_UIDGID) {
	$self->{uid} = $buf->get_int32_untaint;
	$self->{gid} = $buf->get_int32_untaint;
    }

    if ($flags & SSH2_FILEXFER_ATTR_PERMISSIONS) {
	$self->{perm} = $buf->get_int32_untaint;
    }

    if ($flags & SSH2_FILEXFER_ATTR_ACMODTIME) {
	$self->{atime} = $buf->get_int32_untaint;
	$self->{mtime} = $buf->get_int32_untaint;
    }

    if ($flags & SSH2_FILEXFER_ATTR_EXTENDED) {
        my $n = $buf->get_int32;
	$n >= 0 and $n <= 10000 or return undef;
        my @pairs = map $buf->get_str, 1..2*$n;
        $self->{extended} = \@pairs;
    }

    $self;
}

sub skip_from_buffer {
    my ($class, $buf) = @_;
    my $flags = $buf->get_int32;
    if ($flags == ( SSH2_FILEXFER_ATTR_SIZE |
		    SSH2_FILEXFER_ATTR_UIDGID |
		    SSH2_FILEXFER_ATTR_PERMISSIONS |
		    SSH2_FILEXFER_ATTR_ACMODTIME )) {
	$buf->skip_bytes(28);
    }
    else {
	my $len = 0;
	$len += 8 if $flags & SSH2_FILEXFER_ATTR_SIZE;
	$len += 8 if $flags & SSH2_FILEXFER_ATTR_UIDGID;
	$len += 4 if $flags & SSH2_FILEXFER_ATTR_PERMISSIONS;
	$len += 8 if $flags & SSH2_FILEXFER_ATTR_ACMODTIME;
	$buf->skip_bytes($len);
	if ($flags & SSH2_FILEXFER_ATTR_EXTENDED) {
	    my $n = $buf->get_int32;
	    $buf->skip_str, $buf->skip_str for (1..$n);
	}
    }
}

sub as_buffer {
    my $a = shift;
    my $buf = Net::SFTP::Foreign::Buffer->new(int32 => $a->{flags});

    if ($a->{flags} & SSH2_FILEXFER_ATTR_SIZE) {
        $buf->put_int64(int $a->{size});
    }
    if ($a->{flags} & SSH2_FILEXFER_ATTR_UIDGID) {
        $buf->put(int32 => $a->{uid}, int32 => $a->{gid});
    }
    if ($a->{flags} & SSH2_FILEXFER_ATTR_PERMISSIONS) {
        $buf->put_int32($a->{perm});
    }
    if ($a->{flags} & SSH2_FILEXFER_ATTR_ACMODTIME) {
        $buf->put(int32 => $a->{atime}, int32 => $a->{mtime});
    }
    if ($a->{flags} & SSH2_FILEXFER_ATTR_EXTENDED) {
        my $pairs = $a->{extended};
        $buf->put_int32(int(@$pairs / 2));
        $buf->put_str($_) for @$pairs;
    }

    $buf;
}

sub flags { shift->{flags} }

sub size { shift->{size} }

sub set_size {
    my ($self, $size) = @_;
    if (defined $size) {
	$self->{flags} |= SSH2_FILEXFER_ATTR_SIZE;
	$self->{size} = $size;
    }
    else {
	$self->{flags} &= ~SSH2_FILEXFER_ATTR_SIZE;
	delete $self->{size}
    }
}

sub uid { shift->{uid} }

sub gid { shift->{gid} }

sub set_ugid {
    my ($self, $uid, $gid) = @_;
    if (defined $uid and defined $gid) {
	$self->{flags} |= SSH2_FILEXFER_ATTR_UIDGID;
	$self->{uid} = $uid;
	$self->{gid} = $gid;
    }
    elsif (!defined $uid and !defined $gid) {
	$self->{flags} &= ~SSH2_FILEXFER_ATTR_UIDGID;
	delete $self->{uid};
	delete $self->{gid};
    }
    else {
	croak "wrong arguments for set_ugid"
    }
}

sub perm { shift->{perm} }

sub set_perm {
    my ($self, $perm) = @_;
    if (defined $perm) {
	$self->{flags} |= SSH2_FILEXFER_ATTR_PERMISSIONS;
	$self->{perm} = $perm;
    }
    else {
	$self->{flags} &= ~SSH2_FILEXFER_ATTR_PERMISSIONS;
	delete $self->{perm}
    }
}

sub atime { shift->{atime} }

sub mtime { shift->{mtime} }

sub set_amtime {
    my ($self, $atime, $mtime) = @_;
    if (defined $atime and defined $mtime) {
	$self->{flags} |= SSH2_FILEXFER_ATTR_ACMODTIME;
	$self->{atime} = $atime;
	$self->{mtime} = $mtime;
    }
    elsif (!defined $atime and !defined $mtime) {
	$self->{flags} &= ~SSH2_FILEXFER_ATTR_ACMODTIME;
	delete $self->{atime};
	delete $self->{mtime};
    }
    else {
	croak "wrong arguments for set_amtime"
    }
}

sub extended { @{shift->{extended} || [] } }

sub set_extended {
    my $self = shift;
    @_ & 1 and croak "odd number of arguments passed to set_extended";
    if (@_) {
        $self->{flags} |= SSH2_FILEXFER_ATTR_EXTENDED;
        $self->{extended} = [@_];
    }
    else {
        $self->{flags} &= ~SSH2_FILEXFER_ATTR_EXTENDED;
        delete $self->{extended};
    }
}

sub append_extended {
    my $self = shift;
    @_ & 1 and croak "odd number of arguments passed to append_extended";
    my $pairs = $self->{extended};
    if (@$pairs) {
        push @$pairs, @_;
    }
    else {
        $self->set_extended(@_);
    }
}

sub clone {
    my $self = shift;
    my $clone = { %$self };
    bless $clone, ref $self;
    $clone;
}

1;
__END__

=head1 NAME

Net::SFTP::Foreign::Attributes - File/directory attribute container

=head1 SYNOPSIS

    use Net::SFTP::Foreign;

    my $a1 = Net::SFTP::Foreign::Attributes->new();
    $a1->set_size($size);
    $a1->set_ugid($uid, $gid);

    my $a2 = $sftp->stat($file)
        or die "remote stat command failed: ".$sftp->status;

    my $size = $a2->size;
    my $mtime = $a2->mtime;

=head1 DESCRIPTION

I<Net::SFTP::Foreign::Attributes> encapsulates file/directory
attributes for I<Net::SFTP::Foreign>. It also provides serialization
and deserialization methods to encode/decode attributes into
I<Net::SFTP::Foreign::Buffer> objects.

=head1 USAGE

=over 4

=item Net::SFTP::Foreign::Attributes-E<gt>new()

Returns a new C<Net::SFTP::Foreign::Attributes> object.

=item Net::SFTP::Foreign::Attributes-E<gt>new_from_buffer($buffer)

Creates a new attributes object and populates it with information read
from C<$buffer>.

=item $attrs-E<gt>as_buffer

Serializes the I<Attributes> object I<$attrs> into a buffer object.

=item $attrs-E<gt>flags

returns the value of the flags field.

=item $attrs-E<gt>size

returns the values of the size field or undef if it is not set.

=item $attrs-E<gt>uid

returns the value of the uid field or undef if it is not set.

=item $attrs-E<gt>gid

returns the value of the gid field or undef if it is not set.

=item $attrs-E<gt>perm

returns the value of the permissions field or undef if it is not set.

See also L<perlfunc/stat> for instructions on how to process the
returned value with the L<Fcntl> module.

For instance, the following code checks if some attributes object
corresponds to a directory:

  use Fcntl qw(S_ISDIR);
  ...
  if (S_ISDIR($attr->perm)) {
    # it is a directory!
  }

=item $attrs-E<gt>atime

returns the value of the atime field or undef if it is not set.

=item $attrs-E<gt>mtime

returns the value of the mtime field or undef if it is not set.

=item %extended = $attr-E<gt>extended

returns the vendor-dependent extended attributes

=item $attrs-E<gt>set_size($size)

sets the value of the size field, or if $size is undef removes the
field. The flags field is adjusted accordingly.

=item $attrs-E<gt>set_perm($perm)

sets the value of the permissions field or removes it if the value is
undefined. The flags field is also adjusted.

=item $attr-E<gt>set_ugid($uid, $gid)

sets the values of the uid and gid fields, or removes them if they are
undefined values. The flags field is adjusted.

This pair of fields can not be set separately because they share the
same bit on the flags field and so both have to be set or not.

=item $attr-E<gt>set_amtime($atime, $mtime)

sets the values of the atime and mtime fields or remove them if they
are undefined values. The flags field is also adjusted.

=item $attr-E<gt>set_extended(%extended)

sets the vendor-dependent extended attributes

=item $attr-E<gt>append_extended(%more_extended)

adds more pairs to the list of vendor-dependent extended attributes

=back

=head1 COPYRIGHT

Copyright (c) 2006-2008 Salvador FandiE<ntilde>o.

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
