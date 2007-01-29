//======================================================================
// sos/io.h
//
// $Id: io.h,v 19.1 2005/10/17 18:10:35 dschieb Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#ifndef sos_io_h_
#define sos_io_h_
#include "sos/header.h"
#include "sos/list.h"

#if defined(ENABLE_STR)
#include "sos/str.h"
#else
#if !defined(sos_str_h_)
typedef const char * const * const_charptr;
typedef const char* charptr;
#endif
#endif

typedef void (*final_func)(void*);

class sos_common {
    public:
	sos_common( ) : remote_version_( SOS_VERSION ) { }
	int remote_version( ) const { return remote_version_; }
	void set_remote_version( int v ) { if ( v <= SOS_VERSION ) remote_version_ = v; }
    protected:
        int remote_version_;
};

class sos_status GC_FINAL_CLASS {
    public:
	enum Type { WRITE, READ, UNKNOWN };

	sos_status( sos_common *c ) : common(c) { }

	virtual Type type() { return UNKNOWN; }
	virtual int fd() { return -1; }

	virtual unsigned int total() { return 0; }
	virtual unsigned int remaining() { return 0; }

	virtual void finalize( final_func, void * ) { }
	virtual sos_status *resume( ) { return 0; }

	int remote_version( ) const { return common ? common->remote_version() : SOS_VERSION; }
	void set_remote_version( int v ) { if ( common ) common->set_remote_version( v ); }

    protected:
	// In Glish, the presence of a null common indicates that
	// sos is being used to store values to disk.
	sos_common *common;
};

extern sos_status *sos_err_status;

class sos_sink : public sos_status {
    public:
	enum buffer_type { FREE, HOLD, COPY };
	sos_sink( sos_common *c ) : sos_status( c ) { }
	virtual sos_status *write( const unsigned char *, unsigned int, buffer_type type = HOLD ) = 0;
	sos_status *write( void *buf, unsigned int len, buffer_type type = HOLD )
			{ return write( (const unsigned char *) buf, len, type ); }
	virtual sos_status *flush( ) = 0;
	virtual ~sos_sink();
	Type type() { return WRITE; }
};

class sos_source : public sos_status {
    public:
	sos_source( sos_common *c ) : sos_status( c ) { }
	virtual unsigned int read( unsigned char *, unsigned int ) = 0;
	virtual ~sos_source();
	Type type() { return READ; }
};

struct sos_fd_buf_kernel;
sos_declare(PList,sos_fd_buf_kernel);
typedef PList(sos_fd_buf_kernel) sos_buf_list;

class sos_fd_buf GC_FINAL_CLASS {
    public:
	sos_fd_buf();
	~sos_fd_buf();

	// used in the "flush" phase
	sos_fd_buf_kernel *first( ) { return buf[0]; }
	sos_fd_buf_kernel *next( );

	// total number of bytes in the "first()" buffer
	unsigned int total();

	// used in the "write" phase
	sos_fd_buf_kernel *last( ) { return buf[buf.length()-1]; }

	// used to add a new buffer, once all of the
	// buckets are filled in the "last()" one
	sos_fd_buf_kernel *add( );

    private:
	sos_buf_list buf;
};

class sos_fd_sink : public sos_sink {
    public:
	sos_fd_sink( int fd_ = -1, sos_common *c=0 );
	sos_status *write( const unsigned char *, unsigned int, buffer_type type = HOLD );
	sos_status *flush( );

	void finalize( final_func, void * );
	sos_status *resume( ) { return flush(); }

	//
	// set fd state for blocking or nonblocking writes
	//
	void block( );
	void nonblock( );

	~sos_fd_sink();

	void setFd( int fd__ );
	int fd() { return fd_; }

	unsigned int total() { return buf.total(); }
	unsigned int remaining() { return buf.total() - sent; }

    private:
	void reset();
	// how much have we already sent
	unsigned int sent;
	// where to start writing
	unsigned int start;

	sos_fd_buf buf;

	int fd_;
};

