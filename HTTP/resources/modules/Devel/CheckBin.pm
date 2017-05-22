package Devel::CheckBin;
use strict;
use warnings;
use 5.008001;
our $VERSION = "0.04";
use parent qw(Exporter);

our @EXPORT = qw(can_run check_bin);

use ExtUtils::MakeMaker;
use File::Spec;
use Config;

# Check if we can run some command
sub can_run {
    my ($cmd) = @_;

    my $_cmd = $cmd;
    return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

    for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
        next if $dir eq '';
        my $abs = File::Spec->catfile($dir, $cmd);
        return $abs if (-x $abs or $abs = MM->maybe_command($abs));
    }

    return;
}

sub check_bin {
    my ( $bin, $version) = @_;
    if ( $version ) {
        die "check_bin does not support versions yet";
    }

    # Locate the bin
    print "Locating bin:$bin...";
    my $found_bin = can_run( $bin );
    if ( $found_bin ) {
        print " found at $found_bin.\n";
        return 1;
    } else {
        print " missing.\n";
        print "Unresolvable missing external dependency.\n";
        print "Please install '$bin' seperately and try again.\n";
        print STDERR "NA: Unable to build distribution on this platform.\n";
        exit(0);
    }
}

1;
__END__

=for stopwords distro

=head1 NAME

Devel::CheckBin - check that a command is available

=head1 SYNOPSIS

    use Devel::CheckBin;

=head1 DESCRIPTION

Devel::CheckBin is a perl module that checks whether a particular command is available.

=head1 USING IT IN Makefile.PL or Build.PL

If you want to use this from Makefile.PL or Build.PL, do not simply copy the module into your distribution as this may cause problems when PAUSE and search.cpan.org index the distro. Instead, use the 'configure_requires'.


=head1 LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

