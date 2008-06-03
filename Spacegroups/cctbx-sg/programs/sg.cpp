#include <iostream>
#include <sgtbx/space_group.h>

using namespace cctbx::sgtbx;
using namespace std;

int main( int argc, char *argv[] )
{
    std::cout << "This is '" << argv[0] << "'\n";

    space_group sg ("-P 3");

    cout << sg.order_p() << "\n";

    for (std::size_t i_ltr = 0; i_ltr < sg.n_ltr(); i_ltr++)
	for (std::size_t i_inv = 0; i_inv < sg.f_inv(); i_inv++)
	    for (std::size_t i_smx = 0; i_smx < sg.n_smx(); i_smx++) {
                rt_mx M = sg(i_ltr, i_inv, i_smx);
		for( int i = 0; i < 3; i++ ) {
		    for( int j = 0; j < 3; j++ ) {
			cout << M.r()(i, j) << " ";
		    }
		    cout << "\n";
		}
		cout << "=====\n";
	    }

    return 0;
}
