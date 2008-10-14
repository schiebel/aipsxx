//# SubGroupInfo.cc : class keeping the info about a subgroup
//# Copyright (C) 1998
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
//# $Id: SubGroupInfo.cc,v 19.3 2004/10/18 10:40:42 gvandiep Exp $


#include <SubGroupInfo.h>
#include <NStarSubGroupHeader.h>
#include <casa/Containers/Block.h>
#ifdef AIPS_TRACE
# include <casa/Containers/BlockIO.h>
#endif
#include <casa/Utilities/GenSort.h>
#include <casa/BasicMath/Math.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>
#include <casa/fstream.h>


SubGroupInfo::SubGroupInfo()
: itsAddress (0)
{
    for (Int i=0; i<8; i++) {
	itsId[i] = 0;
    }
}

SubGroupInfo::SubGroupInfo (Int grp, Int obs, Int field, Int chan, Int sector)
: itsAddress (0)
{
    itsId[0] = grp;
    itsId[1] = obs;
    itsId[2] = field;
    itsId[3] = chan;
    itsId[4] = sector;
    for (Int i=5; i<8; i++) {
	itsId[i] = 0;
    }
}

void SubGroupInfo::setId (const Int* id)
{
    for (Int i=0; i<8; i++) {
	itsId[i] = id[i];
    }
}


int SubGroupInfo::operator== (const SubGroupInfo& that) const
{
    for (Int i=0; i<5; i++) {
	if (itsId[i] != that.itsId[i]) {
	    return 0;
	}
    }
    return 1;
}

int SubGroupInfo::operator< (const SubGroupInfo& that) const
{
    for (Int i=0; i<5; i++) {
	if (itsId[i] < that.itsId[i]) {
	    return 1;
	} else if (itsId[i] > that.itsId[i]) {
	    return 0;
	}
    }
    return 0;
}

int SubGroupInfo::operator> (const SubGroupInfo& that) const
{
    for (Int i=0; i<5; i++) {
	if (itsId[i] > that.itsId[i]) {
	    return 1;
	} else if (itsId[i] < that.itsId[i]) {
	    return 0;
	}
    }
    return 0;
}


