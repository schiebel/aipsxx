//# tFileIO.cc: Test program for performance of file IO
//# Copyright (C) 1997,2000,2001,2003
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
//# $Id: tFileIO.cc,v 19.4 2004/11/30 17:50:16 ddebonis Exp $

#include <casa/IO/RegularFileIO.h>
#include <casa/IO/FiledesIO.h>
#include <casa/IO/LargeRegularFileIO.h>
#include <casa/IO/LargeFiledesIO.h>
#include <casa/OS/Timer.h>
#include <casa/BasicSL/String.h>
#include <casa/iostream.h>
#include <casa/sstream.h>


#include <casa/namespace.h>
int main (int argc, char** argv)
{
    int nr = 100;
    if (argc > 1) {
	istringstream istr(argv[1]);
	istr >> nr;
    }
    int leng = 1024;
    if (argc > 2) {
	istringstream istr(argv[2]);
	istr >> leng;
    }
    int size = 0;
    if (argc > 3) {
	istringstream istr(argv[3]);
	istr >> size;
    }
    int seek = 0;
    if (argc > 4) {
	istringstream istr(argv[4]);
	istr >> seek;
    }
    cout << "tFileIO  nrrec=" << nr << " reclength=" << leng
	 << " buffersize=" << size << " seek=" << seek << endl;
    char* buf = new char[leng];
    int i;
    for (i=0; i<leng; i++) {
	buf[i] = 0;
    }

    {
	RegularFileIO file1(RegularFile("tFileIO_tmp.dat1"),
			    ByteIO::New, size);
	Timer timer;
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file1.seek (i*leng, ByteIO::Begin);
	    }
	    file1.write (leng, buf);
	}
	timer.show ("RegularFileIO write");
	int fd = FiledesIO::create ("tFileIO_tmp.dat1");
	FiledesIO file2 (fd);
	timer.mark();
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file2.seek (i*leng, ByteIO::Begin);
	    }
	    file2.write (leng, buf);
	}
	timer.show ("FiledesIO     write");
	fsync(fd);
	timer.show ("FiledesIO     +sync");
    }
    {
	RegularFileIO file1(RegularFile("tFileIO_tmp.dat1"),
			    ByteIO::Old, size);
	Timer timer;
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file1.seek (i*leng, ByteIO::Begin);
	    }
	    file1.read (leng, buf);
	    if (buf[0] != 0) cout << "mismatch" << endl;
	}
	timer.show ("RegularFileIO read ");
	FiledesIO file2 (FiledesIO::open ("tFileIO_tmp.dat1"));
	timer.mark();
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file2.seek (i*leng, ByteIO::Begin);
	    }
	    file2.read (leng, buf);
	    if (buf[0] != 0) cout << "mismatch" << endl;
	}
	timer.show ("FiledesIO     read ");
    }
    {
	LargeRegularFileIO file1(RegularFile("tFileIO_tmp.dat2"),
				 ByteIO::New, size);
	Timer timer;
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file1.seek (i*leng, ByteIO::Begin);
	    }
	    file1.write (leng, buf);
	}
	timer.show ("LargeRegularFileIO write");
	int fd = LargeFiledesIO::create ("tFileIO_tmp.dat2");
	LargeFiledesIO file2 (fd);
	timer.mark();
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file2.seek (i*leng, ByteIO::Begin);
	    }
	    file2.write (leng, buf);
	}
	timer.show ("LargeFiledesIO     write");
	fsync(fd);
	timer.show ("LargeFiledesIO     +sync");
    }
    {
	LargeRegularFileIO file1(RegularFile("tFileIO_tmp.dat2"),
				 ByteIO::Old, size);
	Timer timer;
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file1.seek (i*leng, ByteIO::Begin);
	    }
	    file1.read (leng, buf);
	}
	timer.show ("LargeRegularFileIO read ");
	LargeFiledesIO file2 (LargeFiledesIO::open ("tFileIO_tmp.dat2"));
	timer.mark();
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file2.seek (i*leng, ByteIO::Begin);
	    }
	    file2.read (leng, buf);
	}
	timer.show ("LargeFiledesIO     read ");
    }

    {
	RegularFileIO file1(RegularFile("tFileIO_tmp.dat2"),
			    ByteIO::Old, size);
	Timer timer;
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file1.seek (i*leng, ByteIO::Begin);
	    }
	    file1.read (leng, buf);
	}
	timer.show ("RegularFileIO large ");
	FiledesIO file2 (FiledesIO::open ("tFileIO_tmp.dat2"));
	timer.mark();
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file2.seek (i*leng, ByteIO::Begin);
	    }
	    file2.read (leng, buf);
	}
	timer.show ("FiledesIO     large");
    }
    {
	LargeRegularFileIO file1(RegularFile("tFileIO_tmp.dat1"),
				 ByteIO::Old, size);
	Timer timer;
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file1.seek (i*leng, ByteIO::Begin);
	    }
	    file1.read (leng, buf);
	}
	timer.show ("LargeRegularFileIO small");
	LargeFiledesIO file2 (LargeFiledesIO::open ("tFileIO_tmp.dat1"));
	timer.mark();
	for (i=0; i<nr; i++) {
	    if (seek  &&  i%3 == 0) {
		file2.seek (i*leng, ByteIO::Begin);
	    }
	    file2.read (leng, buf);
	}
	timer.show ("LargeFiledesIO     small");
    }

    delete [] buf;
    return 0;                           // exit with success status
}
