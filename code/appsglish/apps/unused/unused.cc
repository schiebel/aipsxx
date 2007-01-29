//# unused.cc: Find used .o files in executables
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
//# $Id: unused.cc,v 19.4 2004/11/30 17:50:09 ddebonis Exp $

// For documentation, see the "usage" function, or "unused -help"

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
static void unu_usage(const String &msg) {
  if (!msg.empty())
    cerr << msg << endl;
  cerr << "Usage: unused [-z] [-nz] [-a] [-[0-9]...]\n"
    "                  [-p package] [-r package] [-u package] ...\n"
    "                          [-t templates_1 ... templates_n] ...\n "
    "                  -f|-b nam1 ...\n"
    "                  [-i list ...]\n";
  cerr <<  "Templates files must be supplied with one or more of the \n"
    " -p -r -u or -t options. If none supplied, then ALL the system templates \n"
    " will be used.\n"
    "The templates files will be checked against names or binary files \n"
    "specified with the -f switch, or the -b switch. \n"
    "Name files (for -f) are the output of either 'nm' or 'gnm',\n"
    "filtered by the g++filt, or output from an earlier run. E.g.:\n"
    "     [g]nm executable | g++filt >! a.tmp\n"
    "The operation will be much faster if a further reduction is made:\n"
    "     [g]nm executable | g++filt | grep '[<(]' >! a.tmp\n\n"
    " -z : show unused templates (default)\n"
    " -nz: show used templates only (e.g. for later -i switch use)\n"
    " -a : show usage of all templates\n"
    " -[0-9] : e.g. -0 -10: count only onece per binary file, and show only\n"
    "      templates with minimum number of counts given\n"
    " -p package  include all system templates files in the package\n"
    " -r package  include all system repository templates files in the package\n"
    " -u package  include all user system templates files in the package\n"
    "Note: package name may be all\n"
    " -t file ... : use specified templates files (or output from previous run)\n"
    " -f file ... : use specified names files\n"
    " -b file ... : use binary file rather than names files\n"
    " -i file ... : add specified lists from previous run\n"
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
    unu_usage("No AIPSPATH defined");
    exit(1);
  } 

  Bool GIVEN = False;		// explicit names given
  Bool RESTR = False;		// Restricted part given
  Bool ZERO = True;		// show unused
  Bool ALL = False;		// show all
  Bool CNTF = False;		// count only files
  Bool SEENFB = False;
  Bool BIN = False;		// binary input
  Int mincnt = 0;		// for CNTF
  // This will hold the names of the templates files we are going to look for
  // duplicates in.
  Vector<String> templatesFiles;
  Vector<String> interFiles;	// interim set
  Vector<String> namFiles;	// files with nm names
  Vector<String> listFiles;	// files with lists
  // These are a set of rules to cope with typedefs
  const uInt Npattp0 = 2;
  const Regex REpattp00[Npattp0] = {
    String("[^a-zA-Z_]FitsLong[^a-zA-Z_]"),
    String("[^a-zA-Z_]lDouble[^a-zA-Z_]") };
  const Regex REpattp01[Npattp0] = {
    String("FitsLong"),
    String("lDouble") };
  String REpattp02[Npattp0] = {
    "Long",
    "lDouble" };
  if (Register(static_cast<FitsLong *>(0)) == Register(static_cast<Int *>(0))) 
    REpattp02[0] = "Int";
  if (Register(static_cast<lDouble *>(0)) == Register(static_cast<Double *>(0)))
    REpattp02[1] = "Double";
  // Rules to change canonical aips++ to gnu
  const uInt Npattp1 = 16;
  const Regex REpattp10[Npattp1] = {
    String(" \\* const "),
    String("[a-zA-Z_]\\(\\*"),
    String("[^a-zA-Z_]Char[^a-zA-Z_]"),
    String("[^a-zA-Z_]uChar[^a-zA-Z_]"),
    String("[^a-zA-Z_]Short[^a-zA-Z_]"),
    String("[^a-zA-Z_]uShort[^a-zA-Z_]"),
    String("[^a-zA-Z_]Int[^a-zA-Z_]"),
    String("[^a-zA-Z_]uInt[^a-zA-Z_]"),
    String("[^a-zA-Z_]Long[^a-zA-Z_]"),
    String("[^a-zA-Z_]uLong[^a-zA-Z_]"),
    String("[^a-zA-Z_]Float[^a-zA-Z_]"),
    String("[^a-zA-Z_]Double[^a-zA-Z_]"),
    String("[^a-zA-Z_]lDouble[^a-zA-Z_]"),
    String("[^a-zA-Z_]Complex[^a-zA-Z_]"),
    String("[^a-zA-Z_]DComplex[^a-zA-Z_]"),
    String("[^a-zA-Z_]IComplex[^a-zA-Z_]") };
  const Regex REpattp11[Npattp1] = {
    String(" \\* const "),
    String("\\(\\*"),
    String("Char"),
    String("uChar"),
    String("Short"),
    String("uShort"),
    String("Int"),
    String("uInt"),
    String("Long"),
    String("uLong"),
    String("Float"),
    String("Double"),
    String("lDouble"),
    String("Complex"),
    String("DComplex"),
    String("IComplex") };
  const String REpattp12[Npattp1] = {
    String(" *const "),
    String(" (*"),
    String("char"),
    String("unsigned char"),
    String("short"),
    String("unsigned short"),
    String("int"),
    String("unsigned int"),
    String("long"),
    String("unsigned long"),
    String("float"),
    String("double"),
    String("long double"),
    String("floatG_COMPLEX"),
    String("doubleG_COMPLEX"),
    String("intG_COMPLEX") };
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
    String("[^a-zA-Z_]floatG_COMPLEX[^a-zA-Z_]"),
    String("[^a-zA-Z_]doubleG_COMPLEX[^a-zA-Z_]"),
    String("[^a-zA-Z_]intG_COMPLEX[^a-zA-Z_]"),
    String("[^a-zA-Z_]complex<Float>"),
    String("[^a-zA-Z_]complex<Double>"),
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
    "Complex",
    "DComplex",
    "<Complex>",
    "<DComplex>",
    "Bool" };
  const Regex fndcnt("^-[0-9]+$");
  // Get arguments
  for (uInt i=1; i<argc; i++) {
    String nam = argv[i];
    if (nam[0] == '-') {
      if (nam == "-") {
	unu_usage("Unknown switch");
	exit(1);
      } else if (nam == "-z") {
	ZERO = True; 
	ALL = False;
	continue;
      } else if (nam == "-nz") {
	ZERO = False; 
	ALL = False;
	continue;
      } else if (nam == "-a") {
	ZERO = False; 
	ALL = True;
	continue;
      } else if (nam.contains(fndcnt)) {
	CNTF = True;
	mincnt = abs(atoi(nam.chars()));
	continue;
      } else if (nam == "-f" || nam == "-b") {
	if (SEENFB) {
	  unu_usage("Multiple -f and/or -b present");
	  exit(1);
	};
	SEENFB = True; if (nam == "-b") BIN = True;
	while (++i < argc) {
	  nam = argv[i];
	  if (nam[0] == '-') {
	    i--;
	    break;
	  };
	  // The user has supplied a set of names files. Use them.
	  File userTemplate(nam);
	  if (userTemplate.exists()) {
	    uInt n = namFiles.nelements();
	    namFiles.resize(n+1, True);
	    namFiles(n) = nam;
	  };
	};
	continue;
      } else if (nam == "-i") {
	while (++i < argc) {
	  nam = argv[i];
	  if (nam[0] == '-') {
	    i--;
	    break;
	  };
	  // The user has supplied a set of names files. Use them.
	  File userTemplate(nam);
	  if (userTemplate.exists()) {
	    uInt n = listFiles.nelements();
	    listFiles.resize(n+1, True);
	    listFiles(n) = nam;
	  };
	};
	continue;
      } else if (nam == "-t") {
	while (++i < argc) {
	  nam = argv[i];
	  if (nam[0] == '-') {
	    i--;
	    break;
	  };
	  // The user has supplied a set of templates files names. Use them.
	  File userTemplate(nam);
	  GIVEN = True;		// Indicate given names
	  if (userTemplate.exists()) {
	    uInt n = templatesFiles.nelements();
	    templatesFiles.resize(n+1, True);
	    templatesFiles(n) = nam;
	  };
	};
	continue;
      } else if (nam == "-p" || nam == "-u" || nam == "-r") {
	String pnam;
	i++;		// next arg
	if (i >= argc || argv[i][0] == '-') {
	  unu_usage("No package name provided");
	  exit(1);
	};
	RESTR = True;
	pnam = argv[i];
	String aipspath = aipsroot + "/code";
	if (pnam != "all") {
	  aipspath += (String("/") + pnam);
	  File tst(aipspath);
	  if (!tst.isDirectory()) {
	    aipspath = String("Package ") + pnam + " does not exist";
	    unu_usage(aipspath);
	    exit(1);
	  };
	};
	Vector<String> locFiles;
	Directory aipsroot(aipspath);
	String repf("_ReposFiller");
	// Find all files named "templates" found under aipsroot.
	locFiles = aipspath + String("/") + 
	  aipsroot.find(Regex::fromString("templates"));
	if (nam == "-p") {
	  cerr << "Using all templates files under " << aipspath << endl;
	} else if (nam == "-r") {
	  cerr << "Using all repository templates files under " <<
	    aipspath << endl;
	} else {
	  cerr << "Using all non-repository templates files under " <<
	    aipspath << endl;
	};
	for (uInt j=0; j<locFiles.nelements(); j++) {
	  if ((nam == "-p") ||
	      (nam == "-r" && locFiles(j).contains(repf)) ||
	      (nam == "-u" && !locFiles(j).contains(repf))) {
	    uInt n = interFiles.nelements();
	    interFiles.resize(n+1, True);
	    interFiles(n) = locFiles(j);
	  };
	};
	continue;
      } else {
	unu_usage("Unknown switch");
	exit(1);
      };
    } else {
      unu_usage("Cannot type file name: precede with switch");
      exit(1);
    };
  };
  
  
  // Add local templates file
  if (!GIVEN) {
    File localTemplates("templates");
    // Add ./templates to the list if it exists
    if (localTemplates.exists()) {
      uInt n = templatesFiles.nelements();
      templatesFiles.resize(n+1, True);
      templatesFiles(n) = "./templates";
      cerr << "Using ./templates" << endl;
    };
  };

  if (templatesFiles.nelements() != 0)
    cerr << "Using " << templatesFiles << endl;

  {	// Copy all
    for (uInt j=0; j<interFiles.nelements(); j++) {
      uInt n = templatesFiles.nelements();
      templatesFiles.resize(n+1, True);
      templatesFiles(n) = interFiles(j);
    };
  }

  if (namFiles.nelements() == 0) {
    unu_usage("No names or binary files specified");
    exit(1);
  };

  char buffer[8192]; // Single lines in templates file must fit in here
  
  // Various regular expressions for discarding parts of templates entries we
  // aren't interested in.  I should be able to be cleverer and do it in one
  // R.E.
  const Regex classprelude("^.*template *class *");
  const Regex functionprelude("^.*template *");
  const Regex forwardprelude("^.*template *<");
  const Regex mylistprelude("^[ ]*[0-9]+: ");
  const Regex funcnameprelude("[^ ]*\\(");
  const Regex comment("^[ 	]*#");
  const Regex cont("^[ 	]*=");
  const Regex spaces("^[ 	]*$");
  const Regex leadsp("^[ 	]+");
  const Regex endsp("[ 	]+$");
  const Regex doublesp("[ 	]+");
  const Regex nosp("[ 	]+");
  const String nulls = "";
  const String spst = " ";
  String extracted = ""; 	// What's left

  // List of all templates in templates files given
  SimpleOrderedMap<String, Int> counts(0, 5000);
  Vector<Int> tfcnt;	// total counts for file count
  Vector<Int> fcnt;	// file count
  Int lineN = 0;
  String lpat;
  String lrep;
  {
    for (uInt i=0; i < templatesFiles.nelements(); i++) { // for each file...
      ifstream file(templatesFiles(i).chars(), ios::in); 
      while (file.getline(&buffer[0], sizeof(buffer))) { // read line by line
	lineN++;
	extracted = buffer;
	if (extracted.contains(comment)) {
	  continue; // skip comment and #if and #ifdef lines
	};
	if (extracted.empty() || extracted.contains(spaces)) {
	  continue;	// skip empty lines
	};
	if (extracted.contains(cont)) {
	  continue; // skip continuation lines
	};
	if (extracted.contains(forwardprelude)) {
	  continue;	// skip forward declarations
	};
	Bool ok = True; // Assume valid entry
	if (extracted.contains(classprelude)) {
	  extracted = extracted.after(classprelude); // template class
	} else if (extracted.contains(functionprelude)) {
	  extracted = extracted.after(functionprelude); // template global
	  if (extracted.contains(funcnameprelude)) {
	    extracted = extracted.from(funcnameprelude);
	  };
	} else if (extracted.contains(mylistprelude)) {
	  extracted = extracted.after(mylistprelude); // an unused list
	} else {
	  continue;	// entry with only include files
	};
	if (ok) {
	  // Remove leading/trailing spaces and singlefy spaces and make gnu types
	  extracted.gsub(leadsp, nulls); 
	  extracted.gsub(endsp, nulls);
	  extracted.gsub(doublesp, spst);
	  uInt j;
	  for (j=0; j<Npattp0; j++) {
	    if (REpattp02[j] != "lDouble") {
	      while (extracted.contains(REpattp00[j])) {
		lpat = extracted.at(REpattp00[j]);
		lpat = lpat.through(REpattp00[j]);
		lrep = lpat;
		lrep.gsub(REpattp01[j], REpattp02[j]);
		extracted.gsub(lpat, lrep);
	      };
	    };
	  };
          for (j=0; j<Npattp1; j++) {
            while (extracted.contains(REpattp10[j])) {
              lpat = extracted.at(REpattp10[j]);
              lpat = lpat.through(REpattp10[j]);
              lrep = lpat;
              lrep.gsub(REpattp11[j], REpattp12[j]);
              extracted.gsub(lpat, lrep);
            };
          };
	  counts(extracted) = 0;
	};
      };
    };
  }

  cerr << counts.ndefined() << " templates in " <<
    templatesFiles.nelements() << " files" << endl;

  { // Add old files
    const Regex tb(": ");
    Int j;
    for (uInt i=0; i<listFiles.nelements(); i++) {
      ifstream file(listFiles(i).chars(), ios::in);
      while (file.getline(&buffer[0], sizeof(buffer))) { // read line by line
	extracted = buffer;
	if (extracted.contains(comment)) continue; // skip comment
	if (extracted.empty() || extracted.contains(spaces)) 
	  continue;	// skip empty lines
	j = atoi(extracted.chars());
	extracted = extracted.after(tb);
	if (counts.isDefined(extracted)) j += counts(extracted);
	counts(extracted) = j;
      };
    };
  }

  cerr << counts.ndefined() << " templates in " <<
    templatesFiles.nelements() << " files after " <<
    listFiles.nelements() << " inclusion files" << endl;


  if (counts.ndefined() == 0) {
    unu_usage("No template specifications found");
    exit(1);
  };

  if (CNTF) {
    tfcnt.resize(counts.ndefined()); tfcnt = Int(0);
    fcnt.resize(counts.ndefined()); fcnt = Int(0);
    for (uInt i=0; i<counts.ndefined(); i++) {
      fcnt(i) = counts.getVal(i);
      counts(counts.getKey(i)) = 0;
    };
  };
  Int ncount = 0;
  const Regex gnmRE("^[0-9a-f]+.* T .*[<(]");
  const Regex gnmRE2("^[0-9a-f]+.* T +");
  const String gnmRE3("::");
  const Regex nmRE2("^.*\\|.*\\|.*\\|.*FUNC.*\\|.*GLOB[^|]*\\|"
		    "[^|]*\\|[^|]*\\|[ ]*");
  const Regex nmRE("^.*\\|.*\\|.*\\|.*FUNC.*\\|.*GLOB[^|]*\\|"
		   "[^|]*\\|[^|]*\\|.*[<(]");
  const Regex lstRE("^[ ]*[0-9]+: .*[<(]");
  const Regex lstRE2("^[ ]*[0-9]+: ");
  String spcol[50];	// Check for multiple ::
  { // Check names
    Int n;
    String namFile;
    String execString;
    for (uInt i=0; i < namFiles.nelements(); i++) { // for each file...
      if (!BIN) {
	namFile = namFiles(i);
      } else {
	namFile = File::newUniqueName("./").originalName();
	Aipsrc::find(lpat, "unused.file.nm", "gnm");
	execString = lpat + " " + namFiles(i);
	Aipsrc::find(lpat, "unused.file.gfilt", "g++filt");
	execString += " | " + lpat + " | " + "grep 'T .*[<(]' > " + namFile;
	if (system(execString.chars()) != 0) {
	  lpat = "Error reading/converting binary " + namFiles(i);
	  File file(namFile);
	  if (file.exists()) RegularFile(file).remove();
	  unu_usage(lpat);
	  exit(1);
	};
      };
      const String lbr("(");
      const String rbr(")");
      Int cbr = 0;
      const String llt("<");
      const String rgt(">");
      ifstream file(namFile.chars(), ios::in);
      while (file.getline(&buffer[0], sizeof(buffer))) { // read line by line
	extracted = buffer;
	if (extracted.contains(comment)) continue; // skip comment
	if (extracted.empty() || extracted.contains(spaces)) 
	  continue;	// skip empty lines
	if (extracted.contains(gnmRE)) {
	  extracted = extracted.after(gnmRE2);
	} else if (extracted.contains(nmRE)) {
	  extracted = extracted.after(nmRE2);
	} else if (extracted.contains(lstRE)) {
	  extracted = extracted.after(lstRE2);
	} else {
	  continue;
	};
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
	ncount++;
	if (counts.isDefined(extracted)) {
	  n = counts(extracted);
	  n++;
	  counts(extracted) = n;
	};
      };
      if (BIN && !namFile.empty()) {
	File file(namFile);
	if (file.exists()) RegularFile(file).remove();
      };
      if (CNTF) {
	for (uInt j2=0; j2<counts.ndefined(); j2++) {
	  if (counts.getVal(j2) > tfcnt(j2)) {
	    fcnt(j2) +=1;
	    tfcnt(j2) = counts.getVal(j2);
	  };
	};
      };
    };
  }

  cerr << "Checked against " <<
    ncount << " names in " << namFiles.nelements() << " name files" <<
    endl;

  Int ucount = 0;
  {	// Show unused templates
    if (CNTF) {
      cout << "# Used file count >= " << mincnt << endl;
    } else if (ZERO) {
      cout << "# Unused templates: " << endl;
    } else if (!ALL) {
      cout << "# Used templates: " << endl;
    } else {
       cout << "# Template usage: " << endl;
   };
    for (uInt i=0; i<counts.ndefined(); i++) {
      if (CNTF) {
	if (fcnt(i) >= mincnt) {
	  ucount++;
	  printf("%5d: ", fcnt(i));
	  cout << counts.getKey(i) << endl;
	};
      } else if ((ZERO && counts.getVal(i) == 0) ||
		 (!ZERO && !ALL && counts.getVal(i) != 0) ||
		 (!ZERO && ALL)) {
	ucount++;
	printf("%5d: ", counts.getVal(i));
	extracted = counts.getKey(i);
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

  cerr << ucount << " templates shown" << endl;
  
  exit(0);
}