void SubGroupInfo::writeSGH (SubGroupInfo* groups, Int ngroup, Int gfhOffset,
			     ofstream& file, Int& first, Int& last, Int& nlinkg)
{
    // Seek to the end of the file and get the offset.
    file.seekp (0, ios::end);
    Int offset = file.tellp();

    // Sort the groups in ascending order.
    GenSort<SubGroupInfo>::sort (groups, ngroup, Sort::Ascending,
				 Sort::HeapSort);

    // Now iterate through all groups.
    // Count how many subgroupheaders we have per level (initialize to 1)
    // and compose the id for each group.
    // Set the groupid in the SubGroupInfo objects.
    Block<Int> groupCount = SubGroupInfo::setGroupIds (groups, ngroup);
#ifdef AIPS_TRACE
    cout << "Groupcount = " << groupCount << endl;
#endif

    // Count the number of groups per group at the higher level.
    // Also determine the index of each group in the SubGroupInfo array.
    Block<Int> ngroup0 (1, 0);
    Block<Int> ngroup1 (groupCount[0], 0);
    Block<Int> ngroup2 (groupCount[1], 0);
    Block<Int> ngroup3 (groupCount[2], 0);
    Block<Int> ngroup4 (groupCount[3], 0);
    ngroup0[0] = ngroup1[0] = ngroup2[0] = ngroup3[0] = ngroup4[0] = 1;
    Block<Int> index0 (groupCount[0], 0);
    Block<Int> index1 (groupCount[1], 0);
    Block<Int> index2 (groupCount[2], 0);
    Block<Int> index3 (groupCount[3], 0);
    const SubGroupInfo* lastGroup = &groups[0];
    Int g0 = 0;
    Int g1 = 0;
    Int g2 = 0;
    Int g3 = 0;
    Int i;
    for (i=1; i<ngroup; i++) {
	const SubGroupInfo* thisGroup = &groups[i];
#ifdef AIPS_TRACE
	const Int* tid = thisGroup->getId();
	cout << i << ": " << tid[0] << ' ' << tid[1] << ' ' << tid[2] << ' ' 
	     << tid[3] << ' ' << tid[4] << ";   "
	     << thisGroup->getAddress() << endl;
#endif
	int state;
	if (thisGroup->getGrp() != lastGroup->getGrp()) {
	    state = 0;
	} else if (thisGroup->getObs() != lastGroup->getObs()) {
	    state = 1;
	} else if (thisGroup->getField() != lastGroup->getField()) {
	    state = 2;
	} else if (thisGroup->getChannel() != lastGroup->getChannel()) {
	    state = 3;
	} else {
	    state = 4;
	}
	switch (state) {
	case 0:
	    ngroup0[0]++;
	    g0++;
	    index0[g0] = i;
	case 1:
	    ngroup1[g0]++;
	    g1++;
	    index1[g1] = i;
	case 2:
	    ngroup2[g1]++;
	    g2++;
	    index2[g2] = i;
	case 3:
	    ngroup3[g2]++;
	    g3++;
	    index3[g3] = i;
	default:
	    ngroup4[g3]++;
	}
	lastGroup = thisGroup;
    }
    Block<Int> cumNgroup0 (2, 0);
    cumNgroup0[1] = ngroup0[0];
    Block<Int> cumNgroup1 (groupCount[0] + 1, 0);
    for (i=0; i<groupCount[0]; i++) {
	cumNgroup1[i+1] = cumNgroup1[i] + ngroup1[i];
    }
    Block<Int> cumNgroup2 (groupCount[1] + 1, 0);
    for (i=0; i<groupCount[1]; i++) {
	cumNgroup2[i+1] = cumNgroup2[i] + ngroup2[i];
    }
    Block<Int> cumNgroup3 (groupCount[2] + 1, 0);
    for (i=0; i<groupCount[2]; i++) {
	cumNgroup3[i+1] = cumNgroup3[i] + ngroup3[i];
    }
    Block<Int> cumNgroup4 (groupCount[3] + 1, 0);
    for (i=0; i<groupCount[3]; i++) {
	cumNgroup4[i+1] = cumNgroup4[i] + ngroup4[i];
    }

#ifdef AIPS_TRACE
    cout << "index0 = " << index0 << endl;
    cout << "index1 = " << index1 << endl;
    cout << "index2 = " << index2 << endl;
    cout << "index3 = " << index3 << endl;
    cout << "ngroup0 = " << ngroup0 << endl;
    cout << "ngroup1 = " << ngroup1 << endl;
    cout << "ngroup2 = " << ngroup2 << endl;
    cout << "ngroup3 = " << ngroup3 << endl;
    cout << "ngroup4 = " << ngroup4 << endl;
    cout << "cumNgroup0 = " << cumNgroup0 << endl;
    cout << "cumNgroup1 = " << cumNgroup1 << endl;
    cout << "cumNgroup2 = " << cumNgroup2 << endl;
    cout << "cumNgroup3 = " << cumNgroup3 << endl;
    cout << "cumNgroup4 = " << cumNgroup4 << endl;
#endif

    // Create the parent (the GFH) for the first level.
    // Subtract the LINKG offset in the SGH from the GFH offset.
    // It will be added later by writeLevel().
    NStarSubGroupHeader sgh;
    Block<Int> parentsA (1, gfhOffset - sgh.getOffsetLINKG());
    Block<Int> parentsB;
    offset = SubGroupInfo::writeLevel (parentsB, 0, 4, offset, file, parentsA,
				       groups, index0, ngroup0, ngroup1,
				       cumNgroup0, cumNgroup1);
    first  = parentsB[0];
    last   = parentsB[parentsB.nelements() - 1];
    nlinkg = groupCount[0];
    offset = SubGroupInfo::writeLevel (parentsA, 1, 4, offset, file, parentsB,
				       groups, index1, ngroup1, ngroup2,
				       cumNgroup1, cumNgroup2);
    offset = SubGroupInfo::writeLevel (parentsB, 2, 4, offset, file, parentsA,
				       groups, index2, ngroup2, ngroup3,
				       cumNgroup2, cumNgroup3);
    offset = SubGroupInfo::writeLevel (parentsA, 3, 4, offset, file, parentsB,
				       groups, index3, ngroup3, ngroup4,
				       cumNgroup3, cumNgroup4);
    offset = SubGroupInfo::writeLevel (parentsB, 4, 4, offset, file, parentsA,
				       groups, index3, ngroup4, ngroup4,
				       cumNgroup4, cumNgroup4);
}


