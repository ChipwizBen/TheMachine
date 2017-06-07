use 5.006;
use strict;
use warnings;

package Git::Wrapper;
#ABSTRACT: Wrap git(7) command-line interface
$Git::Wrapper::VERSION = '0.047';
our $DEBUG=0;

# Prevent ANSI color with extreme prejudice
# https://github.com/genehack/Git-Wrapper/issues/13
delete $ENV{GIT_PAGER_IN_USE};

use File::chdir;
use File::Temp;
use IPC::Open3      qw();
use Scalar::Util    qw(blessed);
use Sort::Versions;
use Symbol;

use Git::Wrapper::Exception;
use Git::Wrapper::File::RawModification;
use Git::Wrapper::Log;
use Git::Wrapper::Statuses;

sub new {
  my $class = shift;

  # three calling conventions
  # 1: my $gw = Git::Wrapper->new( $dir )
  # 2: my $gw = Git::Wrapper->new( $dir , %options )
  # 3: my $gw = Git::Wrapper->new({ dir => $dir , %options });

  my $args;

  if ( scalar @_ == 1 ) {
    my $arg = shift;
    if ( ref $arg eq 'HASH' ) { $args = $arg }
    elsif ( blessed $arg )    { $args = { dir => "$arg" } }  # my objects, let me
                                                             # show you them.
    elsif ( ! ref $arg )      { $args = { dir =>  $arg  } }
    else { die "Single arg must be hashref, scalar, or stringify-able object" }
  }
  else {
    my( $dir , %opts ) = @_;
    $dir = "$dir" if blessed $dir; # we can stringify it for you wholesale
    $args = { dir => $dir , %opts }
  }

  my $self = bless $args => $class;

  die "usage: $class->new(\$dir)" unless $self->dir;

  return $self;
}

sub AUTOLOAD {
  my $self = shift;

  (my $meth = our $AUTOLOAD) =~ s/.+:://;
  return if $meth eq 'DESTROY';

  $meth =~ tr/_/-/;

  return $self->RUN($meth, @_);
}

sub ERR { shift->{err} }
sub OUT { shift->{out} }

sub RUN {
  my $self = shift;

  delete $self->{err};
  delete $self->{out};

  my $cmd = shift;

  my( $parts , $stdin ) = _parse_args( $cmd , @_ );

  my @cmd = ( $self->git , @$parts );

  my( @out , @err );

  {
    local $CWD = $self->dir unless $cmd eq 'clone';

    my ($wtr, $rdr, $err);

    local *TEMP;
    if ($^O eq 'MSWin32' && defined $stdin) {
      my $file = File::Temp->new;
      $file->autoflush(1);
      $file->print($stdin);
      $file->seek(0,0);
      open TEMP, '<&=', $file;
      $wtr = '<&TEMP';
      undef $stdin;
    }

    $err = Symbol::gensym;

    print STDERR join(' ',@cmd),"\n" if $DEBUG;

    # Prevent commands from running interactively
    local $ENV{GIT_EDITOR} = ' ';

    my $pid = IPC::Open3::open3($wtr, $rdr, $err, @cmd);
    print $wtr $stdin
      if defined $stdin;

    close $wtr;
    chomp(@out = <$rdr>);
    chomp(@err = <$err>);

    waitpid $pid, 0;
  };

  print "status: $?\n" if $DEBUG;

  # In earlier gits (1.5, 1.6, I'm not sure when it changed), "git status"
  # would exit 1 if there was nothing to commit, or in other cases. This is
  # basically insane, and has been fixed, but if we don't require git 1.7, we
  # should cope with it. -- rjbs, 2012-03-31
  my $stupid_status = $cmd eq 'status' && @out && ! @err;

  if ($? && ! $stupid_status) {
    die Git::Wrapper::Exception->new(
      output => \@out,
      error  => \@err,
      status => $? >> 8,
    );
  }

  chomp(@err);
  $self->{err} = \@err;

  chomp(@out);
  $self->{out} = \@out;

  return @out;
}

sub branch {
  my $self = shift;

  my $opt = ref $_[0] eq 'HASH' ? shift : {};
  $opt->{no_color} = 1;

  return $self->RUN(branch => $opt,@_);
}

