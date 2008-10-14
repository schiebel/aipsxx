//# NStarFile.h : class for access to Newstar Files
//# Copyright (C) 1997,1998,2000,2001
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
//# $Id: NStarFile.h,v 19.4 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_NSTARFILE_H
#define NFRA_NSTARFILE_H
 

//# Includes
#include <NStarFileType.h>
#include <NStarGeneralFileHeader.h>
#include <SubGroupInfo.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Block.h>
#include <casa/fstream.h>
#include <casa/namespace.h>

//# Forward Declarations
class NStarSetHeader;


class NStarFile
{
public:

    // Constructor NStar File 
    NStarFile(NStarFileType aType, const Char* aName);

    // Destructor NStar File
    ~NStarFile();

    // set the correct size of the set/group blocks.
    void setSizes (uInt nrSets, uInt nrGroups);

    // add a NStarSetHeader
    Bool addSet(NStarSetHeader* aSet, const SubGroupInfo& group);

    // add a (dummy) SubGroupInfo.
    // This should only be called after all addSet's are done.
    // Otherwise the next addSet throws an exception.
    Bool addGroup(const SubGroupInfo& group);

    // Write out the NStarFile
    Bool write();

    // return a reference to the file object.
    std::ofstream& getFile();

    // return a reference (non-const) to itsGFH
    NStarGeneralFileHeader& getGeneralFileHeader();

    // return a pointer to the given set header.
    NStarSetHeader* getSetHeader (uInt index);

    // Fill the IFheader pointer and length in set headers of the given band.
    void setIFHPtr (Short aBand, Int aPtr, Int aSize);
private:

    // The full pathname for the NStarFile
    String itsFileName;

    // The output steam for the file
    std::ofstream itsFile;

    // The GFH for this NStarFile
    NStarGeneralFileHeader itsGFH;

    // Full list of SubGroupInfo
    Block<SubGroupInfo> itsGroups;

    // list of NStarSets currently in memory
    PtrBlock<NStarSetHeader*> itsSets;

    // Nr of sets in block.
    uInt itsCurNrSets;

    // Nr of groups in block.
    uInt itsCurNrGroups;
};


#endif
