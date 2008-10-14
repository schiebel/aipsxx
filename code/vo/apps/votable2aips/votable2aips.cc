// votable2aips: Converts a VOTABLE table file to an AIPS++ table.
//# Copyright (C) 2003
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: votable2aips.cc,v 19.4 2004/11/30 17:51:23 ddebonis Exp $

// This a sample application using the VOTable class to read a VOTABLE
// data file and an VOT2AIPS object to write an AIPS++ table.
#include <stdio.h>
#include <casa/iostream.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>	// strncmp

#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>
#include <casa/Inputs.h>

#include <VOTable.h>
#include <VOT2AIPS.h>

#include <casa/namespace.h>
// Print error message when an AIPS++ error gets thrown.
#define AERR(err) {cerr << __FILE__ << ":" << __LINE__ << endl;\
		   cerr << err.getMesg() << endl;}


////////////////////////////////////////////////////////////////
//			Preliminary processing.
////////////////////////////////////////////////////////////////

// Handle command line arguments.
static void getParserArgs(Input &inputs, VOTableParserArgs &args)
{
	if(inputs.getString("doSchema") != "")
	{ bool doSchema = inputs.getBool("doSchema");
		args.setDoSchema(doSchema);
	}

	String s =  inputs.getString("validation");

	if(s != "")
	{	if(fcompare(s, "Auto") == 0)
			args.setValidationScheme(XercesDOMParser::Val_Auto);
		else
		if(fcompare(s, "Always") == 0)
			args.setValidationScheme(XercesDOMParser::Val_Always);
		else
		if(fcompare(s, "Never") == 0)
			args.setValidationScheme(XercesDOMParser::Val_Never);
		else
		cout << "Unknown validation scheme: " << s << endl;
	}

	s = inputs.getString("fullvalidation");
	if(s != "")
	{ bool full = inputs.getBool("fullvalidation");
		args.setValidationSchemaFullChecking(full);
	}

	s = inputs.getString("donamespaces");
	if(s != "")
	{ bool ns = inputs.getBool("donamespaces");
		args.setDoNamespaces(ns);
	}
}

static void help(const char *name)
{
	cout << "Test program for VOTABLE to AIPS++ conversion.\n";
	cout << name << "	[ifile=inputfile]	Input file";
	cout << " (Default is 'tst.xml')\n";
	cout <<  "	[ofile=outputfile]	Output file";
	cout <<  " (Default is <ifile>.tbl.\n";
	cout <<  "				A trailing 'xml' is removed.)\n";
	cout <<  "	[doSchema=t/F]		Sets xerces' doSchema flag.";
	cout <<  " (Default is f)\n";
	cout <<  "	[validation= Auto|Always|Never]\n";
	cout <<  "				Sets xerces' validation flag.";
	cout <<  " (Default is Auto)\n";
 cout <<  "	[fullvalidation=t/F]	Sets xerces' fullvalidation flag.";
	cout <<  " (Default is f)\n";
 cout <<  "	[donamespaces=t/F]	Sets xerces' doNameSpaces flag.";
	cout <<  " (Default is f)\n";
 cout <<  "	[l1=T/f]		If false, use old SIMPLE test.\n";
}

static const char *INFILE="tst.xml";
static const char *valMesg =
"Validation Scheme: ([Auto], Always, Never)?";

int main(int argc, char *argv[])
{String ifile, ofile;
 bool printReferences;
 VOTableParserArgs args;
 Input inputs(1);
 uLong maxdepth = ~0;
 VOT2AIPS	vot2aips;
 int rtn = 0;

	if((argc > 1) && (strncmp(argv[1], "-h", 2)==0))
	{	help(argv[0]);
		exit(0);
	}

//	inputs.version("$@w{Revision}$");
	inputs.create("ifile", INFILE, "XML file name?", "Infile");
	// 'default' output file is empty.
	inputs.create("ofile", "", "AIPS++ table name?", "Outfile");
	inputs.create("refer", "False", "Print References?", "Bool");
	inputs.create("doSchema", "", "Do Schema?", "Bool");
	inputs.create("validation", "", valMesg);
	inputs.create("fullvalidation", "", "Do Full Schema Validation",
		      "Bool");
	inputs.create("donamespaces", "", "Do namespaces", "Bool");
	inputs.create("l1", "true", "Do 1 level", "Bool");

	try {
		inputs.readArguments(argc, argv);
		ifile = inputs.getString("ifile");
		ofile = inputs.getString("ofile");
		printReferences = inputs.getBool("refer");
		bool level1 = inputs.getBool("l1");
		if(level1) maxdepth = 1;

		// Our default is to not load DTD.
		args.setLoadExternalDTD(false);
		getParserArgs(inputs, args);
	}
	catch (AipsError x) {
		AERR(x);
		return 1;
	}

	// Parse VOTABLE file.
	VOTable *tbl = VOTable::makeVOTable(ifile.chars(), args);

	if(tbl == 0)
	{	cerr << argv[0] << ": Could not process " << ifile << endl;
		help(argv[0]);
		exit(1);
	}

 	// If no output file name was given, create one from the input.
	if(ofile == "")
	{ Regex re(".xml$");	// Remove trailing extension.

		ofile = ifile.before(re) + ".tbl";
	}

	try {
	  vot2aips.buildAIPSTable(tbl, ofile, maxdepth);
	}
	catch (const AipsError &err) {
	  rtn = 1;
	  //	  cout << err.getMesg() << endl;
	}
	return rtn;
}
