//# tabjdbc.cc:  Table daemon for supplying table data.
//# Copyright (C) 1999,2000,2001
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
//# $Id: tabjdbc.cc,v 1.10 2005/08/29 11:11:52 gvandiep Exp $


#include <stdio.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <sys/uio.h>
#include <unistd.h>
#include <string.h>
#include <casa/BasicSL/String.h>
#include <tables/Tables/Table.h>

#include <tables/Tables/TableParse.h>
#include <tables/Tables/TableRow.h>
#include <tables/Tables/ExprNode.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/TableColumn.h>
#include <casa/Containers/RecordField.h>
#include <casa/Arrays/Vector.h>
#include <casa/iostream.h>
#include <casa/sstream.h>
#include <iostream>
#include <string>
#include <casa/Exceptions/Error.h>
#include <sstream>


#include <casa/namespace.h>
const int BUF_SIZE(2048);
const int PacketSize(4096);

String getcalfluxes(const String &tableName, const String &sourceName,
                  const Int iatStart = 0, const Float todStart = 0.0,
                  const Int iatStop = 60000, const Float todStop = 6.29);

int readn(int fd, char *ptr, int nbytes);
int writen(int fd, char *ptr, int nbytes);
int setupNet(int *);
int SendData(int sock, char *theData, int DataSize);
String createVOTab(String tablename, int totalrows, Vector<String> colnames, Vector<String> datatype, String records, String keyword, Bool insRowOk, Bool delRowOk, String columnkeywords);
String createKeyword(TableRecord trec, int a);

