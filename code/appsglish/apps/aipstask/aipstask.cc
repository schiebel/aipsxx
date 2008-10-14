//# ClassFileName.cc:  this defines ClassName, which ...
//# Copyright (C) 1997,1998,1999,2000,2001,2002
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
//# $Id: aipstask.cc,v 19.5 2004/11/30 17:50:06 ddebonis Exp $

//# Includes

/*
OK so how does this work?

We need the TD description, which is stored in vars record;
We need then to extract from the TS file the TD data and put it in a
data record

The glish script then does a setinput of the gui.

When go is pressed we need both the vars and data records, we use vars to
format the data record and put it in a TD file, then into a TS file.
*/

#include <casa/fstream.h>
#include <casa/sstream.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish.h>

#include <casa/namespace.h>
Bool readTSFile (GlishSysEvent &event, void *);
Bool writeTSFile (GlishSysEvent &event, void *);
Bool writeTDFile (GlishSysEvent &event, void *);
Bool aipsEHexID (GlishSysEvent &event, void *);
Bool defaultHandler (GlishSysEvent &event, void *);
Char *getTDRecord(const String&, const String&);
Bool putTDRecord(const String &, const String &, const Char *);

int main(Int argc, Char **argv)
{
  try {
     GlishSysEventSource glishStream(argc, argv);
     glishStream.setDefault(defaultHandler);
     glishStream.addTarget(readTSFile, "^read_ts_file$");
     glishStream.addTarget(writeTSFile, "^write_ts_file$");
     glishStream.addTarget(writeTDFile, "^write_td_file$");
     glishStream.addTarget(aipsEHexID, "^get_ehex_id$");
     glishStream.loop();
  } catch (AipsError x) {
    cerr << "----------------------- exception! -------------------" << endl;
    cerr << x.getMesg () << endl;
    cerr << "Exception Caught" << endl;

  } 
  return 0;

}

//#-------------------

Bool defaultHandler (GlishSysEvent &event, void *)
{
  GlishSysEventSource *src =  event.glishSource ();
  src->postEvent ("default_result", event.type ());
  return True;
}

//----------------------------------------------------------------------------

   // readTSFile -- given the TS file looks for the task in the TS file and
   // if it finds it, assigns the data from the last run to the data record

Bool readTSFile (GlishSysEvent &event, void *)
{
 
  GlishSysEventSource *glishBus =  event.glishSource ();
  GlishRecord val(event.val());
    // does the event contain a record?
  if (val.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("read_ts_file", 
                         "read_ts_file error: argument not a record");
    return True;
    }
  
  GlishArray tsFileName(val.get("file"));
 
  if (tsFileName.elementType() != GlishArray::STRING) {
    glishBus->postEvent ("read_ts_file", 
                         "read_ts_file error: argument missing file=");
    return True;
    }

  String tsFile;
  tsFileName.get(tsFile);

     // Contains a description of the datamembers not the data itself
  GlishRecord dataMembers(val.get("datamembers"));

//
  GlishArray task(val.get("task"));
  String taskName;
  task.get(taskName);
//
     // Fetch the buffer containing the binary data from the TS file

  Char *buffer = getTDRecord(tsFile, taskName);
  Int argSize(0);
  Int stringLen(0);
  if(buffer){
        // OK got it, now loop though the variables and create the data
        // record.
     GlishArray varNames(val.get("datanorder"));
     Vector<String> argNames(varNames.nelements());
     varNames.get(argNames);
     GlishRecord data;
     uInt tdOffset(40);
     for(uInt i=0;i<argNames.nelements();i++){
        GlishRecord dArg(dataMembers.get(argNames(i)));
        GlishArray aType(dArg.get("type"));
        String argType;
        aType.get(argType);
        if(argType == String("float")){
           argSize = 4;
        }

        if(dArg.exists("hint")){
           GlishArray aHint(dArg.get("hint"));
           if(argType == String("string")){
              aHint.get(argSize);
              stringLen = argSize;   // Pad to four byte words
              argSize += (argSize%4) ? (4-argSize%4) : argSize%4;
           }
        }
    
        GlishArray aArray(dArg.get("array"));
        Vector<Int> arrayLen;
        if(aArray.elementType() == GlishArray::INT){
           arrayLen.resize(aArray.nelements());;
           aArray.get(arrayLen);
           for(uInt j=0;j<arrayLen.nelements();j++){
              argSize *= arrayLen(j);
           }
        } else {
           arrayLen.resize(1);;
           arrayLen(0) = 1;
        }

        if(argType == String("string")){
           Vector<String>stringVals(arrayLen(0));
           for(Int j=0;j<arrayLen(0);j++){
              stringVals(j) = String(buffer+tdOffset+argSize*j, stringLen);
           }
              // Add string data to the record
           data.add(argNames(i), GlishArray(stringVals));
        } else {
           Int memCount(1);
           for(uInt j=0;j<arrayLen.nelements();j++)
              memCount *= arrayLen(j);
           Vector<Float>floatVals(memCount);
           Int el(0);
              // Add floating point data to the record
           for(uInt k=0;k<arrayLen.nelements();k++){
              for(Int j=0;j<arrayLen(k);j++){
                 memcpy(&floatVals(el), buffer+tdOffset+4*el, 4);
                 el++;
              }
           }
           data.add(argNames(i), GlishArray(floatVals));
        }
        tdOffset += argSize;  // set the pointer to the next data member
     }
       // All done post the data record and split.
     glishBus->postEvent("read_ts_file_result", data);
     delete buffer;
  } else {

        // Nothing in the TS File so send back an F to the requestor telling
        // them to use the standard defaults.

     GlishArray data(False);
     glishBus->postEvent("read_ts_file_result", data);
  }
  return True;
}

