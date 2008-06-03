#include <iostream>
#include <sgtbx/symbols.h>

using namespace cctbx::sgtbx;
using namespace std;

int main( int argc, char *argv[] )
{
    space_group_symbol_iterator i;

    for(;;) {
	space_group_symbols symbol = i.next();
	if( symbol.number() == 0 )
	    break;
	// cout << symbol.hall() << "\n";
	// cout << symbol.hermann_mauguin();
	cout << symbol.universal_hermann_mauguin();
	//char extension = symbol.extension();
	//if( extension != '\0' ) {
	//    cout << ":" << extension;
	//}
	cout << "\n";
    }

    return 0;
}