sub dir { shift->{dir} }

sub git {
  my $self = shift;

  return $self->{git_binary} if defined $self->{git_binary};

  return ( defined $ENV{GIT_WRAPPER_GIT} ) ? $ENV{GIT_WRAPPER_GIT} : 'git';
}

sub has_git_in_path {
  require IPC::Cmd;
  IPC::Cmd::can_run('git');
}

sub log {
  my $self = shift;

  if ( grep /format=/, @_ ) {
    die Git::Wrapper::Exception->new(
      error  => [qw/--format not allowed. Use the RUN() method if you with to use a custom log format./],
      output => undef,
      status => 255 ,
    );
  }

  my $opt  = ref $_[0] eq 'HASH' ? shift : {};
  $opt->{no_color}         = 1;
  $opt->{pretty}           = 'medium';
  $opt->{no_abbrev}        = 1;  # https://github.com/genehack/Git-Wrapper/issues/67

  $opt->{no_abbrev_commit} = 1
    if $self->supports_log_no_abbrev_commit;
  $opt->{no_expand_tabs} = 1
    if $self->supports_log_no_expand_tabs;

  my $raw = defined $opt->{raw} && $opt->{raw};

  my @out = $self->RUN(log => $opt, @_);

  my @logs;
  while (my $line = shift @out) {
    die "unhandled: $line" unless $line =~ /^commit (\S+)/;

    my $current = Git::Wrapper::Log->new($1);

    $line = shift @out;         # next line;

    while ($line =~ /^(\S+):\s+(.+)$/) {
      $current->attr->{lc $1} = $2;
      $line = shift @out;       # next line;
    }

    die "no blank line separating head from message" if $line;

    my ( $initial_indent ) = $out[0] =~ /^(\s*)/ if @out;

    my $message = '';
    while (
      @out
        and $out[0] !~ /^commit (\S+)/
          and length($line = shift @out)
        ) {
      $line =~ s/^$initial_indent//; # strip just the indenting added by git
      $message .= "$line\n";
    }

    $current->message($message);

    if ($raw) {
      my @modifications;

      # example outputs:
      #  regular:
      # :000000 100644 0000000000000000000000000000000000000000 ce013625030ba8dba906f756967f9e9ca394464a A     foo/bar
      #  with score value after file type (see https://github.com/genehack/Git-Wrapper/issues/70):
      # :100644 100644 c659037... c659037... R100       foo bar
      while(@out and $out[0] =~ m/^\:(\d{6}) (\d{6}) (\w{40}) (\w{40}) (\w{1}[0-9]*)\t(.*)$/) {
        push @modifications, Git::Wrapper::File::RawModification->new($6,$5,$1,$2,$3,$4);
        shift @out;
      }
      $current->modifications(@modifications) if @modifications;
    }

    push @logs, $current;

    last unless @out; # handle running out of log
    shift @out unless $out[0] =~ /^commit/;  # blank line at end of entry, except merge commits;
  }

  return @logs;
}

my %STATUS_CONFLICTS = map { $_ => 1 } qw<DD AU UD UA DU AA UU>;

sub status {
  my $self = shift;

  return $self->RUN('status' , @_ )
    unless $self->supports_status_porcelain;

  my $opt  = ref $_[0] eq 'HASH' ? shift : {};
  $opt->{$_} = 1 for qw<porcelain>;

  my @out = $self->RUN(status => $opt, @_);

  my $statuses = Git::Wrapper::Statuses->new;

  return $statuses if !@out;

  for (@out) {
    my ($x, $y, $from, $to) = $_ =~ /\A(.)(.) (.*?)(?: -> (.*))?\z/;

    if ($STATUS_CONFLICTS{"$x$y"}) {
      $statuses->add('conflict', "$x$y", $from, $to);
    }
    elsif ($x eq '?' && $y eq '?') {
      $statuses->add('unknown', '?', $from, $to);
    }
    else {
      $statuses->add('changed', $y, $from, $to)
        if $y ne ' ';
      $statuses->add('indexed', $x, $from, $to)
        if $x ne ' ';
    }
  }
  return $statuses;
}

sub supports_hash_object_filters {
  my $self = shift;

  # The '--no-filters' option to 'git-hash-object' was added in version 1.6.1
  return 0 if ( versioncmp( $self->version , '1.6.1' ) eq -1 );
  return 1;
}

