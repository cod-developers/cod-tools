package Graph::Nauty::EdgeVertex;

use strict;
use warnings;

our $VERSION = '0.3.7'; # VERSION

use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

sub new {
    my( $class, $attributes ) = @_;
    return bless { attributes => $attributes }, $class;
};

sub color {
    return Dumper $_[0]->{attributes};
}

1;
