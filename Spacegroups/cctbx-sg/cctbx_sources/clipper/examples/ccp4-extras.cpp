// Clipper extras
/* Copyright 2003-2004 Kevin Cowtan & University of York all rights reserved */

#include "ccp4-extras.h"

#include <ccp4_general.h>
#include <ccp4_program.h>


CommandInput::CommandInput( int argc, char** argv, bool echo )
{
  for ( int arg = 0; arg < argc; arg++ ) {
    if ( std::string(argv[arg]) == "-stdin" ) {
      std::string line;
      while ( !std::getline(std::cin,line).eof() )
	if ( line.length() > 0 )
	  if ( line[0] != '#' ) {
	    int i = line.find_first_not_of( " \t" );
	    if ( i != std::string::npos ) {
	      line = line.substr( i );
	      i = line.find_first_of( " \t" );
	      std::string word = line.substr( 0, i );
	      if ( word[0] != '-' ) word = "-" + word;
	      push_back( word );
	      if ( i != std::string::npos ) {
		line = line.substr( i );
		i = line.find_first_not_of( " \t" );
		if ( i != std::string::npos ) {
		  line = line.substr( i );
		  i = line.find_last_not_of( " \t" );
		  push_back( line.substr( 0, i+1 ) );
		}
	      }
	    }
	  }
    } else {
      std::string thisarg( argv[arg] );
      if ( thisarg.length() > 2 )
	if ( thisarg[0] == '-' && thisarg[1] == '-' )
	  thisarg = thisarg.substr(1);
      push_back( thisarg );
    }
  }
  if ( echo ) {  // echo output
    for ( int i = 1; i < size(); i++ ) {
      char c1 = ' ', c2 = ' ';  // spot keywords vs negative numbers
      if ( (*this)[i].length() > 0 ) c1 = (*this)[i][0];
      if ( (*this)[i].length() > 1 ) c2 = (*this)[i][1];
      if ( c1 == '-' && ( c2 < '0' || c2 > '9' ) )
	std::cout << "\n" << (*this)[i].substr(1);  // keywords on newline
      else
	std::cout << " \t" << (*this)[i];           // arguments on sameline
    }
    std::cout << "\n";
  }
}


CCP4program::CCP4program( const char* name, const char* vers, const char* rcsdate )
{
  CCP4::ccp4ProgramName( (char*)name );
  CCP4::ccp4_prog_vers( (char*)vers );
  CCP4::ccp4RCSDate( (char*)rcsdate );
  CCP4::ccp4_banner();
  CCP4::ccp4ProgramTime(1);
}


CCP4program::~CCP4program()
{
  printf("\n");
  CCP4::ccp4ProgramTime(0);
}
