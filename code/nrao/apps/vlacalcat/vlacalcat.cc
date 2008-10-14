//# vlacalcat.cc: This program produces calibrator tables from csource.mas
//# Copyright (C) 2000,2001,2002
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
//# $Id: vlacalcat.cc,v 19.4 2004/11/30 17:50:41 ddebonis Exp $
#include <casa/iostream.h>
#include <casa/fstream.h>
#include <casa/sstream.h>
#include <casa/Containers/Block.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/StManAipsIO.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/ArrColDesc.h>
#include <casa/Inputs/Input.h>
#include "vlacalcat.h"
#include <string.h>

#include <casa/namespace.h>

/*
   A quick and dirty way to read the existing observe calibrator table and
   produce output for observe
*/

String removeChars(const String &theString, const String &removeTheseChars)
{  String theStrippedString;
   String dummyString;
   for(uInt i=0;i<theString.length();i++){
      dummyString = theString[i];
      if(!removeTheseChars.contains(dummyString))
         theStrippedString += theString[i];
   }
   return theStrippedString; }       // Return the stripped string, leave the original untouched.

class Source {
   private :
    String name;
    String equinox;
    String calCode;
    String ra;
    String dec;
    String alias;
   public :
      Source(){}
      void       readTable(istream &);
      String&    getName(){return name;}
      String&    getAlias(){return alias;}
      void       writeObsCal(ostream &);
      void       writeAips2Table(Table &);
      Source &   operator =(const Source &a){ name = a.name;
                                              equinox = a.equinox;
                                              calCode = a.calCode;
                                              ra = a.ra;
                                              dec = a.dec;
                                              alias = a.alias;
                                              return *this; }
};

void Source::readTable(istream &is)
{ alias = String("");
  Char buff[20];
  is >> name >> equinox >> calCode >> ra >> dec;
  is.get(buff, 8);
  is >> alias;
  return;
}
void Source::writeObsCal(ostream &os)
{ ra = removeChars(ra, "hms");
  dec = removeChars(dec, "d'\"");
  if(equinox == "J2000")
     os << "NEWSOURCE" << endl << "POS2000," << name << ",,";
  else
     os << "POSEPOCH," << name << ",1950.0,";
  os << calCode << "," << ra << "," << dec << endl;
  return;
}

void Source::writeAips2Table(Table &the_table)
{  ScalarColumn<String> scName(the_table, "Name");
   uInt howMany = scName.nrow();
   howMany -= 1;

   ScalarColumn<String> scCalCode(the_table, "CalCode");
   scCalCode.put(howMany, calCode);

   if(equinox == "J2000"){
      ScalarColumn<String> scRA(the_table, "RA_J2000");
      ScalarColumn<String> scDec(the_table, "Dec_J2000");
      ScalarColumn<String> scAlias(the_table, "Alias");
      scName.put(howMany, name);
      scAlias.put(howMany, alias);
      scRA.put(howMany, ra);
      scDec.put(howMany, dec);
   } else {
      ScalarColumn<String> scRA(the_table, "RA_B1950");
      ScalarColumn<String> scDec(the_table, "Dec_B1950");
      scRA.put(howMany, ra);
      scDec.put(howMany, dec);
   }
   return; 
}

ostream& operator<<(ostream &ost, const BandInfo &a)
{
   ost << a.j2000Name << " "
       << a.b1950Name << " "
       << a.receiverName << " "
       << a.band << " "
       << a.flux << " "
       << a.aCal << " "
       << a.bCal << " "
       << a.cCal << " "
       << a.dCal << " "
       << a.uvMin << " "
       << a.uvMax;
   return ost;
}

void BandInfo::readTable(char *buffer)
{ istringstream iss(buffer);
  iss >> receiverName >> band >> aCal >> bCal >> cCal >> dCal >> flux;

  uvMin = String("");
  uvMax = String("");
  int lengthOfBuffer(strlen(buffer));
  if(lengthOfBuffer > 30){
    istringstream iss;
    iss.read(buffer+30, 13);
    iss  >> uvMin;       // uvMin maybe in this part of the record.
  } 
  if(lengthOfBuffer > 45){
    istringstream iss;
    iss.read(buffer+45, lengthOfBuffer - 45);
    iss >> uvMax;  // uvMax may occur after column 45
  }
   
  // Need to fret about UV-limits
  return; }