//----------------------------------------------------------------------------

   // This function replaces the existing binary data in the AIPS TS file with
   // that supplied by the user in the "data" record

Bool writeTSFile (GlishSysEvent &event, void *)
{
 
  GlishSysEventSource *glishBus =  event.glishSource ();
  GlishRecord val(event.val());
    // does the event contain a record?
  if (val.type () != GlishValue::RECORD)  {
    glishBus->postEvent ("write_ts_file", 
                         "write_ts_file error: argument not a record");
    return True;
    }
  
  GlishArray tsFileName(val.get("file"));
 
  if (tsFileName.elementType() != GlishArray::STRING) {
    glishBus->postEvent ("write_ts_file", 
                         "write_ts_file error: argument missing file=");
    return True;
    }

  String tsFile;
  tsFileName.get(tsFile);


     // Description the data members and not the data itself.
  GlishRecord dataMembers(val.get("datamembers"));

//
  GlishArray task(val.get("task"));
  String taskName;
  task.get(taskName);
//
     //Get the existing data buffer
  Char *buffer = getTDRecord(tsFile, taskName);
  if(!buffer)
      buffer = new Char[3*1024];

  Int argSize(0);
  Int stringLen(0);
  GlishArray varNames(val.get("datanorder"));
  Vector<String> argNames(varNames.nelements());
  varNames.get(argNames);
  GlishRecord data(val.get("data"));
  uInt tdOffset(40);
     // For each data member replace the data with the "new data"
  for(uInt i=0;i<argNames.nelements();i++){
     GlishRecord dArg(dataMembers.get(argNames(i)));
     GlishArray aType(dArg.get("type"));
    GlishArray aData(data.get(argNames(i)));
     String argType;
     aType.get(argType);
     if(argType == String("float")){
        argSize = 4;
     }

     if(dArg.exists("hint")){
        GlishArray aHint(dArg.get("hint"));
        if(argType == String("string")){
           aHint.get(argSize);
           stringLen = argSize;   // Pad to four byte words
           argSize += (argSize%4) ? (4-argSize%4) : argSize%4;
        }
     }
    
     GlishArray aArray(dArg.get("array"));
     Vector<Int> arrayLen;
     if(aArray.elementType() == GlishArray::INT){
        arrayLen.resize(aArray.nelements());;
        aArray.get(arrayLen);
        for(uInt j=0;j<arrayLen.nelements();j++){
           argSize *= arrayLen(j);
        }
     } else {
        arrayLen.resize(1);;
        arrayLen(0) = 1;
     }
     if(argType == String("string")){
        Vector<String>stringVals(arrayLen(0));
        aData.get(stringVals);
        for(Int j=0;j<arrayLen(0);j++){
           if(j < static_cast<Int>(stringVals.nelements()))
              memcpy(buffer+tdOffset+argSize*j,
		     stringVals(j).data(), stringLen);
        }
        data.add(argNames(i), GlishArray(stringVals));
     } else {
        Int memCount(1);
        for(uInt j=0;j<arrayLen.nelements();j++)
           memCount *= arrayLen(j);

        Vector<Float>floatVals(memCount);
        aData.get(floatVals);
        uInt el(0);
        for(uInt k=0;k<arrayLen.nelements();k++){
           for(Int j=0;j<arrayLen(k);j++){
              if(el < floatVals.nelements())
                 memcpy(buffer+tdOffset+4*el, &floatVals(el), 4);
              el++;
           }
        }
     }
     tdOffset += argSize;    // Update the current data member pointer
  }
  Bool rStat(putTDRecord(tsFile, taskName, buffer));  //update the TS file
  // Bool rStat(True);
  delete buffer;

  
  glishBus->postEvent("write_ts_file_result", GlishArray(rStat));
  return rStat;
}

//----------------------------------------------------------------------------
Bool writeTDFile (GlishSysEvent &event, void *)
{
 
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();
  glishBus->postEvent("write_td_file_result", GlishArray(True));

  return True;
}

//----------------------------------------------------------------------------

  // This function takes the decimal AIPSID and turns it into the extended hex
  // aips ID (base 36)

