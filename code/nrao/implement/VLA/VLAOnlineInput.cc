//# VLAOnlineInput.cc: This class reads VLA archive files from a Disk
//# Copyright (C) 2001
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
//# $Id: VLAOnlineInput.cc,v 19.1 2004/08/25 05:49:30 gvandiep Exp $

#include <nrao/VLA/VLAOnlineInput.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/MemoryIO.h>
#include <casa/IO/ByteIO.h>

const String host = "146.88.1.11";
const uShort port =  6104;
const String sendMesg = "send.data.record";

VLAOnlineInput::VLAOnlineInput() 
  :VLAArchiveInput(),
   itsPort(host, port)
{
}

VLAOnlineInput::~VLAOnlineInput() {
  // The StreamIO destructor closes the port.
}

Bool VLAOnlineInput::read() {
  itsMemIO.clear();
  // tell the visserver to send a record
  itsPort.write(sendMesg.length(), sendMesg.chars());
  // Get the first 4 bytes to work out how big the logical record is.
  Int logicalRecordSize = 0;
  {
    uChar* recordPtr = itsMemIO.setBuffer(4);
    itsPort.read(4, recordPtr, False);
    // We have the first physical record in Memory. Now decode how long this
    // logical record is.
    itsRecord.seek(0);

    itsRecord >> logicalRecordSize;
    logicalRecordSize *= 2;
  }
  uChar* recordPtr = itsMemIO.setBuffer(logicalRecordSize);
  AlwaysAssert(itsPort.read(logicalRecordSize-4, recordPtr+4, False) ==
	       logicalRecordSize-4, AipsError);

  itsMemIO.setUsed(logicalRecordSize);
  itsRecord.seek(0);
  return True;
}

// Local Variables: 
// compile-command: "gmake VLADiskInput; cd test; gmake OPTLIB=1 tVLADiskInput"
// End: 