int main(int argc, char *argv[])
{  int sock(0), bytesToRead(0);
   char buff[BUF_SIZE];
   String initQuery;
   String keywords;
   int in_bytes;
   if(!setupNet(&sock)){
      // cerr << "Spawned" << endl;
      while((in_bytes = readn(sock, buff, strlen("send.table.query")+4)) > 0){
	  //initQuery = buff;
          istringstream istrbuff(buff);
          istrbuff >> initQuery >> bytesToRead;
                  // If BUF_SIZE < bytesToRead we've got to do something else.
          // cerr << "Bytes to read: " << bytesToRead << " Query: " << buff << endl;
          readn(sock, buff, bytesToRead);
          // cerr << "Bytes to read: " << bytesToRead << " Query: " << buff << endl;
	  // null terminate things
          *(buff+bytesToRead) = '\0';
          String query(buff);
	  cerr<<"querrying"<<query<<endl;
          try {
	    if(initQuery== "send.table.array"){
	      
	      cerr<<"arrayInfo:"<<endl<< query<<endl;
	      string qu="";
	      string tag;
	    
	      int row;
	      string type;
	      int col;
	      stringstream stream;
	      stream<<query;
	      stream>>tag;
	      cout<<"first tag:" <<tag<<endl;
	      stream>>tag;
	   
	     
	      stream>>tag;
	      while(tag!="</QUERY>"){
		qu.append(tag);
		qu.append(" ");
		stream>>tag;
	      }
	      
	      
	      stream>>tag;
	      stream>>row;
	      cout<<"row num: "<<row<<endl;
	      stream>>tag;
	      stream>> tag;
	      stream >>col;
	      cout<<"col num: "<<col<<endl;
	      stream >>tag;
	      stream>> tag;
	      stream>>type;

	      stringstream diff;
	      diff<<qu;
	      string word;
	      string word2;
	      string name;
	      diff>>word;
	      diff>>word2;
	      diff>>name;
	      Table result;
	      //  cout<<"words : "<<word<<" "<<word2<<" "<<name<<endl;
	      
	      String qur(qu);
	      
	     
	      
	      if(word=="SELECT"&&word2=="FROM"&&(!qur.contains("WHERE"))){
		
		
		result=Table(name);
		
	      }
	      else{
		
		result = tableCommand(qu); 
	      }
	      
	     
	      TableDesc td = result.tableDesc();
	      ColumnDesc cd = td.columnDesc(col);
	      String columnName = cd.name();
	     
	      
	      
	      String arrayInfo;
	      ostringstream hits;
	      
	      
	      if(type=="TpArrayBool"){
	
		ROArrayColumn< Bool > column(result, columnName);
		Array<Bool > array = column(row);
		hits<<array;
	
		
	      }
	      
	      else if(type=="TpArrayFloat"){
	
		ROArrayColumn< Float > column(result, columnName);
		Array<Float > array = column(row);
		hits<<array;
	
		
	      }

	      else if(type=="TpArrayDouble"){
	
		ROArrayColumn< Double > column(result, columnName);
		Array<Double > array = column(row);
		hits<<array;
	
		
	      }

	     //  else if(type=="TpArrayChar"){
	
// 		ROArrayColumn< Char > column(result, columnName);
// 		Array<Char > array = column(row);
// 		hits<<array;
	
		
// 	      }
	      else if(type=="TpArrayUChar"){
	
		ROArrayColumn< uChar > column(result, columnName);
		Array<uChar > array = column(row);
		hits<<array;
	
		
	      }
	      

	      else if(type=="TpArrayShort"){
	
		ROArrayColumn< Short > column(result, columnName);
		Array<Short > array = column(row);
		hits<<array;
	
		
	      }

	      else if(type=="TpArrayInt"){
	
		ROArrayColumn< Int > column(result, columnName);
		Array<Int > array = column(row);
		hits<<array;
	
		
	      }
	      else if(type=="TpArrayUInt"){
	
		ROArrayColumn< uInt > column(result, columnName);
		Array<uInt > array = column(row);
		hits<<array;
	
		
	      }


	      else if(type=="TpArrayComplex"){
	
		ROArrayColumn< Complex > column(result, columnName);
		Array<Complex > array = column(row);
		hits<<array;
	
		
	      }


	      else if(type=="TpArrayDComplex"){
	
		ROArrayColumn< DComplex > column(result, columnName);
		Array<DComplex > array = column(row);
		hits<<array;
	
		
	      }


	      else if(type=="TpArrayString"){
	
		ROArrayColumn< String > column(result, columnName);
		Array<String > array = column(row);
		hits<<array;
	
		
	      }
	      arrayInfo = hits.str();
	      int length = htonl(arrayInfo.length());

	      if(SendData(sock, (char *)&length, sizeof(int)) == -1){
		printf("Error sending data111\n");
		break;
	      } 


	     if(SendData(sock, (char *)arrayInfo.chars(), arrayInfo.length()) == -1){
	       printf("Error sending data222\n");
	       break;
             }    

             if(SendData(sock, "thats.all.folks\n", 16) == -1){
	       printf("Error sending data333\n");
	       break;
             }

	    }
	    
	    else if(initQuery== "send.table.updat"){
	      cerr<<"Attempting to update table: "<<endl<<query<<endl;
	      
	      string tag;
	      string content;
	      stringstream stream;
	      stream<<query;
	      stream>>tag;
	      cout<<"first tag:" <<tag<<endl;
	      stream>>tag;
	      cout<<"should be select: "<<tag<<endl;
	      
	      while(tag!="</QUERY>"){
		content.append(tag);
		content.append(" ");
		stream>>tag;
		cout<<tag<<endl;
	      }

	      cout<<"query is: "<<content<<endl;
	      
	      stringstream diff;
	      diff<<content;
	      string word;
	      string word2;
	      string name;
	      diff>>word;
	      diff>>word2;
	      diff>>name;
	      Table subtable;
	      // cout<<" update words : "<<word<<" "<<word2<<" "<<name<<endl;

	      String qur(content);
	      
	     
	      
	      if(word=="SELECT"&&word2=="FROM"&&(!qur.contains("WHERE"))){
		
			
		subtable = Table(name);
		
	      }
	      
	      else{
		subtable =tableCommand(content);
	      }




	      subtable.reopenRW();
	    

	      /////////////////


	      ROTableRow row(subtable);
	      Vector<String> colNames = row.columnNames();
	      void **fieldPtrs = (void **)new uInt*[colNames.nelements()];
	      

	      Vector<String> dataTypes(30);
	      {
		
		for(int i=0;i<Int(colNames.nelements());i++){
		  //  cerr<<"entering for 1"<<endl;
		  switch(row.record().type(row.record().fieldNumber(colNames(i)))){
		  case TpString :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<String>(row.record(), colNames(i));
		    
		    dataTypes[i]="TpString";
		    break;
		    
		  case TpInt :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Int>(row.record(), colNames(i));
		    dataTypes[i]="TpInt";
		    
		    break;
		   
		  case TpFloat :
		    fieldPtrs[i] =  (void *)
		      new RORecordFieldPtr<Float>(row.record(), colNames(i));
		    dataTypes[i]="TpFloat";
		    break;
		   
		  case TpDouble :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Double>(row.record(), colNames(i));
		    dataTypes[i]="TpDouble";
		    break;

		  case TpBool :
		    fieldPtrs[i] =  (void *)
		      new RORecordFieldPtr<Bool>(row.record(), colNames(i));
		    dataTypes[i]="TpBool";
		    
		    break;
		    
		  case TpUChar :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<uChar>(row.record(), colNames(i));
		    dataTypes[i]="TpUChar";
		    break;
		    
		  case TpShort :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Short>(row.record(), colNames(i));
		    dataTypes[i]="TpShort";
		    break;

		  case TpUInt :
		    fieldPtrs[i] = 
		      new RORecordFieldPtr<uInt>(row.record(), colNames(i));
		    dataTypes[i]="TpUInt";
		    break;
		    
                   case TpComplex :
		     fieldPtrs[i] = 
		       new RORecordFieldPtr<Complex>(row.record(), colNames(i)); 
		     dataTypes[i]="TpComplex";
                      break;
		      
		  case TpDComplex :
		    fieldPtrs[i] = 
		      new RORecordFieldPtr<DComplex>(row.record(), colNames(i));
		      dataTypes[i]="TpDComplex";
		      break;

		  case TpArrayDouble :
		  
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Double> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayDouble";
		    break;

		  case TpArrayBool :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Bool> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayBool";
		    break;
		    
		    
		  case TpArrayChar :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Char> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayChar";
		    break;
		    
		    
		  case TpArrayUChar :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<uChar> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayUChar";
		    break;
		    
		  case TpArrayShort :
		    
		    fieldPtrs[i] =
		    new RORecordFieldPtr<Array<Short> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayShort";
		    break;
		    

		  case TpArrayInt :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Int> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayInt";
		    break;
		    
		  case TpArrayUInt :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<uInt> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayUInt";
		    break;
		    
		  case TpArrayFloat :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Float> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayFloat";
		    break;
		    

		  case TpArrayComplex :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Complex> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayComplex";
		    break;
		    
		    
		  case TpArrayDComplex :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<DComplex> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayDComplex";
		    break;
		    
		  case TpArrayString :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<String> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayString";
		    break;
		    
		    
		  default:
		    cerr<<"index i: "<<i<<endl;
		    cerr<<"columnName: "<<colNames(i)<<endl;
		    TableDesc td = subtable.tableDesc();
		    ColumnDesc cd = td.columnDesc(colNames(i));
		    cerr<<"datatype is: "<<cd.dataType()<<endl;

		    throw(AipsError("atabd: unexpected type, this should never happ"));
		   
		    break;
		  }
		}
	      }
		//////////////////////
	     
	      int ncol = subtable.tableDesc().ncolumn();
	      TableColumn* colarr = new TableColumn[ncol];
	      for(int a=0; a<ncol; a++){
		colarr[a].attach(subtable, a);
	      }
	      
	      stream>>tag;
	      cout<<"should be command"<<tag<<endl;
	     
	      int rownum;
	      int colnum;
	      double doubleval;
	      int intval;
	      bool boolval;
	      float floatval;
	      String strval;
	      while(stream>>tag){
		if(tag!="</COMMAND>"){
		  if(tag=="<UPDATE"){
		    cout<<"update cell"<<endl;
		    stream>>tag;
		    cerr<<"marker row? :"<< tag<<endl;
		    
		    stream>>tag;
		    cout<<tag<<endl;
		    
		    stream>>rownum;
		    cout<<"row number: "<<rownum<<endl;
		    
		    stream>>tag;
		    cout<<tag<<endl;
		    
		    stream>>tag;
		    cout<<tag<<endl;
		    
		    stream>>colnum;
		    cout<<"col number: "<<colnum<<endl;
		    
		    stream>>tag;
		    cout<<tag<<endl;
		    
		    stream>>tag;
		    cout<<tag<<endl;
		    
		    if(dataTypes[colnum]=="TpDouble"){
		      
		      ColumnDesc desc = colarr[colnum].columnDesc();
		      
		      if(desc.comment()=="Modified Julian Day"){
			stream>>strval;
			cout<<"date is: "<<strval<<endl;
			
			int index = strval.find("-",0);
			String year = strval.at(0, index);
			
			int index2 = strval.find("-",index+1);
			String month = strval.at(index+1, index2-index-1);
			
			index = strval.find("-",index2+1);
			String day = strval.at(index2+1, index-index2-1);
			
			index2 = strval.find(":", index+1);
			String hour = strval.at(index+1, index2-index-1);
			
			index = strval.find(":",index2+1);
			String min = strval.at(index2+1, index-index2-1);
			
			String sec =strval.at(index+1, strval.length()-index-1);
			
			stringstream converter;
			uInt iyear;
			uInt imonth;
			uInt iday;
			uInt ihour;
			uInt imin;
			double isec;

			converter<<year;
			converter>>iyear;
			converter.clear();
			converter<<month;
			converter>>imonth;
			converter.clear();
			converter<<day;
			converter>>iday;
			converter.clear();
			converter<<hour;
			converter>>ihour;
			converter.clear();
			converter<<min;
			converter>>imin;
			converter.clear();
			converter<<sec;
			converter>>isec;
			
			Time temptime(iyear, imonth, iday, ihour, imin, isec);
			cout<<"the date is: "<<temptime<<endl;
			const double dval = (temptime.julianDay()-2400000.5)*86400;
			
			colarr[colnum].putScalar((uInt)rownum, dval);
		      }
		      else{
		      cout<<"col "<<colnum<<" = double"<<endl;
		      stream>>doubleval;
		      
		      cout<<"newval is: "<<doubleval<<endl;
		      const double dval = doubleval;
		      colarr[colnum].putScalar((uInt)rownum, dval);
		      }
		    }
		    
		    else if(dataTypes[colnum]=="TpFloat"){
		      
		      cout<<"col "<<colnum<<" = float"<<endl;
		      stream>>floatval;
		      
		      cout<<"newval is: "<<floatval<<endl;
		      const float fval = floatval;
		      colarr[colnum].putScalar((uInt)rownum, fval);
		      
		    }
		    
		    
		    else if(dataTypes[colnum]=="TpInt"){
		      
		      cout<<"col "<<colnum<<" = int"<<endl;
		      stream>>intval;
		      
		      cout<<"newval is: "<<intval<<endl;
		      const Int ival= intval;
		      colarr[colnum].putScalar((uInt)rownum,ival);
		      
		    }
		    
		    else if(dataTypes[colnum]=="TpBool"){
		      
		      cout<<"col "<<colnum<<" = bool"<<endl;
		      stream>>boolval;
		      
		      cout<<"newval is: "<<boolval<<endl;
		      const Bool bval=boolval;
		      colarr[colnum].putScalar((uInt)rownum, bval);
		      
		    }
		    else if(dataTypes[colnum]=="TpString"){
		      
		      cout<<"col "<<colnum<<" = string"<<endl;
		      stream>>strval;
		      
		      cout<<"newval is: "<<boolval<<endl;
		      const String strival=strval;
		      colarr[colnum].putScalar((uInt)rownum, strival);
		      
		    }

		    else if(dataTypes[colnum]=="TpComplex"){
		      
		      stream>>strval;
		      int comma = strval.find(",");
		      String real = strval.at(1,comma-1);
		      String imag = strval.at(comma+1, strval.length()-1-comma);
		      stringstream converter;
		      stringstream converter2;
		      float dreal;
		      float dimag;
		      converter<<real;
		      converter>>dreal;
		      converter2<<imag;
		      converter2>>dimag;
		      Complex x(dreal,dimag);

		      colarr[colnum].putScalar((uInt)rownum, x);
		      
		
		    }

		    else if(dataTypes[colnum]=="TpDComplex"){
		      
		     
		      stream>>strval;
		      int comma = strval.find(",");
		      String real = strval.at(1,comma-1);
		      String imag = strval.at(comma+1, strval.length()-1-comma);
		      stringstream converter;
		      stringstream converter2;
		      double dreal;
		      double dimag;
		      converter<<real;
		      converter>>dreal;
		      converter2<<imag;
		      converter2>>dimag;
		      DComplex x(dreal,dimag);

		      colarr[colnum].putScalar((uInt)rownum, x);
		      
		    }
		    
		    
		    else{
		      
		      cout<<"unknown type: "<<dataTypes[colnum]<<endl;
		      break;
		      
		    }

		    
		    stream>>tag;
		    cout<<"should be >"<<endl;
		  }
		  
		  else if(tag=="<ARRAYUPDATE"){

		    cout<<"update array"<<endl;
		    stream>>tag;
		    cerr<<"marker row? :"<< tag<<endl;
		    
		    stream>>tag;
		    cout<<tag<<endl;
		    
		    stream>>rownum;
		    cout<<"row number: "<<rownum<<endl;
		    
		    stream>>tag;
		    cout<<tag<<endl;
		    
		    stream>>tag;
		    cout<<tag<<endl;
		    
		    stream>>colnum;
		    cout<<"col number: "<<colnum<<endl;
		    TableDesc td =subtable.tableDesc();
		    ColumnDesc cd = td.columnDesc(colnum);
		    DataType type =cd.dataType();
		    String name = cd.name();
		    stream>>tag;
		    int coord;
		    
		    if(type==TpBool){
		      
		      ArrayColumn<Bool> arraycol(subtable, name);
		      Array<Bool> array =arraycol(rownum);
		      int dim = array.ndim();
		      
		      Bool value;
		      bool val;
		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
			if(tag=="<ARRAYCELLUPDATE"){
			  stream>>tag; //coordinates
			  stream>>tag; //=
			  stream>>tag; //[
			  IPosition coordinates((uInt)dim);
			  for(int abc=0;abc<dim;abc++){
			    stream>>coord;
			    
			    coordinates(abc)=coord;
			  }
			  stream>>tag; // ]
			  stream>>tag; //val
			  stream>>tag; //=
			  stream>>val;
			  value=val;
			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
			  ostringstream def;
			  def<<coordinates<<" = "<<value;
			  String tester =def.str();
			  cout<<"array cell action setting: "<<tester<<endl;
			  Bool before = array(coordinates);
			  cout<<"before assignment: "<<before<<endl;
			  
			  array(coordinates) =value;
			  Bool after = array(coordinates);
			  cout<<"after assignment: "<<after<<endl;
			  
			  
			  


			}
			
		      }
		      arraycol.put(rownum, array);
		    }
		    
			
			
			
		    else if(type==TpUChar){
			  
		      ArrayColumn<uChar> arraycol(subtable, name);
		      Array<uChar> array =arraycol(rownum);
		      int dim = array.ndim();
		      
		      uChar value;
		      char val;
		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
			if(tag=="<ARRAYCELLUPDATE"){
			  stream>>tag; //coordinates
			  stream>>tag; //=
			  stream>>tag; //[
			  IPosition coordinates((uInt)dim);
			  for(int abc=0;abc<dim;abc++){
			    stream>>coord;
			    
			    coordinates(abc)=coord;
			  }
			  stream>>tag; // ]
			  stream>>tag; //val
			  stream>>tag; //=
			  stream>>val;
			  value=val;
			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
			  ostringstream def;
			  def<<coordinates<<" = "<<value;
			  String tester =def.str();
			  cout<<"array cell action setting: "<<tester<<endl;
			  uChar before = array(coordinates);
			  cout<<"before assignment: "<<before<<endl;
			  
			  array(coordinates) =value;
			  uChar after = array(coordinates);
			  cout<<"after assignment: "<<after<<endl;
			  
			  
			  


			}
			
		      }
		      arraycol.put(rownum, array);
		 
		    }     
		    
		    else if(type==TpShort){
			  
		      ArrayColumn<Short> arraycol(subtable, name);
		      Array<Short> array =arraycol(rownum);
		      int dim = array.ndim();
		      
		      Short value;
		      short val;
		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
			if(tag=="<ARRAYCELLUPDATE"){
			  stream>>tag; //coordinates
			  stream>>tag; //=
			  stream>>tag; //[
			  IPosition coordinates((uInt)dim);
			  for(int abc=0;abc<dim;abc++){
			    stream>>coord;
			    
			    coordinates(abc)=coord;
			  }
			  stream>>tag; // ]
			  stream>>tag; //val
			  stream>>tag; //=
			  stream>>val;
			  value=val;
			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
			  ostringstream def;
			  def<<coordinates<<" = "<<value;
			  String tester =def.str();
			  cout<<"array cell action setting: "<<tester<<endl;
			  Short before = array(coordinates);
			  cout<<"before assignment: "<<before<<endl;
			  
			  array(coordinates) =value;
			  Short after = array(coordinates);
			  cout<<"after assignment: "<<after<<endl;
			  
			  
			  


			}
			
		      }
		      arraycol.put(rownum, array);	  
		    }    
			
		    else if(type==TpInt){
			  
		      ArrayColumn<Int> arraycol(subtable, name);
		      Array<Int> array =arraycol(rownum);
		      int dim = array.ndim();
		      
		      Int value;
		      int val;
		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
			if(tag=="<ARRAYCELLUPDATE"){
			  stream>>tag; //coordinates
			  stream>>tag; //=
			  stream>>tag; //[
			  IPosition coordinates((uInt)dim);
			  for(int abc=0;abc<dim;abc++){
			    stream>>coord;
			    
			    coordinates(abc)=coord;
			  }
			  stream>>tag; // ]
			  stream>>tag; //val
			  stream>>tag; //=
			  stream>>val;
			  value=val;
			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
			  ostringstream def;
			  def<<coordinates<<" = "<<value;
			  String tester =def.str();
			  cout<<"array cell action setting: "<<tester<<endl;
			  Int before = array(coordinates);
			  cout<<"before assignment: "<<before<<endl;
			  
			  array(coordinates) =value;
			  Int after = array(coordinates);
			  cout<<"after assignment: "<<after<<endl;
			  
			  
			  


			}
			
		      }
		      arraycol.put(rownum, array);	  
		    }     
		    else if(type==TpUInt){
			  
		      ArrayColumn<uInt> arraycol(subtable, name);
		      Array<uInt> array =arraycol(rownum);
		      int dim = array.ndim();
		      
		      uInt value;
		      int val;
		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
			if(tag=="<ARRAYCELLUPDATE"){
			  stream>>tag; //coordinates
			  stream>>tag; //=
			  stream>>tag; //[
			  IPosition coordinates((uInt)dim);
			  for(int abc=0;abc<dim;abc++){
			    stream>>coord;
			    
			    coordinates(abc)=coord;
			  }
			  stream>>tag; // ]
			  stream>>tag; //val
			  stream>>tag; //=
			  stream>>val;
			  value=val;
			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
			  ostringstream def;
			  def<<coordinates<<" = "<<value;
			  String tester =def.str();
			  cout<<"array cell action setting: "<<tester<<endl;
			  uInt before = array(coordinates);
			  cout<<"before assignment: "<<before<<endl;
			  
			  array(coordinates) =value;
			  uInt after = array(coordinates);
			  cout<<"after assignment: "<<after<<endl;
			  
			  
			  


			}
			
		      }
		      arraycol.put(rownum, array);	  
			  
		    }    
		    
		    else if(type==TpFloat){
		      ArrayColumn<Float> arraycol(subtable, name);
		      Array<Float> array =arraycol(rownum);
		      int dim = array.ndim();
		      
		      Float value;
		      float val;
		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
			if(tag=="<ARRAYCELLUPDATE"){
			  stream>>tag; //coordinates
			  stream>>tag; //=
			  stream>>tag; //[
			  IPosition coordinates((uInt)dim);
			  for(int abc=0;abc<dim;abc++){
			    stream>>coord;
			    
			    coordinates(abc)=coord;
			  }
			  stream>>tag; // ]
			  stream>>tag; //val
			  stream>>tag; //=
			  stream>>val;
			  value=val;
			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
			  ostringstream def;
			  def<<coordinates<<" = "<<value;
			  String tester =def.str();
			  cout<<"array cell action setting: "<<tester<<endl;
			  Float before = array(coordinates);
			  cout<<"before assignment: "<<before<<endl;
			  
			  array(coordinates) =value;
			  Float after = array(coordinates);
			  cout<<"after assignment: "<<after<<endl;
			  
			  
			  


			}
			
		      }
		      arraycol.put(rownum, array);  
		      
		    }   
		    
		    else if(type==TpDouble){
		      ArrayColumn<Double> arraycol(subtable, name);
		      Array<Double> array =arraycol(rownum);
		      int dim = array.ndim();
		      
		      Double value;
		      double val;
		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
			if(tag=="<ARRAYCELLUPDATE"){
			  stream>>tag; //coordinates
			  stream>>tag; //=
			  stream>>tag; //[
			  IPosition coordinates((uInt)dim);
			  for(int abc=0;abc<dim;abc++){
			    stream>>coord;
			    
			    coordinates(abc)=coord;
			  }
			  stream>>tag; // ]
			  stream>>tag; //val
			  stream>>tag; //=
			  stream>>val;
			  value=val;
			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
			  ostringstream def;
			  def<<coordinates<<" = "<<value;
			  String tester =def.str();
			  cout<<"array cell action setting: "<<tester<<endl;
			  Double before = array(coordinates);
			  cout<<"before assignment: "<<before<<endl;
			  
			  array(coordinates) =value;
			  Double after = array(coordinates);
			  cout<<"after assignment: "<<after<<endl;
			  
			  
			  


			}
			
		      }
		      arraycol.put(rownum, array);	  
			  
		    }  
		    else if(type==TpComplex){

		      



		      ArrayColumn<Complex> arraycol(subtable, name);
 		      Array<Complex> array =arraycol(rownum);
 		      int dim = array.ndim();
		      
    
		     
		     


		      String strval;

		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
 			if(tag=="<ARRAYCELLUPDATE"){
 			  stream>>tag; //coordinates
 			  stream>>tag; //=
 			  stream>>tag; //[
 			  IPosition coordinates((uInt)dim);
 			  for(int abc=0;abc<dim;abc++){
 			    stream>>coord;
			    
 			    coordinates(abc)=coord;
 			  }
 			  stream>>tag; // ]
 			  stream>>tag; //val
 			  stream>>tag; //=
 			  stream>>strval;

			  
			  int comma = strval.find(",");
			  String real = strval.at(1,comma-1);
			  String imag = strval.at(comma+1, strval.length()-1-comma);
			  stringstream converter;
			  float dreal;
			  stringstream converter2;
			  float dimag;
			  converter<<real;
			  converter>>dreal;
			  converter2<<imag;
			  converter2>>dimag;
			  Complex value(dreal,dimag);
			  cout<<"the complex value being stored is: "<<value<<endl<<"real: "<<dreal<< "  imag: "<<dimag<<endl;
			  
 			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
 			  array(coordinates) =value;

			  
			  
			  


			}
			
		      }
 		      arraycol.put(rownum, array);
		    }  
		    else if(type==TpDComplex){

		      ArrayColumn<DComplex> arraycol(subtable, name);
 		      Array<DComplex> array =arraycol(rownum);
 		      int dim = array.ndim();
		      
    		      String strval;

		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
 			if(tag=="<ARRAYCELLUPDATE"){
 			  stream>>tag; //coordinates
 			  stream>>tag; //=
 			  stream>>tag; //[
 			  IPosition coordinates((uInt)dim);
 			  for(int abc=0;abc<dim;abc++){
 			    stream>>coord;
			    
 			    coordinates(abc)=coord;
 			  }
 			  stream>>tag; // ]
 			  stream>>tag; //val
 			  stream>>tag; //=
 			  stream>>strval;

			  
			  int comma = strval.find(",");
			  String real = strval.at(1,comma-1);
			  String imag = strval.at(comma+1, strval.length()-1-comma);
			  stringstream converter;
			  stringstream converter2;
			  double dreal;
			  double dimag;
			  converter<<real;
			  converter>>dreal;
			 
			  converter2<<imag;
			  converter2>>dimag;
			  DComplex value(dreal,dimag);
			  
			  
 			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
 			  array(coordinates) =value;

			  
			  
			  


			}
			
		      }
 		      arraycol.put(rownum, array);

		    
			  
		    }  
		  //   else if(type==TpComplex){