Bool aipsEHexID (GlishSysEvent &event, void *)
{
 
  GlishValue glishValue = event.val ();
  GlishSysEventSource *glishBus =  event.glishSource ();
    // does the event contain a record?
  if (glishValue.type () == GlishValue::RECORD)  {
    glishBus->postEvent ("get_ehex_id", 
                         "get_ehex_id error: argument not an array");
    return True;
    }
 
  GlishArray glishArray = glishValue;
  if (glishArray.elementType() != GlishArray::INT) {
    glishBus->postEvent ("get_ehex_id", 
                         "get_ehex_id error: argument is not an integer");
    return True;
    }
  
     //Fetch the aips id 

  Int aipsID;
  glishArray.get(aipsID);

     // The following looks like what it does, first identify the characters
     // in the extend hex representation, then find each "digit" in the AIPS
     // extended character set, lump them all together and presto!

  String ehexchars("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ");
  Int firstChar(aipsID/(36*36));
  Int secndChar((aipsID-1296*firstChar)/36);
  int thirdChar(aipsID%36);
  ostringstream oss;
  oss << ehexchars[firstChar] << ehexchars[secndChar] << ehexchars[thirdChar];
 
  GlishArray data(oss.str());
  glishBus->postEvent("get_ehex_id_result", data);
  return True;
}
   // This function fetches the TDRecord from a TSfile.  The tsFile is assumed
   // to exist (it's checked in the glish code).  

Char *getTDRecord(const String &tsFile, const String &task){
   Char *buffer(0);

       // Open the file and see if it's any good

   ifstream ts(tsFile.chars());
   if(ts.good()){
      const Int recsize(6*1024);   //First 6k contains logical records
      Char logRec[recsize];
      ts.read(logRec, recsize);    //Read the logical records and figure out
      Int nTasks;                  //How many tasks are in the TS file
      memcpy(&nTasks, logRec+4, 4);

         // Loop through the task count till we find the one we want

      String taskName;
      const uInt taskNameLen = 8;
      Char * taskNameBuff = new Char[taskNameLen+1];
      for (uInt c = 0; c < taskNameLen+1; c++) {
	*(taskNameBuff+c) = '\0';
      }
      for(Int lr=0;lr<nTasks;lr++){ 
	{
	  istringstream istr;
          istr.read(logRec+20*(lr+1), taskNameLen);
	  istr >> taskNameBuff;
	}
	taskName = taskNameBuff;
        if(taskName == task){
           ts.ignore(lr*3*1024);       // Fast forward to the data area
           buffer = new Char[3*1024];
           ts.read(buffer, 3*1024);    // Read the data
           ts.close();                 // Close the ifstream
           break;
        }
      }
   }
   return buffer;   //If buffer == 0 then task name not found in TS file.
}

//
//  OK well we don't handle time stamps and version codes, but that can be
//  added later.
//

Bool putTDRecord(const String &tsFile, const String &task, const Char *buffer){
   Bool rstat(False);

       // Open the file and see if it's any good

   fstream ts(tsFile.chars(), ios::in | ios::out);
   Int nTasks;                  //How many tasks are in the TS file
   Int blocksNFile;
   if(ts.good()){
      const Int recsize(6*1024);   //First 6k contains logical records
      Char logRec[recsize];
      ts.read(logRec, recsize);    //Read the logical records and figure out
      memcpy(&nTasks, logRec+4, 4);
      memcpy(&blocksNFile, logRec, 4);

         // Loop through the task count till we find the one we want

      String taskName;
      const uInt taskNameLen = 8;
      Char * taskNameBuff = new Char[taskNameLen+1];
      for (uInt c = 0; c < taskNameLen+1; c++) {
	*(taskNameBuff+c) = '\0';
      }
      for(Int lr=0;lr<nTasks;lr++){ 
	{
	  istringstream istr;
          istr.read(logRec+20*(lr+1), taskNameLen);
	  istr >> taskNameBuff;
	}
	taskName = taskNameBuff;
        if(taskName == task){
           ts.ignore(lr*3*1024);       // Fast forward to the data area
           ts.write(buffer, 3*1024);    // Read the data
           ts.close();                 // Close the ifstream
           rstat = True;
           break;
        }
      }
         // Task not saved so write it out
      if(!rstat){
         nTasks += 1;
         if(blocksNFile < (3*nTasks+6)){
            blocksNFile = 3*nTasks+6;
            ts.seekp(0, ios::beg);
            ts.write((Char *)&blocksNFile, 4);
         }
         ts.seekp(4, ios::beg);
         ts.write((Char *)&nTasks, 4);
         ts.seekp(20*nTasks, ios::beg);
         ts.write(task.chars(), 8);
         ts.seekp((3*(nTasks-1)+6)*1024, ios::beg);
         ts.write(buffer, 3*1024);
         ts.close();
         rstat = True;
      }
   }
   return rstat;   //If buffer == 0 then task name not found in TS file.
}
