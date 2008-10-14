//# VOTableParserArgs.cc:  this defines VOTableParserArgs which pass args to VOTable
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
//# $Id: VOTableParserArgs.cc,v 19.1 2004/11/30 17:51:23 ddebonis Exp $

#include <VOTableParserArgs.h>

#include <casa/namespace.h>
VOTableParserArgs::VOTableParserArgs() : setBits_(0)
{
	////////////////////////////////////////////////////////////////
	// These values are only referenced if the associated set function
	// has been called (the the value set). They are explicitly set here
	// to keep debuggers that do access checking happy.

	setCalculateSrcOfs_ = setCreateCommentNodes_ = false;
	setCreateEntityReferenceNodes_ = setDoNamespaces_ = false;
	setDoSchema_ = setDoValidation_ = false;
	setExitOnFirstFatalError_ = setExpandEntityReferences_ = false;
	setIncludeIgnorableWhitespace_ = setLoadExternalDTD_ = false;
	setStandardUriConformant_ = setValidationConstraintFatal_ = false;
	setValidationSchemaFullChecking_ = setValidationScheme_ = false;

	// Just pick a value, it doesn't matter.
	validationScheme_ = XercesDOMParser::Val_Never;
	////////////////////////////////////////////////////////////////

	// Our default is to NOT load the DTD.
	setLoadExternalDTD(false);
}

VOTableParserArgs::~VOTableParserArgs() {}

// Copy any value that has been explicitly set to the parser.
void VOTableParserArgs::setParserArgs(XercesDOMParser *parser)const
{
	if(parser == 0)
		return;

	if(bits.setValidationScheme)
	{	parser->setValidationScheme(validationScheme_);
		switch(validationScheme_) {
		case XercesDOMParser::Val_Auto:
			break;
		case XercesDOMParser::Val_Always:
			break;
		case XercesDOMParser::Val_Never:
			break;
		default:
			break;
		}
		//		cerr << "setParserArgs:: ValidationScheme: "
		//   << vs << endl;
	}

	if(bits.setCalculateSrcOfs)
	{	parser->setCalculateSrcOfs(setCalculateSrcOfs_);
	}

	if(bits.setCreateCommentNodes)
	{	parser->setCreateCommentNodes(setCreateCommentNodes_);
	}

	if(bits.setCreateEntityReferenceNodes)
	{	parser->setCreateEntityReferenceNodes(setCreateEntityReferenceNodes_);
	}

	if(bits.setDoNamespaces)
	{	parser->setDoNamespaces(setDoNamespaces_);
	}

	if(bits.setDoSchema)
	{	parser->setDoSchema(setDoSchema_);
	}

	if(bits.setDoValidation)
	{	parser->setDoValidation(setDoValidation_);
	}

	if(bits.setExitOnFirstFatalError)
	{	parser->setExitOnFirstFatalError(setExitOnFirstFatalError_);
	}

	if(bits.setExpandEntityReferences)
	{	parser->setExpandEntityReferences(setExpandEntityReferences_);
	}

	if(bits.setIncludeIgnorableWhitespace)
	{	parser->setIncludeIgnorableWhitespace(setIncludeIgnorableWhitespace_);
	}

	if(bits.setLoadExternalDTD)
	{	parser->setLoadExternalDTD(setLoadExternalDTD_);
	}

	if(bits.setStandardUriConformant)
	{	parser->setStandardUriConformant(setStandardUriConformant_);
	}

	if(bits.setValidationConstraintFatal)
	{	parser->setValidationConstraintFatal(setValidationConstraintFatal_);
	}

	if(bits.setValidationSchemaFullChecking)
	{	parser->setValidationSchemaFullChecking(setValidationSchemaFullChecking_);
	}

	if(bits.setValidationScheme)
	{	parser->setValidationScheme(validationScheme_);
	}
}
