#! /bin/sh

# This Shell test attempts to parse the command line options from the
# script and it's help in order to locate non-described and non-existing
# command line options.

for i in $(find . -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print)
do
    ./$i --help </dev/null 2>/dev/null \
        | perl -e '
            use strict;
            use warnings;

            my $script = shift @ARGV;

            my @file_options;
            my @help_options;

            while( <> ) {
                if( /^\s*((?:-[a-zA-Z\-_\d]+,\s*)*)(-[a-zA-Z\-_\d]+)/ ) {
                    push( @help_options, $2 );
                    push( @help_options, split( /,\s*/, $1 ) ) if $1;
                }
            }

            open( my $help, $script );
            my $getoptions_seen = 0;
            while( <$help> ) {
                if( $getoptions_seen ) {
                    last if /^\);$/;
                    if( /^\s*(["])(-[^\1]+?)\1/ ) {
                        push( @file_options, split( ",", $2 ) );
                    }
                } else {
                    $getoptions_seen = 1 if /@ARGV\s+=\s+getOptions/;
                }
            }

            # print join( "\n", sort @help_options ) . "\n--------\n";
            # print join( "\n", sort @file_options ) . "\n--------\n";

            my %help_options = map { $_ => 1 } @help_options;
            my %file_options = map { $_ => 1 } @file_options;

            my @not_described;
            for my $key (@file_options) {
                push( @not_described, $key ) if !exists $help_options{$key};
            }

            if( @not_described ) {
                print "$script: options " .
                    join( ", ", map { "\"$_\"" } @not_described ) .
                    " are not described in help.\n";
            }

            my @not_existing;
            for my $key (@help_options) {
                push( @not_existing, $key ) if !exists $file_options{$key};
            }

            if( @not_existing ) {
                print "$script: options " .
                    join( ", ", map { "\"$_\"" } @not_existing ) .
                    " are described in help, but no longer exist.\n";
            }' $i
done
