//======================================================================
// sos/header.h
//
// $Id: header.h,v 19.1 2004/07/13 22:37:02 dschieb Exp $
//
// Copyright (c) 1997,2000 Associated Universities Inc.
//
//======================================================================
#ifndef sos_header_h
#define sos_header_h
#include "sos/mdep.h"
#include "sos/alloc.h"

#define SOS_HEADER_0_SIZE	24
#define SOS_HEADER_1_SIZE	28
#define SOS_HEADER_2_SIZE	28
#define SOS_HEADER_SIZE		SOS_HEADER_2_SIZE
#define SOS_VERSION		2

struct sos_header_kernel GC_FINAL_CLASS {
	sos_header_kernel( void *b, unsigned int l, sos_code t, int freeit = 0,
			   int ver = SOS_VERSION ) : buf_((unsigned char*)b), off_(ver ? 0 : -4),
				type_(t), length_(l), count_(1), freeit_(freeit), version_(ver) { }
	unsigned int count() { return count_; }
	unsigned int ref() { return ++count_; }
	unsigned int unref() { return --count_; }

	~sos_header_kernel() { if ( freeit_ ) free_memory( buf_ ); }

	void set( void *b, unsigned int l, sos_code t, int freeit = 0 );
	void set( unsigned int l, sos_code t ) { type_ = t; length_ = l; }

	// SOS version of the remote receiver
	int version( ) const { return version_; }
	void set_version( unsigned char v ) { if ( v <= SOS_VERSION ) version_ = v; off_ = version_ ? 0 : -4; }
	void set_version_override( unsigned char v ) { version_ = v; off_ = version_ ? 0 : -4; }

	void set_length_override( unsigned int v ) { type_ = SOS_BYTE; length_ = v; }

	// What is the differential between the remote SOS header version
	// and the current SOS header version. This is needed for sending
	// legacy SOS headers to old clients.
	int offset( ) const { return off_; }

	unsigned char	*buf_;
	char		off_;
	sos_code	type_;
	unsigned int	length_;	// in units of type_
	unsigned int	count_;
	int		freeit_;
	unsigned char	version_;
};

//==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ====
//	sos (version #0) header structure
//							      offset
//		1 byte version number				0
//		1 byte architecture				1
//		1 byte type					2
//		1 byte type length				3
//		4 byte magic number				4
//		4 byte length					8
//		4 byte time stamp				12
//		2 byte future use				16
//		2 byte user data				18
//		4 byte user data				20
//
//==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ====
//	sos (version #1) header structure
//							      offset
//		1 byte version number				0
//		1 byte architecture				1
//		1 byte type					2
//		1 byte type length				3
//		4 byte magic number				4
//		4 byte length					8
//		4 byte time stamp				12
//		4 byte time stamp				16
//		2 byte future use				20
//		2 byte user data				22
//		4 byte user data				24
//
//	( should provide a way for user control info... )
//
class sos_header GC_FINAL_CLASS {
friend class sos_fd_sink;
public:
	//
	// information from the buffer
	//
	unsigned char version() const { return kernel->buf_[0]; }
	unsigned char arch() const { return kernel->buf_[1]; }
	sos_code type() const { return kernel->buf_[2]; }
	unsigned char typeLen() const { return kernel->buf_[3]; }
	unsigned int magic() const { return *((int*)&kernel->buf_[4]); }
	unsigned int length() const { return kernel->buf_[8] + (kernel->buf_[9] << 8) +
				      (kernel->buf_[10] << 16) + (kernel->buf_[11] << 24); }
	unsigned int time() const  { return kernel->buf_[12] + (kernel->buf_[13] << 8) +
				     (kernel->buf_[14] << 16) + (kernel->buf_[15] << 24); }
	unsigned int utime() const { return kernel->buf_[16] + (kernel->buf_[17] << 8) +
				     (kernel->buf_[18] << 16) + (kernel->buf_[19] << 24); }

	//
	// information "local" to the class
	//
	unsigned char *iBuffer() { return kernel->buf_; }
	unsigned int iLength() { return kernel->length_; }
	sos_code iType() { return kernel->type_; }

	//
	// update buffer information
	//
	void stamp( struct timeval &initial_stamp );
	void stamp( );

	//
	// reference count
	//
	unsigned int count( ) const { return kernel->count(); }

