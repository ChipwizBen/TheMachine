package Tie::Simple::Array;
$Tie::Simple::Array::VERSION = '1.04';
use strict;
use warnings;

use base qw(Tie::Array Tie::Simple);

# Copyright 2004, 2015 Andrew Sterling Hanenkamp. This software
# is made available under the same terms as Perl itself.

sub _doit {
	my $self = shift;
	Tie::Simple::Util::_doit($self, 'Tie::Array', @_);
}

sub FETCH     { shift->_doit('FETCH', @_) }
sub STORE     { shift->_doit('STORE', @_) }
sub FETCHSIZE { shift->_doit('FETCHSIZE') }
sub STORESIZE { shift->_doit('STORESIZE', @_) }
sub EXTEND    { shift->_doit('EXTEND', @_) }
sub EXISTS    { shift->_doit('EXISTS', @_) }
sub DELETE    { shift->_doit('DELETE', @_) }
sub CLEAR     { shift->_doit('CLEAR') }
sub PUSH      { shift->_doit('PUSH', @_) }
sub POP       { shift->_doit('POP') }
sub SHIFT     { shift->_doit('SHIFT') }
sub UNSHIFT   { shift->_doit('UNSHIFT', @_) }
sub SPLICE    { shift->_doit('SPLICE', @_) }
sub UNTIE     { shift->_doit('UNTIE') }
sub DESTROY   { shift->_doit('DESTROY') }

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Simple::Array

=head1 VERSION

version 1.04

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
