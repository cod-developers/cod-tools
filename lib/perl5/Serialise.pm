#------------------------------------------------------------------------
#$Author: saulius $
#$Date: 2008-02-18 15:38:32 +0200 (Mon, 18 Feb 2008) $ 
#$Revision: 1171 $
#$URL: svn+ssh://lokys.ibt.lt/home/saulius/svn-repositories/cce/aux/Serialise.pm $
#------------------------------------------------------------------------

package Serialise;

use strict;
require Exporter;
@Serialise::ISA = qw(Exporter);
@Serialise::EXPORT = qw(
    serialiseHash serialiseArray serialiseRef serialiseScalar
);

my $separator = "#-------------------------\n";

sub serialiseRef
{
    my $ref = shift;
    my $indent = ( scalar(@_) != 0 ? shift : "" ) ;
    if( ref($ref) eq "ARRAY" ) {
        &serialiseArray( $ref, $indent );
    } elsif( ref($ref) eq "HASH" ) {
        &serialiseHash( $ref, $indent );
    } elsif( ref($ref) eq "SCALAR" ) {
        &serialiseScalar( $ref, $indent );
    } else {
        print $ref;
    }
}

sub serialiseHash
{
   my $hash = shift;
   my $indent = ( scalar(@_) != 0 ? shift : "" ) ;

   my $key;
   ## printf STDOUT "\n" unless $indent eq "";
   ## print STDOUT $indent, "{\n";
   print STDOUT "{\n";
   my $old_indent = $indent;
   $indent .= " " x 3;
   foreach $key ( sort {$a cmp $b} keys %{$hash} ) {
       printf STDOUT "%s%-5s => ", $indent, '"' . $key . '"';
       if( ref $hash->{$key} eq "HASH" ) {
	   serialiseHash( $hash->{$key}, $indent );
       } elsif( ref $hash->{$key} eq "ARRAY" ) {
	   serialiseArray( $hash->{$key}, $indent );
       } elsif( ref $hash->{$key} eq "SCALAR" ) {
	   serialiseScalar( $hash->{$key}, $indent );
       } else {
	   printf STDOUT "\"%s\",\n", $hash->{$key}; 
       }
   }
   print STDOUT $old_indent, "},\n";
   print STDOUT $separator if $old_indent eq "";
}

sub serialiseArray
{
   my $array = shift;
   my $indent = ( scalar(@_) != 0 ? shift : "" ) ;

   my $item;
   my $isFlat = 1;
   if( int(@{$array}) > 100 ) {
       $isFlat = 0;
   } else {
       foreach $item ( @{$array} ) {
	   if( ref $item or length($item) > 20 ) {
	       $isFlat = 0; last;
	   }
       }
   }
   my $old_indent = $indent;
   if( $isFlat ) {
       local $" = ", ";
       my @val = map { "\"$_\"" } @{$array};
       print STDOUT "[ @val ],\n";
   } else {
       ## printf STDOUT "\n" unless $indent eq "";
       ## print STDOUT $indent, "[\n";
       print STDOUT "[\n";

       $indent .= " " x 3;
       my $index = 0;
       foreach $item ( @{$array} ) {
	   if( ref $item eq "HASH" ) {
	       printf STDOUT "%s# %3d:\n%s", $indent, $index++, $indent;
		   serialiseHash( $item, $indent );
	   } elsif( ref $item eq "ARRAY" ) {
	       printf STDOUT "%s# %3d:\n%s", $indent, $index++, $indent;
	       serialiseArray( $item, $indent );
	   } elsif( ref $item eq "SCALAR" ) {
	       printf STDOUT "%s# %3d:\n%s", $indent, $index++, $indent;
	       serialiseScalar( $item, $indent );
	   } else {
	       printf STDOUT "%s# %3s:\n%s\"%s\",\n", $indent, $index++,
	       $indent, $item;
	   }
       }
       print STDOUT $old_indent, "],\n";
   }
   print STDOUT $separator if $old_indent eq "";
}

sub serialiseScalar
{
   my $scalar = shift;
   my $indent = ( scalar(@_) != 0 ? shift : "" ) ;

   my $value = $$scalar;

   if( ref $value ) {
       serialiseRef( $value, $indent );
   } else {
       print '\"', $$scalar, '",', "\n";
   }
}

return 1;