// 		      ArrayColumn<Complex> arraycol(subtable, name);
//  		      Array<Complex> array =arraycol(rownum);
//  		      int dim = array.ndim();
		      
    
		     
		     


// 		      String strval;

// 		      stream>>tag; //<ARRAYCELLUPDATE
// 		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
// 		      while(tag!="</ARRAYUPDATE>"){
			  
		
//  			if(tag=="<ARRAYCELLUPDATE"){
//  			  stream>>tag; //coordinates
//  			  stream>>tag; //=
//  			  stream>>tag; //[
//  			  IPosition coordinates((uInt)dim);
//  			  for(int abc=0;abc<dim;abc++){
//  			    stream>>coord;
			    
//  			    coordinates(abc)=coord;
//  			  }
//  			  stream>>tag; // ]
//  			  stream>>tag; //val
//  			  stream>>tag; //=
//  			  stream>>strval;

			  
// 			  int comma = strval.find(",");
// 			  String real = strval.at(1,comma-1);
// 			  String imag = strval.at(comma+1, strval.length()-1-comma);
// 			  strstream converter;
// 			  float dreal;
// 			  float dimag;
// 			  converter<<real;
// 			  converter>>dreal;
// 			  converter<<imag;
// 			  converter>>dimag;
// 			  Complex value(dreal,dimag);
			  
		

//  			  stream>>tag; //>
// 			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
//  			  array(coordinates) =value;

			  
			  
			  


// 			}
			
