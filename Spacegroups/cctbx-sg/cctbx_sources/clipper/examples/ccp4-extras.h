/*! \file ccp4-extras.h CCP4 C++ program extras */
/* Copyright 2003-2004 Kevin Cowtan & University of York all rights reserved */

#include <vector>
#include <iostream>
#include <string>


//! Mini-parser for command line input
/*! This class removes any escape characters from the command-line,
  and if a -stdin option is present reads standard input and adds the
  result to the argument list. */
class CommandInput : public std::vector<std::string>
{
 public:
  CommandInput( int argc, char** argv, bool echo = false );
};


//! class for program start and end
class CCP4program
{
 public:
  CCP4program( const char* name, const char* vers, const char* rcsdate );
  ~CCP4program();
};
