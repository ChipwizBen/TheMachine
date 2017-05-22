package Net::SFTP::Foreign::Local;

our $VERSION = '1.57';

use strict;
use warnings;
use Carp;
use File::Spec;

use Net::SFTP::Foreign::Attributes;
use Net::SFTP::Foreign::Constants qw(:error);
use Net::SFTP::Foreign::Helpers qw(_sort_entries _gen_wanted _do_nothing);
require Net::SFTP::Foreign::Common;
our @ISA = qw(Net::SFTP::Foreign::Common);

sub new {
    my $class = shift;
    my $self = { status => 0,
		 error => 0 };
    bless $self, $class;
}

sub realpath {
    $! = 0;
    File::Spec->rel2abs($_[1])
}

sub stat {
    $! = 0;
    my $a = Net::SFTP::Foreign::Attributes->new_from_stat(CORE::stat($_[1]));
    unless ($a) {
	$_[0]->_set_error(SFTP_ERR_LOCAL_STAT_FAILED, "Couldn't stat local file '$_[1]'", $!);
    }
    $a
}

sub lstat {
    $! = 0;
    my $a = Net::SFTP::Foreign::Attributes->new_from_stat(CORE::lstat($_[1]));
    unless ($a) {
	$_[0]->_set_error(SFTP_ERR_LOCAL_STAT_FAILED, "Couldn't stat local file '$_[1]'", $!);
    }
    $a
}

sub readlink {
    $! = 0;
    my $target = readlink $_[1];
    unless (defined $target) {
	$_[0]->_set_error(SFTP_ERR_LOCAL_READLINK_FAILED, "Couldn't read link '$_[1]'", $!);
    }
    $target
}

sub join {
    shift;
    my $path = File::Spec->join(@_);
    $path = File::Spec->canonpath($path);
    # print 'lfs->join("'.join('", "', @_)."\") => $path\n";
    $path
}

sub ls {
    my ($self, $dir, %opts) = @_;

    my $ordered = delete $opts{ordered};
    my $follow_links = delete $opts{follow_links};
    my $atomic_readdir = delete $opts{atomic_readdir};

    my $wanted = delete $opts{_wanted} ||
	_gen_wanted(delete $opts{wanted},
		    delete $opts{no_wanted});

    %opts and croak "invalid option(s) '".CORE::join("', '", keys %opts)."'";

    $! = 0;

    opendir(my $ldh, $dir)
	or return undef;

    my @dir;
    while (defined(my $part = readdir $ldh)) {
	my $fn = File::Spec->join($dir, $part);
	my $a = $self->lstat($fn);
	if ($a and $follow_links and S_ISLNK($a->perm)) {
	    if (my $fa = $self->stat($fn)) {
		$a = $fa;
	    }
	    else {
		$! = 0;
	    }
	}
	my $entry = { filename => $part,
		      a => $a };
	if ($atomic_readdir or !$wanted or $wanted->($self, $entry)) {
	    push @dir, $entry;
	}
    }

    if ($atomic_readdir and $wanted) {
	@dir = grep { $wanted->($self, $_) } @dir;
    }

    _sort_entries(\@dir) if $ordered;

    return \@dir;
}

1;

__END__

=head1 NAME

Net::SFTP::Foreign::Local - access local file system through Net::SFTP::Foreign API.

=head1 SYNOPSIS

    my $localfs = Net::SFTP::Foreign::Local->new;
    my @find = $localfs->find('.', no_wanted => qr/(?:\/|^).svn/);

=head1 DESCRIPTION

This module is a partial implementation of the L<Net::SFTP::Foreign>
interface for the local filesystem.

The methods currently implemented are: C<stat>, C<lstat>, C<ls> and
C<find>.

=head1 COPYRIGHT

Copyright (c) 2006 Salvador FandiE<ntilde>o.

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

