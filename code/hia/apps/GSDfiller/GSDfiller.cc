#include <casa/iostream.h>
#include <casa/aips.h>
#include <casa/Exceptions.h>
#include <casa/BasicSL/String.h>
#include <hia/GSDDataSource/GSDDataSource.h>

#include <casa/namespace.h>
 template void std::vector<String, std::allocator<String> >::_M_insert_aux(__gnu_cxx::__normal_iterator<String*, std::vector<String, std::allocator<String> > >, String const&);
 template void std::vector<unsigned, std::allocator<unsigned> >::_M_insert_aux(__gnu_cxx::__normal_iterator<unsigned*, std::vector<unsigned, std::allocator<unsigned> > >, unsigned const&);
 template void std::vector<GSDspectralWindow, std::allocator<GSDspectralWindow> >::_M_insert_aux(__gnu_cxx::__normal_iterator<GSDspectralWindow*, std::vector<GSDspectralWindow, std::allocator<GSDspectralWindow> > >, GSDspectralWindow const&);
 template void std::vector<unsigned, std::allocator<unsigned> >::_M_fill_insert(__gnu_cxx::__normal_iterator<unsigned*, std::vector<unsigned, std::allocator<unsigned> > >, unsigned, unsigned const&);
 template unsigned* std::fill_n<unsigned*, unsigned, unsigned>(unsigned*, unsigned, unsigned const&);
 template void std::vector<MEpoch, std::allocator<MEpoch> >::_M_insert_aux(__gnu_cxx::__normal_iterator<MEpoch*, std::vector<MEpoch, std::allocator<MEpoch> > >, MEpoch const&);
 template __gnu_cxx::__normal_iterator<MEpoch*, std::vector<MEpoch, std::allocator<MEpoch> > > std::__uninitialized_copy_aux<__gnu_cxx::__normal_iterator<MEpoch*, std::vector<MEpoch, std::allocator<MEpoch> > >, __gnu_cxx::__normal_iterator<MEpoch*, std::vector<MEpoch, std::allocator<MEpoch> > > >(__gnu_cxx::__normal_iterator<MEpoch*, std::vector<MEpoch, std::allocator<MEpoch> > >, __gnu_cxx::__normal_iterator<MEpoch*, std::vector<MEpoch, std::allocator<MEpoch> > >, __gnu_cxx::__normal_iterator<MEpoch*, std::vector<MEpoch, std::allocator<MEpoch> > >, __false_type);
 template __gnu_cxx::__normal_iterator<unsigned*, std::vector<unsigned, std::allocator<unsigned> > > std::fill_n<__gnu_cxx::__normal_iterator<unsigned*, std::vector<unsigned, std::allocator<unsigned> > >, unsigned, unsigned>(__gnu_cxx::__normal_iterator<unsigned*, std::vector<unsigned, std::allocator<unsigned> > >, unsigned, unsigned const&);
 template void std::fill<__gnu_cxx::__normal_iterator<unsigned*, std::vector<unsigned, std::allocator<unsigned> > >, unsigned>(__gnu_cxx::__normal_iterator<unsigned*, std::vector<unsigned, std::allocator<unsigned> > >, __gnu_cxx::__normal_iterator<unsigned*, std::vector<unsigned, std::allocator<unsigned> > >, unsigned const&);
 template __gnu_cxx::__normal_iterator<GSDspectralWindow*, std::vector<GSDspectralWindow, std::allocator<GSDspectralWindow> > > std::__uninitialized_copy_aux<__gnu_cxx::__normal_iterator<GSDspectralWindow*, std::vector<GSDspectralWindow, std::allocator<GSDspectralWindow> > >, __gnu_cxx::__normal_iterator<GSDspectralWindow*, std::vector<GSDspectralWindow, std::allocator<GSDspectralWindow> > > >(__gnu_cxx::__normal_iterator<GSDspectralWindow*, std::vector<GSDspectralWindow, std::allocator<GSDspectralWindow> > >, __gnu_cxx::__normal_iterator<GSDspectralWindow*, std::vector<GSDspectralWindow, std::allocator<GSDspectralWindow> > >, __gnu_cxx::__normal_iterator<GSDspectralWindow*, std::vector<GSDspectralWindow, std::allocator<GSDspectralWindow> > >, __false_type);
 template __gnu_cxx::__normal_iterator<String*, std::vector<String, std::allocator<String> > > std::__uninitialized_copy_aux<__gnu_cxx::__normal_iterator<String*, std::vector<String, std::allocator<String> > >, __gnu_cxx::__normal_iterator<String*, std::vector<String, std::allocator<String> > > >(__gnu_cxx::__normal_iterator<String*, std::vector<String, std::allocator<String> > >, __gnu_cxx::__normal_iterator<String*, std::vector<String, std::allocator<String> > >, __gnu_cxx::__normal_iterator<String*, std::vector<String, std::allocator<String> > >, __false_type);

int main () {
  try {
    String gsdin;
    String ext(".dat");
    cout << "Name of input GSD file: ";
    cin >> gsdin;
    int pos = gsdin.find (".dat");
    if (pos != -1) {
      gsdin.resize (pos);
    } else if ( (pos = gsdin.find(".gsd")) != -1 ) {
      gsdin.resize (pos);
      ext = ".gsd";
    }
    String msout = gsdin;
    gsdin += ext;
    msout += "ms";
    cout << "Input file : " << gsdin << endl;
    cout << "Output file: " << msout << endl;
//
// Create the DataSource object.
//
    GSDDataSource dataSource (gsdin);
    dataSource.fill (msout);
  } catch (AipsError x) {
    cerr << "Exception thrown: \"" << x.getMesg () << "\"" << endl;
    return 1;
  } 
  return 0;
}

