package Git::Wrapper::File::RawModification;
# ABSTRACT: Modification of a file in a commit
$Git::Wrapper::File::RawModification::VERSION = '0.047';
use 5.006;
use strict;
use warnings;

sub new {
  my ($class, $filename, $type, $perms_from, $perms_to, $blob_from, $blob_to) = @_;

  my $score;
  if ( defined $type && $type =~ s{^(.)([0-9]+)$}{$1} ) {
    $score = $2;
    (undef, $filename) = split(qr{\s+}, $filename, 2 );
  }

  return bless {
    filename   => $filename,
    type       => $type,
    score      => $score,
    perms_from => $perms_from,
    perms_to   => $perms_to,
    blob_from  => $blob_from,
    blob_to    => $blob_to,
  } => $class;
}

sub filename   { shift->{filename} }
sub type       { shift->{type} }
sub score      { shift->{score} }

sub perms_from { shift->{perms_from} }
sub perms_to   { shift->{perms_to} }

sub blob_from  { shift->{blob_from} }
sub blob_to    { shift->{blob_to} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::File::RawModification - Modification of a file in a commit

=head1 VERSION

version 0.047

=head1 METHODS

=head2 new

Constructor

=head2 filename

=head2 type

=head2 score

=head2 perms_from

=head2 perms_to

=head2 blob_from

=head2 blob_to

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