sub supports_log_no_abbrev_commit {
  my $self = shift;

  # The '--no-abbrev-commit' option to 'git log' was added in version 1.7.6
  return ( versioncmp( $self->version , '1.7.6' ) eq -1 ) ? 0 : 1;
}

sub supports_log_no_expand_tabs {
  my $self = shift;

  # The '--no-expand-tabs' option to git log was added in version 2.9.0
  return 0 if ( versioncmp( $self->version , '2.9' ) eq -1 );
  return 1;
}

sub supports_log_raw_dates {
  my $self = shift;

  # The '--date=raw' option to 'git log' was added in version 1.6.2
  return 0 if ( versioncmp( $self->version , '1.6.2' ) eq -1 );
  return 1;
}

sub supports_status_porcelain {
  my $self = shift;

  # The '--porcelain' option to git status was added in version 1.7.0
  return 0 if ( versioncmp( $self->version , '1.7' ) eq -1 );
  return 1;
}

sub version {
  my $self = shift;

  my ($version) = $self->RUN('version');

  $version =~ s/^git version //;

  return $version;
}

sub _message_tempfile {
  my ( $message ) = @_;

  my $tmp = File::Temp->new( UNLINK => 0 );
  $tmp->print( $message );

  return ( "file", '"'.$tmp->filename.'"' );
}

sub _opt_and_val {
  my( $name , $val ) = @_;

  $name =~ tr/_/-/;
  my $opt = length($name) == 1
    ? "-$name"
      : "--$name"
        ;

  return
      $val eq '1' ? ($opt)
    : length($name) == 1 ? ($opt, $val)
    :                      "$opt=$val";
}

sub _parse_args {
  my $cmd = shift;
  die "initial argument must not be a reference\n"
    if ref $cmd;

  my( $stdin , @pre_cmd , @post_cmd );

  foreach ( @_ ) {
    if ( ref $_ eq 'HASH' ) {
      $stdin = delete $_->{-STDIN}
        if exists $_->{-STDIN};

      for my $name ( sort keys %$_ ) {
        my $val = delete $_->{$name};
        next if $val eq '0';

        if ( $name =~ s/^-// ) {
          push @pre_cmd , _opt_and_val( $name , $val );
        }
        else {
          ( $name, $val ) = _message_tempfile( $val )
            if _win32_multiline_commit_msg( $cmd, $name, $val );

          push @post_cmd , _opt_and_val( $name , $val );
        }
      }
    }
    elsif ( blessed $_ ) {
      push @post_cmd , "$_";      # here be anteaters
    }
    elsif ( ref $_ ) {
      die "Git::Wrapper command arguments must be plain scalars, hashrefs, "
        . "or stringify-able objects.\n";
    }
    else { push @post_cmd , $_; }
  }

  return( [ @pre_cmd , $cmd , @post_cmd ] , $stdin );
}

