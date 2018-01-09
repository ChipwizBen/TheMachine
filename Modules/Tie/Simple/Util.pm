package Tie::Simple::Util;
$Tie::Simple::Util::VERSION = '1.04';
use strict;
use warnings;

# Copyright 2004, 2015 Andrew Sterling Hanenkamp. This software
# is made available under the same terms as Perl itself.

sub _doit {
	my $self = shift;
	my $parent = shift;
	my $method = shift;

	if (defined $$self{subs}{$method}) {
		$$self{subs}{$method}->($$self{data}, @_);
	} elsif ($parent->can($method)) {
		no strict 'refs';
		my $sub = "$parent\::$method";
		&{$sub}($self, @_);
	}
}

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Simple::Util

=head1 VERSION

version 1.04

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