// 		      }
//  		      arraycol.put(rownum, array);

		   
// 		    }  
		    else if(type==TpString){
		      ArrayColumn<String> arraycol(subtable, name);
		      Array<String> array =arraycol(rownum);
		      int dim = array.ndim();
		      
		      String value;
		      string val;
		      stream>>tag; //<ARRAYCELLUPDATE
		      cout<<"should be <ARRAYCELLUPDATE: "<<tag<<endl;
		      while(tag!="</ARRAYUPDATE>"){
			  
		
			if(tag=="<ARRAYCELLUPDATE"){
			  stream>>tag; //coordinates
			  stream>>tag; //=
			  stream>>tag; //[
			  IPosition coordinates((uInt)dim);
			  for(int abc=0;abc<dim;abc++){
			    stream>>coord;
			    
			    coordinates(abc)=coord;
			  }
			  stream>>tag; // ]
			  stream>>tag; //val
			  stream>>tag; //=
			  stream>>val;
			  value=val;
			  stream>>tag; //>
			  stream>>tag; // either <ARRACELLUPDATE or </ARRAYUPDATE
			  ostringstream def;
			  def<<coordinates<<" = "<<value;
			  String tester =def.str();
			  cout<<"array cell action setting: "<<tester<<endl;
			  String before = array(coordinates);
			  cout<<"before assignment: "<<before<<endl;
			  
			  array(coordinates) =value;
			  String after = array(coordinates);
			  cout<<"after assignment: "<<after<<endl;
			  
			  
			  


			}
			
		      }
		      arraycol.put(rownum, array);	  
		      
		    }
		    
		    else{
		      cout<<"unidentified array type : "<<type<<endl;
		      
		    }
		    
		  }
		
		  else if(tag=="<DELROW"){
		    cout<<"can remove row: "<<subtable.canRemoveRow()<<endl;
		    int number;
		    stream >>number;
		    stream>>tag;
		   
		    cout<<"deleting row: "+number<<endl;
		    subtable.removeRow((uInt)number);
		    
		    
		  }
		      
		  else if(tag=="<ADDROW>"){
		    cout<<"atttempting to add row"<<endl;
		    		    
		    
		    subtable.addRow(1,false);

		  }
		
		  else{
		    cout<<"unidentified command: "<<tag<<endl;
		    
		  }
		}
		
	      }
	      
	      
	      delete [] colarr;

	      String hits="Done";
	      

	      
	      int length = htonl(hits.length());
	     //length = length/65000+1;
	     
	     //cerr<<"numtimes = "<<length<<endl;
	     //  cout<<"char at 154048: "<<hits[154048]<<endl;
	     stringstream converter;
	     converter<<length;
	     string strlength;
	     converter>>strlength;
	     
	     

	     String slen = strlength+"\n";
	     
	     //  cerr <<"slen of string = "<<slen<<endl;
	     
	     if(SendData(sock, (char *)&length, sizeof(int)) == -1){
	       printf("Error sending data1\n");
	       break;
             } 


	     if(SendData(sock, (char *)hits.chars(), hits.length()) == -1){
	       printf("Error sending data2\n");
	       break;
             }    

             if(SendData(sock, "thats.all.folks\n", 16) == -1){
	       printf("Error sending data3\n");
	       break;
             }
	     
	    

	    }

	    else if(initQuery == "send.table.query"){
	      //  cerr<<"got into if"<<endl;
	      cout<<"query string: "<<query;
	      stringstream diff;
	      diff<<query;
	      string word;
	      string word2;
	      string name;
	      diff>>word;
	      diff>>word2;
	      diff>>name;
	      int totalNumRows;
	      int start;
	      int numRows;
	      string tag;
	      
	      diff>>tag;
	      while(tag!="<START")
		diff>>tag;
	      
	      if(tag=="<START"){
		cout<<"should be <START = "<<tag<<endl;
		diff>>tag;
		diff>>start;
		diff>>tag;
		diff>>tag;
		diff>>numRows;
		
		
	      }
	      
	      else{
		diff>>tag;
	      }
	      
	      int hjk  = query.index("<START");
	      cout<<"index of hjk: "<<hjk<<endl;
	      query=query.at(0, hjk);
	     
	      cout<<"the actual query: "<<query<<endl;
	      
	      cout<<"start pos: "<<start<<" rows per page: "<<numRows<<endl;
	      
	     
	      Table result;

	      String qur(query);
	      
	     
	      
	      if(word=="SELECT"&&word2=="FROM"&&(!qur.contains("WHERE"))){
		
		
		result=Table(name);
		
	      }
	      else{
		
		result = tableCommand(query); 
	      }
	      
	      
	      
	      totalNumRows=result.nrow();
	      int startIndex;
	      if (start<0)
		startIndex=0;
	      else{
		startIndex=start;
	      }
	      int endIndex;
	      
	      if(start+numRows<(int)result.nrow())
		endIndex=start+numRows;
	      
	      else if(numRows==0){
		endIndex = result.nrow();
	      }
	      else{
		endIndex = result.nrow();
	      }
	      cout<<"startindex: "<<startIndex<<" endIndex "<<endIndex<<endl;
	      String hits;
	      if(endIndex<=startIndex){
		throw(AipsError("EMPTY"));
		
	      }
	      
	      
	      
	      
	      Bool cinsRowOk= result.canAddRow();
	      Bool cdelRowOk = result.canRemoveRow();
	      
	      TableRecord trec = result.keywordSet();
	      //   cout<<"# of fields in keywordset: "<<trec.nfields()<<endl;
	      
	      
	      keywords= createKeyword(trec, -1);
	      
	      //  cout<<endl<<endl<<"Keywords: "<<endl<<keywords<<endl;
	      
	      
	      ROTableRow row(result);
	      Vector<String> colNames = row.columnNames();
	      void **fieldPtrs = (void **)new uInt*[colNames.nelements()];
	      
	      ostringstream oss;
	      Vector<String> dataTypes(30);
	      
	      {
		// String columnkw = "<COLUMNKEYWORDS>\n";
		String columnkw="none";
		TableDesc tdesc= result.tableDesc();
		if(colNames.nelements()>0){
		  columnkw="";
		}
		for(int i=0;i<Int(colNames.nelements());i++){
		  //  cerr<<"entering for 1"<<endl;
		  
		  ColumnDesc cdesc = tdesc.columnDesc((uInt)i);
		  //columnkw+="<COLUMN num = "+ String::toString(i)+" >\n";
		  TableRecord ctrec = cdesc.keywordSet();
		  String tempkw="";
		  
		  tempkw = createKeyword(ctrec,i);
	      
		 
		  if(tempkw!="none"){
		    columnkw+=tempkw;
		  }
		  else{
		    cout<<"column keyword is null"<<endl;
		    columnkw+=" ";
		  }
	      
		  
		  switch(row.record().type(row.record().fieldNumber(colNames(i)))){
		  case TpString :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<String>(row.record(), colNames(i));
		    
		    dataTypes[i]="TpString";
		    
		    
		    
		    
		    break;
		    
		  case TpInt :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Int>(row.record(), colNames(i));
		    dataTypes[i]="TpInt";
		    
		    break;
		    
		  case TpFloat :
		    fieldPtrs[i] =  (void *)
		      new RORecordFieldPtr<Float>(row.record(), colNames(i));
		    dataTypes[i]="TpFloat";
		    break;
		    
		  case TpDouble :
		    {
                      fieldPtrs[i] =
			new RORecordFieldPtr<Double>(row.record(), colNames(i));	  
		      TableDesc td = result.tableDesc();
		      ColumnDesc cd = td[i];
		      String com = cd.comment();
		      cerr<<endl<<"+++++++++++++++++++++"<<endl;
		      cerr<<"double comment: "<<com<<endl;
		      if(com=="Modified Julian Day"){
			cerr<<"its a date"<<endl;
			dataTypes[i]="TpDate";
		      }
		      else{
			dataTypes[i]="TpDouble";
		      }
                      break;
		    }
		  case TpBool :
		    fieldPtrs[i] =  (void *)
		      new RORecordFieldPtr<Bool>(row.record(), colNames(i));
		    dataTypes[i]="TpBool";
		    
		    break;
		    
		  case TpUChar :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<uChar>(row.record(), colNames(i));
		    dataTypes[i]="TpUChar";
		    break;
		    
		  case TpShort :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Short>(row.record(), colNames(i));
		    dataTypes[i]="TpShort";
		    break;
		    
		  case TpUInt :
		    fieldPtrs[i] = 
		      new RORecordFieldPtr<uInt>(row.record(), colNames(i));
		    dataTypes[i]="TpUInt";
		    break;
		    
		  case TpComplex :
		    fieldPtrs[i] = 
		      new RORecordFieldPtr<Complex>(row.record(), colNames(i)); 
		    dataTypes[i]="TpComplex";
		    break;
		    
		  case TpDComplex :
		    fieldPtrs[i] = 
		      new RORecordFieldPtr<DComplex>(row.record(), colNames(i));
		    dataTypes[i]="TpDComplex";
                    break;
		    
		  case TpArrayDouble :
		  
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Double> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayDouble";
		    break;
		    
		  case TpArrayBool :
		    
		    fieldPtrs[i] =
		    new RORecordFieldPtr<Array<Bool> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayBool";
		    break;
		    
		    
		  case TpArrayChar :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Char> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayChar";
		    break;

		    
		  case TpArrayUChar :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<uChar> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayUChar";
		    break;
		    
		case TpArrayShort :
		  
		  fieldPtrs[i] =
		    new RORecordFieldPtr<Array<Short> >(row.record(), colNames(i));
		  dataTypes[i]="TpArrayShort";
		  break;
		  
		  // 	case TpArrayUShort :
		  
// 		  fieldPtrs[i] =
// 		    new RORecordFieldPtr<Array<uShort> >(row.record(), colNames(i));
// 		  dataTypes[i]="TpArrayUShort";
// 		  break;
		  
		  case TpArrayInt :
		  
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Int> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayInt";
		    break;
		    
		  case TpArrayUInt :
		    
		  fieldPtrs[i] =
		    new RORecordFieldPtr<Array<uInt> >(row.record(), colNames(i));
		  dataTypes[i]="TpArrayUInt";
		  break;
		  
		  case TpArrayFloat :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Float> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayFloat";
		    break;
		    
		    
		  case TpArrayComplex :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Complex> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayComplex";
		    break;
		    
		    
		  case TpArrayDComplex :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<DComplex> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayDComplex";
		    break;
		    
		  case TpArrayString :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<String> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayString";
		    break;
		    
		  default:
		    cout<<"unknown type: "<<row.record().type(row.record().fieldNumber(colNames(i)))<<endl;
		    throw(AipsError("atabd: unexpected type, this should never happen"));
		    break;
		  }
		  
	   
		}

	     

		//   ostrstream oss;
		
		
		cout<<"getting entries from "<<start<<" to "<<start+numRows<<endl;

	      
	       
	       
	      
		for(int i=startIndex;i<endIndex;i++){
		  // cerr<<"entering for 2"<<endl;
		  
		  row.get(i);
		  oss<<"<TR>"<<endl;
		  for(int j=0;j<Int(colNames.nelements());j++){
		    
		    switch(row.record().type(j)){
		    case TpString :
		      
		      oss << "<TD> "<<**((RORecordFieldPtr<String> *)fieldPtrs[j])<<" </TD>";
		      break;
		    case TpFloat :
		      
		      oss << "<TD> "<< **((RORecordFieldPtr<Float> *)fieldPtrs[j])<<" </TD>";
		      break;
		    case TpInt :
		      
		      oss << "<TD> "<< **((RORecordFieldPtr<Int> *)fieldPtrs[j])<<" </TD>";
		      break;
		    case TpDouble :
		      {
			
			TableDesc td = result.tableDesc();
			ColumnDesc cd = td[j];
			String com = cd.comment();
			
			
			if(com=="Modified Julian Day"){
			  
			  double days = (**((RORecordFieldPtr<Double> *)fieldPtrs[j]))/86400+2400000.5;
			  
			  Time t(days);
			  String tstring;
			  tstring+=String::toString(t.year())+"-";
			  tstring+=String::toString(t.month())+"-";
			  tstring+=String::toString(t.dayOfMonth())+"-";
			  tstring+=String::toString(t.hours())+":";
			  tstring+=String::toString(t.minutes())+":";
			  tstring+=String::toString(t.seconds());
			  
			    //cerr<<"thee time is: "<<tstring<<endl;
			    
			    oss <<  "<TD> "<<tstring<<" </TD>";
			    
			  }
			else{
			  oss <<  "<TD> "<<**((RORecordFieldPtr<Double> *)fieldPtrs[j])<<" </TD>";
			  }
			  
                         break;
			}
                      case TpBool :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<Bool> *)fieldPtrs[j])<<" </TD>";
                         break;
                      case TpUChar :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<uChar> *)fieldPtrs[j])<<" </TD>";
                         break;
                      case TpShort :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<Short> *)fieldPtrs[j])<<" </TD>";
                         break;
                      case TpUInt :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<uInt> *)fieldPtrs[j])<<" </TD>";
                         break;
                      case TpComplex :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<Complex> *)fieldPtrs[j])<<" </TD>";
                         break;
		   case TpDComplex :

		     oss << "<TD> "<< **((RORecordFieldPtr<DComplex> *)fieldPtrs[j])<<" </TD>";
                         break;
			 
		   case TpArrayDouble :
		     {
		       IPosition pos = (**((RORecordFieldPtr<Array<Double> > *)fieldPtrs[j])).shape();
		       if(pos.nelements()==1){
			
			 oss << "<TD> "<< **((RORecordFieldPtr<Array<Double> > *)fieldPtrs[j])<<" </TD>";
		       }
			 
		       else{
			 oss<<"<TD> "<<pos<<"Double"<<" </TD>";
		       }
		       break;
		     }
		     
		     
		     
		      case TpArrayBool :
		     
			
			{
			  IPosition pos = (**((RORecordFieldPtr<Array<Bool> > *)fieldPtrs[j])).shape();
			  if(pos.nelements()==1){
			
			    oss << "<TD> "<< **((RORecordFieldPtr<Array<Bool> > *)fieldPtrs[j])<<" </TD>";
			  }
			  
			  else{
			    oss<<"<TD> "<<pos<<"Boolean"<<" </TD>";
			  }
			  break;
			}
		   case TpArrayChar :
		     	{
			  IPosition pos = (**((RORecordFieldPtr<Array<Char> > *)fieldPtrs[j])).shape();
			  if(pos.nelements()==1){
			
			    oss << "<TD> "<< **((RORecordFieldPtr<Array<Char> > *)fieldPtrs[j])<<" </TD>";
			  }
			 
			  else{
			    oss<<"<TD> "<<pos<<"Char"<<" </TD>";
			  }
			  break;
			}
		

		      case TpArrayUChar :
		     
			{
			  IPosition pos = (**((RORecordFieldPtr<Array<uChar> > *)fieldPtrs[j])).shape();
			  if(pos.nelements()==1){
			
			    oss << "<TD> "<< **((RORecordFieldPtr<Array<uChar> > *)fieldPtrs[j])<<" </TD>";
			  }
			  
			  else{
			    oss<<"<TD> "<<pos<<"UChar"<<" </TD>";
			  }
			  break;
			}


		     case TpArrayShort :
		     
		       {
			 IPosition pos = (**((RORecordFieldPtr<Array<Short> > *)fieldPtrs[j])).shape();
			 if(pos.nelements()==1){
			
			   oss << "<TD> "<< **((RORecordFieldPtr<Array<Short> > *)fieldPtrs[j])<<" </TD>";
			 }
			 
			 else{
			   oss<<"<TD> "<<pos<<"Short"<<" </TD>";
			 }
			 break;
		       }

		      
		   
		   case TpArrayInt :
		     {
		       IPosition pos = (**((RORecordFieldPtr<Array<Int> > *)fieldPtrs[j])).shape();
		       if(pos.nelements()==1){
			
			 oss << "<TD> "<< **((RORecordFieldPtr<Array<Int> > *)fieldPtrs[j])<<" </TD>";
		       }
			 
		       else{
			 oss<<"<TD> "<<pos<<"Int"<<" </TD>";
		       }
		       break;
		     }

		  
		     
		   case TpArrayUInt :
		     {
		       IPosition pos = (**((RORecordFieldPtr<Array<uInt> > *)fieldPtrs[j])).shape();
		       if(pos.nelements()==1){
			
			 oss << "<TD> "<< **((RORecordFieldPtr<Array<uInt> > *)fieldPtrs[j])<<" </TD>";
		       }
			 
		       else{
			 oss<<"<TD> "<<pos<<"UInt"<<" </TD>";
		       }
		       break;
		     }
		    

		   case TpArrayFloat :
		     
		     {
		       IPosition pos = (**((RORecordFieldPtr<Array<Float> > *)fieldPtrs[j])).shape();
		       if(pos.nelements()==1){
			 
			 oss << "<TD> "<< **((RORecordFieldPtr<Array<Float> > *)fieldPtrs[j])<<" </TD>";
		       }
			 
		       else{
			 oss<<"<TD> "<<pos<<"Float"<<" </TD>";
		       }
		       break;
		     }

		   case TpArrayComplex :
		     {
		       IPosition pos = (**((RORecordFieldPtr<Array<Complex> > *)fieldPtrs[j])).shape();
		       if(pos.nelements()==1){
			
			 oss << "<TD> "<< **((RORecordFieldPtr<Array<Complex> > *)fieldPtrs[j])<<" </TD>";
		       }
		       
		       else{
			 oss<<"<TD> "<<pos<<"Complex"<<" </TD>";
		       }
		       break;
		     }
		    
		   case TpArrayDComplex :
		     {
		       IPosition pos = (**((RORecordFieldPtr<Array<DComplex> > *)fieldPtrs[j])).shape();
		       if(pos.nelements()==1){
			
			 oss << "<TD> "<< **((RORecordFieldPtr<Array<DComplex> > *)fieldPtrs[j])<<" </TD>";
		       }
			 
		       else{
			 oss<<"<TD> "<<pos<<"DComplex"<<" </TD>";
		       }
		       break;
		     }
		    
		   case TpArrayString :
		     {
		       IPosition pos = (**((RORecordFieldPtr<Array<String> > *)fieldPtrs[j])).shape();
		       if(pos.nelements()==1){
			
			 oss << "<TD> "<< **((RORecordFieldPtr<Array<String> > *)fieldPtrs[j])<<" </TD>";
		       }
			 
		       else{
			 oss<<"<TD> "<<pos<<"String"<<" </TD>";
		       }
		       break;
		     }

		   default:
		     throw(AipsError("atabd: unexpected type, this should never happen:"));
		     
		         break;
                   }
                   oss << " ";
		  }
                oss <<endl<< "</TR>"<<endl;
		}
	       
	     
             


             hits = oss.str();
	     
	     hits=createVOTab(result.tableName(),totalNumRows ,colNames, dataTypes, hits, keywords, cinsRowOk, cdelRowOk, columnkw);
	     
	     
	  
      
	     
	      
	    
	     //	     cout << "Hits: " << hits << endl;

	     int length = htonl(hits.length());
	     //length = length/65000+1;
	     
	     //cerr<<"numtimes = "<<length<<endl;
	     //  cout<<"char at 154048: "<<hits[154048]<<endl;
	     stringstream converter;
	     converter<<length;
	     string strlength;
	     converter>>strlength;
	     
	     

	     String slen = strlength+"\n";
	     
	     //  cerr <<"slen of string = "<<slen<<endl;
	     
	     if(SendData(sock, (char *)&length, sizeof(int)) == -1){
	       printf("Error sending data1\n");
	       break;
             } 


	     if(SendData(sock, (char *)hits.chars(), hits.length()) == -1){
	       printf("Error sending data2\n");
	       break;
             }    

             if(SendData(sock, "thats.all.folks\n", 16) == -1){
	       printf("Error sending data3\n");
	       break;
             }
             {
             for(int j=0;j<Int(colNames.nelements());j++){
                   switch(row.record().type(j)){
                      case TpString :
                         delete (RORecordFieldPtr<String> *)fieldPtrs[j];
                         break;
                      case TpFloat :
                         delete (RORecordFieldPtr<Float> *)fieldPtrs[j];
                         break;
                      case TpInt :
                         delete (RORecordFieldPtr<Int> *)fieldPtrs[j];
                         break;
                      case TpDouble :
                         delete (RORecordFieldPtr<Double> *)fieldPtrs[j];
                         break;
                      case TpBool :
                         delete (RORecordFieldPtr<Bool> *)fieldPtrs[j];
                         break;
                      case TpUChar :
                         delete (RORecordFieldPtr<uChar> *)fieldPtrs[j];
                         break;
                      case TpShort :
                         delete (RORecordFieldPtr<Short> *)fieldPtrs[j];
                         break;
                      case TpUInt :
                         delete (RORecordFieldPtr<uInt> *)fieldPtrs[j];
                         break;
                      case TpComplex :
                         delete (RORecordFieldPtr<Complex> *)fieldPtrs[j];
                         break;
                      case TpDComplex :
                         delete (RORecordFieldPtr<DComplex> *)fieldPtrs[j];
                         break;
		   case TpArrayDouble :
		     delete (RORecordFieldPtr<Array<Double> > *)fieldPtrs[j];
		     break;
		  

		   case TpArrayBool   :
		     delete (RORecordFieldPtr<Array<Bool> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayChar :
		     delete (RORecordFieldPtr<Array<Char> > *)fieldPtrs[j];
		     break;

		   case TpArrayUChar :
		     delete (RORecordFieldPtr<Array<uChar> > *)fieldPtrs[j];
		     break;

		  //  case TpArrayUShort :
// 		     delete (RORecordFieldPtr<Array<uShort> > *)fieldPtrs[j];
// 		     break;
		     
		   case TpArrayShort :
		     delete (RORecordFieldPtr<Array<Short> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayInt :
		     delete (RORecordFieldPtr<Array<Int> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayUInt :
		     delete (RORecordFieldPtr<Array<uInt> > *)fieldPtrs[j];
		     break;
		      
		     
		   case TpArrayFloat :
		     delete (RORecordFieldPtr<Array<Float> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayComplex :
		     delete (RORecordFieldPtr<Array<Complex> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayDComplex :
		     delete (RORecordFieldPtr<Array<DComplex> > *)fieldPtrs[j];
		     break;

		   case TpArrayString :
		     delete (RORecordFieldPtr<Array<String> > *)fieldPtrs[j];
		     break;
		     
		     
		     
		      default:
			throw(AipsError("atabd: unexpected type, this should never happen" ));
			
			break;
                   }
             }
             }
             result.~Table();
             delete [] fieldPtrs;
	      }



	    }
  else if(initQuery == "send.table.qfull"){
	      //  cerr<<"got into if"<<endl;
	      cout<<"query string: "<<query;
	      stringstream diff;
	      diff<<query;
	      string word;
	      string word2;
	      string name;
	      diff>>word;
	      diff>>word2;
	      diff>>name;
	      int totalNumRows;
	      int start;
	      int numRows;
	      string tag;
	      
	      diff>>tag;
	      while(tag!="<START")
		diff>>tag;
	      
	      if(tag=="<START"){
		cout<<"should be <START = "<<tag<<endl;
		diff>>tag;
		diff>>start;
		diff>>tag;
		diff>>tag;
		diff>>numRows;
		
		
	      }
	      
	      else{
		diff>>tag;
	      }
	      
	      int hjk  = query.index("<START");
	      cout<<"index of hjk: "<<hjk<<endl;
	      query=query.at(0, hjk);
	     
	      cout<<"the actual query: "<<query<<endl;
	      
	      cout<<"start pos: "<<start<<" rows per page: "<<numRows<<endl;
	      
	     
	      Table result;


	      String qur(query);
	      
	     
	      
	      if(word=="SELECT"&&word2=="FROM"&&(!qur.contains("WHERE"))){
		
		
		result=Table(name);
		
	      }
	      else{
		
		result = tableCommand(query); 
	      }

	      // //cout<<"words : "<<word<<" "<<word2<<" "<<name<<endl;
	      
// 	      //if(word=="SELECT"&&word2=="FROM"){
		
		
// 		result=Table(name);
		
// 		// }
// 		// else{
		
// 		result = tableCommand(query); 
// 		// }
	      
	      
	      
	      totalNumRows=result.nrow();
	      int startIndex;
	      if (start<0)
		startIndex=0;
	      else{
		startIndex=start;
	      }
	      int endIndex;
	      
	      if(start+numRows<(int)result.nrow())
		endIndex=start+numRows;
	      
	      else if(numRows==0){
		endIndex = result.nrow();
	      }
	      else{
		endIndex = result.nrow();
	      }
	      cout<<"startindex: "<<startIndex<<" endIndex "<<endIndex<<endl;
	      String hits;
	      if(endIndex<=startIndex){
		throw(AipsError("EMPTY"));
		
	      }
	      
	      
	      
	      
	      Bool cinsRowOk= result.canAddRow();
	      Bool cdelRowOk = result.canRemoveRow();
	      
	      TableRecord trec = result.keywordSet();
	      //   cout<<"# of fields in keywordset: "<<trec.nfields()<<endl;
	      
	      
	      keywords= createKeyword(trec, -1);
	      
	      //  cout<<endl<<endl<<"Keywords: "<<endl<<keywords<<endl;
	      
	      
	      ROTableRow row(result);
	      Vector<String> colNames = row.columnNames();
	      void **fieldPtrs = (void **)new uInt*[colNames.nelements()];
	      
	      ostringstream oss;
	      Vector<String> dataTypes(30);
	      
	      {
		// String columnkw = "<COLUMNKEYWORDS>\n";
		String columnkw="none";
		TableDesc tdesc= result.tableDesc();
		if(colNames.nelements()>0){
		  columnkw="";
		}
		for(int i=0;i<Int(colNames.nelements());i++){
		  //  cerr<<"entering for 1"<<endl;
		  
		  ColumnDesc cdesc = tdesc.columnDesc((uInt)i);
		  //columnkw+="<COLUMN num = "+ String::toString(i)+" >\n";
		  TableRecord ctrec = cdesc.keywordSet();
		  String tempkw="";
		  
		  tempkw = createKeyword(ctrec,i);
	      
		 
		  if(tempkw!="none"){
		    columnkw+=tempkw;
		  }
		  else{
		    cout<<"column keyword is null"<<endl;
		    columnkw+=" ";
		  }
	      
		  
		  switch(row.record().type(row.record().fieldNumber(colNames(i)))){
		  case TpString :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<String>(row.record(), colNames(i));
		    
		    dataTypes[i]="TpString";
		    
		    
		    
		    
		    break;
		    
		  case TpInt :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Int>(row.record(), colNames(i));
		    dataTypes[i]="TpInt";
		    
		    break;
		    
		  case TpFloat :
		    fieldPtrs[i] =  (void *)
		      new RORecordFieldPtr<Float>(row.record(), colNames(i));
		    dataTypes[i]="TpFloat";
		    break;
		    
		  case TpDouble :
		    {
                      fieldPtrs[i] =
			new RORecordFieldPtr<Double>(row.record(), colNames(i));	  
		      TableDesc td = result.tableDesc();
		      ColumnDesc cd = td[i];
		      String com = cd.comment();
		      cerr<<endl<<"+++++++++++++++++++++"<<endl;
		      cerr<<"double comment: "<<com<<endl;
		      if(com=="Modified Julian Day"){
			cerr<<"its a date"<<endl;
			dataTypes[i]="TpDate";
		      }
		      else{
			dataTypes[i]="TpDouble";
		      }
                      break;
		    }
		  case TpBool :
		    fieldPtrs[i] =  (void *)
		      new RORecordFieldPtr<Bool>(row.record(), colNames(i));
		    dataTypes[i]="TpBool";
		    
		    break;
		    
		  case TpUChar :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<uChar>(row.record(), colNames(i));
		    dataTypes[i]="TpUChar";
		    break;
		    
		  case TpShort :
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Short>(row.record(), colNames(i));
		    dataTypes[i]="TpShort";
		    break;
		    
		  case TpUInt :
		    fieldPtrs[i] = 
		      new RORecordFieldPtr<uInt>(row.record(), colNames(i));
		    dataTypes[i]="TpUInt";
		    break;
		    
		  case TpComplex :
		    fieldPtrs[i] = 
		      new RORecordFieldPtr<Complex>(row.record(), colNames(i)); 
		    dataTypes[i]="TpComplex";
		    break;
		    
		  case TpDComplex :
		    fieldPtrs[i] = 
		      new RORecordFieldPtr<DComplex>(row.record(), colNames(i));
		    dataTypes[i]="TpDComplex";
                    break;
		    
		  case TpArrayDouble :
		  
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Double> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayDouble";
		    break;
		    
		  case TpArrayBool :
		    
		    fieldPtrs[i] =
		    new RORecordFieldPtr<Array<Bool> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayBool";
		    break;
		    
		    
		  case TpArrayChar :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Char> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayChar";
		    break;

		    
		  case TpArrayUChar :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<uChar> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayUChar";
		    break;
		    
		case TpArrayShort :
		  
		  fieldPtrs[i] =
		    new RORecordFieldPtr<Array<Short> >(row.record(), colNames(i));
		  dataTypes[i]="TpArrayShort";
		  break;
		  
		  // 	case TpArrayUShort :
		  
// 		  fieldPtrs[i] =
// 		    new RORecordFieldPtr<Array<uShort> >(row.record(), colNames(i));
// 		  dataTypes[i]="TpArrayUShort";
// 		  break;
		  
		  case TpArrayInt :
		  
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Int> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayInt";
		    break;
		    
		  case TpArrayUInt :
		    
		  fieldPtrs[i] =
		    new RORecordFieldPtr<Array<uInt> >(row.record(), colNames(i));
		  dataTypes[i]="TpArrayUInt";
		  break;
		  
		  case TpArrayFloat :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Float> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayFloat";
		    break;
		    
		    
		  case TpArrayComplex :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<Complex> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayComplex";
		    break;
		    
		    
		  case TpArrayDComplex :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<DComplex> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayDComplex";
		    break;
		    
		  case TpArrayString :
		    
		    fieldPtrs[i] =
		      new RORecordFieldPtr<Array<String> >(row.record(), colNames(i));
		    dataTypes[i]="TpArrayString";
		    break;
		    
		  default:
		    cout<<"unknown type: "<<row.record().type(row.record().fieldNumber(colNames(i)))<<endl;
		    throw(AipsError("atabd: unexpected type, this should never happen"));
		    break;
		  }
		  
	   
		}

	     

		//   ostrstream oss;
		
		
		cout<<"getting entries from "<<start<<" to "<<start+numRows<<endl;

	      
	       
	       
	      
		for(int i=startIndex;i<endIndex;i++){
		  // cerr<<"entering for 2"<<endl;
		  
		  row.get(i);
		  oss<<"<TR>"<<endl;
		  for(int j=0;j<Int(colNames.nelements());j++){
		    
		    switch(row.record().type(j)){
		    case TpString :
		      
		      oss << "<TD> "<<**((RORecordFieldPtr<String> *)fieldPtrs[j])<<" </TD>";
		      break;
		    case TpFloat :
		      
		      oss << "<TD> "<< **((RORecordFieldPtr<Float> *)fieldPtrs[j])<<" </TD>";
		      break;
		    case TpInt :
		      
		      oss << "<TD> "<< **((RORecordFieldPtr<Int> *)fieldPtrs[j])<<" </TD>";
		      break;
		    case TpDouble :
		      {
			
			TableDesc td = result.tableDesc();
			ColumnDesc cd = td[j];
			String com = cd.comment();
			
			
			if(com=="Modified Julian Day"){
			  
			  double days = (**((RORecordFieldPtr<Double> *)fieldPtrs[j]))/86400+2400000.5;
			  
			  Time t(days);
			  String tstring;
			  tstring+=String::toString(t.year())+"-";
			  tstring+=String::toString(t.month())+"-";
			  tstring+=String::toString(t.dayOfMonth())+"-";
			  tstring+=String::toString(t.hours())+":";
			  tstring+=String::toString(t.minutes())+":";
			  tstring+=String::toString(t.seconds());
			  
			    //cerr<<"thee time is: "<<tstring<<endl;
			    
			    oss <<  "<TD> "<<tstring<<" </TD>";
			    
			  }
			else{
			  oss <<  "<TD> "<<**((RORecordFieldPtr<Double> *)fieldPtrs[j])<<" </TD>";
			  }
			  
                         break;
			}
                      case TpBool :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<Bool> *)fieldPtrs[j])<<" </TD>";
                         break;
                      case TpUChar :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<uChar> *)fieldPtrs[j])<<" </TD>";
                         break;
                      case TpShort :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<Short> *)fieldPtrs[j])<<" </TD>";
                         break;
                      case TpUInt :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<uInt> *)fieldPtrs[j])<<" </TD>";
                         break;
                      case TpComplex :
			
                         oss << "<TD> "<< **((RORecordFieldPtr<Complex> *)fieldPtrs[j])<<" </TD>";
                         break;
		   case TpDComplex :

		     oss << "<TD> "<< **((RORecordFieldPtr<DComplex> *)fieldPtrs[j])<<" </TD>";
                         break;
			 
		   case TpArrayDouble :
		     {
		     
		      		       
		       oss << "<TD> "<< **((RORecordFieldPtr<Array<Double> > *)fieldPtrs[j])<<" </TD>";
		       
		       break;
		     }
		     
		     
		     
		      case TpArrayBool :
		     
			
			{
			  
			  oss << "<TD> "<< **((RORecordFieldPtr<Array<Bool> > *)fieldPtrs[j])<<" </TD>";
			  break;
			}
		   case TpArrayChar :
		     	{
			  oss << "<TD> "<< **((RORecordFieldPtr<Array<Char> > *)fieldPtrs[j])<<" </TD>";
			  break;
			}
		

		      case TpArrayUChar :
		     
			{
				  oss << "<TD> "<< **((RORecordFieldPtr<Array<uChar> > *)fieldPtrs[j])<<" </TD>";
			  break;
			}


		     case TpArrayShort :
		     
		       {

			 oss << "<TD> "<< **((RORecordFieldPtr<Array<Short> > *)fieldPtrs[j])<<" </TD>";
		
			 break;
		       }

		      
		   
		   case TpArrayInt :
		     {

		       oss << "<TD> "<< **((RORecordFieldPtr<Array<Int> > *)fieldPtrs[j])<<" </TD>";
	
		       break;
		     }

		  
		     
		   case TpArrayUInt :
		     {
		        oss << "<TD> "<< **((RORecordFieldPtr<Array<uInt> > *)fieldPtrs[j])<<" </TD>";
		       break;
		     }
		    

		   case TpArrayFloat :
		     
		     {
		       oss << "<TD> "<< **((RORecordFieldPtr<Array<Float> > *)fieldPtrs[j])<<" </TD>";
		     
		       break;
		     }

		   case TpArrayComplex :
		     {

		       oss << "<TD> "<< **((RORecordFieldPtr<Array<Complex> > *)fieldPtrs[j])<<" </TD>";
		     
		       break;
		     }
		    
		   case TpArrayDComplex :
		     {
		       oss << "<TD> "<< **((RORecordFieldPtr<Array<DComplex> > *)fieldPtrs[j])<<" </TD>";
		     

		   
		       break;
		     }
		    
		   case TpArrayString :
		     {
		       oss << "<TD> "<< **((RORecordFieldPtr<Array<DComplex> > *)fieldPtrs[j])<<" </TD>";
		     

		      
		       break;
		     }

		   default:
		     throw(AipsError("atabd: unexpected type, this should never happen:"));
		     
		         break;
                   }
                   oss << " ";
		  }
                oss <<endl<< "</TR>"<<endl;
		}
	       
	     
             


             hits = oss.str();
	     
	     hits=createVOTab(result.tableName(),totalNumRows ,colNames, dataTypes, hits, keywords, cinsRowOk, cdelRowOk, columnkw);
	     
	     
	  
      
	     
	      
	    
	     //	     cout << "Hits: " << hits << endl;

	     int length = htonl(hits.length());
	     //length = length/65000+1;
	     
	     //cerr<<"numtimes = "<<length<<endl;
	     //  cout<<"char at 154048: "<<hits[154048]<<endl;
	     stringstream converter;
	     converter<<length;
	     string strlength;
	     converter>>strlength;
	     
	     

	     String slen = strlength+"\n";
	     
	     //  cerr <<"slen of string = "<<slen<<endl;
	     
	     if(SendData(sock, (char *)&length, sizeof(int)) == -1){
	       printf("Error sending data1\n");
	       break;
             } 


	     if(SendData(sock, (char *)hits.chars(), hits.length()) == -1){
	       printf("Error sending data2\n");
	       break;
             }    

             if(SendData(sock, "thats.all.folks\n", 16) == -1){
	       printf("Error sending data3\n");
	       break;
             }
             {
             for(int j=0;j<Int(colNames.nelements());j++){
                   switch(row.record().type(j)){
                      case TpString :
                         delete (RORecordFieldPtr<String> *)fieldPtrs[j];
                         break;
                      case TpFloat :
                         delete (RORecordFieldPtr<Float> *)fieldPtrs[j];
                         break;
                      case TpInt :
                         delete (RORecordFieldPtr<Int> *)fieldPtrs[j];
                         break;
                      case TpDouble :
                         delete (RORecordFieldPtr<Double> *)fieldPtrs[j];
                         break;
                      case TpBool :
                         delete (RORecordFieldPtr<Bool> *)fieldPtrs[j];
                         break;
                      case TpUChar :
                         delete (RORecordFieldPtr<uChar> *)fieldPtrs[j];
                         break;
                      case TpShort :
                         delete (RORecordFieldPtr<Short> *)fieldPtrs[j];
                         break;
                      case TpUInt :
                         delete (RORecordFieldPtr<uInt> *)fieldPtrs[j];
                         break;
                      case TpComplex :
                         delete (RORecordFieldPtr<Complex> *)fieldPtrs[j];
                         break;
                      case TpDComplex :
                         delete (RORecordFieldPtr<DComplex> *)fieldPtrs[j];
                         break;
		   case TpArrayDouble :
		     delete (RORecordFieldPtr<Array<Double> > *)fieldPtrs[j];
		     break;
		  

		   case TpArrayBool   :
		     delete (RORecordFieldPtr<Array<Bool> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayChar :
		     delete (RORecordFieldPtr<Array<Char> > *)fieldPtrs[j];
		     break;

		   case TpArrayUChar :
		     delete (RORecordFieldPtr<Array<uChar> > *)fieldPtrs[j];
		     break;

		  //  case TpArrayUShort :
// 		     delete (RORecordFieldPtr<Array<uShort> > *)fieldPtrs[j];
// 		     break;
		     
		   case TpArrayShort :
		     delete (RORecordFieldPtr<Array<Short> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayInt :
		     delete (RORecordFieldPtr<Array<Int> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayUInt :
		     delete (RORecordFieldPtr<Array<uInt> > *)fieldPtrs[j];
		     break;
		      
		     
		   case TpArrayFloat :
		     delete (RORecordFieldPtr<Array<Float> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayComplex :
		     delete (RORecordFieldPtr<Array<Complex> > *)fieldPtrs[j];
		     break;
		     
		   case TpArrayDComplex :
		     delete (RORecordFieldPtr<Array<DComplex> > *)fieldPtrs[j];
		     break;

		   case TpArrayString :
		     delete (RORecordFieldPtr<Array<String> > *)fieldPtrs[j];
		     break;
		     
		     
		     
		      default:
			throw(AipsError("atabd: unexpected type, this should never happen" ));
			
			break;
                   }
             }
             }
             result.~Table();
             delete [] fieldPtrs;
	      }



	    }

	  }
     
	  catch (AipsError x) {
             ostringstream oss;
             oss << "AipsError: ta" << x.getMesg() << endl;
             String hits = oss.str();
	     
	     int length = htonl(hits.length());

	   	   
	    
	     if(SendData(sock, (char *)&length, sizeof(int)) == -1){
	       printf("Error sending data7\n");
	       break;
             } 

             if(SendData(sock, (char *)hits.chars(), hits.length()) == -1){
                printf("Error sending data4\n");
                break;
             }
             if(SendData(sock, "thats.all.folks\n", 16) == -1){
                printf("Error sending data5\n");
                break;
             }      
             cerr << "AipsError thrown : ta" << x.getMesg() << endl;
          } 
          close(sock);
      }
   }
   return 0;
}

