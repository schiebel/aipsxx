//# used.cc: Find undefined modules in libraries
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: used.cc,v 19.4 2004/11/30 17:50:09 ddebonis Exp $

// For documentation, see the "usage" function, or "used -help"

#include <casa/aips.h>
#include <casa/Exceptions/Error.h>
#include <casa/System/Aipsrc.h>
#include <casa/Utilities/Register.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>
#include <casa/Containers/SimOrdMap.h>
#include <casa/OS/Directory.h>
#include <casa/OS/RegularFile.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <fits/FITS/fits.h>

#include <casa/stdlib.h>
#include <casa/stdio.h>
#include <casa/iostream.h>
#include <casa/fstream.h>

#include <casa/namespace.h>
static void us_usage(const String &msg) {
  if (!msg.empty())
    cerr << msg << endl;
  cerr << "Usage: used [-tc] [-ng] [-nc] [-b|-f] library_1 [-b|-f] library_2...\n";
  cerr <<  "Libraries(or .o) are assumed to be original if no or -b switch given.\n"
    "The program works faster if they are pre-processed (-f switch) with:\n"
    "     [g]nm library | g++filt >! a.tmp\n"
    " -tc: show templated classes only\n"
    " -ng: do not show global functions\n"
    " -nc: do not show classes\n"
    "Note: aipsrc variables unused.file.nm and unused.file.gfilt can \n"
    "       be set to give nm name ('gnm' default) and 'g++filt'.\n" << endl;
};

