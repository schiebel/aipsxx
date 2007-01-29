// $Id: Socket.h,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
#ifndef Socket_h
#define Socket_h

class Socket GC_FINAL_CLASS {
    public:
	// The first parameter, if true, specifies that the socket
	// will only be used locally (same host).  The second, if
	// present, means "the socket's already been created, here's
	// its fd".
	Socket( int is_local, int socket_fd = -1 );
	~Socket();

	int FD()	{ return fd; }
	int Port()	{ return port; }
	int IsLocal()	{ return is_local; }

    protected:
	void Gripe( char* msg );

	int fd;
	int port;
	int is_local;
	};

class AcceptSocket : public Socket {
    public:
	// The first parameter, if true, specifies that the socket
	// will only be used locally (same host).  The second gives
	// the port number at which to begin searching for a free
	// port.  If the third parameter is false, then the second
	// parameter is *not* a hint, but a requirement; if the
	// particular port is not available, then a subsequent call
	// to Port() will return 0 (and the AcceptSocket should be
	// deleted).
	AcceptSocket( int is_local = 0, int port_hint = 3000,
			int is_a_hint = 1 );

	Socket* Accept();
	};

#endif	/* Socket_h */
