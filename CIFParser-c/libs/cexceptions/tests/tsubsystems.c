
#include <stdio.h>
#include <cexceptions.h>
#include <subsystem_a.h>
#include <subsystem_b.h>

int main() 
{
    cexception_t ex;
    int i;

    for( i = 0; i < 2; i ++ ) {
        cexception_guard( ex ) {
	    switch(i) {
	        case 0: subsystem_a_function( &ex );
	        case 1: subsystem_b_function( &ex );
	    }
	}
	cexception_catch {
	    printf( "%s from ", cexception_message( &ex ));
	    if( cexception_subsystem_tag( &ex ) == 0 ) {
	        puts("default (main) subsystem");
	    } else if( cexception_subsystem_tag( &ex ) == subsystem_a_tag ) {
	        puts("subsystem A"); 
	    } else if( cexception_subsystem_tag( &ex ) == subsystem_b_tag ) {
	        puts("subsystem B"); 
	    } else {
	        puts("some unknown subsystem");
	    }
	}
    }

    return 0;
}
