//# e2echromepipe.cc
//#		a Glish client to accept data on a socket and forward that
//#		data to Glish as a Glish Record.
//#
//# Time-stamp: <2002-04-05 02:20:59 bwaters>
//
//# Copyright (C) 2002
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

// from wyoung's atabd in code/nrao/atabd
// help from drs! Thanks Darrell!
//
// more sockets-avoiding-zombies help from sample code by
// Ting-jen Yen (yentj@cs.nyu.edu)
// http://www.cs.nyu.edu/~yap/classes/visual/01f/lect/l7/l_server.c.html

// TODO:
// accept XML on the socket
// parse and convert to GlishRecord.


#include <stdio.h>
#include <netdb.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <sys/uio.h>
#include <unistd.h>
#include <malloc.h>
#include <string.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/RecordField.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Exceptions/Error.h>
#include "Glish/Client.h"
#include <casa/iostream.h>
#include <casa/sstream.h>
 

#include <casa/namespace.h>
//////////////////////////////////////////////////////// globals
//
const int BUF_SIZE(2048);
const int PacketSize(4096);
const int SRV_PORT(7003);
const int NUM_BACKLOGGED_ALLOWED(5);

int me_sock(0);
int them_sock(0);

//////////////////////////////////////////////////////// util. funcs
//

//
// cleanup is the signal handler that ensures sockets get closed
//
void cleanup( int signum ) {
  // the "signum" parameter is needed simply
  // to conform to the function signature of
  // a Unix signal handler.

  close(them_sock);
  close(me_sock);
  cout << "e2echromepipe closed.\n";

  exit(0);
}

//
// this code installs cleanup as the signal handler
//
inline void install_signal_handlers() {
  
  // intercept some signals that end this process, 
  // so we can close connections and whatnot before dying
  //
  signal( SIGTERM, cleanup );
  signal( SIGQUIT, cleanup );
  signal( SIGINT,  cleanup );
}

//
// a macro to select GlishEvents by name
//
inline bool evtName(GlishEvent *e,const char *what ) {
  return bool(!strcmp( e->name, what ));
}

inline void croak( const char*msg ) {
  cerr << msg << "\n";
  exit(1);
}

//////////////////////////////////////////////////////// fwd decls
//
Value* parsePost( char *cgi );
int readn(int fd, char *ptr, int nbytes);
int writen(int fd, char *ptr, int nbytes);
int setupNet();
int SendData(int sock, char *theData, int DataSize);


//////////////////////////////////////////////////////// main
//
int main(int argc, char **argv)
{
  install_signal_handlers();

  Client *client =
	( (argc > 1) && argv ) ?
	new Client(argc, argv) : NULL;

  // If a socket number has been passed to the Glish Client
  // as an argument, then use that number, otherwise use default.
  //
  // WARNING: This means that it's possible to pass ANY
  // socket number to this client -- note that socket numbers
  // lower than 1024 would require special permissions to bind!
  // 
  // Such socket freedom may be a SECURITY concern.

  int socket_port =
    argc ?
    atoi( argv[1] ) :
    SRV_PORT;

  cout << "Binding to socket " << socket_port << "... ";

  struct sockaddr_in  me, them;
  socklen_t len = sizeof(me);
 
  me_sock         = socket(AF_INET, SOCK_STREAM, 0);

  if( me_sock    <= 0){ croak("\nCouldn't create socket.");      }

  me.sin_family = AF_INET;
  me.sin_addr.s_addr = INADDR_ANY;
  me.sin_port = htons( socket_port );              
 
  int bind_result = bind(me_sock, (sockaddr *)&me, len);
  if( bind_result < 0){ croak("Couldn't bind socket to port.");}

  int name_result = getsockname(me_sock, (sockaddr *)&me, &len);
  if( name_result < 0){ croak("Couldn't find name of socket.") ;}

  // else report success!
  cout << "done!" << endl;

  listen(me_sock, NUM_BACKLOGGED_ALLOWED);
 
  /* wait for someone to contact us */
		
  while(1){
	    them_sock = accept(me_sock, (sockaddr *)&them, &len);
	if( them_sock==-1){ croak("Error on Accept call.") ;}
			
	//  HANDLE_REQUEST:
	{
	  char buff[BUF_SIZE];
	  int in_bytes;
	  
	  while( (in_bytes = readn(them_sock, buff, BUF_SIZE)) > 0){
		
		// null terminate things
		buff[in_bytes] = '\0';

		try {
		  if( client ) {
			cout << buff << endl;
			// parse the values into a Glish record
			Value* result = parsePost( buff );
			
			client->PostEvent("cgi",result);
			
			Unref( result );

			
			// now wait for Glish to tell us to do something
			// 
			// WARNING: this blocks. we MUST receive something
			// from Glish!
			//
			GlishEvent* e = client->NextEvent();

			// FORWARD THE XML BACK TO THE CGI

			Value *glishXML = e->value;

			// turn the value into a c string

			char *xml = glishXML->StringVal();
			int   len = strlen(xml);
				  
			cout << xml << endl;
			cout << e->name << endl;
			cout << glishXML->Type() << endl;
			cout << len << endl;

			// and send it back (ignoring errors)!
			  
			writen( them_sock, xml, len );

			// The Glish Manual says:
			// "The string returned is dynamically allocated and
			// should be delete'd when done with."

			delete xml;

		  }// end if client
		}
		catch (AipsError x) {
		  cerr << "AipsError thrown : " << x.getMesg() << endl;
		}
	  }
	}
	// HANDLE_REQUEST

	close(them_sock);
  }
  // end accept loop

  close(me_sock);

  return 0;
}
// end main
//
//
/////////////////////////////////

//////////////////////////////////////////////////////// util. funcs
//

// on entry:
// names, values are uninitialized
// cgi is a string containing mulitple lines of name/value pairs
// lines are delimited by CRLF ("\015\012" (octal; decimal 13,10))
// name=value
//
// Fri Apr  5 01:08:00 2002
// changed: if line is of form
// name=
// (that is, the value is not present)
// then we don't include the "pair" in the record
//
// returns a pointer to a Glish record.
// you should call UnRef on this ptr when done with it.
//

Value* parsePost( char *cgi ) {
  const int CR = '\r';	// carriage return
  const int LF = '\n';	// line feed

  Value* result = NULL;

  if( cgi ) {
	int  num_values = 0;

	// first pass: count the number of name-value pairs
	// by counting the number of (CR)LFs.
	for( char *str = cgi; *str; str++ )
	  if( *str == CR )
		if(*(++str) == LF)
		  num_values++;

	if( num_values ) {
	  try {
		result = create_record();

		if( result ) {
		  char *str = cgi;

		  for( int i = 0; i < num_values; i++ ) {
			char *name = str;
			char *value;

			while( *str ) {
			  if( *str == '=' ) {
				*str = 0;	// null-terminate the name string at the =
				str++;		// move past the =

				value = str;	// value starts at the first char past the =
			  }
			  else if( (*str == 13) && (*(str+1) == LF) ) {
				*str = 0;	// null-terminate the value string at the CR

				if( strlen(value) )
				  result->SetField( name, value );

				str++;		// move past the CR
				str++;		// move past the LF
				name = str; // point to the next name
			  }
			  else
				str++;

			}// end while
		  }// end for int i = 0; num_values
		}// end if result
	  }
	  catch (AipsError x) {
		cerr << "AipsError thrown : " << x.getMesg() << endl;
	  }

	}// end if num_values
  }// end if cgi

  return result;
}

//
// SendData
//
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