int setupNet ( int *r_sock)
{
   int l_sock;
#if defined(AIPS_LINUX)
   unsigned int len;
#else
   int len;
#endif
   struct sockaddr_in  me, them;
   int e_status = 0;
 
   char ErrorMessage[81];
 
   if ( (l_sock = socket(AF_INET, SOCK_STREAM, 0)) > 0 ) {
 
      me.sin_family = AF_INET;
      me.sin_addr.s_addr = INADDR_ANY;
      me.sin_port = htons(7007);              
 
 
      len = sizeof(me);
      if (bind(l_sock, (sockaddr *)&me, sizeof(me)) >= 0) {
         if (getsockname(l_sock, (sockaddr *)&me, &len) >= 0) {
            listen(l_sock,5);              /* tell system to accept
                                              connections for us */
 
   /* wait for someone to contact us */
  
            while(1){
               len = sizeof(them);
               *r_sock = accept(l_sock, (sockaddr *)&them, &len);
               if (*r_sock != -1) {
                  e_status = 0;
                  int pid = fork();
                  if(pid == 0){
                     close(l_sock);
                     break;
                  }
                  int statusp;
                  waitpid(pid, &statusp, 0);
                  close(*r_sock);
               } else{
                  e_status = 1;
                  strcpy(ErrorMessage, "error on accept call");
                  break;
               }
            }
         }
         else{
            e_status = 1;
            strcpy (ErrorMessage, "error in getting socket name");
         }
      }
      else{
         e_status = 1;
         strcpy(ErrorMessage, "error in binding socket to a port");
      }
   }
   else{
      e_status = 1;
      strcpy(ErrorMessage, "error in creating socket");
   }
   if(e_status)
     perror(ErrorMessage);
   return(e_status);
}

