#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Header:
#$Locker:  $
#$Log: ShowStruct.pm,v $
#Revision 1.3  1997/09/03 15:56:59  saulius
#RCS header added
#
#$Revision$
#$Source: /home/saulius/src/perl-modules/ShowStruct/RCS/ShowStruct.pm,v $
#$State: Exp $
#------------------------------------------------------------------------

package ShowStruct;

use strict;
require Exporter;
@ShowStruct::ISA = qw(Exporter);
@ShowStruct::EXPORT = qw(showHash showArray showRef);

my $separator = "-------------------------";

sub showRef
{
    my $ref = shift;
    if( ref($ref) eq "ARRAY" ) {
        &showArray( $ref );
    } elsif( ref($ref) eq "HASH" ) {
        &showHash( $ref );
    } else {
        print $ref;
    }
}

sub showHash
{
   my $hash = shift;
   my $ident = ( scalar(@_) != 0 ? shift : "" ) ;
   local $, = " ";
   local $\ = "\n";

   my $key;
   my $isFlat = 1;
   foreach $key ( keys %{$hash} ) {
      if( ref $hash->{$key} eq "HASH" or ref $hash->{$key} eq "ARRAY" ) {
         $isFlat = 0; last;
      }
   }
   if( $isFlat ) {
      print STDOUT "{ @{[%$hash]} }";
   } else {
      printf STDOUT "\n" unless $ident eq "";
      foreach $key ( keys %{$hash} ) {
         if( ref $hash->{$key} eq "HASH" ) {
            printf STDOUT "%s%-5s -> ", $ident, $key;
            showHash( $hash->{$key}, $ident . "   " );
         } elsif( ref $hash->{$key} eq "ARRAY" ) {
            printf STDOUT "%s%-5s -> ", $ident, $key;
            showArray( $hash->{$key}, $ident . "   " );
         } else {
            printf STDOUT "%s%-5s -> %s\n", $ident, $key, $hash->{$key}; 
         }
      }
   }
   print STDOUT $separator if $ident eq "";
}

sub showArray
{
   my $array = shift;
   my $ident = ( scalar(@_) != 0 ? shift : "" ) ;
   local $, = " ";
   local $\ = "\n";

   my $item;
   my $isFlat = 1;
   foreach $item ( @{$array} ) {
      if( defined $item and (ref $item eq "HASH" or ref $item eq "ARRAY" )) {
         $isFlat = 0; last;
      }
   }
   if( $isFlat ) {
       print STDOUT "[ ", map( { defined $_ ? $_ : "undef" } @{$array} ), " ]";
   } else {
       printf STDOUT "\n" unless $ident eq "";
       print STDOUT $ident, "[";
       my $index = 1;
       foreach $item ( @{$array} ) {
           if( !defined $item  ) {
               printf STDOUT "   %s%-3d: ", "undef", $index++;
           } elsif( ref $item eq "HASH" ) {
               printf STDOUT "   %s%-3d: ", $ident, $index++;
	       showHash( $item, $ident . "   " );
	   } elsif( ref $item eq "ARRAY" ) {
               printf STDOUT "   %s%-3d: ", $ident, $index++;
	       showArray( $item, $ident . "   " );
	   } else {
	       printf STDOUT "%s%-3s%-17s\n", $ident, $index++, $item; 
	   }
       }
       print STDOUT $ident, "]";
   }
   print STDOUT $separator if $ident eq "";
}

return 1;
