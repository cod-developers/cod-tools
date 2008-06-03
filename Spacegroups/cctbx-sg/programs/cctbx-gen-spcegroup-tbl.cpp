#include <iostream>
#include <sgtbx/space_group.h>
#include <sgtbx/symbols.h>

using namespace cctbx::sgtbx;
using namespace std;

void list_nc_symops( space_group &sg, string prefix = "" )
{
	std::size_t i_ltr = 0;

        for (std::size_t i_inv = 0; i_inv < sg.f_inv(); i_inv++)
	    for (std::size_t i_smx = 0; i_smx < sg.n_smx(); i_smx++) {
                rt_mx M = sg(i_ltr, i_inv, i_smx);
		cout << prefix << "'" << M.as_xyz() << "',\n";
	    }
}

void list_symops( space_group &sg, string prefix = "" )
{
    for (std::size_t i_ltr = 0; i_ltr < sg.n_ltr(); i_ltr++)
        for (std::size_t i_inv = 0; i_inv < sg.f_inv(); i_inv++)
	    for (std::size_t i_smx = 0; i_smx < sg.n_smx(); i_smx++) {
                rt_mx M = sg(i_ltr, i_inv, i_smx);
		cout << prefix << "'" << M.as_xyz() << "',\n";
	    }
}

int main( int argc, char *argv[] )
{
    space_group_symbol_iterator i;

    for(;;) {
	space_group_symbols symbol = i.next();
	if( symbol.number() == 0 )
	    break;
	space_group sg( symbol );
	cout << "{\n";
	cout << "    number          => " << symbol.number() << ",\n";
	cout << "    hall            => '" << symbol.hall() << "',\n";
	cout << "    schoenflies     => '" << symbol.schoenflies() << "',\n";
	cout << "    hermann_mauguin => '" <<
	    symbol.hermann_mauguin() << "',\n";
	cout << "    universal_h_m   => '" << 
	    symbol.universal_hermann_mauguin() << "',\n";
	cout << "    symops => [\n";
	list_symops( sg, "        " );
	cout << "    ],\n";
	cout << "    ncsym => [\n";
	list_nc_symops( sg, "        " );
	cout << "    ]\n";
	cout << "},\n\n";
    }

    return 0;
}