int SendData(int sock, char *theData, int DataSize)
{
   int r_status(0);
 
   int NumRecords(DataSize/PacketSize);
   if(DataSize%PacketSize)
      NumRecords++;
   for(int i=0;i<NumRecords;i++){
      int SendBytes = (i == NumRecords-1) ? DataSize%PacketSize : PacketSize;
      r_status = writen(sock, theData+i*PacketSize, SendBytes);
      //  cerr<<"sent: "<<SendBytes<<endl;
      // cerr<<"r_status: "<<r_status<<endl;
   }
 
   return(r_status);
}



int readn(int fd, char *ptr, int nbytes)
{
   int nleft(nbytes);
   while(nleft > 0){
      int nread = read(fd, ptr, nleft);
      if(nread < 0)
         return(nread);
      else if(nread == 0)
         break;
      nleft -= nread;
      ptr += nread;
   }
   return(nbytes - nleft);
}

int writen(int fd, char *ptr, int nbytes)
{
   int nleft(nbytes);
   while(nleft > 0){
      int nwrite = write(fd, ptr, nleft);
      if(nwrite < 0)
         return(nwrite);
      nleft -= nwrite;
      ptr += nwrite;
   }
   return(nbytes - nleft);
}

String createVOTab(String tablename, int totalrows, Vector<String> colnames, Vector<String> datatype, String records, String keyword, Bool insRowOk, Bool delRowOk, String columnkeywords ){
  String insRow;
  String delRow;
  if(insRowOk)
    insRow="true";
  else
    insRow="false";
  
  if(delRowOk)
    delRow="true";
  else
    delRow="false";
  
  
  String head= "<?xml version=\"1.0\"?>\n";
  head+="<!DOCTYPE VOTABLE SYSTEM \"http://us-vo.org/xml/VOTable.dtd\">\n";
  head+="<VOTABLE version=\"1.0\">\n<RESOURCE>\n<TABLE name=\"";
  head+=tablename;
  head+="\" />\n";
  head+="<TOTAL row = "+String::toString(totalrows)+" />\n";
  

  for (int i=0; i<(int)colnames.nelements();i++){
    
    head+="<FIELD name=\"";
    head+=colnames[i];
    head+="\" ucd=\"\" ref=\"\" unit=\"\" datatype=\"";
    head+=datatype[i];
    head+="\" precision=\"\" width=\"\"/>\n";
    
  }
  if(keyword!="none"){
    head+=keyword;
  }
  else{
    cout<<"keyword is null"<<endl;
  }
  
  if(columnkeywords!="none"){

    head+=columnkeywords;
  }

  else{
    cout<<"no column keywords"<<endl;
  }
  head+="<RWINFO insertRow = "+ insRow+ " removeRow = "+delRow+ " />\n";
  head+="<DATA>\n<TABLEDATA>\n";
  head+=records;
  head+="</TABLEDATA>\n</DATA>\n</TABLE>\n</RESOURCE>\n</VOTABLE>";
  
  return head;   


}


