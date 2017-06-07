package Tie::Simple::Handle;
$Tie::Simple::Handle::VERSION = '1.04';
use strict;
use warnings;

use base qw(Tie::Handle Tie::Simple);

# Copyright 2004, 2015 Andrew Sterling Hanenkamp. This software
# is made available under the same terms as Perl itself.

sub _doit {
	my $self = shift;
	Tie::Simple::Util::_doit($self, 'Tie::Handle', @_);
}

sub WRITE { shift->_doit('WRITE', @_) }
sub PRINT { shift->_doit('PRINT', @_) }
sub PRINTF { shift->_doit('PRINTF', @_) }
sub READ { shift->_doit('READ', @_) }
sub READLINE { shift->_doit('READLINE') }
sub GETC { shift->_doit('GETC') }
sub CLOSE { shift->_doit('CLOSE') }
sub UNTIE { shift->_doit('UNTIE') }
sub DESTROY { shift->_doit('DESTROY') }

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Simple::Handle

=head1 VERSION

version 1.04

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
