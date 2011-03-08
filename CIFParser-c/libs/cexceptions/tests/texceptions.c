
#include <stdio.h>
#include <cxprintf.h>
#include <cexceptions.h>
#include <allocx.h>

void f( cexception_t * );
void g( cexception_t * );
void h( cexception_t * );

int main()
{
    cexception_t ex;
    cexception_guard(ex) {
       puts("Guarded statement");
       g(&ex);
       f(&ex);
       g(&ex);
       f(&ex);
       puts("End of guarded statements");
    }
    cexception_catch {
       puts("Exception happened:");
       puts( cexception_message( &ex ));
    }

    puts("after the guarded block");
    cexception_raise( NULL, -1, "unguarded cexception" );
    puts("main terminated");
    return 0;
}

void g( cexception_t *ex )
{
    puts("------g() enters ---------");
    puts("------g() leaves ---------");
}

void f( cexception_t *ex )
{
    cexception_t f_ex;

    puts("------f() enters ---------");
    cexception_guard(f_ex) {
      /* mallocx( 1000000000L, &f_ex ); */
        h( &f_ex );
    }
    cexception_catch {
        printf("Exception caught in f() from ");
	if( cexception_subsystem_tag( &f_ex ) == 0 ) {
	    puts("default (main) subsystem");
	} else if( cexception_subsystem_tag( &f_ex ) == allocx_subsystem ) {
	    puts("allocx subsystem"); 
	} else {
	    puts("some unknown subsystem");
	}
	cexception_reraise( f_ex, ex );
    }

    cexception_raise( ex, -2, "cexception in f()" );
    puts("------f() leaves ---------");
}

void h( cexception_t *ex )
{
    puts("------h() enters ---------");
    cexception_raise( ex, -3,
		      cxprintf( "cexception generated in h(), "
				"code = %d", -3 ));
    puts("------h() leaves ---------");
}
