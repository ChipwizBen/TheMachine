package Git::Wrapper::Log;
# ABSTRACT: Log line of the Git
$Git::Wrapper::Log::VERSION = '0.047';
use 5.006;
use strict;
use warnings;

sub new {
  my ($class, $id, %arg) = @_;
  my $modifications = defined $arg{modifications} ? delete $arg{modifications} : [];
  return bless {
    id            => $id,
    attr          => {},
    modifications => $modifications,
    %arg,
  } => $class;
}

sub id   { shift->{id} }
sub attr { shift->{attr} }

sub modifications {
  my $self = shift;
  if (@_ > 0) {
    $self->{modifications} = [@_];
    return scalar @{$self->{modifications}};
  }
  else { return @{$self->{modifications}} }
}

sub message { @_ > 1 ? ($_[0]->{message} = $_[1]) : $_[0]->{message} }

sub date { shift->attr->{date} }

sub author { shift->attr->{author} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Log - Log line of the Git

=head1 VERSION

version 0.047

=head1 METHODS

=head2 new

=head2 modifications

=head2 attr

=head2 author

=head2 date

=head2 id

=head2 message

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