void BandInfo::writeObsCal(ostream &os)
{
   os << "CAL" << band << ", " << flux << " ," << aCal << bCal << cCal << dCal << "," << uvMin << "," << uvMax << endl;
   return; }

void BandInfo::writeAips2Table(Table &the_table)
{
   the_table.addRow();
   ScalarColumn<String>scJ2000Name(the_table, "J2000Name");
   uInt howMany = scJ2000Name.nrow();
   howMany -= 1;
   scJ2000Name.put(howMany, j2000Name);

   ScalarColumn<String>scB1950Name(the_table, "B1950Name");
   scB1950Name.put(howMany, b1950Name);

   ScalarColumn<String>scReceiverName(the_table, "ReceiverName");
   scReceiverName.put(howMany, receiverName);

   ScalarColumn<String>scFlux(the_table, "Flux");
   scFlux.put(howMany, flux);

   ScalarColumn<String>scBandCode(the_table, "BandCode");
   scBandCode.put(howMany, band);

   ScalarColumn<String>scA(the_table, "A");
   scA.put(howMany, aCal);

   ScalarColumn<String>scB(the_table, "B");
   scB.put(howMany, bCal);

   ScalarColumn<String>scC(the_table, "C");
   scC.put(howMany, cCal);

   ScalarColumn<String>scD(the_table, "D");
   scD.put(howMany, dCal);

   ScalarColumn<String>scUVMin(the_table, "UVMin");
   scUVMin.put(howMany, uvMin);

   ScalarColumn<String>scUVMax(the_table, "UVMax");
   scUVMax.put(howMany, uvMax);

   return;
}

class CalibratorInfo {
   private :
    String name;
    Source j2000;
    Source b1950;
    Block<BandInfo> bandData;
//
   public :
      CalibratorInfo(){}
      void setJ2000(Source &a){j2000 = a;}
      void setB1950(Source &a){b1950 = a;}
      void clearBands(){bandData.resize(0, True);}
      void addBand(BandInfo &a){int count = bandData.nelements();
                                bandData.resize(count+1);
                                bandData[count] = a;}
      void writeObsCal(ostream &os);
      void writeAips2Table(Table &, Table&);
      String &getJ2000Name(){return j2000.getName();}
      String &getB1950Name(){return b1950.getName();}
      static Table *makeTable();
      static Table *makeBandTable();
};


Table *CalibratorInfo::makeTable(){
   TableDesc td("tTableDesc", "1", TableDesc::Scratch);
//
   td.comment() = "first attempt at making a VLA calibrator table in aips++";
   td.addColumn(ScalarColumnDesc<String>("Name"));
   td.addColumn(ScalarColumnDesc<String>("Alias"));
   td.addColumn(ScalarColumnDesc<String>("CalCode"));
   td.addColumn(ScalarColumnDesc<String>("RA_J2000"));
   td.addColumn(ScalarColumnDesc<String>("Dec_J2000"));
   td.addColumn(ScalarColumnDesc<String>("RA_B1950"));
   td.addColumn(ScalarColumnDesc<String>("Dec_B1950"));
   td.addColumn(ScalarColumnDesc<String>("Band Data"));  // Band Table
   SetupNewTable myNewTable("calibrator.data", td, Table::New);
   StManAipsIO *storageManager = new StManAipsIO;
   myNewTable.bindAll(*storageManager);
   return (new Table(myNewTable)); }