String createKeyword(TableRecord trec, int a){
  cout<<"method create keyword called"<<endl;
  stringstream kwordstream;
  String keywords="none";
  bool ent=false;


  for(Int g=0;g<(Int)trec.nfields();g++){
    if(a<0){
      kwordstream<<"<KEYWORD";
    }
    
    else{

      kwordstream<<"<COLUMNKW col = "<<String::toString(a)<<" ";
    }
    RecordFieldId rfid(g);
    if(trec.type(g)==TpFloat){
      float c =trec.asFloat(rfid);
      // cout<<"key type float"<<endl;
      kwordstream<<" type = \"TpFloat\"";
      kwordstream<<" name = \""<< trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<<c<<"\"";
      ent=true;
      
      
    }
    
    else if(trec.type(g)==TpTable){
      //	 cout<<"key type table"<<endl;
      Table t = trec.asTable(rfid);
      String c = t.tableName();
      kwordstream<<" type = \"TpTable\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }
    
    else if(trec.type(g)==TpInt){
      
      cerr<<"keyword type: int"<<endl;
      int c = trec.asInt(rfid);
      kwordstream<<" type = \"TpInt\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }
    
    else if(trec.type(g)==TpBool){
      
      cerr<<"keyword type: bool"<<endl;
      bool c = trec.asBool(rfid);
      kwordstream<<" type = \"TpBool\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }       
    else if(trec.type(g)==TpChar){
      
      cerr<<"keyword type: char not supported"<<endl;
      // char c = trec.asChar(rfid);
      kwordstream<<" type = \"TpChar\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< "not supported"<<"\"";
      ent=true;
    }      
    else if(trec.type(g)==TpUChar){
      
      cerr<<"keyword type: uchar"<<endl;
      
      kwordstream<<" type = \"TpUChar\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< "uchar"<<"\"";
      ent=true;
    }      
    
    else if(trec.type(g)==TpShort){
      
      cerr<<"keyword type: short"<<endl;
      short c = trec.asShort(rfid);
      kwordstream<<" type = \"TpShort\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }      
    
    else if(trec.type(g)==TpUInt){
      
      cerr<<"keyword type: uInt"<<endl;
      uInt c = trec.asuInt(rfid);
      kwordstream<<" type = \"TpUInt\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }      
    else if(trec.type(g)==TpDouble){
      
      cerr<<"keyword type: Double"<<endl;
      double c = trec.asDouble(rfid);
      kwordstream<<" type = \"TpDouble\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }      
    else if(trec.type(g)==TpComplex){
      
      cerr<<"keyword type: Complex not supported"<<endl;
      
      Complex c = trec.asComplex(rfid);
      kwordstream<<" type = \"TpDouble\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }      
    else if(trec.type(g)==TpDComplex){
      
      cerr<<"keyword type: DComplex not supported"<<endl;
      DComplex c = trec.asDComplex(rfid);
      kwordstream<<" type = \"TpDouble\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<<c<<"\"";
      ent=true;
    }  
    
    else if(trec.type(g)==TpString){
      
      cerr<<"keyword type: String"<<endl;
      String c = trec.asString(rfid);
      kwordstream<<" type = \"TpString\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }      
    else if(trec.type(g)==TpArrayBool){
      
      cerr<<"keyword type: ArrayBool"<<endl;
      Array<Bool> c = trec.asArrayBool(rfid);
      kwordstream<<" type = \"TpArrayBool\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }     

    else if(trec.type(g)==TpArrayUChar){
      
      cerr<<"keyword type: ArrayUChar"<<endl;
      Array<uChar> c = trec.asArrayuChar(rfid);
      kwordstream<<" type = \"TpArrayUChar\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< "array uchar"<<"\"";
      ent=true; 
    }     
    
    else if(trec.type(g)==TpArrayShort){
      
      cerr<<"keyword type: ArrayShort"<<endl;
      Array<Short> c = trec.asArrayShort(rfid);
      kwordstream<<" type = \"TpArrayShort\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }    
    
    else if(trec.type(g)==TpArrayInt){
      
      cerr<<"keyword type: ArrayInt"<<endl;
      Array<Int> c = trec.asArrayInt(rfid);
      cerr<<c;
      kwordstream<<" type = \"TpArrayInt\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }     
    else if(trec.type(g)==TpArrayUInt){
      
      cerr<<"keyword type: ArrayUInt"<<endl;
      Array<uInt> c = trec.asArrayuInt(rfid);
      kwordstream<<" type = \"TpArrayUInt\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }    
    
    else if(trec.type(g)==TpArrayFloat){
      
      cerr<<"keyword type: ArrayFloat"<<endl;
      Array<Float> c = trec.asArrayFloat(rfid);
      kwordstream<<" type = \"TpArrayFloat\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }   
    
    else if(trec.type(g)==TpArrayDouble){
      
      cerr<<"keyword type: ArrayDouble"<<endl;
      Array<Double> c = trec.asArrayDouble(rfid);
      kwordstream<<" type = \"TpArrayDouble\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<< c<<"\"";
      ent=true;
    }  
    else if(trec.type(g)==TpArrayComplex){
      
      cerr<<"keyword type: ArrayComplex not supported"<<endl;
      Array<Complex> c = trec.asArrayComplex(rfid);
      kwordstream<<" type = \"TpArrayComplex\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<<c<<"\"";
      ent=true;
    }  
    else if(trec.type(g)==TpArrayDComplex){
      
      cerr<<"keyword type: ArrayDComplex not supported"<<endl;
      Array<DComplex> c = trec.asArrayDComplex(rfid);
      kwordstream<<" type = \"TpArrayDComplex\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<<c<<"\"";
      ent=true;
    }  
    else if(trec.type(g)==TpArrayString){
      
      cerr<<"keyword type: ArrayString"<<endl;
      Array<String> c = trec.asArrayString(rfid);
      cerr<<c;
      kwordstream<<" type = \"TpArrayString\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \""<<c<<"\"";
      ent=true;
    }  
    
    else if(trec.type(g)==TpRecord){
      
      cerr<<"keyword type: TpRecord"<<endl;
      
      kwordstream<<" type = \"TpRecord\"";
      kwordstream<<" name = \""<<trec.name(rfid)<<"\"";
      kwordstream<<" val = \" { ";
      for(Int ijk = 0 ; ijk< (Int)trec.nfields();ijk++){
	RecordFieldId fid(ijk);
	DataType tp = trec.dataType(fid);
	cerr<<"the record's type is "<<tp<<endl;
	
	if(tp==TpBool){
	  
	  kwordstream<<"boolean ";
	}
	

	else if(tp==TpArrayString){
	  kwordstream<<"stringArray ";
	}
	
	else if(tp==TpRecord){
	  kwordstream<<"record ";
	
	}
	
      }

      kwordstream<<"}\"";
      
      

      
    
      
      ent=true;
      
    }
    else{
      
      cerr<<"===============WARNING====================="<<endl;
      cerr<<"Keyword type not supported: "<<trec.type(g)<<endl;
    }
    
    kwordstream<<" />"<<endl;
    
  }
  if(ent){
    keywords= kwordstream.str();
  }
  cout<<"returning keywords: "<<endl<<keywords<<endl;
  
  return keywords;
}
