//# atabd.cc:  Table daemon for supplying table data.
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
//# $Id: atabd.cc,v 19.6 2005/06/22 05:22:19 gvandiep Exp $


#include <stdio.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <sys/uio.h>
#include <unistd.h>
#include <malloc.h>
#include <string.h>
#include <casa/BasicSL/String.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableParse.h>
#include <tables/Tables/TableRow.h>
#include <tables/Tables/ExprNode.h>
#include <casa/Containers/RecordField.h>
#include <casa/Arrays/Vector.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>
#include <casa/sstream.h>
 
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

int main(int argc, char *argv[])
{  int sock(0), bytesToRead(0);
   char buff[BUF_SIZE];
   String initQuery;
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
          try {
          if(initQuery == "send.table.query"){
             Table result = tableCommand(query);
             ROTableRow row(result);
             Vector<String> colNames = row.columnNames();
             void **fieldPtrs = (void **)new uInt*[colNames.nelements()];
//
             {
             for(int i=0;i<Int(colNames.nelements());i++){
                switch(row.record().type(row.record().fieldNumber(colNames(i)))){
                   case TpString :
                      fieldPtrs[i] =
                       new RORecordFieldPtr<String>(row.record(), colNames(i));
                      break;
                   case TpInt :
                      fieldPtrs[i] =
                       new RORecordFieldPtr<Int>(row.record(), colNames(i));
                      break;
                   case TpFloat :
                      fieldPtrs[i] =  (void *)
                       new RORecordFieldPtr<Float>(row.record(), colNames(i));
                      break;
                   case TpDouble :
                      fieldPtrs[i] =
                       new RORecordFieldPtr<Double>(row.record(), colNames(i));
                      break;
                   case TpBool :
                      fieldPtrs[i] =  (void *)
                       new RORecordFieldPtr<Bool>(row.record(), colNames(i));
                      break;
                   case TpUChar :
                      fieldPtrs[i] =
                       new RORecordFieldPtr<uChar>(row.record(), colNames(i));
                      break;
                   case TpShort :
                      fieldPtrs[i] =
                       new RORecordFieldPtr<Short>(row.record(), colNames(i));
                      break;
                   case TpUInt :
                      fieldPtrs[i] = 
                       new RORecordFieldPtr<uInt>(row.record(), colNames(i));
                      break;
                   case TpComplex :
                      fieldPtrs[i] = 
                       new RORecordFieldPtr<Complex>(row.record(), colNames(i));
                      break;
                   case TpDComplex :
                      fieldPtrs[i] = 
                       new RORecordFieldPtr<DComplex>(row.record(), colNames(i));
                      break;
		   default:
		      throw(AipsError("atabd: unexpected type, this should never happen"));
		      break;
                }
             }
             }
//
             ostringstream oss;
//
             {
             for(int i=0;i<Int(result.nrow());i++){
                row.get(i);
                for(int j=0;j<Int(colNames.nelements());j++){
                   switch(row.record().type(j)){
                      case TpString :
                         oss << **((RORecordFieldPtr<String> *)fieldPtrs[j]);
                         break;
                      case TpFloat :
                         oss << **((RORecordFieldPtr<Float> *)fieldPtrs[j]);
                         break;
                      case TpInt :
                         oss << **((RORecordFieldPtr<Int> *)fieldPtrs[j]);
                         break;
                      case TpDouble :
                         oss << **((RORecordFieldPtr<Double> *)fieldPtrs[j]);
                         break;
                      case TpBool :
                         oss << **((RORecordFieldPtr<Bool> *)fieldPtrs[j]);
                         break;
                      case TpUChar :
                         oss << **((RORecordFieldPtr<uChar> *)fieldPtrs[j]);
                         break;
                      case TpShort :
                         oss << **((RORecordFieldPtr<Short> *)fieldPtrs[j]);
                         break;
                      case TpUInt :
                         oss << **((RORecordFieldPtr<uInt> *)fieldPtrs[j]);
                         break;
                      case TpComplex :
                         oss << **((RORecordFieldPtr<Complex> *)fieldPtrs[j]);
                         break;
                      case TpDComplex :
                         oss << **((RORecordFieldPtr<DComplex> *)fieldPtrs[j]);
                         break;
		      default:
		         throw(AipsError("atabd: unexpected type, this should never happen"));
		         break;
                   }
                   oss << " ";
                }
                oss << endl;
             }
             }
             String hits = oss.str();
             // cerr << "Hits: " << hits << endl;
             if(SendData(sock, (char *)hits.chars(), hits.length()) == -1){
                printf("Error sending data\n");
                break;
             }
             if(SendData(sock, "thats.all.folks\n", 16) == -1){
                printf("Error sending data\n");
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
		      default:
		         throw(AipsError("atabd: unexpected type, this should never happen"));
		         break;
                   }
             }
             }
             result.~Table();
             delete [] fieldPtrs;
          }
          }catch (AipsError x) {
             ostringstream oss;
             oss << "AipsError: " << x.getMesg() << endl;
             String hits = oss.str();
             if(SendData(sock, (char *)hits.chars(), hits.length()) == -1){
                printf("Error sending data\n");
                break;
             }
             if(SendData(sock, "thats.all.folks\n", 16) == -1){
                printf("Error sending data\n");
                break;
             }      
             cerr << "AipsError thrown : " << x.getMesg() << endl;
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
      me.sin_port = htons(7002);              
 
 
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