sub _win32_multiline_commit_msg {
  my ( $cmd, $name, $val ) = @_;

  return 0 if $^O ne "MSWin32";
  return 0 if $cmd ne "commit";
  return 0 if $name ne "m" and $name ne "message";
  return 0 if $val !~ /\n/;

  return 1;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper - Wrap git(7) command-line interface

=head1 VERSION

version 0.047

=head1 SYNOPSIS

  my $git = Git::Wrapper->new('/var/foo');

  $git->commit(...)
  print $_->message for $git->log;

  # specify which git binary to use
  my $git = Git::Wrapper->new({
    dir        => '/var/foo ,
    git_binary => '/path/to/git/bin/git' ,
  });

=head1 DESCRIPTION

Git::Wrapper provides an API for git(7) that uses Perl data structures for
argument passing, instead of CLI-style C<--options> as L<Git> does.

=head1 METHOD INVOCATION

Except as documented, every git subcommand is available as a method on a
Git::Wrapper object. Replace any hyphens in the git command with underscores
(for example, C<git init-db> would become C<< $git->init_db >>).

=head2 Method Arguments

Methods accept a combination of hashrefs and scalars, which is used to build
the command used to invoke git. Arguments passed in hashrefs will be
automatically parsed into option pairs, but the ordering of these in the
resulting shell command is not guaranteed (with the exception of options with
a leading '-'; see below). Options that are passed as plain scalars will
retain their order. Some examples may help clarify. This code:

  $git->commit({ message => "stuff" , all => 1 });

may produce this shell command:

  git commit --all --message="stuff"

This code, however:

  $git->commit(qw/ --message "stuff" / , { all => 1 });

will always produce this shell command:

  git commit --message "stuff" --all

In most cases, this exact control over argument ordering is not needed and
simply passing all options as part of a hashref, and all other options as
additional list arguments, will be sufficient. In some cases, however, the
ordering of options to particular git sub-commands is significant, resulting
in the need for this level of control.

I<N.b.> Options that are given with a leading '-' (with the exception of
special options noted below) are applied as arguments to the C<git> command
itself; options without a leading '-' are applied as arguments to the
sub-command. For example:

  $git->command({ -foo => 1 , bar => 2 });

invokes the command line

  git --foo=1 command --bar=2

I<N.b.> Because of the way arguments are parsed, should you need to pass an
explicit '0' value to an option (for example, to have the same effect as
C<--abbrev=0> on the command line), you should pass it with a leading space, like so:

  $git->describe({ abbrev => ' 0' };

To pass content via STDIN, use the -STDIN option:

  $git->hash_object({ stdin => 1, -STDIN => 'content to hash' });

Output is available as an array of lines, each chomped.

  @sha1s_and_titles = $git->rev_list({ all => 1, pretty => 'oneline' });

=head3 Passing stringify-able objects as arguments

Objects may be passed in the place of scalars, assuming those objects overload
stringification in such a way as to produce a useful value. However, relying
on this stringification is discouraged and likely to be officially deprecated
in a subsequent release. Instead, if you have an object that stringifies to a
meaningful value (I<e.g.>, a L<Path::Class> object), you should stringify it
yourself before passing it to C<Git::Wrapper> methods.

=head2 Error handling

If a git command exits nonzero, a C<Git::Wrapper::Exception> object will be
thrown (via C<die>) and may be capture via C<eval> or L<Try::Tiny>, for
example.

The error object has three useful methods:

=over

=item * error

Returns the full error message reported by the resulting git command sent to
C<STDERR>. This method should not be used as a success/failure check, as
C<git> will sometimes produce output on STDERR when a command is successful.

=item * output

Returns the full output generated by the git command that is sent to
C<STDOUT>.  This method should not be used as a success/failure check, as
C<git> will frequently not have any output with a successful command.

=item * status

Returns the non-zero exit code reported by git on error

=back

=head3 Using Try::Tiny

L<Try::Tiny> is the recommended way to catch exception objects thrown by
L<Git::Wrapper>.

  use Try::Tiny

  my $git = Git::Wrapper->new('/path/to/my/repo');

  try {
    # equivalent to, "git --non-existent-option=1" on the commandline
    $git->status({ "non-existent-option"=>1 });
  }
  catch {
    # print STERR from erroneous git command
    print $_->error;

    # print STOUT from git command
    print $_->output;

    # print non-zero exist status of git processo
    print $_->status;

    # quotes are overloaded, so:
    print "$_"; # equivalent to $_->error
  };

=head3 Using C<eval>

If for some reason you are unable to use L<Try::Tiny>, it is also possible to
use the C<eval> function to catch exception objects. B<THIS IS NOT
RECOMMENDED!>

  my $git = Git::Wrapper->new('/path/to/my/repo');

  my $ok = eval {
    # equivalent to, "git --non-existent-option=1" on the commandline
    $git->status({ "non-existent-option"=>1 });
    1;
  };

  if ($@ and ref $@ eq q{Git::Wrapper::Exception}) {
    # print STERR from erroneous git command
    print $@->error;

    # print STOUT from git command
    print $@->output;

    # print non-zero exist status of git processo
    print $@->status;

    # quotes are overloaded, so:
    print "$@"; # equivalent to $@->error
  }

=head1 METHODS

=head2 new

  my $git = Git::Wrapper->new($dir);
  my $git = Git::Wrapper->new({ dir => $dir , git_binary => '/path/to/git' });

  # To force the git binary location
  my $git = Git::Wrapper->new($dir, 'git_binary' => '/usr/local/bin/git');

=head2 git

  print $git->git; # /path/to/git/binary/being/used

=head2 dir

  print $git->dir; # /var/foo

=head2 version

  my $version = $git->version; # 1.6.1.4.8.15.16.23.42

=head2 branch

  my @branches = $git->branch;

This command intentionally disables ANSI color highlighting in the output. If
you want ANSI color highlighting, you'll need to bypass via the RUN() method
(see below).

=head2 log

  my @logs = $git->log;

Instead of giving back an arrayref of lines, the C<log> method returns a list
of C<Git::Wrapper::Log> objects.

There are five methods in a C<Git::Wrapper::Log> objects:

=over

=item * id

=item * author

=item * date

=item * message

=item * modifications

Only populated with when C<< raw => 1 >> option is set; see L<Raw logs> below.

=back

=head3 Raw logs

Calling the C<log> method with the C<< raw => 1 >> option set, as below, will
do additional parsing to populate the C<modifications> attribute on each
C<Git::Wrapper::Log> object. This method returns a list of
C<Git::Wrapper::File::RawModification> objects, with can be used to get
filenames, permissions, and other metadata associated with individual files in
the given commit. A short example, to loop over all commits in the log and
print the filenames that were changed in each commit, one filename per file:

    my @logs = $git->log({ raw => 1 });
    foreach my $log ( @logs ) {
        say "In commit '" . $log->id . "', the following files changed:";
        my @mods = $log->modifications;
        foreach my $mod ( @mods ) {
            say "\t" . $mod->filename;
        }
    }

Note that some commits (e.g., merge commits) will not contain any file
changes. The C<modifications> method will return an empty list in that case.

=head3 Custom log formats

C<log> will throw an exception if it is passed the C<--format> option. The
reason for this has to do with the fact that the parsing of the full log
output into C<Git::Wrapper::Log> objects assumes the default format provided
by `git` itself. Passing C<--format> to the underlying `git log` method affects
this assumption and the output is no longer able to be processed as intented.

If you wish to specify a custom log format, please use the L<RUN> method
directly.  The caller will be supplied with the full log output. From there,
the caller may process the output as it wishes.

=head2 has_git_in_path

This method returns a true or false value indicating if there is a 'git'
binary in the current $PATH.

=head2 supports_status_porcelain

=head2 supports_log_no_abbrev_commit

=head2 supports_log_no_expand_tabs

=head2 supports_log_raw_dates

=head2 supports_hash_object_filters

These methods return a true or false value (1 or 0) indicating whether the git
binary being used has support for these options. (The '--porcelain' option on
'git status', the '--no-abbrev-commit', '--no-expand-tabs', and '--date=raw'
options on 'git log', and the '--no-filters' option on 'git hash-object'
respectively.)

These are primarily for use in this distribution's test suite, but may also be
useful when writing code using Git::Wrapper that might be run with different
versions of the underlying git binary.

=head2 status

When running with an underlying git binary that returns false for the
L</supports_status_porcelain> method, this method will act like any other
wrapped command: it will return output as an array of chomped lines.

When running with an underlying git binary that returns true for the
L</supports_status_porcelain> method, this method instead returns an
instance of Git::Wrapper::Statuses:

  my $statuses = $git->status;

Git::Wrapper:Statuses has two public methods. First, C<is_dirty>:

  my $dirty_flag = $statuses->is_dirty;

which returns a true/false value depending on whether the repository has any
uncommitted changes.

Second, C<get>:

  my @status = $statuses->get($group)

which returns an array of Git::Wrapper::Status objects, one per file changed.

There are four status groups, each of which may contain zero or more changes.

=over

=item * indexed : Changed & added to the index (aka, will be committed)

=item * changed : Changed but not in the index (aka, won't be committed)

=item * unknown : Untracked files

=item * conflict : Merge conflicts

=back

Note that a single file can occur in more than one group. Eg, a modified file
that has been added to the index will appear in the 'indexed' list. If it is
subsequently further modified it will additionally appear in the 'changed'
group.

A Git::Wrapper::Status object has three methods you can call:

  my $from = $status->from;

The file path of the changed file, relative to the repo root. For renames,
this is the original path.

  my $to = $status->to;

Renames returns the new path/name for the path. In all other cases returns
an empty string.

  my $mode = $status->mode;

Indicates what has changed about the file.

Within each group (except 'conflict') a file can be in one of a number of
modes, although some modes only occur in some groups (eg, 'added' never appears
in the 'unknown' group).

=over

=item * modified

=item * added

=item * deleted

=item * renamed

=item * copied

=item * conflict

=back

All files in the 'unknown' group will have a mode of 'unknown' (which is
redundant but at least consistent).

The 'conflict' group instead has the following modes.

=over

=item * 'both deleted' : deleted on both branches

=item * 'both added'   : added on both branches

=item * 'both modified' : modified on both branches

=item * 'added by us'  : added only on our branch

=item * 'deleted by us' : deleted only on our branch

=item * 'added by them' : added on the branch we are merging in

=item * 'deleted by them' : deleted on the branch we are merging in

=back

See git-status man page for more details.

=head3 Example

    my $git = Git::Wrapper->new('/path/to/git/repo');
    my $statuses = $git->status;
    for my $type (qw<indexed changed unknown conflict>) {
        my @states = $statuses->get($type)
            or next;
        print "Files in state $type\n";
        for (@states) {
            print '  ', $_->mode, ' ', $_->from;
            print ' renamed to ', $_->to
                if $_->mode eq 'renamed';
            print "\n";
        }
    }

=head2 RUN

This method bypasses the output rearranging performed by some of the wrapped
methods described above (i.e., C<log>, C<status>, etc.). This can be useful
in various situations, such as when you want to produce a particular log
output format that isn't compatible with the way C<Git::Wrapper> constructs
C<Git::Wrapper::Log>, or when you want raw C<git status> output that isn't
parsed into a C<Git::Wrapper::Status> object.

This method should be called with an initial string argument of the C<git>
subcommand you want to run, followed by a hashref containing options and their
values, and then a list of any other arguments.

=head3 Example

    my $git = Git::Wrapper->new( '/path/to/git/repo' );

    # the 'log' method returns Git::Wrapper::Log objects
    my @log_objects = $git->log();

    # while 'RUN('log')' returns an array of chomped lines
    my @log_lines = $git->RUN('log');

    # getting the full of commit SHAs via `git log` by using the '--format' option
    my @log_lines = $git->RUN('log', '--format=%H');

=head2 ERR

After a command has been run, this method will return anything that was sent
to C<STDERR>, in the form of an array of chomped lines. This information will
be cleared as soon as a new command is executed. This method should B<*NOT*>
be used as a success/failure check, as C<git> will sometimes produce output on
STDERR when a command is successful.

=head2 OUT

After a command has been run, this method will return anything that was sent
to C<STDOUT>, in the form of an array of chomped lines. It is identical to
what is returned from the method call that runs the command, and is provided
simply for symmetry with the C<ERR> method. This method should B<*NOT*> be
used as a success/failure check, as C<git> will frequently not have any output
with a successful command.

=head1 COMPATIBILITY

On Win32 Git::Wrapper is incompatible with msysGit installations earlier than
Git-1.7.1-preview20100612 due to a bug involving the return value of a git
command in cmd/git.cmd. If you use the msysGit version distributed with
GitExtensions or an earlier version of msysGit, tests will fail during
installation of this module. You can get the latest version of msysGit on the
Google Code project page: L<http://code.google.com/p/msysgit/downloads>

=head1 ENVIRONMENT VARIABLES

Git::Wrapper normally uses the first 'git' binary in your path. The original
override provided to change this was by setting the GIT_WRAPPER_GIT environment
variable. Now that object creation accepts an override, you are encouraged to
instead pass the binary location (git_binary) to new on object creation.

=head1 SEE ALSO

L<VCI::VCS::Git> is the git implementation for L<VCI>, a generic interface to
version-control systems.

L<Other Perl Git Wrappers|https://metacpan.org/module/Git::Repository#OTHER-PERL-GIT-WRAPPERS>
is a list of other Git interfaces in Perl. If L<Git::Wrapper> doesn't scratch
your itch, possibly one of the modules listed there will.

Git itself is at L<http://git.or.cz>.

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
