# $Id$

package Fstream;

# ----------------------------------------------------------------------------

=head1 NAME

Fstream - a class to encapsulate a filehandle as a stream;

=head1 SYNOPSIS

    use Fstream;

=head1 DESCRIPTION

Fstream wraps a filehandle and provides methods that make it easier to
write a lexer.

=cut

# ----------------------------------------------------------------------------

=head2 Class Methods
=over 4

=item new($filehandle, $name)
Creates an Fstream object from $filehandle (a filehandle glob
reference). $name is a string which is stored for debugging purposes
and may be accessed with &name.

=back
=cut

sub new {
    my ($class, $fh, $name) = @_;
    my $stream = bless {}, $class;
    $stream->{fh} = $fh;
    $stream->{name} = $name;
    $stream->{lineno} = 1;
    $stream->{save} = undef;
    $stream->{saved} = 0;
    return $stream;
}

# ----------------------------------------------------------------------------

=head2 Object Methods
=over 4

=item getc
Returns the next character in the stream, or the empty string if the
stream has been exhausted.

=cut

sub getc {
    my ($stream) = @_;
    my $c;

    if ($stream->{saved}) {
	$stream->{saved} = 0;
	$c = $stream->{save};
	if ($c eq "\n") {
	    $stream->{lineno}++;
	}
	return $c;
    }
    elsif (($c = getc($stream->{fh})) eq '') {
	return '';
    }
    else {
	$stream->{save} = $c;
	if ($c eq "\n") {
	    $stream->{lineno}++;
	}
	return $c;
    }
}

=item ungetc
Pushes the last character read back onto the stream, where it will be
returned on the next call to getc. You may only push one character
back on the stream.

=cut

sub ungetc {
    my ($stream) = @_;

    $stream->{saved} = 1;
    if ($stream->{save} eq "\n") {
	$stream->{lineno}--;
    }
}

=item lineno
Returns the line-number of the stream (based on the number of newlines
seen).

=cut

sub lineno {
    my ($stream) = @_;
    return $stream->{lineno};
}

=item name
Returns the name that was given in the constructor.

=back
=cut

sub name {
    my ($stream) = @_;
    return $stream->{name};
}

1;
