package Git::Wrapper::Statuses;
# ABSTRACT: Multiple git statuses information
$Git::Wrapper::Statuses::VERSION = '0.047';
use 5.006;
use strict;
use warnings;

use Git::Wrapper::Status;

sub new { return bless {} => shift }

sub add {
  my ($self, $type, $mode, $from, $to) = @_;

  my $status = Git::Wrapper::Status->new($mode, $from, $to);

  push @{ $self->{ $type } }, $status;
}

sub get {
  my ($self, $type) = @_;

  return @{ defined $self->{$type} ? $self->{$type} : [] };
}

sub is_dirty {
  my( $self ) = @_;

  return keys %$self ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Statuses - Multiple git statuses information

=head1 VERSION

version 0.047

=head1 METHODS

=head2 add

=head2 get

=head2 is_dirty

=head2 new

=head1 SEE ALSO

=head2 L<Git::Wrapper>

=head1 REPORTING BUGS & OTHER WAYS TO CONTRIBUTE

The code for this module is maintained on GitHub, at
L<https://github.com/genehack/Git-Wrapper>. If you have a patch, feel free to
fork the repository and submit a pull request. If you find a bug, please open
an issue on the project at GitHub. (We also watch the L<http://rt.cpan.org>
queue for Git::Wrapper, so feel free to use that bug reporting system if you
prefer)

=head1 AUTHORS

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Chris Prather <chris@prather.org>

=item *

John SJ Anderson <genehack@genehack.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
