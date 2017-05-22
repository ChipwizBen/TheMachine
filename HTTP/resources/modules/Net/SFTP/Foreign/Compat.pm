package Net::SFTP::Foreign::Compat;

our $VERSION = '1.70_05';

use warnings;
use strict;
use Carp;

require Net::SFTP::Foreign;
require Net::SFTP::Foreign::Constants;
require Net::SFTP::Foreign::Attributes::Compat;

our @ISA = qw(Net::SFTP::Foreign);

my $supplant;

sub import {
    for my $arg (@_[1..$#_]) {
	if ($arg eq ':supplant') {
            # print STDERR "suplanting Net::SFTP...\n";
	    if (!$supplant) {
		$supplant = 1;

		@Net::SFTP::ISA = qw(Net::SFTP::Foreign::Compat);
		@Net::SFTP::Attributes::ISA = qw(Net::SFTP::Foreign::Attributes::Compat);
		@Net::SFTP::Constant::ISA = qw(Net::SFTP::Foreign::Constants);

		$INC{q(Net/SFTP.pm)} = $INC{q(Net/SFTP/Foreign/Compat.pm)};
		$INC{q(Net/SFTP/Attributes.pm)} = $INC{q(Net/SFTP/Foreign/Compat.pm)};
		$INC{q(Net/SFTP/Constants.pm)} = $INC{q(Net/SFTP/Foreign/Compat.pm)};

	    }
	}
	else {
	    croak "invalid import tag '$arg'"
	}
    }
}

our %DEFAULTS = ( put => [best_effort => 1],
                  get => [best_effort => 1],
                  ls  => [],
                  new => [] );

BEGIN {
    my @forbidden = qw( setcwd cwd open opendir sftpread sftpwrite
                        seek tell eof write flush read getc lstat stat
                        fstat remove rmdir mkdir setstat fsetstat
                        close closedir readdir realpath readlink
                        rename symlink abort get_content join glob
                        rremove rget rput error die_on_error );

    for my $method (@forbidden) {
        my $super = "SUPER::$method";
        no strict 'refs';
        *{$method} = sub {
            unless (index((caller)[0], "Net::SFTP::Foreign") == 0) {
                croak "Method '$method' is not available from " . __PACKAGE__
                    . ", use the real Net::SFTP::Foreign if you want it!";
            }
            shift->$super(@_);
        };
    }
}

sub new {
    my ($class, $host, %opts) = @_;

    my $warn;
    if (exists $opts{warn}) {
	$warn = delete($opts{warn}) || sub {};
    }
    else {
	$warn = sub { warn(CORE::join '', @_, "\n") };
    }

    my $sftp = $class->SUPER::new($host, @{$DEFAULTS{new}}, %opts);

    $sftp->{_compat_warn} = $warn;

    return $sftp;

}

sub _warn {
    my $sftp = shift;
    if (my $w = $sftp->{_compat_warn}) {
	$w->(@_);
    }
}

sub _warn_error {
    my $sftp = shift;
    if (my $e = $sftp->SUPER::error) {
	$sftp->_warn($e);
    }
}

sub status {
    my $status = shift->SUPER::status;
    return wantarray ? ($status + 0, "$status") : $status + 0;
}

sub get {
    croak '$Usage: $sftp->get($local, $remote, $cb)' if @_ < 2 or @_ > 4;
    my ($sftp, $remote, $local, $cb) = @_;

    my $save = defined(wantarray);
    my @content;
    my @cb;
    if (defined $cb or $save) {
        @cb = ( callback => sub {
                    my ($sftp, $data, $off, $size) = @_;
                    $cb->($sftp, $data, $off, $size) if $cb;
                    push @content, $data if $save
                });
    }

    $sftp->SUPER::get($remote, $local,
                      @{$DEFAULTS{get}},
                      dont_save => !defined($local),
                      @cb)
        or return undef;

    if ($save) {
	return CORE::join('', @content);
    }
}

sub put {
    croak '$Usage: $sftp->put($local, $remote, $cb)' if @_ < 3 or @_ > 4;
    my ($sftp, $local, $remote, $cb) = @_;

    $sftp->SUPER::put($local, $remote,
                      @{$DEFAULTS{put}},
		      callback => $cb);
    $sftp->_warn_error;
    !$sftp->SUPER::error;
}

sub ls {
    croak '$Usage: $sftp->ls($path, $cb)' if @_ < 2 or @_ > 3;
    my ($sftp, $path, $cb) = @_;
    if ($cb) {
	$sftp->SUPER::ls($path,
                         @{$DEFAULTS{ls}},
			 wanted => sub { _rebless_attrs($_[1]->{a});
					 $cb->($_[1]);
					 0 } );
	return ();
    }
    else {
	if (my $ls = $sftp->SUPER::ls($path, @{$DEFAULTS{ls}})) {
	    _rebless_attrs($_->{a}) for @$ls;
	    return @$ls;
	}
	return ()
    }
}

sub do_open { shift->SUPER::open(@_) }

sub do_opendir { shift->SUPER::opendir(@_) }

sub do_realpath { shift->SUPER::realpath(@_) }

sub do_read {
    my $sftp = shift;
    my $read = $sftp->SUPER::sftpread(@_);
    $sftp->_warn_error;
    if (wantarray) {
	return ($read, $sftp->status);
    }
    else {
	return $read
    }
}

sub _gen_do_and_status {
    my $method = "SUPER::" . shift;
    return sub {
	my $sftp = shift;
	$sftp->$method(@_);
	$sftp->_warn_error;
	$sftp->status;
    }
}

*do_write = _gen_do_and_status('sftpwrite');
*do_close = _gen_do_and_status('close');
*do_setstat = _gen_do_and_status('setstat');
*do_fsetstat = _gen_do_and_status('setstat');
*do_remove = _gen_do_and_status('remove');
*do_rename = _gen_do_and_status('rename');
*do_mkdir = _gen_do_and_status('mkdir');
*do_rmdir = _gen_do_and_status('rmdir');

sub _rebless_attrs {
    my $a = shift;
    if ($a) {
	bless $a,  ( $supplant
		     ? "Net::SFTP::Attributes"
		     : "Net::SFTP::Foreign::Attributes::Compat" );
    }
    $a;
}

sub _gen_do_stat {
    my $name = shift;
    my $method = "SUPER::$name";
    return sub {
        croak '$Usage: $sftp->'.$name.'($local, $remote, $cb)' if @_ != 2;
	my $sftp = shift;
	if (my $a = $sftp->$method(@_)) {
	    return _rebless_attrs($a);
	}
	else {
	    $sftp->_warn_error;
	    return undef;
	}
    }
}

*do_lstat = _gen_do_stat('lstat');
*do_fstat = _gen_do_stat('fstat');
*do_stat = _gen_do_stat('stat');


1;

__END__

=head1 NAME

Net::SFTP::Foreign::Compat - Adapter for Net::SFTP compatibility

=head1 SYNOPSIS

    use Net::SFTP::Foreign::Compat;
    my $sftp = Net::SFTP::Foreign::Compat->new($host);
    $sftp->get("foo", "bar");
    $sftp->put("bar", "baz");

    use Net::SFTP::Foreign::Compat ':supplant';
    my $sftp = Net::SFTP->new($host);

=head1 DESCRIPTION

This package is a wrapper around L<Net::SFTP::Foreign> that provides
an API (mostly) compatible with that of L<Net::SFTP>.

Methods on this package are identical to those in L<Net::SFTP> except
that L<Net::SFTP::Foreign::Attributes::Compat> objects have to be used
instead of L<Net::SFTP::Attributes>.

If the C<:supplant> tag is used, this module installs also wrappers on
the C<Net::SFTP> and L<Net::SFTP::Attributes> packages so no other
parts of the program have to modified in order to move from Net::SFTP
to Net::SFTP::Foreign.

=head2 Setting defaults

The hash C<%Net::SFTP::Foreign::DEFAULTS> can be used to set default
values for L<Net::SFTP::Foreign> methods called under the hood and
otherwise not accessible through the Net::SFTP API.

The entries currently supported are:

=over

=item new => \@opts

extra options passed to Net::SFTP::Foreign constructor.

=item get => \@opts

extra options passed to Net::SFTP::Foreign::get method.

=item put => \@opts

extra options passed to Net::SFTP::Foreign::put method.

=item ls  => \@opts

extra options passed to Net::SFTP::Foreign::ls method.

=back

=head1 COPYRIGHT

Copyright (c) 2006-2008, 2011 Salvador FandiE<ntilde>o

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

