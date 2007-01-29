//# VLADiskInput.cc: This class reads VLA archive files from a Disk
//# Copyright (C) 1999,2000,2001,2002,2003
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
//# $Id: VLADiskInput.cc,v 19.2 2004/08/25 05:49:29 gvandiep Exp $

#include <nrao/VLA/VLADiskInput.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/MemoryIO.h>
#include <casa/IO/ByteIO.h>
#include <casa/OS/RegularFile.h>
#include <casa/iostream.h>

VLADiskInput::VLADiskInput(const Path& fileName) 
  :VLAArchiveInput(),
   itsFile(RegularFile(fileName))
{
}

VLADiskInput::~VLADiskInput() {
  // The RegularFileIO destructor closes the disk file.
}

Bool VLADiskInput::read() {
  // Clear the internal buffers and reset the flags as we will try to read some
  // more data.
  itsMemIO.clear();
  // Find an initial record. 
  Short n = 1, m;
  if (findFirstRecord(m) == False) return False;
  // We have the first physical record in Memory. Now decode how long this
  // logical record is.
  itsRecord.seek(0);
  Int logicalRecordSize;
  itsRecord >> logicalRecordSize;
  logicalRecordSize *= 2;
  uInt curRecSize = itsMemIO.length();
  Int bytesToRead = logicalRecordSize - curRecSize;
  Int thisReadSize;
  // make the buffer a bit bigger than necessary as we may need to read up to
  // VLAArchiveInput::BlockSize - 1 extra bytes (to pad out the block).
  uChar* recordPtr = itsMemIO.setBuffer(logicalRecordSize + 
				  VLAArchiveInput::BlockSize-1);
// Sanity check here.
  if(this->bytesRead() >= this->totalBytes()){
    cerr << "VLADiskInput::read attempt read past end of file. Handled." << endl;
    itsMemIO.clear();
    return False;
  }
  
  while (bytesToRead > 0) {
    thisReadSize = VLAArchiveInput::HeaderSize;
    DebugAssert(static_cast<Int64>(curRecSize + VLAArchiveInput::HeaderSize) <=
                itsMemIO.length(), AipsError);
    Int bytesRead =
      itsFile.read(VLAArchiveInput::HeaderSize, recordPtr+curRecSize, False);
    if (bytesRead < static_cast<Int>(VLAArchiveInput::HeaderSize)) {
      itsMemIO.clear();
      return False;
    }
    // Check the sequence numbers
    {
      itsRecord.seek(Int64(curRecSize));
      Short newn, newm;
      itsRecord >> newn;
      itsRecord >> newm;
      if (newm != m || ++n != newn) {
 	itsMemIO.clear();
 	return False;
      }
      itsRecord.seek(Int64(curRecSize));
    }
    // The sequence numbers are OK so read the rest of the data
    if (bytesToRead < 
	static_cast<Int>(VLAArchiveInput::BlockSize*
			 VLAArchiveInput::MaxBlocksPerPhysicalRecord)) {
      thisReadSize = (bytesToRead-1)/VLAArchiveInput::BlockSize + 1;
      thisReadSize *= VLAArchiveInput::BlockSize;
    } else {
      thisReadSize = VLAArchiveInput::BlockSize *
	VLAArchiveInput::MaxBlocksPerPhysicalRecord;
    }
    thisReadSize -= VLAArchiveInput::HeaderSize;
    DebugAssert(static_cast<Int64>(curRecSize+thisReadSize)<=itsMemIO.length(),
		AipsError);
    bytesRead = itsFile.read(thisReadSize, recordPtr+curRecSize, False);
    if (bytesRead < thisReadSize) {
      itsMemIO.clear();
      return False;
    }
    curRecSize += thisReadSize;
    bytesToRead -= thisReadSize;
  }
  itsMemIO.setUsed(logicalRecordSize);
  itsRecord.seek(0);
  return True;
}

// Find an initial record. An initial record MUST have the first 2-byte integer
// as 1 and the next 2-byte integer as a number greater than zero. If we have
// not found an initial record after searching 5MBytes worth of data then just
// give up.
Bool VLADiskInput::findFirstRecord(Short& m) {
  const uInt maxBytesToSearch = 5*1024*1024;
  Short n = 0 ;
  m = 0;
  {
    uInt bytesSearched = 0;
    // Search for the correct sequence number or give up after a while.
    uChar* recordPtr = itsMemIO.setBuffer(VLAArchiveInput::HeaderSize);
    while (!(n == 1 && m > 0 && m < 40) && (bytesSearched <= maxBytesToSearch)) {
      if (bytesSearched > 0) {
	itsFile.seek(Int64(VLAArchiveInput::BlockSize -
			   VLAArchiveInput::HeaderSize),
		     ByteIO::Current);
      }
      bytesSearched += VLAArchiveInput::BlockSize;
      Int bytesRead = 
	itsFile.read(VLAArchiveInput::HeaderSize, recordPtr, False);
      if (bytesRead < static_cast<Int>(VLAArchiveInput::HeaderSize)) {
	itsMemIO.clear();
	return False;
      }
      // Find out what the sequence numbers are.
      itsRecord.seek(0);
      itsRecord >> n;
      itsRecord >> m;
    }
    if (bytesSearched > maxBytesToSearch) {
      itsMemIO.clear();
      return False;
    }
  }
  // OK so we have found the beginning of the first physical record. Now read
  // the data into the logical record.
  uInt offset = 0;
  Int bytesToCopy = 
    VLAArchiveInput::MaxBlocksPerPhysicalRecord * VLAArchiveInput::BlockSize -
    VLAArchiveInput::HeaderSize;
  if (m == 1) { // If m=1 we may need to copy less than the maximum number of
    // blocks per physical record. To work this out we need to read and parse
    // the first block.
    itsRecord.seek(0);
    const Int bytesToRead =
      VLAArchiveInput::BlockSize - VLAArchiveInput::HeaderSize;
    uChar* recordPtr = itsMemIO.setBuffer(bytesToRead);
    const Int bytesRead = itsFile.read(bytesToRead, recordPtr, False);
    if (bytesRead < bytesToRead) {
      itsMemIO.clear();
      return False;
    }
    itsRecord.seek(0);
    Int logicalRecordSize;
    itsRecord >> logicalRecordSize;
    logicalRecordSize *= 2;
    bytesToCopy =
      ((logicalRecordSize - bytesToRead)/VLAArchiveInput::BlockSize + 1) * 
      VLAArchiveInput::BlockSize;
    offset = bytesToRead;
  }
  if (bytesToCopy > 0) {
    uChar* recordPtr = itsMemIO.setBuffer(bytesToCopy+offset);
    Int bytesRead = itsFile.read(bytesToCopy, recordPtr+offset, False);
    if (bytesRead < bytesToCopy) {
      itsMemIO.clear();
      return False;
    }
  }
  DebugAssert(n == 1, AipsError);
  DebugAssert(m > 0, AipsError);
  return True;
}

uInt VLADiskInput::bytesRead() {
  return itsFile.seek(0, ByteIO::Current);
}

uInt VLADiskInput::totalBytes() {
  return itsFile.length();
}
  
// Local Variables: 
// compile-command: "gmake VLADiskInput; cd test; gmake OPTLIB=1 tVLADiskInput"
// End: 
