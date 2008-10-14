//# VOTableParserArgs.h: this defines VOTableParserArgs, which holds parser args.
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
//# $Id: VOTableParserArgs.h,v 19.3 2004/11/30 17:51:23 ddebonis Exp $

#ifndef VO_VOTABLEPARSERARGS_H
#define VO_VOTABLEPARSERARGS_H

#include <xercesc/parsers/XercesDOMParser.hpp>
#include <casa/namespace.h>
using xercesc::XercesDOMParser;

// <summary>
// A box to pass arguments to the xerces parser.
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
// XercesDOMParser
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// VOTableParserArgs is a box to hold user settable flags that can be
// passed to VOTable::makeVOTable. Most of the flags are for the xerces
// parser. Most will probably never be used. In many cases, VOTableParserArgs
// will likely be unnecessary.
// </synopsis>
//
// <example>
// <srcblock>
// Input inputs;
// VOTableParserArgs args;
//   ...
//	if(fcompare(s, "Auto") == 0)
//		args.setValidationScheme(XercesDOMParser::Val_Auto);
//	args.setLoadExternalDTD(false);
// </srcblock>
// </example>
//
// <motivation>
// It was this or an awful lot of function arguments.
// </motivation>
//
// <templating arg=T>
// None
// </templating>
//
// <thrown>
// None
// </thrown>
//
// <todo asof="2003/04/25">
//
// </todo>

// Structure to pass optional arguments to the parser.
class VOTableParserArgs {
  public:
	VOTableParserArgs();
	~VOTableParserArgs();

	// Set parser args to match ours.
	void setParserArgs(XercesDOMParser *parser)const;

// <group>
	// A whole bunch of settable flags. Most are just here to experiment
	// with. If a routine isn't called, the corresponding flag in the
	// parser is not changed.
	void setCalculateSrcOfs(bool val)
		{ setCalculateSrcOfs_ = val; bits.setCalculateSrcOfs=1;}

	void setCreateCommentNodes(bool val)
		{ setCreateCommentNodes_ = val; bits.setCreateCommentNodes=1;}

	void setCreateEntityReferenceNodes(bool val)
		{ setCreateEntityReferenceNodes_ = val;
		   bits.setCreateEntityReferenceNodes=1;
		}

	void setDoNamespaces(bool val)
		{ setDoNamespaces_ = val; bits.setDoNamespaces=1;}

	void setDoSchema(bool val)
		{ setDoSchema_ = val; bits.setDoSchema=1;}

	void setDoValidation(bool val)
		{ setDoValidation_ = val; bits.setDoValidation=1;}

	void setExitOnFirstFatalError(bool val)
		{ setExitOnFirstFatalError_ = val;
		  bits.setExitOnFirstFatalError=1;
		}

	void setExpandEntityReferences(bool val)
		{ setExpandEntityReferences_ = val;
		  bits.setExpandEntityReferences=1;
		}

	void setIncludeIgnorableWhitespace(bool val)
		{ setIncludeIgnorableWhitespace_ = val;
		  bits.setIncludeIgnorableWhitespace=1;
		}

	// This routine is called with val=false by the constructor.
	void setLoadExternalDTD(bool val)
		{ setLoadExternalDTD_ = val; bits.setLoadExternalDTD=1;}

	void setStandardUriConformant(bool val)
		{ setStandardUriConformant_ = val;
		  bits.setStandardUriConformant=1;
		}

	void setValidationConstraintFatal(bool val)
		{ setValidationConstraintFatal_ = val;
		  bits.setValidationConstraintFatal=1;
		}

	void setValidationSchemaFullChecking(bool val)
		{ setValidationSchemaFullChecking_ = val;
		  bits.setValidationSchemaFullChecking=1;
		}

	void setValidationScheme(XercesDOMParser::ValSchemes val)
		{ validationScheme_ = val; bits.setValidationScheme=1;}
// </group>

  private:

	bool	setCalculateSrcOfs_, setCreateCommentNodes_;
	bool	setCreateEntityReferenceNodes_, setDoNamespaces_;
	bool	setDoSchema_, setDoValidation_;
	bool	setExitOnFirstFatalError_, setExpandEntityReferences_;
	bool	setIncludeIgnorableWhitespace_, setLoadExternalDTD_;
	bool	setStandardUriConformant_, setValidationConstraintFatal_;
	bool	setValidationSchemaFullChecking_, setValidationScheme_;
	XercesDOMParser::ValSchemes validationScheme_;

	// If set, the corresponding variable has been set.
	union {
		unsigned long	setBits_;
		struct {
		unsigned int	setCalculateSrcOfs :1;
		unsigned int	setCreateCommentNodes :1;
		unsigned int	setCreateEntityReferenceNodes :1;
		unsigned int	setDoNamespaces :1;
		unsigned int	setDoSchema	:1;
		unsigned int	setDoValidation :1;
		unsigned int	setExitOnFirstFatalError :1;
		unsigned int	setExpandEntityReferences :1;
		unsigned int	setIncludeIgnorableWhitespace :1;
		unsigned int	setLoadExternalDTD :1;
		unsigned int	setStandardUriConformant :1;
		unsigned int	setValidationConstraintFatal :1;
		unsigned int	setValidationSchemaFullChecking :1;
		unsigned int	setValidationScheme:1;
		} bits;
	};
};

#endif