class sos_fd_source : public sos_source {
    public:
	sos_fd_source( int fd__ = -1, sos_common *c=0 ) : sos_source(c), fd_(fd__) { }
	unsigned int read( unsigned char *, unsigned int );

	~sos_fd_source();

	void setFd( int fd__ ) { fd_ = fd__; }
	int fd() { return fd_; }
    private:
	int fd_;
};

class sos_out GC_FINAL_CLASS {
public:
	sos_out( sos_sink *out_ = 0, int integral_header = 0 );
	void set( sos_sink *out_ ) { out = out_; if ( out ) head.set_version(out->remote_version( )); }

	sos_status *put( byte *a, unsigned int l, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( byte *a, unsigned int l, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( short *a, unsigned int l, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( short *a, unsigned int l, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( int *a, unsigned int l, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( int *a, unsigned int l, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( float *a, unsigned int l, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( float *a, unsigned int l, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( double *a, unsigned int l, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( double *a, unsigned int l, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( char *a, unsigned int l, sos_code t, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( char *a, unsigned int l, sos_code t, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( unsigned char *a, unsigned int l, sos_code t, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( unsigned char *a, unsigned int l, sos_code t, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD );

	sos_status *put( charptr *cv, unsigned int l, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( charptr *cv, unsigned int l, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD );
	sos_status *put( char **cv, unsigned int l, sos_sink::buffer_type type = sos_sink::HOLD )
		{ return put( (charptr*)cv, l, type ); }
	sos_status *put( char **cv, unsigned int l, sos_header &h, sos_sink::buffer_type type = sos_sink::HOLD )
		{ return put( (charptr*)cv, l, h, type ); }

#if defined(ENABLE_STR)
	sos_status *put( const str & );
	sos_status *put( const str &, sos_header &h );
#endif

	sos_status *put_record_start( unsigned int l );
	sos_status *put_record_start( unsigned int l, sos_header &h );

	sos_status *write( const char *buf, unsigned int len, sos_sink::buffer_type type = sos_sink::HOLD )
		{ return out ? out->write( (const unsigned char*) buf, len, type ) : Error( NO_SINK ); }

	sos_status *flush( ) { return out ? out->flush( ) : Error( NO_SINK ); }

	~sos_out( );

	const struct timeval &get_stamp( ) { return initial_stamp; }
	void clear_stamp( ) { initial_stamp.tv_sec = 0; }

	int remote_version( ) const { return out ? out->remote_version() : SOS_VERSION; }

private:
	enum error_mode { NO_SINK };
	sos_status *Error( error_mode );
	char *not_integral;
	sos_header head;
	sos_sink *out;
	struct timeval initial_stamp;
};

class sos_in GC_FINAL_CLASS {
public:
	sos_in( sos_source *in_ = 0, int use_str_ = 0, int integral_header = 0 );
	void set( sos_source *in_ ) { in = in_; }

	void *get( unsigned int &length, sos_code &type );
	void *get( unsigned int &length, sos_code &type, sos_header &h );

	int read( unsigned char *buf, unsigned int len )
		{ return buffer_contents > 0 ? readback( buf, len ) : in ? in->read( buf, len ) : 0; }
	int read( char *buf, unsigned int len )
		{ return read( (unsigned char *) buf, len ); }

	void unread( unsigned char *buf, int len );

	~sos_in( );

private:
	enum error_mode { NO_SOURCE };
	sos_status *Error( error_mode );
	void *get_numeric( sos_code &, unsigned int & );
	void *get_string( unsigned int & );
	void *get_chars( unsigned int & );
	int readback( unsigned char *buf, unsigned int len );
	sos_header head;
	int use_str;
	int not_integral;
	sos_source *in;

	// Buffer used to "unread" bytes, needed for backward
	// compatibility after the header was enlarged (could
	// perhaps be removed when support for support for the
	// old version of SOS is no longer required).
	char *buffer;
	int buffer_length;
	int buffer_contents;
};

#endif
