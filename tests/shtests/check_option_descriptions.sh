#! /bin/sh

# This Shell test attempts to parse the command line options from the
# script and it's help in order to locate non-described and non-existing
# command line options.

for i in $(find scripts -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print | sort)
do
    SCRIPT_TYPE=''
    if grep -qlF '#!perl -w # --*- Perl -*--' $i; then
        SCRIPT_TYPE='perl'
    elif grep -qlE '#!\s*/bin/sh' $i; then
        SCRIPT_TYPE='sh'
    elif grep -qlE '#!\s*/bin/bash' $i; then
        SCRIPT_TYPE='bash'
    elif grep -qlE '#!\s*/usr/bin/python' $i; then
        SCRIPT_TYPE='python'
    else
        echo "$i:: WARNING, could not determine the interpreter for the script."
    fi

    ./$i --help </dev/null 2>/dev/null \
        | perl -e '
            use strict;
            use warnings;

            my $script      = shift @ARGV;
            my $interpreter = shift @ARGV;

            my @file_options;
            my @help_options;

            while( <> ) {
                if( /^\s*((?:-[a-zA-Z\-_\d]+,\s*)*)(-[a-zA-Z\-_\d]+)/ ) {
                    # skip built-in help options in Python scripts
                    if ( $interpreter eq "python" &&
                        $2 =~ /^((-h)|(--help))$/ ) {
                        next;
                    };
                    push( @help_options, $2 );
                    push( @help_options, split( /,\s*/, $1 ) ) if $1;
                }
            }

            open( my $help, $script );
            my $getoptions_seen = 0;
            if ( $interpreter eq "perl" ) {
                while( <$help> ) {
                    if( $getoptions_seen ) {
                        # ignore the '--options' option
                        next if /--options/;
                        last if /^\);$/;
                        if( /^\s*(["])(-[^\1]+?)\1/ ) {
                            push( @file_options, split( /,\s*/, $2 ) );
                        }
                    } else {
                        $getoptions_seen = 1 if /@ARGV\s+=\s+getOptions/;
                    }
                }
            } elsif ( $interpreter eq "sh" || $interpreter eq "bash" ) {
                my @substr;
                while( <$help> ) {
                    if( $getoptions_seen ) {
                        last if /^done$/;
                        if( /^\s*(-.*)[\\)]/ ) {
                            push @substr, split ( qw(\|), $1 );
                        }
                    } else {
                        $getoptions_seen = 1 if /while\s+[\s+\$#\s+-gt\s+0\s+]/;
                    }
                }
                @substr = sort { length $a <=> length $b } @substr;
                for ( my $i = 0; $i < scalar(@substr); $i++ ) {
                    # ignore the safeguard catch-all option
                    next if $substr[$i] =~ /-\*/;
                    next if $substr[$i] =~ /-\?\*/;
                    # ignore the '--options' option
                    next if $substr[$i] =~ /--options/;
                    my $is_prefix = 0;
                    for ( my $j = ($i+1); $j < scalar(@substr); $j++ ) {
                        # assume short form options will not be prefixes
                        last if $substr[$i] =~ /^-[^-](-)?$/;
                        if ( $substr[$j] =~ /^$substr[$i]/ ) {
                            $is_prefix = 1;
                            last;
                        }
                    }
                    push( @file_options, $substr[$i] ) if !$is_prefix;
                }
            } elsif ( $interpreter eq "python" ) {
                # This section could potentially be removed due to the way
                # argparse.ArgumentParser handles option descriptions (if
                # the option is defined then it will automatically be printed
                # in the help message)
                while( <$help> ) {
                    if( $getoptions_seen ) {
                        last if /parse_args\(args=sys.argv\[1:\]\)/;
                        if( /parser.add_argument\("(--[^"]+)/ ) {
                            push( @file_options, $1 );
                        }
                    } else {
                        $getoptions_seen = 1 if /argparse.ArgumentParser/;
                    }
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
            }' $i $SCRIPT_TYPE
done
