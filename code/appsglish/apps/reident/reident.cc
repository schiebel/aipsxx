//# reident.cc: Check and reformat entries in aips++/g++ "templates" files
//# Copyright (C) 1996-2002,2004,2005
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
//# $Id: reident.cc,v 19.6 2005/05/13 13:20:56 wbrouw Exp $

// For documentation, see the System manual, or "reident -help"

#include <casa/aips.h>
#include <casa/Utilities/Template.h>
#include <casa/BasicSL/String.h>
#include <casa/OS/Directory.h>
#include <casa/OS/RegularFile.h>
#include <casa/Arrays/Vector.h>

#include <casa/stdio.h>
#include <casa/fstream.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
static void rei_usage() {
  cerr << "Usage: reident [-z] [-t] [templates_1 ... templates_n]\n";
  cerr << "If no templates files are supplied, then the "
    "templates file\nin the current directory will be used "
    "if it exists.\nIf input files given they will be concatenated.\n"
    "One input file may be specified as '-' to indicate stdin.\n"
    "The output will be reformatted, sorted, and missing or duplicate "
    "numbers\n(or numbers less than 1000) will be made unique.\n" 
    "The result will be written to the templates "
    "file in the local\ndirectory, unless the -t switch is given.\n"
    "Note that no check for duplicate template definitions is made. Run\n"
    "'duplicates templates' to get duplicates in result.\n"
    "Comments stay at top or tuned to template instantiation.\n"
    " -z: renumber all templates definitions\n"
    " -t: write output to terminal (stdout)\n\n"
    " -v: give more verbose output for warnings\n"
    "Example: reident -t | duplicates -r trial -\n"
    "will canonicalise the templates in current directory, and check \n"
    "against duplicates in itself and in the trial/_ReposFiller/templates.\n"
       << endl;
}

int main(int argc, char **argv) {

  // This will hold the names of the templates files we are going to use
  Vector<String> templatesFiles;
  Bool ZERO = False;		// -z switch given	
  Bool TERM = False;		// -t switch given
  Bool VERB = False;            // -v switch given
  String STDI = "";		// - file name
  
  // Get templates files
  for (Int i=1; i<argc; i++) {
    String nam = argv[i];
    if (nam[0] == '-') {
      if (nam == "-z") {
	ZERO = True;
	continue;
      } else if (nam == "-v") {
	VERB = True;
	continue;
      } else if (nam == "-t") {
	TERM = True;
	continue;
      } else if (nam == "-") {
	if (!STDI.empty()) {
	  rei_usage();
	  exit(1);
	};
	STDI = File::newUniqueName("./").originalName();
	continue;
      } else {
	rei_usage();
	exit(1);
      };
    };
    File userTemplate(nam);
    if (userTemplate.exists()) {
      uInt n = templatesFiles.nelements();
      templatesFiles.resize(n+1, True);
      templatesFiles(n) = nam;
    } else {
      cerr << "No such templates file: " << nam << endl;
    };
  };
  
  if (!STDI.empty()) {
    uInt n = templatesFiles.nelements();
    templatesFiles.resize(n+1, True);
    templatesFiles(n) = STDI;
  };
  
  if (templatesFiles.nelements() == 0) {
    File localTemplates("templates");
    // Add ./templates to the list if it exists
    if (localTemplates.exists()) {
      uInt n = templatesFiles.nelements();
      templatesFiles.resize(n+1, True);
      templatesFiles(n) = "./templates";
    };
  };
  
  if (templatesFiles.nelements() == 0) {
    cerr << "No input templates files found" << endl;
    rei_usage();
    exit(1);
  } else {
    cerr << "Using " << templatesFiles << endl;
  };
  
  // Get stdin
  if (!STDI.empty()) {
    String extracted = "";
    ofstream std(STDI.chars(), ios::out);
    while (getline(cin, extracted)) std << extracted << endl;
    std.close();
  };
  
  String combine = "";	// Full line
  String extracted = "";
  
  // Read all files into single lines
  Template tmpls;
  tmpls.read(templatesFiles);
  
  // Make the template entries canonical format
  tmpls.canonical();
    
  // Split in number and name and sort
  tmpls.sortName(ZERO);

  // Write formatted output
  if (!TERM) {
    ofstream file("templates", ios::out);
    tmpls.writeOut(file, VERB);
  } else tmpls.writeOut(cout, VERB);
  
  // Ready
  cerr << tmpls.getCount() << " template instantiation files processed with " <<
    tmpls.getTCount() << " templates" << endl;

  // Remove temporary file
  if (!STDI.empty()) {
    File file(STDI);
    if (file.exists()) RegularFile(STDI).remove();
  };
  
  exit(0);
}
