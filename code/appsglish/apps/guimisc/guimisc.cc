//# ClassFileName.cc:  this defines ClassName, which ...
//# Copyright (C) 1995,1996,1997,1999,2000,2001,2002
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
//# $Id: guimisc.cc,v 19.5 2004/11/30 17:50:07 ddebonis Exp $

//# Includes

#include <casa/iostream.h>
#include <casa/sstream.h>
#include <unistd.h>
#include <casa/stdio.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Glish.h>
#include <casa/OS/Path.h>
#include <casa/OS/File.h>
#include <casa/OS/RegularFile.h>
#include <casa/OS/Directory.h>
#include <casa/OS/DirectoryIterator.h>

#include <casa/namespace.h>
Bool defaultHandler(GlishSysEvent &event, void *);
Bool dirops(GlishSysEvent &event, void *);
Bool guiret(GlishSysEvent &event, void *);
Bool getDirsAndFiles( String  theDirectory,
                      String  theFilter,
		      Bool  dataOnly,
		      Bool  tablesOnly,
		      String fileAccess,
		      String &cwd,
		      Vector<String>& dirDirs,
		      Vector<String>& dirFiles,
		      Vector<String>& fileInfo);

int main(int argc, char **argv)
{
    GlishSysEventSource glishStream (argc, argv);
    glishStream.setDefault (defaultHandler);
    glishStream.addTarget  (dirops, String("^dirops$"));
    glishStream.addTarget  (guiret, String("^guiret$"));
    glishStream.loop ();

    return 0;
}

Bool guiret (GlishSysEvent &event, void *)
{
    GlishRecord glishRecord(event.val());
    GlishSysEventSource *glishBus =  event.glishSource ();
    if (glishRecord.exists(String("gui_returns"))) {
	GlishArray guiOps(glishRecord.get(String("gui_returns")));

	String gui_returns;
	guiOps.get(gui_returns);
	GlishRecord r;
	r.add(String("guiReturns"), gui_returns);
	glishBus->postEvent(String("guiret_result"), r);
     
	// cerr << __LINE__ << endl;
    }
    return True;
}

Bool dirops (GlishSysEvent &event, void *)
{
    GlishRecord glishRecord(event.val());
    GlishSysEventSource *glishBus =  event.glishSource ();
    if(glishRecord.exists(String("directory"))){
	GlishArray dirOps(glishRecord.get(String("directory")));

	String directory;
	dirOps.get(directory);

	String filterOnly("");
	if(glishRecord.exists(String("filefilter"))){
	    String filter;
	    GlishArray filters(glishRecord.get(String("filefilter")));
	    filters.get(filter);
	    char *buffer = strrchr(const_cast<char *>(filter.chars()), '/');
	    if(!buffer){
		filterOnly = filter;
	    } else {
		filterOnly = String(buffer+1);
	    }
            //
            // Ah yes now the filter == the directory so let's see if
            // the filter is the directory, then if it isn't strip off
            // the filtering strings and use that as the directory
            //
            //  Seems the Motif file chooser doesn't do it this way
            //  but it makes more sense to me
            //
	    if(filter == directory){
		if (!File(directory).isDirectory()) {
		    // It ain't a directory so assumes its a directory
		    // with the filter chars after it 
		    directory = Path(Path(directory).dirName()).absoluteName();
		} else {
                   filterOnly = String("*");
                }
	    }
	}

      Bool dataFlag(False);
      if(glishRecord.exists(String("dataonly"))){
         GlishArray isData(glishRecord.get(String("dataonly")));
         isData.get(dataFlag);
      }
//
      Bool tablesFlag(False);
      if(glishRecord.exists(String("tablesonly"))){
         GlishArray isData(glishRecord.get(String("tablesonly")));
         isData.get(tablesFlag);
      }

      // datafilter is currently not used
      String dataFilter("");
      if (glishRecord.exists(String("datafilter"))) {
	  GlishArray isData(glishRecord.get(String("datafilter")));
	  isData.get(dataFilter);
      }
//
      String fileAccess("r");
      if (glishRecord.exists(String("access"))) {
	  GlishArray isData(glishRecord.get(String("access")));
	  isData.get(fileAccess);
      }
//
      Vector<String> dirDirs;
      Vector<String> dirFiles;
      Vector<String> fileInfo;
      String cwd;
      GlishRecord r;
      if(!getDirsAndFiles(directory, filterOnly, dataFlag, tablesFlag, 
			  fileAccess, cwd, dirDirs, dirFiles, fileInfo)){
         r.add(String("Dirs"), GlishArray(dirDirs));
         r.add(String("Files"), GlishArray(dirFiles));
         r.add(String("FileInfo"), GlishArray(fileInfo));
         r.add(String("Directory"), String(cwd));
         r.add(String("Filter"), filterOnly);
      } else {
         r.add(String("Error"), String("Unable to open directory ")+directory);
      }
      glishBus->postEvent(String("dirops_result"), r);
  } else {
    glishBus->postEvent (String("dirops_result"),
                         String("dirops error: must have directory"));
    return True;
  }

  return True;

}