Block<Int> SubGroupInfo::setGroupIds (SubGroupInfo* groups, Int ngroup)
{
    Block<Int> id(8, 0);
    Block<Int> groupCount(5, 0);
    SubGroupInfo lastGroup = groups[0];
    groups[0].setId (id.storage());
    for (Int i=1; i<ngroup; i++) {
	SubGroupInfo* thisGroup = &groups[i];
	if (thisGroup->getGrp() != lastGroup.getGrp()) {
	    groupCount[0]++;
	    id[0]++;
	    id[1] = 0;
	    id[2] = 0;
	    id[3] = 0;
	    id[4] = 0;
	} else if (thisGroup->getObs() != lastGroup.getObs()) {
	    groupCount[1]++;
	    id[1]++;
	    id[2] = 0;
	    id[3] = 0;
	    id[4] = 0;
	} else if (thisGroup->getField() != lastGroup.getField()) {
	    groupCount[2]++;
	    id[2]++;
	    id[3] = 0;
	    id[4] = 0;
	} else if (thisGroup->getChannel() != lastGroup.getChannel()) {
	    groupCount[3]++;
	    id[3]++;
	    id[4] = 0;
	} else if (thisGroup->getSector() != lastGroup.getSector()) {
	    groupCount[4]++;
	    id[4]++;
	} else {
	    throw (AipsError ("SubGroupInfo: equal sub group"));
	}
	lastGroup = *thisGroup;
	thisGroup->setId (id.storage());
    }
    groupCount[0] += 1;
    groupCount[1] += groupCount[0];
    groupCount[2] += groupCount[1];
    groupCount[3] += groupCount[2];
    groupCount[4] += groupCount[3];

    // The number of groups must be equal to the group count at the
    // lowest level.
    AlwaysAssert (ngroup == groupCount[4], AipsError);
    return groupCount;
}


Int SubGroupInfo::writeLevel (Block<Int>& offsets,
			      Int level, Int maxLevel, Int offset,
			      ofstream& file,
			      const Block<Int>& parents,
			      const SubGroupInfo* info,
			      const Block<Int>& index,
			      const Block<Int>& ngroup,
			      const Block<Int>& nchild,
			      const Block<Int>& cumNgroup,
			      const Block<Int>& cumNchild)
{
    Int nelem = ngroup.nelements();
    Int totNgroup = cumNgroup[nelem];
    offsets.resize (totNgroup, True);
    NStarSubGroupHeader sgh;
    Int offsetLINKG = sgh.getOffsetLINKG();
    Int k = 0;
    for (Int i=0; i<nelem; i++) {
	Int ng = ngroup[i];
	for (Int j=0; j<ng; j++) {
	    offsets[k] = offset;
	    Int setptr = -1;
	    const Int* id;
	    Int nch = 0;
	    Int cumNch = 0;
	    if (level == maxLevel) {
		setptr = info[k].getAddress();
		id = info[k].getId();
	    } else {
		id = info[index[k]].getId();
		nch = nchild[k];
		cumNch = cumNchild[k];
	    }
	    offset = sgh.write (offset, file, ng, j, nch,
				parents[i] + offsetLINKG,
				setptr, cumNch, totNgroup - cumNgroup[i],
				id, level);
	    k++;
	}
    }
    return offset;
}
