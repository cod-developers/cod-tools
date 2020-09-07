package Graph::Nauty::EdgeNode;

use strict;
use warnings;

our $VERSION = '0.3.1'; # VERSION

use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

use overload '""' => sub { return Dumper $_[0]->{attributes} };

sub new {
    my( $class, $attributes ) = @_;
    return bless { attributes => $attributes }, $class;
};

1;
