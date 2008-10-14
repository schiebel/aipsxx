//# SubGroupInfo.h : class keeping the info about a subgroup
//# Copyright (C) 1998,2001
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
//# $Id: SubGroupInfo.h,v 19.3 2004/11/30 17:50:39 ddebonis Exp $

#ifndef NFRA_SUBGROUPINFO_H
#define NFRA_SUBGROUPINFO_H
 

//# Includes
#include <casa/aips.h>

//# Forward Declarations
#include <casa/iosfwd.h>
#include <casa/namespace.h>

namespace casa {
   template <class T> class Block;
}

class SubGroupInfo
{
public:
    // Default constructor (is needed for the sort).
    SubGroupInfo();

    // Constructor.
    SubGroupInfo (Int grp, Int obs, Int field, Int chan, Int sector);

    // Destructor Convert to SCN
    ~SubGroupInfo()
        {}

    // Test if 2 objects are equal.
    int operator== (const SubGroupInfo& that) const;

    // Test if this is less than that.
    int operator< (const SubGroupInfo& that) const;

    // Test if this is greater than that.
    int operator> (const SubGroupInfo& that) const;

    // Set the id values (id must have 8 values).
    void setId (const Int* id);

    // Set the file address.
    void setAddress (uInt address)
        { itsAddress = address; }

    // Get the info.
    // <group>
    Int getGrp() const
        { return itsId[0]; }

    Int getObs() const
        { return itsId[1]; }

    Int getField() const
        { return itsId[2]; }

    Int getChannel() const
        { return itsId[3]; }

    Int getSector() const
        { return itsId[4]; }
    // </group>

    // Get a pointer to the full id.
    const Int* getId() const
        { return itsId; }

    // Get the file offset.
    uInt getAddress() const
        { return itsAddress; }

    // Compose all Sub-Group-Headers and write them at the end of the file.
    // It returns the first and last top-level SGH pointer, so they
    // can be stored in the general file header.
    static void writeSGH (SubGroupInfo* groups, Int ngroup, Int gfhOffset,
			  std::ofstream& file, Int& first, Int& last, Int& nlinkg);

    // Set the id in the SubGroupInfo objects.
    // It returns a Block with the total number of groups per level.
    static Block<Int> setGroupIds (SubGroupInfo* groups, Int ngroup);

    // Compose and write the Sub-Group-Headers of the given level.
    // It returns the offset of the SGH's written.
    static Int writeLevel (Block<Int>& offsets,
			   Int level, Int maxLevel, Int offset,
			   std::ofstream& file,
			   const Block<Int>& parents,
			   const SubGroupInfo* info,
			   const Block<Int>& index,
			   const Block<Int>& ngroup,
			   const Block<Int>& nchild,
			   const Block<Int>& cumNgroup,
			   const Block<Int>& cumNchild);

private:
    Int  itsId[8];
    uInt itsAddress;
};


#endif
