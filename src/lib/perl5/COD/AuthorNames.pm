#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Subroutines for parsing and regularisation of author names.
#**

package COD::AuthorNames;

use strict;
use warnings;

use Data::Compare;
use Text::Unidecode;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    author_names_are_the_same
    canonicalize_author_name
    get_name_syntax_description
    parse_author_name
);

# TODO: The subroutine should be refactored to always return the same data
# structure. For this to happen the following changes should be implemented:
# 1) The structure should always return the original name in addition to
#    other fields;
# 2) Parser warning messages should be returned as a separate field in the
#    structure instead of raising them as Perl warnings.
# 3) $name_syntax_explained should be removed since raising this message should
#    not be the responsibility of the parser.

##
# Parse an author name according to COD (aka BibTeX) conventions and return
# a data structure with the author name components. In case the name could
# not be parsed successfully the data structure with an additional field
# that contains the unparsed name is returned.
#
# @params $unparsed_name
#       The name that should be parsed.
# @params $name_syntax_explained
#       Boolean value denoting if a warning containing the name syntax
#       description should be raised in case of unsuccessful parsing
#       (default '0').
# @return
#       The following data structure containing the parsed name:
#       {
#          # Initials of the 'first' names
#         'initials' => [ 'A.', 'B.' ],
#         'first'    => [ 'AFirst', 'BFirst' ],
#         'last'     => [ "ALast", 'BLast' ],
#         'von'      => [ 'van', 'de' ],
#         'jr'       => [ 'Jr' ],
# }
#
# or:
#
# {
#     unparsed => "unparsed name"
# }
##
sub parse_author_name
{
    my ($unparsed_name, $name_syntax_explained) = @_;

    $name_syntax_explained = 0 unless defined $name_syntax_explained;

    my %parsed_name = ( 'last'  => undef,
                        'first' => undef,
                        'von'   => undef,
                        'jr'    => undef,
                      );

    my $First = qr/[[:upper:]] (?:'[[:alpha:]])? [[:lower:]]*
                   (?: \s*-\s* [[:alpha:]] ['[:lower:]]* )?/x;
                # Armel, Miguel, O'Reily, Ding-Quan, Chun-hsien

    my $Initial = qr/[[:upper:]] [[:lower:]]? \.
                     (?: \s*-\s* [[:upper:]] [[:lower:]]? \. )?/x;
                # A., M., O., D.-Q.

    my $Last = qr/(?:
                   [[:upper:]][[:lower:]]{1,2}
                  )? # optional Mc, Da, La prefix
                   [[:upper:]] (?: '[[:alpha:]])? ['[:lower:]]*
                  (?: \s*-\s* [[:upper:]] ['[:lower:]]+ )?
                  (?: \s+ i \s+ [[:upper:]] [[:lower:]]+ )? # poss. 'i Surname'
                  |
                  [[:upper:]][[:lower:]]+
                  -[[:lower:]][[:lower:]]-
                  [[:upper:]][[:lower:]]+
                  /x;
                # Neuman, D'Lamber, le Bail, Le Bail (?), Mairata i Payeras

    my $von = qr/[a-z][a-z]+(?:\s+[a-z][a-z]+)?/;
                # von, van, de, De, de la

    my $Jr  = qr/[A-Za-z]+\.?/;
                # Jr, Jr., I, II, III, IV

    my $FirstNames = qr/${First}(?:\s+${First})*/;
    my $Initials = qr/(?:${Initial}|${First})(?:\s+(?:${Initial}|${First}))*
                     |(?:${Initial})(?:\s*${Initial})*(?:\s*${First}(?=[,\s]))?
                     /x;
    my $LastNames = qr/${Last}(?:\s+${Last})*/;

    my $UCS_author = $unparsed_name;
    my $space = {
        leading  => $UCS_author =~ s/^ +//,
        trailing => $UCS_author =~ s/ +$//,
    };
    delete $space->{leading}  if !$space->{leading};
    delete $space->{trailing} if !$space->{trailing};

    if( %$space ) {
        warn "WARNING, name '$unparsed_name' contains " .
             join( ' and ', sort keys %$space ) . ' spaces, ' .
             'that is not permitted in names' . "\n";
    }

    if( $UCS_author =~ /^([^[:alpha:]])/ ||
        $UCS_author =~ /([^-\.,[:alpha:]'()\s])/ ) {
        my $symbol_escaped = $1;
        my $author_escaped = $unparsed_name;
        my $UCS_author_escaped = $UCS_author;
        $symbol_escaped =~ s/\n/\\n/g;
        $author_escaped =~ s/\n/\\n/g;
        $UCS_author_escaped =~ s/\n/\\n/g;
            warn "WARNING, name '$author_escaped'"
                . " contains symbol '$symbol_escaped' "
                . 'that is not permitted in names' . "\n";
        if( ! $name_syntax_explained ) {
            warn 'NOTE,' . get_name_syntax_description() . "\n";
            $name_syntax_explained = 1;
        }
        $parsed_name{'unparsed'} = $UCS_author;
    } else {
        if( $UCS_author =~ /^\s*(${FirstNames})\s+(${von})\s+(${Last})\s*$/ ) {
            $parsed_name{'first'} = $1;
            $parsed_name{'von'}   = $2;
            $parsed_name{'last'}  = $3;
            ## print ">>> 1: name = '$UCS_author', FIRST = '$1', VON = '$2', LAST = '$3'\n";
        } elsif( $UCS_author =~ /^\s*(${FirstNames})\s+(${Last})\s*$/ ) {
            $parsed_name{'first'} = $1;
            $parsed_name{'last'}  = $2;
            ## print ">>> 2: name = '$UCS_author', FIRST = '$1', LAST = '$2'\n";
        } elsif ( $UCS_author =~ /^\s*(${Initials})\s*(${von})\s+(${Last})\s*$/ ) {
            $parsed_name{'initials'} = $1;
            $parsed_name{'von'}      = $2;
            $parsed_name{'last'}     = $3;
            ## print ">>> 3: name = '$UCS_author', INITIALS = '$1', VON = '$2', LAST = '$3'\n";
        } elsif ( $UCS_author =~ /^\s*(${Initials})\s*(${Last})\s*$/ ) {
            $parsed_name{'initials'} = $1;
            $parsed_name{'last'}     = $2;
            ## print ">>> 4: name = '$UCS_author', FIRST = '$1', LAST = '$2'\n";
        } elsif ( $UCS_author =~ /^\s*(${von})\s+(${LastNames})\s*,\s*(${FirstNames})\s*$/ ) {
            $parsed_name{'von'}   = $1;
            $parsed_name{'last'}  = $2;
            $parsed_name{'first'} = $3;
            ## print ">>> 5: name = '$UCS_author', VON = '$1', FIRST = '$3', LAST = '$2'\n";
        } elsif ( $UCS_author =~ /^\s*(${LastNames})\s*,\s*(${FirstNames})\s*$/ ) {
            $parsed_name{'last'}  = $1;
            $parsed_name{'first'} = $2;
            ## print ">>> 6: name = '$UCS_author', FIRST = '$2', LAST = '$1'\n";
        } elsif ( $UCS_author =~ /^\s*(${von})\s+(${LastNames})\s*,\s*(${Initials})\s*$/ ) {
            $parsed_name{'von'}      = $1;
            $parsed_name{'last'}     = $2;
            $parsed_name{'initials'} = $3;
            ## print ">>> 7: name = '$UCS_author', VON = '$1', FIRST = '$3', LAST = '$2'\n";
        } elsif ( $UCS_author =~ /^\s*(${LastNames})\s*,\s*(${Initials})\s*$/ ) {
            $parsed_name{'last'}     = $1;
            $parsed_name{'initials'} = $2;
            ## print ">>> 8: name = '$UCS_author', FIRST = '$2', LAST = '$1'\n";
        } elsif ( $UCS_author =~ /^\s*(${von})\s+(${LastNames})\s*,\s*(${Jr})\s*,\s*(${FirstNames})\s*$/ ) {
            $parsed_name{'von'}   = $1;
            $parsed_name{'last'}  = $2;
            $parsed_name{'jr'}    = $3,
            $parsed_name{'first'} = $4;
            ## print ">>> 9: name = '$UCS_author', FIRST = '$4', VON = '$1', LAST = '$2', JR = '$3'\n";
        } elsif ( $UCS_author =~ /^\s*(${LastNames})(?:\s*,|\s)\s*(${Jr})\s*,\s*(${FirstNames})\s*$/ ) {
            $parsed_name{'first'} = $3;
            $parsed_name{'jr'}    = $2,
            $parsed_name{'last'}  = $1;
            ## print ">>> 10: name = '$UCS_author', FIRST = '$3', LAST = '$1', JR = '$2'\n";
        } elsif ( $UCS_author =~ /^\s*(${von})\s+(${LastNames})\s*,\s*(${Jr})\s*,\s*(${Initials})\s*$/ ) {
            $parsed_name{'von'}      = $1;
            $parsed_name{'last'}     = $2;
            $parsed_name{'jr'}       = $3,
            $parsed_name{'initials'} = $4;
            ## print ">>> 11: name = '$UCS_author', INITIALS = '$4', VON = '$1', LAST = '$2', JR = '$3'\n";
        } elsif ( $UCS_author =~ /^\s*(${LastNames})(?:\s*,|\s)\s*(${Jr})\s*,\s*(${Initials})\s*$/ ) {
            $parsed_name{'last'}     = $1;
            $parsed_name{'jr'}       = $2,
            $parsed_name{'initials'} = $3;
            ## print ">>> 12: name = '$UCS_author', INITIALS = '$3', LAST = '$1', JR = '$2'\n";
        } elsif ( $UCS_author =~ /^\s*(${First}-ur-${Last})\s*$/ ) {
            $parsed_name{'last'}  = $1;
            $parsed_name{'first'} = '';
            ## print STDERR ">>> 13: name = '$UCS_author', LAST = '$1'\n";
        } elsif ( $UCS_author =~ /^\s*(${LastNames})\s*,\s*(${FirstNames})\s+(${Initials})\s*$/ ) {
            $parsed_name{'last'}  = $1;
            $parsed_name{'first'} = $2;
            $parsed_name{'initials'} = $3;
        } else {
            warn "NOTE, name '$unparsed_name' seems unusual" . "\n";
            if( ! $name_syntax_explained ) {
                warn 'NOTE, ' . get_name_syntax_description() . "\n";
                $name_syntax_explained = 1;
            }
            $parsed_name{'unparsed'} = $UCS_author;
        }
    }

    if( !exists $parsed_name{'unparsed'} ) {
        if( defined $parsed_name{'last'} ) {
            $parsed_name{'last'} = [ split( ' ', $parsed_name{'last'} ) ];
        }
        if( defined $parsed_name{'von'} ) {
            $parsed_name{'von'} = [ split( ' ', $parsed_name{'von'} ) ];
        }
        if( defined $parsed_name{'first'} ) {
            $parsed_name{'first'} =
                [ split( ' ', $parsed_name{'first'} ) ];
        }
        if( defined $parsed_name{'jr'} ) {
            $parsed_name{'jr'} = [ split( ' ', $parsed_name{'jr'} ) ];
        }
        if( defined $parsed_name{'initials'} ) {
            $parsed_name{'initials'} = 
                [
                 # S.G. 2016-10-04:
                 # Use simultaneously a look-ahead and look-behind
                 # regular expression to split initials immediately
                 # after a period ('.') that is NOT followed by a
                 # hyphen ('-'):
                 map { split( /(?<=\.(?!-))/, $_ ) }
                 split( ' ', $parsed_name{'initials'} )
                ];
            if( defined $parsed_name{'first'} ) {
                $parsed_name{'first'} = [ @{$parsed_name{'first'}},
                                          @{$parsed_name{'initials'}} ];
            } else {
                $parsed_name{'first'} = $parsed_name{'initials'};
            }
        }
    }

    return \%parsed_name;
}

sub canonicalize_author_name
{
    my ($unparsed_name, $name_syntax_explained) = @_;

    $name_syntax_explained = 0 unless defined $name_syntax_explained;

    my $parsed_name = parse_author_name( $unparsed_name,
                                         $name_syntax_explained );

    return undef if exists $parsed_name->{unparsed};

    my @name_parts;

    if( defined $parsed_name->{'last'} ) {
        my @von;
        if( defined $parsed_name->{'von'} ) {
            @von = @{$parsed_name->{'von'}};
        }
        push @name_parts, join( ' ', @von, @{$parsed_name->{'last'}} );
    }
    if( defined $parsed_name->{'jr'} ) {
        push @name_parts, join( ' ', @{$parsed_name->{'jr'}} );
    }
    if( defined $parsed_name->{'first'} ) {
        push @name_parts, join( ' ', @{$parsed_name->{'first'}} );
    }

    return join( ', ', @name_parts );
}

sub author_names_are_the_same
{
    my( $name1, $name2, $options ) = @_;

    my( $lowercase,
        $names_to_initials,
        $transliterate_non_ascii ) = (
        $options->{lowercase},
        $options->{names_to_initials},
        $options->{transliterate_non_ascii} );

    $name1 = unidecode( $name1 ) if $transliterate_non_ascii;
    $name2 = unidecode( $name2 ) if $transliterate_non_ascii;

    return 1 if $name1 eq $name2;
    return 1 if $lowercase && lc( $name1 ) eq lc( $name2 );

    my $parsed_name1 = parse_author_name( $name1, 1 );
    my $parsed_name2 = parse_author_name( $name2, 1 );

    # Removing undefined keys
    $parsed_name1 = { map { $_ => $parsed_name1->{$_} }
                      grep { defined $parsed_name1->{$_} }
                           keys %$parsed_name1 };
    $parsed_name2 = { map { $_ => $parsed_name2->{$_} }
                      grep { defined $parsed_name2->{$_} }
                           keys %$parsed_name2 };

    # Converting names to initials if requested
    if( $names_to_initials ) {
        if( exists $parsed_name1->{first} ) {
            @{$parsed_name1->{first}} = map { /(.).*/; "$1." }
                                            @{$parsed_name1->{first}};
            $parsed_name1->{initials} = $parsed_name1->{first};
        }
        if( exists $parsed_name2->{first} ) {
            @{$parsed_name2->{first}} = map { /(.).*/; "$1." }
                                            @{$parsed_name2->{first}};
            $parsed_name2->{initials} = $parsed_name2->{first};
        }
    }

    # Lowercasing values before the comparison if requested
    if( $lowercase ) {
        foreach( keys %$parsed_name1 ) {
            if( ref $parsed_name1->{$_} ) {
                $parsed_name1->{$_} = [ map { lc } @{$parsed_name1->{$_}} ];
            } else {
                $parsed_name1->{$_} = lc $parsed_name1->{$_};
            }
        }
        foreach( keys %$parsed_name2 ) {
            if( ref $parsed_name2->{$_} ) {
                $parsed_name2->{$_} = [ map { lc } @{$parsed_name2->{$_}} ];
            } else {
                $parsed_name2->{$_} = lc $parsed_name2->{$_};
            }
        }
    }

    return Compare( $parsed_name1, $parsed_name2 );
}

##
# Returns a human-readable description of the author name syntax.
#
# @return
#       A human-readable description of the author name syntax.
##
sub get_name_syntax_description
{
    return "names should be written as \'First von Last\', "
         . '\'von Last, First\', or \'von Last, Jr, First\' '
         . '(mind the case!)'
}

1;