	//
	// constructors
	//
	sos_header( byte *a, unsigned int l, int freeit = 0, int ver = SOS_VERSION ) :
		kernel( new sos_header_kernel(a,l,SOS_BYTE,freeit,ver) ) { }
	sos_header( short *a, unsigned int l, int freeit = 0, int ver = SOS_VERSION ) :
		kernel( new sos_header_kernel(a,l,SOS_SHORT,freeit, ver) ) { }
	sos_header( int *a, unsigned int l, int freeit = 0, int ver = SOS_VERSION ) :
		kernel( new sos_header_kernel(a,l,SOS_INT,freeit,ver) ) { }
	sos_header( float *a, unsigned int l, int freeit = 0, int ver = SOS_VERSION ) :
		kernel( new sos_header_kernel(a,l,SOS_FLOAT,freeit,ver) ) { }
	sos_header( double *a, unsigned int l, int freeit = 0, int ver = SOS_VERSION ) :
		kernel( new sos_header_kernel(a,l,SOS_DOUBLE,freeit,ver) ) { }

	sos_header( ) : kernel( new sos_header_kernel(0,SOS_UNKNOWN,0,SOS_VERSION) ) { }
	sos_header( char *b, unsigned int l = 0, sos_code t = SOS_UNKNOWN, int freeit = 0, int ver = SOS_VERSION ) :
		kernel( new sos_header_kernel(b,l,t,freeit,ver) ) { }
	sos_header( unsigned char *b, unsigned int l = 0, sos_code t = SOS_UNKNOWN, int freeit = 0, int ver = SOS_VERSION ) :
		kernel( new sos_header_kernel(b,l,t,freeit,ver) ) { }

	sos_header( const sos_header &h ) : kernel( h.kernel ) { kernel->ref(); }

	//
	// assignment
	//
	sos_header &operator=( sos_header &h );

	//
	// change buffer
	//
	void set( byte *a, unsigned int l, int freeit = 0 );
	void set( short *a, unsigned int l, int freeit = 0 );
	void set( int *a, unsigned int l, int freeit = 0 );
	void set( float *a, unsigned int l, int freeit = 0 );
	void set( double *a, unsigned int l, int freeit = 0 );

	void set ( );
	void set( char *a, unsigned int l, sos_code t, int freeit = 0 );
	void set( unsigned char *a, unsigned int l, sos_code t, int freeit = 0 );
	void set( unsigned int l, sos_code t ) { kernel->set( l, t ); }

	// make sure we have a scratch buffer to write to.
	void scratch( );

	//
	// access to user data
	//
	unsigned char ugetc( int off = 0 ) const { return kernel->buf_[user_offset() + (off % 6)]; }
	unsigned short ugets( int off = 0 ) const { off = user_offset() + (off % 3) * 2;
			return kernel->buf_[off] + (kernel->buf_[off+1] << 8); }
	unsigned int ugeti( ) const { int off = user_offset() + 2;
			return kernel->buf_[off] + (kernel->buf_[off+1] << 8) +
				(kernel->buf_[off+2] << 16) + (kernel->buf_[off+3] << 24); }

	void usetc( unsigned char c, int off = 0 ) { kernel->buf_[user_offset() + (off % 6)] = c; }
	void usets( unsigned short s, int off = 0 ) { off = user_offset() + (off % 3) * 2;
			kernel->buf_[off] = s & 0xff; kernel->buf_[off+1] = (s >> 8) & 0xff; }
	void useti( unsigned int i );

	~sos_header( ) { if ( ! kernel->unref() ) delete kernel; }

// 	sos_header &operator=(void *b)
// 		{ buf = (unsigned char*) b; type_ = type(); length_ = length(); }

	static inline int size( int ver )
		{ const int s[3] = { SOS_HEADER_0_SIZE, SOS_HEADER_1_SIZE, SOS_HEADER_2_SIZE };
		  return s[ ver >= 0 && ver <= SOS_VERSION ? ver : SOS_VERSION ]; }
	int size( ) const { return size( kernel->version() ); }

	// where does user data start?
	int user_offset( ) const { return 22 + kernel->offset( ); }

	void set_version( unsigned char v ) { kernel->set_version( v ); }

private:
	void set_version_override( unsigned char v ) { kernel->set_version_override( v ); }
	void set_length_override( unsigned int v ) { kernel->set_length_override( v ); }

	friend class sos_in;
	void adjust_version( );
	sos_header_kernel *kernel;
};

#ifdef SOS_DEBUG
#include <iostream>
extern std::ostream &operator<< (std::ostream &, const sos_header &);
#endif

#endif
