package Tie::Simple;
$Tie::Simple::VERSION = '1.04';
use strict;
use warnings;

use Tie::Simple::Scalar;
use Tie::Simple::Array;
use Tie::Simple::Hash;
use Tie::Simple::Handle;

# ABSTRACT: Variable ties made easier: much, much, much easier...


sub TIESCALAR {
    my ($class, $data, %subs) = @_;
    bless { data => $data, subs => \%subs }, 'Tie::Simple::Scalar';
}

sub TIEARRAY {
    my ($class, $data, %subs) = @_;
    bless { data => $data, subs => \%subs }, 'Tie::Simple::Array';
}

sub TIEHASH {
    my ($class, $data, %subs) = @_;
    bless { data => $data, subs => \%subs }, 'Tie::Simple::Hash';
}

sub TIEHANDLE {
    my ($class, $data, %subs) = @_;
    bless { data => $data, subs => \%subs }, 'Tie::Simple::Handle';
}


1

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Simple - Variable ties made easier: much, much, much easier...

=head1 VERSION

version 1.04

=head1 SYNOPSIS

  use Tie::Simple;

  tie $scalar, 'Tie::Simple', $data,
      FETCH     => sub { ... },
      STORE     => sub { ... };

  tie @array, 'Tie::Simple', $data,
      FETCH     => sub { ... },
      STORE     => sub { ... },
      FETCHSIZE => sub { ... },
      STORESIZE => sub { ... },
      EXTEND    => sub { ... },
      EXISTS    => sub { ... },
      DELETE    => sub { ... },
      CLEAR     => sub { ... },
      PUSH      => sub { ... },
      POP       => sub { ... },
      SHIFT     => sub { ... },
      UNSHIFT   => sub { ... },
      SPLICE    => sub { ... };

  tie %hash, 'Tie::Simple', $data,
      FETCH     => sub { ... },
      STORE     => sub { ... },
      DELETE    => sub { ... },
      CLEAR     => sub { ... },
      EXISTS    => sub { ... },
      FIRSTKEY  => sub { ... },
      NEXTKEY   => sub { ... };

  tie *HANDLE, 'Tie::Simple', $data,
      WRITE     => sub { ... },
      PRINT     => sub { ... },
      PRINTF    => sub { ... },
      READ      => sub { ... },
      READLINE  => sub { ... },
      GETC      => sub { ... },
      CLOSE     => sub { ... };

=head1 DESCRIPTION

This module adds the ability to quickly create new types of tie objects without
creating a complete class. It does so in such a way as to try and make the
programmers life easier when it comes to single-use ties that I find myself
wanting to use from time-to-time.

The C<Tie::Simple> package is actually a front-end to other classes which
really do all the work once tied, but this package does the dwimming to
automatically figure out what you're trying to do.

I've tried to make this as intuitive as possible and dependent on other bits of
Perl where I can to minimize the need for documentation and to make this extra,
extra spiffy.

=head1 SIMPLE TYING

To setup your quick tie, simply start with the typical tie statement on the
variable you're tying. You should always tie to the C<Tie::Simple> package and
not directly to the other packages included with this module as those are only
present as helpers (even though they are really the tie classes).

The type of tie depends upon the type of the first argument given to tie. This
should be rather obvious from the L</SYNOPSIS> above. Therefore, the arguments
are:

=over

=item 1.

The variable to be tied.

=item 2.

The string C<'Tie::Simple'>.

=item 3.

A scalar value (hereafter called the "local data").

=item 4.

A list of name/CODE pairs.

=back

At this point, you'll need to have some understanding of tying before you can
continue. I suggest looking through L<perltie>.

As you will note in the L<perltie> documentation, every tie package defines
functions whose first argument is called C<this>. The third argument,
local data, will take the place of C<this> in all the subroutine calls you
define in the name/CODE pair list. Each name should be the name of the function
that would be defined for the appropriate tie-type if you were to do a
full-blown package definition. The subroutine matched to that name will take
the exact arguments specified in the L<perltie> documentation, but instead of
C<this> it will be given the local data scalar value you set (which could even
be C<undef> if you don't need it).

=head1 TIES CAN BE SIMPLER STILL

The synopsis above shows the typical subroutines you could define. (I left out
the C<UNTIE> and C<DESTROY> methods, but you may define these if you need them,
but be sure to read the L<perltie> documentation on possible caveats.) However,
the L</SYNOPSIS> is way more complete then you probably need to be in most
cases. This is because C<Tie::Simple> does it's best to make use of some of
the handy Perl built-ins which help with creating tie packages.

=head2 SCALARS

If you are creating a scalar tie, then you can assume all the benefits of being
a L<Tie::Scalar>.

=head2 ARRAYS

If you are creating an array tie, then you may assume all the benefits of being
a L<Tie::Array>.

=head2 HASHES

If you are creating a hash tie, then you may assume all the benefits of being a
L<Tie::Hash>.

=head2 HANDLES

If you are creating a handle tie, then you may assume all the benefits of being
a L<Tie::Handle>.

=head1 TO DO

It sure would be nice if you could declare custom C<@ISA> lists, wouldn't it?
I'd like to add such a feature, but coming up with some custom C<SUPER::>
dispatch code or generating new "anonymous" packages are the only ways I can
think to do it. I don't really have time to add such a feature just now.

=head1 SEE ALSO

L<perltie>, L<Tie::Scalar>, L<Tie::Array>, L<Tie::Hash>, L<Tie::Handle>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
