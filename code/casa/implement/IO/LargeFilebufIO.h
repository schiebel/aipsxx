//# LargeFilebufIO.h: Class for buffered IO on a large file
//# Copyright (C) 1996,1997,1999,2001,2002
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
//# $Id: LargeFilebufIO.h,v 19.6 2004/11/30 17:50:16 ddebonis Exp $

#ifndef CASA_LARGEFILEBUFIO_H
#define CASA_LARGEFILEBUFIO_H


//# Includes
#include <casa/aips.h>
#include <casa/IO/ByteIO.h>
#include <casa/BasicSL/String.h>


namespace casa { //# NAMESPACE CASA - BEGIN

// <summary> Class for buffered IO on a large file.</summary>

// <use visibility=export>

// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="tByteIO" demos="">
// </reviewed>

// <prerequisite> 
//  <li> <linkto class=ByteIO>ByteIO</linkto>
// </prerequisite>

// <synopsis>
// This class is a specialization of class
// <linkto class=ByteIO>ByteIO</linkto>.
// This class is doing IO on a file in a buffered way to reduce the number
// of file accesses as much as possible.
// It is part of the entire IO framework. It can for
// instance be used to store data in canonical format in a file
// in an IO-efficient way
// <br>
// The buffer size is dynamic, so any time it can be set as needed.
// <p>
// It is also possible to construct a <src>LargeFilebufIO</src> object
// from a file descriptor (e.g. for a pipe or socket).
// The constructor will determine automatically if the file is
// readable, writable and seekable.
// </synopsis>

// <example>
// This example shows how LargeFilebufIO can be used with an fd.
// It uses the fd for a regular file, which could be done in an easier
// way using class <linkto class=RegularFileIO>RegularFileIO</linkto>.
// However, when using pipes or sockets, this would be the only way.
// <srcblock>
//    // Get a file descriptor for the file.
//    int fd = open ("file.name");
//    // Use that as the source of AipsIO (which will also use CanonicalIO).
//    LargeFilebufIO fio (fd);
//    AipsIO stream (&fio);
//    // Read the data.
//    Int vali;
//    Bool valb;
//    stream >> vali >> valb;
// </srcblock>
// </example>

// <motivation> 
// The stdio package was used, but it proved to be very slow on SOlaris.
// After a seek the buffer was refreshed, which increased the number
// of file accesses enormously.
// Also the interaction between reads and writes in stdio was poor.
// </motivation>


class LargeFilebufIO: public ByteIO
{
public: 
    // Default constructor.
    // A stream can be attached using the attach function.
    LargeFilebufIO();

    // Construct from the given file descriptor.
    // Note that the destructor and the detach function implicitly close
    // the file descriptor.
    explicit LargeFilebufIO (int fd, uInt bufferSize=16384);

    // Attach to the given file descriptor.
    // Note that the destructor and the detach function implicitly close
    // the file descriptor.
    void attach (int fd, uInt bufferSize=16384);

    // The destructor closes the file when it was owned and opened and not
    // closed yet.
    ~LargeFilebufIO();
    
    // Write the number of bytes.
    virtual void write (uInt size, const void* buf);

    // Read <src>size</src> bytes from the File. Returns the number of bytes
    // actually read. Will throw an exception (AipsError) if the requested
    // number of bytes could not be read unless throwException is set to
    // False. Will always throw an exception if the file is not readable or
    // the system call returns an undocumented value.
    virtual Int read (uInt size, void* buf, Bool throwException=True);    

    // Flush the current buffer.
    void flush();

    // Resync the file (i.e. empty the current buffer).
    void resync();
  
    // Get the length of the byte stream.
    virtual Int64 length();
       
    // Is the IO stream readable?
    virtual Bool isReadable() const;

    // Is the IO stream writable?
    virtual Bool isWritable() const;

    // Is the IO stream seekable?
    virtual Bool isSeekable() const;

    // Get the file name of the file attached.
    virtual String fileName() const;

    // Get the buffer size.
    uInt bufferSize() const;

protected:
    // Detach the FILE. Close it when needed.
    void detach (Bool closeFile=False);

    // Determine if the file descriptor is readable and/or writable.
    void fillRWFlags (int fd);

    // Determine if the file is seekable.
    void fillSeekable();

    // Reset the position pointer to the given value. It returns the
    // new position.
    virtual Int64 doSeek (Int64 offset, ByteIO::SeekOption);

    // Set a new buffer size.
    // If a buffer was already existing, flush and delete it.
    void setBuffer (uInt bufSize);

    // Write a buffer of given length into the file at given offset.
    void writeBuffer (Int64 offset, const char* buf, Int size);

    // Read a buffer of given length from the file at given offset.
    uInt readBuffer (Int64 offset, char* buf, uInt size,
		     Bool throwException);

    // Write a block into the stream at the current offset.
    // It is guaranteed that the block fits in a single buffer.
    void writeBlock (uInt size, const char* buf);

    // Read a block from the stream at the current offset.
    // It is guaranteed that the block fits in a single buffer.
    uInt readBlock (uInt size, char* buf, Bool throwException);

private:
    Bool        itsSeekable;
    Bool        itsReadable;
    Bool        itsWritable;
    int         itsFile;
    uInt        itsBufSize;          // the buffer size
    uInt        itsBufLen;           // the current buffer length used
    char*       itsBuffer;
    Int64       itsBufOffset;        // file offset of current buffer
    Int64       itsOffset;           // current file offset
    Int64       itsSeekOffset;       // offset last seeked
    Bool        itsDirty;            // data written into current buffer?

    // Copy constructor, should not be used.
    LargeFilebufIO (const LargeFilebufIO& that);

    // Assignment, should not be used.
    LargeFilebufIO& operator= (const LargeFilebufIO& that);
};


inline uInt LargeFilebufIO::bufferSize() const
{
    return itsBufSize;
}



} //# NAMESPACE CASA - END

#endif
