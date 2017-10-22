#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Perform various checks of the CIF data.
#**

package COD::CIF::Data::Check;

use strict;
use warnings;
use COD::CIF::Unicode2CIF qw( cif2unicode );
use COD::AuthorNames qw( parse_author_name );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
check_author_names
check_bibliography
);

sub check_author_names
{
    my ($dataset) = @_;
    my @messages;

    my $values = $dataset->{'values'};

    if( !defined $values->{'_publ_author_name'} ) {
        push @messages, 'WARNING, _publ_author_name is undefined';
        return \@messages;
    }

    for my $author (@{$values->{'_publ_author_name'}}) {
        eval {
            local $SIG{__WARN__} = sub {
                my $warning = $_[0];
                $warning =~ s/\n$//;
                push @messages, $warning;
            };
            my $parsed_name = parse_author_name( cif2unicode( $author ), 1 );
        }
    }

    return \@messages;
}

sub check_bibliography
{
    my ($dataset, $options) = @_;

    my $require_only_doi = defined $options->{'require_only_doi'} ?
                                   $options->{'require_only_doi'} : 0;
    my @messages;

    my $values = $dataset->{'values'};
    if( $require_only_doi &&
        defined $values->{'_journal_paper_doi'} ) {
        return \@messages;
    }

    if( !defined $values->{'_journal_name_full'} ) {
        push @messages, 'WARNING, _journal_name_full is undefined';
    }
    if( !defined $values->{'_publ_section_title'} ) {
        push @messages, 'WARNING, _publ_section_title is undefined';
    }
    if( !defined $values->{'_journal_year'} &&
        !defined $values->{'_journal_volume'} ) {
        push @messages, 'WARNING, neither _journal_year nor _journal_volume is defined';
    }
    if( !defined $values->{'_journal_page_first'} &&
        !defined $values->{'_journal_article_reference'} ) {
        push @messages, 'WARNING, neither _journal_page_first nor '
                      . '_journal_article_reference is defined';
    }
    return \@messages;
}

1;
