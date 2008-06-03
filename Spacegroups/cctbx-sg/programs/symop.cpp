#include <iostream>
#include <sgtbx/space_group.h>

using namespace cctbx::sgtbx;
using namespace std;

int main( int argc, char *argv[] )
{
    std::cout << "This is '" << argv[0] << "'\n";

    //rt_mx M( "-y+1/3,x-y+2/3,z+2/3" );
    //rt_mx M( "x+y+z+1/3,x+2/3,x+2/3" ); // non-cryst symm. op.
    rt_mx M( "x,y,z" );
    rt_mx M2( "-y,x-y,z" );
    rt_mx M3( "-x+y,-x,z" );
    rt_mx M4( "0.3333+y,0.6667-x,0.6667+z" );
    for( int i = 0; i < 3; i++ ) {
	for( int j = 0; j < 3; j++ ) {
	    cout << M.r()(i, j) << " ";
	}
	cout << "\n";
    }
    cout << "det = " << M.r().determinant() << "\n";

    space_group sg;

#if 1
    cout << "About to expand matrix M\n";
    sg.expand_smx( M );
    cout << "About to expand matrix M2\n";
    sg.expand_smx( M2 );
    cout << "About to expand matrix M3\n";
    sg.expand_smx( M3 );
    cout << "About to expand matrix M4\n";
    sg.expand_smx( M4 );
#else
    sg.add_smx( M );
    sg.add_smx( M2 );
    sg.add_smx( M3 );
    sg.add_smx( M4 );
#endif

    return 0;
}