Bool defaultHandler (GlishSysEvent &event, void *)
{
  GlishSysEventSource *src =  event.glishSource ();
  src->postEvent (String("default_result"), event.type ());
  return True;
}  
String getFileInfo(File &file, const String &fileType)
{
    ostringstream ost;
    ost << fileType << " ";
    if (fileType == String("Table")) {
	Directory tab(file);
	DirectoryIterator tabIter(tab);
	uInt dirSize(0);
	while (!tabIter.pastEnd()) {
	    if (tabIter.file().exists() && tabIter.file().isRegular()) {
		dirSize += RegularFile(tabIter.file()).size();
	    }
	    tabIter++;
	}
	ost << dirSize;
   } else {
       ost << RegularFile(file).size();
   }
   ost << " " << file.modifyTimeString();
   return String(ost.str());
}

Bool getDirsAndFiles( String  theDirectory,
                      String  theFilter,
		      Bool  showFiles,
		      Bool  showTables,
		      String fileAccess,
		      String& cwd,
		      Vector<String>& dirDirs,
		      Vector<String>& dirFiles,
		      Vector<String>& dirFileInfo)
{  
    Bool r_status(False);
    Bool readable, writable, executable;
    readable=writable=executable=False;
    // decode the fileAccess
    if (fileAccess.contains("r")) readable=True;
    if (fileAccess.contains("w")) writable=True;
    if (fileAccess.contains("x")) executable=True;

    File where(theDirectory);
    //    Convert the shell meta characters into a regular expression chars
    Regex regexFilter(Regex::fromPattern (theFilter));

    if (where.isDirectory()) {
	chdir(where.path().absoluteName().chars());
	// thedir is set to the current working directory
	Directory thedir;
	cwd = thedir.path().absoluteName();

	// make room for . and .. entries in directories
	dirDirs.resize(thedir.nEntries()+2);
	dirFiles.resize(thedir.nEntries());
	dirFileInfo.resize(thedir.nEntries());
	uInt fileCount(0),dirCount(2);
	// add in . and .. to directories, always present
	dirDirs(0) = ".";
	dirDirs(1) = "..";

	DirectoryIterator dirIter(thedir);
	while (!dirIter.pastEnd()) {
	    File dirEntry(dirIter.file());
	    Bool addFile, addDir, addTable;
	    addFile = addDir = addTable = False;
	    if (dirEntry.exists()) {
		if (dirEntry.isDirectory() && dirEntry.isReadable()) {
		    if(showFiles || showTables){
			Path possibleTable(dirEntry.path());
			possibleTable.append("/table.dat");
			if (File(possibleTable).exists()) {
			    if (showTables) addTable = True;
			} else {
			    addDir = True;
			}
		    } else {
			addDir = True;
		    }
		} else if (dirEntry.isRegular() && (!showTables || showFiles)) {
		    addFile = True;
		}
		if (addDir) {
		    dirDirs(dirCount++) = dirEntry.path().baseName();
		}
		if (addFile || addTable) {
		    // ignore this if the name doesn't match
		    if (dirEntry.path().baseName().matches(regexFilter)) {
			// check the access mode here
			// if none of these, well, then nothing will be returned
			Bool accessOK = (readable || writable || executable);
			if (readable) accessOK = (accessOK && dirEntry.isReadable());
			if (writable) accessOK = (accessOK && dirEntry.isWritable());
			if (executable) accessOK = (accessOK && dirEntry.isExecutable());
			if (accessOK) {
			    dirFiles(fileCount) = dirEntry.path().baseName();
			    if (addTable) {
				dirFileInfo(fileCount) = getFileInfo(dirEntry, "Table");
			    } else {
				dirFileInfo(fileCount) = getFileInfo(dirEntry, "File");
			    }
			    fileCount++;
			}
		    }
		}
	    }
	    dirIter++;
	}
	// resize these to get them to their actual length
	dirDirs.resize(dirCount,True);
	dirFiles.resize(fileCount,True);
	dirFileInfo.resize(fileCount,True);
    } else {
	r_status = True;
    }
    return r_status; 
}


