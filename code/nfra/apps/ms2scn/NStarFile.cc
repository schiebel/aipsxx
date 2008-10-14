//# NStarFile.cc : class for access to Newstar Files
//# Copyright (C) 1997,1998,2000,2002
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
//# $Id: NStarFile.cc,v 19.2 2005/12/21 13:18:03 rassendo Exp $

#include <NStarFile.h>
#include <NStarSetHeader.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>


// Initialize itsFileName
NStarFile::NStarFile(NStarFileType aType, const Char* aName)
: itsFileName   (aName),
  itsGFH        (aType,aName),
  itsCurNrSets  (0),
  itsCurNrGroups(0)
{
    itsFile.open(itsFileName.chars());
    // Start with writing the (still incomplete) GFH, because it must
    // be located at the beginning of the file.
    itsGFH.write(itsFile);
}

// Destructor
NStarFile::~NStarFile()
{
    // Delete NStarSet list
    for (uInt i=0; i<itsCurNrSets; i++) {
	delete itsSets[i];
    }
}

// Set the size of the blocks.
void NStarFile::setSizes (uInt nrSets, uInt nrGroups)
{
    itsSets.resize (nrSets);
    itsGroups.resize (nrGroups);
}

// add a NStarSetHeader and SubGroupInfo.
Bool NStarFile::addSet(NStarSetHeader* aSet, const SubGroupInfo& group)
{
    AlwaysAssert (itsCurNrGroups == itsCurNrSets, AipsError);
    aSet->setSetNumber(itsCurNrSets);
    itsSets[itsCurNrSets++] = aSet;
    itsGroups[itsCurNrGroups++] = group;
    return True;
}

// add a SubGroupInfo.
Bool NStarFile::addGroup(const SubGroupInfo& group)
{
    itsGroups[itsCurNrGroups++] = group;
    return True;
}

// Write NStarFile
Bool NStarFile::write()
{
    uInt i;
    cout << "writing all sector headers and subgroup headers ..." << endl;
    Vector<Int> aLink(2);
    // Write set headers first time, but only filling in the PREVIOUS links.
    // First sector points back to the LINK field in the GFH.
    Int last=itsGFH.getOffsetLINK();
    Int first=last;
    for (i=0; i<itsCurNrSets; i++) {
       aLink(1)=last;
       aLink(0)=0;				// Next
       itsSets[i]->setLINK(aLink);	        // Fill links
       itsSets[i]->write(itsFile);
       last=itsSets[i]->getAddress();           // Get current position
       if (i==0) {
          first=last;
       }
       itsGroups[i].setAddress(last);           // Set address (for SGH)
    }
    // Fill start/end links in GFH
    aLink(0)=first;
    aLink(1)=last;
    itsGFH.setLINK(aLink,itsCurNrSets);

    // Write second time, but now filling in the NEXT links
    // The last NEXT link points to the LINK field in the GFH.
    NStarSetHeader* curSet=0;
    for (i=0; i<itsCurNrSets; i++) {
       curSet=itsSets[i];                       // Keep current
       aLink = curSet->getLINK();
       if (i<itsCurNrSets-1) {
	 aLink(0)=itsSets[i+1]->getAddress();
       } else {
         aLink(0)=itsGFH.getOffsetLINK();
       } 
       curSet->setLINK(aLink);                  // Fill links
       curSet->write(itsFile);                  // Update header
    }

    // Create the SGH structures.
    // Write the subgroup headers and fill the GFH with the top level
    // SGH links.
    // The head of the SGH's is the LINKG field in the GFH.
    Int head = itsGFH.getOffsetLINKG();
    Int firstg, lastg, nlinkg;
    SubGroupInfo::writeSGH (itsGroups.storage(), itsCurNrGroups, head,
			    itsFile, firstg, lastg, nlinkg);
    itsGFH.setLINKG (firstg, lastg, nlinkg);

    // The GFH is complete now. Write it.
    itsGFH.write(itsFile);

    return True;
}

// return a reference (non-const) to itsGFH
NStarGeneralFileHeader& NStarFile::getGeneralFileHeader()
{
    return itsGFH;
}

// return a reference (non-const) to itsFile
ofstream& NStarFile::getFile()
{
    return itsFile;
}

NStarSetHeader* NStarFile::getSetHeader (uInt index)
{
    return itsSets[index];
}

void NStarFile::setIFHPtr(Short aBand,Int aPtr,Int aSize)
{
  for (uInt i=0; i< itsCurNrSets;i++) {
    if (getSetHeader(i)->getSpwid() == uInt(aBand)) {
      getSetHeader(i)->setIFHP(aPtr);
      getSetHeader(i)->setIFHL(aSize);
      break;
    }
  }
}
