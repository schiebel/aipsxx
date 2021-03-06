//# TSMFile.cc: Tiled Hypercube Storage Manager for tables
//# Copyright (C) 1995,1996,1997,2001
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
//# $Id: TSMFile.cc,v 19.4 2004/11/30 17:51:06 ddebonis Exp $


//# Includes
#include <tables/Tables/TSMFile.h>
#include <tables/Tables/TiledStMan.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/DataManError.h>
#include <casa/IO/AipsIO.h>
#include <casa/BasicSL/String.h>
#include <casa/stdio.h>		// for sprintf

namespace casa { //# NAMESPACE CASA - BEGIN

TSMFile::TSMFile (const TiledStMan* stman, uInt fileSequenceNr)
: fileSeqnr_p (fileSequenceNr),
  file_p      (0),
  length_p    (0)
{
    // Create the file.
    char strc[8];
    sprintf (strc, "_TSM%i", fileSeqnr_p);
    String fileName = stman->fileName() + strc;
    file_p = new BucketFile (fileName);
}

TSMFile::TSMFile (const String& fileName, Bool writable)
: fileSeqnr_p (0),
  file_p      (0),
  length_p    (0)
{
    // Create the file.
    file_p = new BucketFile (fileName, writable);
}

TSMFile::TSMFile (const TiledStMan* stman, AipsIO& ios, uInt seqnr)
: file_p (0)
{
    getObject (ios);
    if (seqnr != fileSeqnr_p) {
	throw (DataManInternalError ("TSMFile::TSMFile"));
    }
    char strc[8];
    sprintf (strc, "_TSM%i", fileSeqnr_p);
    String fileName = stman->fileName() + strc;
    file_p = new BucketFile (fileName, stman->table().isWritable());
}

TSMFile::~TSMFile()
{
    delete file_p;
}


void TSMFile::putObject (AipsIO& ios) const
{
    // Take care of forward compatibility (for small enough files).
    uInt version = (length_p < 2u*1024u*1024u*1024u  ?  1 : 2);
    ios << version;
    ios << fileSeqnr_p;
    if (version == 1) {
        uInt len = length_p;
        ios << len;
    } else {
        ios << length_p;
    }
}

void TSMFile::getObject (AipsIO& ios)
{
    uInt version;
    ios >> version;
    ios >> fileSeqnr_p;
    if (version == 1) {
        uInt len;
        ios >> len;
        length_p = len;
    } else {
        ios >> length_p;
    }
}

} //# NAMESPACE CASA - END

