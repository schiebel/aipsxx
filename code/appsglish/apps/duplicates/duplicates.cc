//# duplicates.cc: Find duplicate entries in aips++/g++ "templates" files
//# Copyright (C) 1996,1997,1999,2000,2001,2002,2004
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
//# $Id: duplicates.cc,v 19.5 2004/11/30 17:50:07 ddebonis Exp $

// For documentation, see the "usage" function, or "duplicates -help"

#include <casa/aips.h>
#include <casa/Utilities/Template.h>

#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Exceptions/Error.h>
#include <casa/System/Aipsrc.h>
#include <casa/OS/Directory.h>
#include <casa/OS/RegularFile.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>

#include <casa/stdio.h>
#include <casa/iostream.h>
#include <casa/fstream.h>
  
#include <casa/namespace.h>
static void dup_usage() {
  cerr << "Usage: duplicates [-s] [-p package] [-r package] [-u package] ...\n"
    "                  [templates_1 ... templates_n]\n";
  cerr << "If no templates files are supplied, then ALL the system templates "
    "will be\nsearched, unless the explicit package switches are given, "
    "which restrict\n the system files,"
    "plus a templates file in the current directory "
    "if it exists.\n"
    "If templates files are given, one may be specified as '-' to "
    "indicate stdin.\n"
    " -s indicates system mode for general test\n"
    "Duplicates are written to standard output.\n\n"
    " -p package  include all system templates files in the package\n"
    " -r package  include all system repository templates files in the package\n"
    " -u package  include all user system templates files in the package\n"
    " Note: package maybe all\n\n"
    "Example: reident -t | duplicates -r trial -\n"
    "will canonicalise the templates in current directory, and check \n"
    "against duplicates in itself and in the trial/_ReposFiller/templates.\n\n"
    "Template entries should already have been canonicalized, e.g. by"
    " reident.\n"
    "#if and #endif on separate lines -- done by reident)\n"
    " formats are supported.\n"
    "Duplicates in the template file in the user directory (if no explicit \n"
    "files are given) or in the first user file (if files given) are \n"
    "indicated with ' ***' at end of line.\n";
}

int main(int argc, char **argv) {

  // This will hold the names of the templates files we are going to look for
  // duplicates in.
  Vector<String> templatesFiles;
  Vector<String> interFiles;	// interim set
  String userFile = "";		// for *** indicator
  String STDI = "";		// - file name
  Bool GIVEN = False;		// explicit names given
  Bool RESTR = False;		// Restricted part given
  Bool SYS   = False;		// System mode
  // The AIPSROOT
  String aipsroot;

  // Get AIPSROOT
  try {
    aipsroot = Aipsrc::aipsRoot();
  } catch (AipsError x) {
    cerr << x.getMesg() << endl;
    dup_usage();
    exit(1);
  } 

  if (argc == 1) {
    // No templates files listed on the command line, so use all the system
    // templates files plus the templates file in the current directory, if
    // any.
    String aipspath = aipsroot + "/code";
    cerr << "Using all templates files under " << aipspath << endl;
    Directory aipsroot(aipspath);
    // Use all files named "templates" found under aipsroot.
    interFiles = aipspath + String("/") + 
      aipsroot.find(Regex::fromString("templates"));
    RESTR = True;
  } else {		// Get templates files from command line
    for (Int i=1; i<argc; i++) {
      String nam = argv[i];
      if (nam[0] == '-') {
	if (nam == "-") {
	  if (!STDI.empty()) {
	    dup_usage();
	    exit(1);
	  };
	  STDI = File::newUniqueName("./").originalName();
	  GIVEN = True;
	  continue;
	} else if (nam == "-s") SYS = True;
	else if (nam == "-p" || nam == "-u" || nam == "-r") {
	  String pnam;
	  i++;		// next arg
	  if (i >= argc || argv[i][0] == '-') {
	    cerr << "No package name provided" << endl;
	    dup_usage();
	    exit(1);
	  };
	  RESTR = True;
	  pnam = argv[i];
	  String aipspath = aipsroot + "/code";
	  if (pnam != "all") {
	    aipspath += (String("/") + pnam);
	    File tst(aipspath);
	    if (!tst.isDirectory()) {
	      cerr << "Package " << pnam << " does not exist" << endl;
	      dup_usage();
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
	  dup_usage();
	  exit(1);
	};
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
  };
  
  // Add local templates file
  if (!GIVEN) {
    File localTemplates("templates");
    // Add ./templates to the list if it exists
    if (localTemplates.exists()) {
      uInt n = templatesFiles.nelements();
      templatesFiles.resize(n+1, True);
      templatesFiles(n) = "./templates";
      userFile = templatesFiles(n);	// remember user file for ***
      cerr << "Using ./templates" << endl;
    };
  };

  if (templatesFiles.nelements() != 0)
    cerr << "Using " << templatesFiles << endl;

  if (!STDI.empty()) {
    uInt n = templatesFiles.nelements();
    templatesFiles.resize(n+1, True);
    templatesFiles(n) = STDI;
    ofstream std(STDI.chars(), ios::out);
    String extracted;
    while (getline(cin, extracted)) std << extracted << endl;
    std.close();
    if (userFile.empty()) {
      userFile = templatesFiles(n);	// remember user file for ***
    };
    cerr << "Using " << "-" << endl;
  };

  // Copy all from interim set
  for (uInt j=0; j<interFiles.nelements(); j++) {
    uInt n = templatesFiles.nelements();
    templatesFiles.resize(n+1, True);
    templatesFiles(n) = interFiles(j);
  };

  if (userFile.empty() && templatesFiles.nelements() != 0) {
    userFile = templatesFiles(0);	// remember user file for ***
  };
  
  // Read all the userfiles
  Template tmpls(templatesFiles);

  // Reformat the templates
  tmpls.canonical(True);

  // Output the duplicates
  tmpls.writeDup(cout, userFile, SYS);

  // Show result
  cerr << tmpls.getDCount() << " duplicates found in " <<
    tmpls.getTDCount() << " templates";
  if (SYS) cout << " (-s switch)";
  cout << endl;
  
  // Remove temp file
  if (!STDI.empty()) {
    File file(STDI);
    if (file.exists()) RegularFile(file).remove();
  };
  
  exit(0);

}
