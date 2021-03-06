//# DirectoryIterator.cc: Class to define a DirectoryIterator
//# Copyright (C) 1996,2001,2002
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
//# $Id: DirectoryIterator.cc,v 19.3 2004/11/30 17:50:17 ddebonis Exp $


#include <casa/OS/DirectoryIterator.h>
#include <casa/OS/Path.h>
#include <casa/Exceptions/Error.h>

#include <errno.h>                // needed for errno
#include <casa/string.h>               // needed for strerror


namespace casa { //# NAMESPACE CASA - BEGIN

DirectoryIterator::DirectoryIterator()
: itsDirectoryDescriptor (0),
  itsDirectoryEntry      (0),
  itsEnd                 (False),
  itsDirectory           (),
  itsExpression          (".*")
{
    init();
}

DirectoryIterator::DirectoryIterator (const Directory& dir)
: itsDirectoryDescriptor (0),
  itsDirectoryEntry      (0),
  itsEnd                 (False),
  itsDirectory           (dir),
  itsExpression          (".*")
{
    init();
}

DirectoryIterator::DirectoryIterator (const Directory& dir,
				      const Regex& regExpression)
: itsDirectoryDescriptor (0),
  itsDirectoryEntry      (0),
  itsEnd                 (False),
  itsDirectory           (dir),
  itsExpression          (regExpression)
{
    init();
}

DirectoryIterator::DirectoryIterator (const DirectoryIterator& that)
: itsDirectoryDescriptor (0),
  itsDirectoryEntry      (0),
  itsEnd                 (False),
  itsDirectory           (that.itsDirectory),
  itsExpression          (that.itsExpression)
{
    init();
}

DirectoryIterator::~DirectoryIterator()
{
    // Free all the memory used by DirectoryIterator.
    closedir (itsDirectoryDescriptor);
}

DirectoryIterator& DirectoryIterator::operator= (const DirectoryIterator& that)
{
    if (this != &that) {
	closedir (itsDirectoryDescriptor);
	itsDirectoryDescriptor = 0;
	itsDirectoryEntry      = 0;
	itsEnd                 = False;
	itsDirectory           = that.itsDirectory;
	itsExpression          = that.itsExpression;
	init();
    }
    return *this;
}


void DirectoryIterator::init()
{
    // Set the private directory on the current working directory
    // Open the directory, if this is not possible throw an exception
    itsDirectoryDescriptor = opendir(itsDirectory.path().expandedName().chars());
    if (itsDirectoryDescriptor == 0){
	throw (AipsError ("DirectoryIterator: error on directory " +
			  itsDirectory.path().expandedName() +
			  ": " + strerror(errno)));
    }
    // Set itsDirectoryEntry on the first entry.
    operator++();
}

void DirectoryIterator::operator++()
{
    if (itsEnd) {
	throw (AipsError ("DirectoryIterator++ past end on " +
			  itsDirectory.path().expandedName()));
    }
    // Read the entries until a match with the expression is found.
    // Skip . and ..
    String name;
    do {
	itsDirectoryEntry = readdir (itsDirectoryDescriptor);
	if (itsDirectoryEntry == 0){
	    itsEnd = True;
	    break;
	}
        name = itsDirectoryEntry->d_name;
    }
    while (name == "."  ||  name == ".."
       ||  name.matches (itsExpression) == 0);
}

void DirectoryIterator::operator++(int)
{
    operator++();
}


String DirectoryIterator::name() const
{
    if (itsEnd) {
	throw (AipsError ("DirectoryIterator::name past end on " +
			  itsDirectory.path().expandedName()));
    }
    return itsDirectoryEntry->d_name;
}

File DirectoryIterator::file() const
{
    return itsDirectory.path().expandedName() + "/" + name();
}

void DirectoryIterator::reset()
{
    // Reset the directory to the beginning of the stream
    // and get the first entry.
    rewinddir (itsDirectoryDescriptor);
    itsEnd = False;
    operator++();
}

Bool DirectoryIterator::pastEnd() const
{
    return  (itsEnd == True);
}

} //# NAMESPACE CASA - END

