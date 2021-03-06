//# RegularFile.cc: Manipulate and get information about regular files
//# Copyright (C) 1993,1994,1995,1996,1997,2001,2002,2003
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
//# $Id: RegularFile.cc,v 19.3 2004/11/30 17:50:17 ddebonis Exp $


#include <casa/Exceptions.h>
#include <casa/OS/RegularFile.h>
#include <casa/OS/SymLink.h>

#include <fcntl.h>                // needed for creat
#include <unistd.h>               // needed for unlink, etc.
#include <errno.h>                // needed for errno
#include <casa/string.h>               // needed for strerror
#include <casa/stdlib.h>               // needed for system


namespace casa { //# NAMESPACE CASA - BEGIN

RegularFile::RegularFile ()
: File()
{}

RegularFile::RegularFile (const Path& path)
: File(path)
{
    checkPath();
}

RegularFile::RegularFile (const String& path)
: File(path)
{
    checkPath();
}

RegularFile::RegularFile (const File& file)
: File(file)
{
    checkPath();
}
    
RegularFile::RegularFile (const RegularFile& that)
: File    (that),
  itsFile (that.itsFile)
{}

RegularFile::~RegularFile()
{}

RegularFile& RegularFile::operator= (const RegularFile& that)
{
    if (this != &that) {
	File::operator= (that);
	itsFile = that.itsFile;
    }
    return *this;
}

void RegularFile::checkPath()
{
    itsFile = *this;
    // If exists, check if it is a regular file.
    // If the file is a symlink, resolve the entire symlink chain.
    // Otherwise check if it can be created.
    if (exists()) {
	if (isSymLink()) {
	    itsFile = SymLink(*this).followSymLink();
	    // Error if no regular file and exists or cannot be created.
	    if (!itsFile.isRegular()) {
		if (itsFile.exists() || !itsFile.canCreate()) {
		    throw (AipsError ("RegularFile: " + path().expandedName()
				      + " is a symbolic link not"
				      " pointing to a valid regular file"));
		}
	    }
	} else if (!isRegular()) {
	    throw (AipsError ("RegularFile: " + path().expandedName() +
			      " exists, but is no regular file"));
	}
    } else {
	if (!canCreate()) {
	    throw (AipsError ("RegularFile: " + path().expandedName() +
			      " does not exist and cannot be created"));
	}
    }
}

void RegularFile::create (Bool overwrite) 
{
    // If overwrite is False the file will not be overwritten.
    if (exists()) {
	if (!itsFile.isRegular (False)) {
	    throw (AipsError ("RegularFile::create: " +
			      itsFile.path().expandedName() +
			      " already exists as a non-regular file"));
	}
	if (!overwrite) {
	    throw (AipsError ("RegularFile::create: " +
			      itsFile.path().expandedName() +
			      " already exists"));
	}
    }
    int fd = ::creat (itsFile.path().expandedName().chars(), 0644);
    if (fd < 0) {
	throw (AipsError ("RegularFile::create error on " +
			  itsFile.path().expandedName() +
			  ": " + strerror(errno)));
    }
    ::close (fd);
}

void RegularFile::remove() 
{
    if (isSymLink()) {
	removeSymLinks();
    }    
    unlink (itsFile.path().expandedName().chars());
}

void RegularFile::copy (const Path& target, Bool overwrite,
			Bool setUserWritePermission) const
{
    Path targetName(target);
    checkTarget (targetName, overwrite);
    // This function uses the system function cp.	    
    String call("cp ");
    call += itsFile.path().expandedName() + " " + targetName.expandedName();
    system (call.chars());
    if (setUserWritePermission) {
	File result(targetName.expandedName());
	if (! result.isWritable()) {
	    result.setPermissions (result.readPermissions() | 0200);
	}
    }
}

void RegularFile::move (const Path& target, Bool overwrite)
{
    Path targetName(target);
    checkTarget (targetName, overwrite);
    // This function uses the system function mv.	    
    String call("mv ");
    call += itsFile.path().expandedName() + " " + targetName.expandedName();
    system (call.chars());
}

Int64 RegularFile::size() const
{
  return itsFile.size();
}

} //# NAMESPACE CASA - END

