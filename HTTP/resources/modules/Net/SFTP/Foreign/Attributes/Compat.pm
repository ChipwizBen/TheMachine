package Net::SFTP::Foreign::Attributes::Compat;

our $VERSION = '0.01';

use strict;
use warnings;

use Net::SFTP::Foreign::Attributes;
our @ISA = qw(Net::SFTP::Foreign::Attributes);

my @fields = qw( flags size uid gid perm atime mtime );

for my $f (@fields) {
    no strict 'refs';
    *$f = sub { @_ > 1 ? $_[0]->{$f} = $_[1] : $_[0]->{$f} || 0 }
}

sub new {
    my ($class, %param) = @_;

    my $a = $class->SUPER::new();

    if (my $stat = $param{Stat}) {
	$a->set_size($stat->[7]);
	$a->set_ugid($stat->[4], $stat->[5]);
	$a->set_perm($stat->[2]);
	$a->set_amtime($stat->[8], $stat->[9]);
    }
    $a;
}

1;
__END__

=head1 NAME

Net::SFTP::Foreign::Attributes::Compat - adapter for Net::SFTP::Attributes compatibility

=head1 SYNOPSIS

    use Net::SFTP::Foreign::Attributes::Compat;
    my $attrs = Net::SFTP::Foreign::Attributes->new(Stat => [ stat "foo" ]);
    my $size = $attrs->size;

=head1 DESCRIPTION

This module provides a wrapper for L<Net::SFTP::Foreign::Attributes>
exposing an API compatible to L<Net::SFTP::Attributes>.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SFTP::Foreign manpage for author, copyright, and
license information.

=cut