Table *CalibratorInfo::makeBandTable(){
   TableDesc td("tTableDesc", "1", TableDesc::Scratch);
//
   td.comment() = "VLA calibrator band data table in aips++";
   td.addColumn(ScalarColumnDesc<String>("J2000Name"));
   td.addColumn(ScalarColumnDesc<String>("B1950Name"));
   td.addColumn(ScalarColumnDesc<String>("ReceiverName"));
   td.addColumn(ScalarColumnDesc<String>("BandCode"));
   td.addColumn(ScalarColumnDesc<String>("Flux"));
   td.addColumn(ScalarColumnDesc<String>("A"));
   td.addColumn(ScalarColumnDesc<String>("B"));
   td.addColumn(ScalarColumnDesc<String>("C"));
   td.addColumn(ScalarColumnDesc<String>("D"));
   td.addColumn(ScalarColumnDesc<String>("UVMin"));
   td.addColumn(ScalarColumnDesc<String>("UVMax"));
   SetupNewTable myNewTable("calibratorBand.data", td, Table::New);
   StManAipsIO *storageManager = new StManAipsIO;
   myNewTable.bindAll(*storageManager);
   return (new Table(myNewTable)); }

void CalibratorInfo::writeAips2Table(Table &source_table, Table &band_table){
   source_table.addRow();
   j2000.writeAips2Table(source_table);
   b1950.writeAips2Table(source_table);
   for(uInt i=0;i<bandData.nelements();i++){
      bandData[i].writeAips2Table(band_table);
   }
   
   return; }

void CalibratorInfo::writeObsCal(ostream &os)
{
   j2000.writeObsCal(os);
   b1950.writeObsCal(os);
   String sourceAlias = j2000.getAlias();  // Only the j2000 position has a source alias
   if(sourceAlias.length())
      os << "AKA," << sourceAlias << endl;
   for(uInt i=0;i<bandData.nelements();i++){
      bandData[i].writeObsCal(os);
   }
   return;
} 

int main(int argc, char **argv){
   Input inputs(1);
   inputs.version("");
   inputs.create("calmaster", "csource.mas", "Master VLA Calibrator File", "InFile");
   inputs.create("observe", "True", "Flag for converting to observe style calibrator file", "Bool");
   inputs.create("aips++", "False", "Flag for converting to AIPS++ style calibrator file", "Bool");
   inputs.readArguments(argc, argv);
   String calTableName = inputs.getString("calmaster");
   Bool writeObserveStyle(True);
   if(calTableName.length() > 0){
      if((!inputs.getBool("observe")) || inputs.getBool("aips++")){
         writeObserveStyle = False;
      }
      ifstream calTable(calTableName.chars());
      char buffer[131];
      String strBuffer;
      int sourceCount(0);
      CalibratorInfo calibrator;
      Source         sourceStuff;
      BandInfo       bandStuff;
//
      Table *sourceTable(0);
      Table *bandTable(0);

      if(!writeObserveStyle){
          sourceTable = calibrator.makeTable();
          bandTable = calibrator.makeBandTable();
      }
//
      while(calTable.peek() != EOF){
          memset(buffer, '\0', 131);
          calTable.getline(buffer, 130);
          // cerr << buffer << endl;
          strBuffer = buffer;
          if(strBuffer.contains("J2000")){                // J2000 position always comes first.
             if(sourceCount){
                if(writeObserveStyle){
                   calibrator.writeObsCal(cout);             // Out with the old
                } else {
                   calibrator.writeAips2Table(*sourceTable, *bandTable);
                }
             }
             calibrator.clearBands();
             istringstream iss(buffer);
             sourceStuff.readTable(iss);   // In with the new
             calibrator.setJ2000(sourceStuff);
             sourceCount++;
          }
          if(strBuffer.contains("B1950")){
             istringstream iss(buffer);
             sourceStuff.readTable(iss);
             calibrator.setB1950(sourceStuff);
          }
          if(strBuffer.contains("cm")){
             bandStuff.readTable(buffer);
             bandStuff.setJ2000Name(calibrator.getJ2000Name());
             bandStuff.setB1950Name(calibrator.getB1950Name());
             calibrator.addBand(bandStuff);
          }
      }
      if(sourceCount){
         if(writeObserveStyle)
            calibrator.writeObsCal(cout);                    // Dump out the last one
         else
            calibrator.writeAips2Table(*sourceTable, *bandTable);
         delete sourceTable;
         delete bandTable;
      }
   } 
   return 0; } 