int main(unsigned int argc, char **argv) {
   // The AIPSROOT
  String aipsroot;

  // Get AIPSROOT
  try {
    aipsroot = Aipsrc::aipsRoot();
  } catch (AipsError x) {
    cerr << x.getMesg() << endl;
    us_usage("No AIPSPATH defined");
    exit(1);
  } 

  Bool BIN = True;		// binary input
  Bool NOCL = False;		// no classes
  Bool NOGL = False;		// no global functions
  Bool TEMCL = False;		// only templated classes

  // This will hold the names of the libray files we are going to look for
  // undefines in.
  Vector<String> libFiles;
  Vector<Bool> libTypes;
  // Overall replacements for gnu -> aips++ canonical
  const Int Npat0 = 49;	// Handle format
  const Regex REpat0[Npat0] = {
    String("	"),
    String("   *"),
    String("^ "),
    String(" $"),
    String(" \\("),
    String(" ,"),
    String(","),
    String("&"),
    String("\\*\\*"),
    String(" \\* \\*"),
    String("\\( \\*\\)"),
    String("\\( *"),
    String("\\*const"),
    String("[ ]*operator "),
    String("[ ]*operator[ ]*&[ ]*&\\("),
    String(" <"),
    String("< "),
    String(" >"),
    String(">>"),
    String(">>"),
    String("[ ]*operator> >\\("),
    String(" template *< *>"),
    String(" template *<"),
    String("> *class "),
    String("short unsigned int"),
    String("unsigned short int"),
    String("short signed int"),
    String("signed short int"),
    String("long unsigned int"),
    String("unsigned long int"),
    String("long signed int"),
    String("signed long int"),
    String("unsigned char"),
    String("signed char"),
    String("unsigned short"),
    String("short unsigned"),
    String("signed short"),
    String("short signed"),
    String("short int"),
    String("unsigned long"),
    String("long unsigned"),
    String("signed long"),
    String("long signed"),
    String("long int"),
    String("long float"),
    String("long double"),
    String("unsigned int"),
    String("signed int"),
    String("  *") };
  const Int Npat01 = 16;
  const Regex REpat01[Npat01] = {
    String("[^a-zA-Z_]char[^a-zA-Z_]"),
    String("[^a-zA-Z_]short[^a-zA-Z_]"),
    String("[^a-zA-Z_]unsigned[^a-zA-Z_]"),
    String("[^a-zA-Z_]signed[^a-zA-Z_]"),
    String("[^a-zA-Z_]int[^a-zA-Z_]"),
    String("[^a-zA-Z_]long[^a-zA-Z_]"),
    String("[^a-zA-Z_]float[^a-zA-Z_]"),
    String("[^a-zA-Z_]double[^a-zA-Z_]"),
    String("[^a-zA-Z_]*floatG_COMPLEX"),
    String("[^a-zA-Z_]*doubleG_COMPLEX"),
    String("[^a-zA-Z_]*intG_COMPLEX"),
    String("[^a-zA-Z_]*complex<Float>"),
    String("[^a-zA-Z_]*complex<Double>"),
    String("<Complex >"),
    String("<DComplex >"),
    String("[^a-zA-Z_]bool[^a-zA-Z_]") };
  const String RErep0[Npat0] = {
    " ",
    " ",
    "",
    "",
    "(",
    ",",
    ", ",
    " &",
    "* *",
    " **",
    "(*)",
    "(",
    "* const",
    "operator",
    "operator&&(",
    "<",
    "<",
    ">",
    "> >",
    "> >",
    "operator>>(",
    " template <> ",
    " template <",
    "> class ",
    "uShort",
    "uShort",
    "Short",
    "Short",
    "uLong",
    "uLong",
    "Long",
    "Long",
    "uChar",
    "Char",
    "uShort",
    "uShort",
    "Short",
    "Short",
    "Short",
    "uLong",
    "uLong",
    "Long",
    "Long",
    "Long",
    "Double",
    "lDouble",
    "uInt",
    "Int",
    " " };
  const Regex REpat02[Npat01] = {
    String("char"),
    String("short"),
    String("unsigned"),
    String("signed"),
    String("int"),
    String("long"),
    String("float"),
    String("double"),
    String("floatG_COMPLEX"),
    String("doubleG_COMPLEX"),
    String("intG_COMPLEX"),
    String("complex<Float>"),
    String("complex<Double>"),
    String("<Complex >"),
    String("<DComplex >"),
    String("bool") };
  const String REpat03[Npat01] = {
    "Char",
    "Short",
    "uInt",
    "Int",
    "Int",
    "Long",
    "Float",
    "Double",
    "Complex",
    "DComplex",
    "IComplex",
    "<Complex>",
    "<DComplex>",
    "Bool" };
  // Get arguments
  for (uInt i=1; i<argc; i++) {
    String nam = argv[i];
    if (nam[0] == '-') {
      if (nam == "-") {
	us_usage("Unknown switch");
	exit(1);
      } else if (nam == "-b") {
	BIN = True; 
	continue;
      } else if (nam == "-f") {
	BIN = False; 
	continue;
      } else if (nam == "-nc") {
	NOCL = True;
	continue;
      } else if (nam == "-ng") {
	NOGL = True;
	continue;
      } else if (nam == "-tc") {
	TEMCL = True;
	continue;
      } else {
	us_usage("Unknown switch");
	exit(1);
      };	
    } else {
      File userTemplate(nam);
      if (userTemplate.exists()) {
	uInt n = libFiles.nelements();
	libFiles.resize(n+1, True);
	libTypes.resize(n+1, True);
	libFiles(n) = nam;
	libTypes(n) = BIN;
      };
    };
  };

  if (libFiles.nelements() == 0) {
    us_usage("No library files specified");
    exit(1);
  };
  
  cerr << "Using " << libFiles << endl;

  char buffer[8192]; // Single lines in library file must fit in here
  
  // Various test expressions for lines
  const Regex comment("^[ 	]*#");
  const Regex spaces("^[ 	]*$");
  String extracted = ""; 	// What's left

  // List of all objects/global methods in library files given
  SimpleOrderedMap<String, Int> counts(0, 5000);
  SimpleOrderedMap<String, Int> ucounts(0, 5000); // undefineds
  String lpat;
  String lrep;
  Int ncount = 0;
  const Regex gnmRE("^[0-9a-f]+.* T .*[<(]");
  const Regex gnmRE2("^[0-9a-f]+.* T +");
  const String gnmRE3("::");
  const Regex nmRE("^.*\\|.*\\|.*\\|FUNC.*\\|GLOB[^|]*\\|"
		   "[^|]*\\|[^|]*\\|.*[<(]");
  const Regex nmRE2("^.*\\|.*\\|.*\\|FUNC.*\\|GLOB[^|]*\\|"
		    "[^|]*\\|[^|]*\\|[ ]*");
  const Regex gnmURE("^ +U ");
  const Regex gnmURE2("^ +U +");
  const Regex nmURE("^.*\\|.*\\|.*\\|NOTY.*\\|GLOB[^|]*\\|"
		   "[^|]*\\|UNDEF *\\| *");
  const Regex nmURE2("^.*\\|.*\\|.*\\|NOTY.*\\|GLOB[^|]*\\|"
		   "[^|]*\\|UNDEF *\\| *");
  String spcol[50];	// Check for multiple ::
  String locExtract;
  { // Check names
    Int n;
    String namFile;
    String execString;
    const String lbr("(");
    const String rbr(")");
    const String llt("<");
    const String rgt(">");
    const Regex perst("^\\.");
    const Regex underst("^_");
    for (uInt i=0; i < libFiles.nelements(); i++) { // for each file...
      if (!libTypes(i)) {
	namFile = libFiles(i);
      } else {
	namFile = File::newUniqueName("./").originalName();
	Aipsrc::find(lpat, "unused.file.nm", "gnm");
	execString = lpat + " " + libFiles(i);
	Aipsrc::find(lpat, "unused.file.gfilt", "g++filt");
	execString += " | " + lpat + " > " + namFile;
	if (system(execString.chars()) != 0) {
	  lpat = "Error reading/converting binary " + libFiles(i);
	  File file(namFile);
	  if (file.exists()) RegularFile(file).remove();
	  us_usage(lpat);
	  exit(1);
	};
      };
      Int cbr = 0;
      Bool ufnd = False;
      ifstream file(namFile.chars(), ios::in);
      while (file.getline(&buffer[0], sizeof(buffer))) { // read line by line
	extracted = buffer;
	if (extracted.contains(comment)) continue; // skip comment
	if (extracted.empty() || extracted.contains(spaces)) 
	  continue;	// skip empty lines
	ufnd = False;
	if (i==0) {
	  ufnd = True;
	  if (extracted.contains(gnmURE)) {
	    extracted = extracted.after(gnmURE2);
	  } else if (extracted.contains(nmURE)) {
	    extracted = extracted.after(nmURE2);
	  } else {
	    ufnd = False;
	  };
	};
	if (!ufnd) {
	  if (extracted.contains(gnmRE)) {
	    extracted = extracted.after(gnmRE2);
	  } else if (extracted.contains(nmRE)) {
	    extracted = extracted.after(nmRE2);
	  } else {
	    continue;
	  };
	};
	if (extracted.contains(perst) ||
	    extracted.contains(underst)) continue; // do not do .x or _x
	locExtract = extracted;
	uInt ns = split(extracted, spcol, 50, gnmRE3);
	cbr = 0;
	if (ns == 1) {
	} else if (ns == 2 && !spcol[0].contains(lbr)) {
	  extracted = spcol[0];
	} else {
	  uInt j;
	  for (j=0; j<ns; j++) {
	    cbr += spcol[j].freq(llt);
	    cbr += spcol[j].freq(lbr);
	    cbr -= spcol[j].freq(rgt);
	    cbr -= spcol[j].freq(rbr);
	    if (cbr <= 0) break;
	  };
	  extracted = join(spcol, j+1, gnmRE3);
	};
	if (extracted == locExtract) {		// global function
	  if (NOGL) continue;
	} else {				// class
	  if (NOCL) continue;
	  if (TEMCL && !extracted.contains(llt)) continue;
	};
	ncount++;
	if (ufnd) {
	  if (ucounts.isDefined(extracted)) {
	    n = ucounts(extracted);
	    n++;
	    ucounts(extracted) = n;
	  } else {
	    ucounts(extracted) =1;
	  };
	} else {
	  if (counts.isDefined(extracted)) {
	    n = counts(extracted);
	    n++;
	    counts(extracted) = n;
	  } else {
	    counts(extracted) =1;
	  };
	};
      };
      if (libTypes(i) && !namFile.empty()) {
	File file(namFile);
	if (file.exists()) RegularFile(file).remove();
      };
    };
  }

  cerr << "Checked " << ucounts.ndefined() << " undefineds against " <<
    counts.ndefined() << " defineds" <<
    endl;

  Int ucount = 0;
  {	// show undefineds
    cout << "# Undefined ";
    if (!NOGL) {
      cout << "global methods";
      if (!NOCL) cout << " and ";
    };
    if (!NOCL) {
      if (TEMCL) cout << "templated ";
      cout << "classes";
    };
    cout << endl;
    for (uInt i=0; i<ucounts.ndefined(); i++) {
      extracted = ucounts.getKey(i);
      if (!counts.isDefined(extracted)) {
	ucount++;
	printf("%5d: ", ucounts.getVal(i));
	Int j;
	for (j=0; j<Npat0; j++) {
	  extracted.gsub(REpat0[j], RErep0[j]);
	};
	for (j=0; j<Npat01; j++) {
	  while (extracted.contains(REpat01[j])) {
	    lpat = extracted.at(REpat01[j]);
	    lpat = lpat.through(REpat01[j]);
	    lrep = lpat;
	    lrep.gsub(REpat02[j], REpat03[j]);
	    extracted.gsub(lpat, lrep);
	  };
	};
	cout << extracted << endl;
      };
    };
  }

  cerr << ucount << " undefined objects/global functions shown" << endl;
  
  exit(0);
}

