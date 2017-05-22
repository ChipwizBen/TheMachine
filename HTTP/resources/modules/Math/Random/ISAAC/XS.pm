package Math::Random::ISAAC::XS;
BEGIN {
  $Math::Random::ISAAC::XS::VERSION = '1.004';
}
# ABSTRACT: C implementation of the ISAAC PRNG algorithm

use strict;
use warnings;


# This is the code that actually bootstraps the module and exposes
# the interface for the user. XSLoader is believed to be more
# memory efficient than DynaLoader.
use XSLoader;
XSLoader::load(__PACKAGE__, $Math::Random::ISAAC::XS::VERSION);


__END__
=pod

=head1 NAME

Math::Random::ISAAC::XS - C implementation of the ISAAC PRNG algorithm

=head1 VERSION

version 1.004

=head1 SYNOPSIS

This module implements the same interface as C<Math::Random::ISAAC> and can
be used as a drop-in replacement. This is the recommended implementation of
the module, based on Bob Jenkins' reference implementation in C.

Selecting the backend to use manually really only has two uses:

=over

=item *

If you are trying to avoid the small overhead incurred with dispatching
method calls to the appropriate backend modules.

=item *

If you are testing the module for performance and wish to explicitly decide
which module you would like to use.

=back

Example code:

  # With Math::Random::ISAAC
  my $rng = Math::Random::ISAAC->new(time);
  my $rand = $rng->rand();

  # With Math::Random::ISAAC::XS
  my $rng = Math::Random::ISAAC::XS->new(time);
  my $rand = $rng->rand();

=head1 DESCRIPTION

See L<Math::Random::ISAAC> for the full description.

=head1 METHODS

=head2 new

  Math::Random::ISAAC::XS->new( @seeds )

Implements the interface as specified in C<Math::Random::ISAAC>

=head2 rand

  $rng->rand()

Implements the interface as specified in C<Math::Random::ISAAC>

=head2 irand

  $rng->irand()

Implements the interface as specified in C<Math::Random::ISAAC>

=head1 SEE ALSO

L<Math::Random::ISAAC>

1;

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Random-ISAAC-XS

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jonathan Yu <jawnsy@cpan.org>

=head1 COPYRIGHT AND LICENSE

Legally speaking, this package and its contents are:

  Copyright (c) 2011 by Jonathan Yu <jawnsy@cpan.org>.

But this is really just a legal technicality that allows the author to
offer this package under the public domain and also a variety of licensing
options. For all intents and purposes, this is public domain software,
which means you can do whatever you want with it.

The software is provided "AS IS", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.

=cut

