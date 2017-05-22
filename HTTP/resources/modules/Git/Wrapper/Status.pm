use 5.006;
use strict;
use warnings;

package Git::Wrapper::Status;
# ABSTRACT: A specific status information in the Git
$Git::Wrapper::Status::VERSION = '0.047';
my %modes = (
  M   => 'modified',
  A   => 'added',
  D   => 'deleted',
  R   => 'renamed',
  C   => 'copied',
  U   => 'conflict',
  '?' => 'unknown',
  DD  => 'both deleted',
  AA  => 'both added',
  UU  => 'both modified',
  AU  => 'added by us',
  DU  => 'deleted by us',
  UA  => 'added by them',
  UD  => 'deleted by them',
);

sub new {
  my ($class, $mode, $from, $to) = @_;

  return bless {
    mode => $mode,
    from => $from,
    to   => $to,
  } => $class;
}

sub mode { $modes{ shift->{mode} } }

sub from { shift->{from} }

sub to   { defined( $_[0]->{to} ) ? $_[0]->{to} : '' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Status - A specific status information in the Git

=head1 VERSION

version 0.047

=head1 METHODS

=head2 new

=head2 mode

=head2 from

=head2 to

=head1 SEE ALSO

=head2 L<Git::Wrapper>

=head2 L<Git::Wrapper::Statuses>

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
