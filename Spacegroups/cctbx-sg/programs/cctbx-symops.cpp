#include <iostream>
#include <sgtbx/space_group.h>
#include <sgtbx/symbols.h>

using namespace cctbx::sgtbx;
using namespace std;

int main( int argc, char *argv[] )
{
    if( argc < 2 ) return 0;

    space_group_symbols sgs( argv[1] );

    space_group sg( sgs.hall() );

    for (std::size_t i_ltr = 0; i_ltr < sg.n_ltr(); i_ltr++)
	for (std::size_t i_inv = 0; i_inv < sg.f_inv(); i_inv++)
	    for (std::size_t i_smx = 0; i_smx < sg.n_smx(); i_smx++) {
                rt_mx M = sg(i_ltr, i_inv, i_smx);
		cout << M.as_xyz() << "\n";
#if 0
		for( int i = 0; i < 3; i++ ) {
		    for( int j = 0; j < 3; j++ ) {
			cout << M.r()(i, j) << " ";
		    }
		    cout << "\n";
		}
		cout << "=====\n";
#endif
	    }

    return 0;
}
