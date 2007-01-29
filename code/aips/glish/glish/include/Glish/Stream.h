// $Id: Stream.h,v 19.0 2003/07/16 05:15:52 aips2adm Exp $
// Copyright (c) 1997 Associated Universities Inc.
//
#if !defined(stream_h_)
#define stream_h_
#include "Glish/Object.h"

class OStream : public GlishRef {
    public:

	virtual OStream &operator<<(float) = 0;
	virtual OStream &operator<<(double) = 0;

	virtual OStream &operator<<(int) = 0;
	virtual OStream &operator<<(long) = 0;
	virtual OStream &operator<<(short) = 0;
	virtual OStream &operator<<(char) = 0;

	virtual OStream &operator<<(unsigned int) = 0;
	virtual OStream &operator<<(unsigned long) = 0;
	virtual OStream &operator<<(unsigned short) = 0;
	virtual OStream &operator<<(unsigned char) = 0;

	virtual OStream &operator<<(void*) = 0;
	virtual OStream &operator<<(const char*) = 0;

	OStream &operator<<( OStream &(*f)(OStream&) );

	virtual OStream &flush( );

	// may or may not do anything... returns non-zero
	// if it actually does something.
	virtual int reset();
};

OStream &endl(OStream&);

class DBuf GC_FINAL_CLASS {
    public:
	DBuf(unsigned int size=1024);
	~DBuf();

	int put(float f, const char *format="%g");
	int put(double d, const char *format="%g");

	int put(int d, const char *format="%d");
	int put(long d, const char *format="%d");
	int put(short s, const char *format="%d");
	int put(char c, const char *format="%c");

	int put(unsigned int d, const char *format="%u");
	int put(unsigned long d, const char *format="%u");
	int put(unsigned char c, const char *format="%u");
	int put(unsigned short s, const char *format="%u");

	int put(void *v, const char *format="%x");
	int put(const char *s, const char *format="%s");

	unsigned int len() const { return len_; }
	unsigned int size() const { return size_; }
	const char *str() const { buf[len_] = '\0'; return buf; }
	char *str() { buf[len_] = '\0'; return buf; }
	void reset();
    private:
	static char *tmpbuf;
	char *buf;
	unsigned int size_;
	unsigned int len_;
};

class SOStream : public OStream {
    public:
	OStream &operator<<(float);
	OStream &operator<<(double);
	
	OStream &operator<<(int);
	OStream &operator<<(long);
	OStream &operator<<(short);
	OStream &operator<<(char);
	
	OStream &operator<<(unsigned int);
	OStream &operator<<(unsigned long);
	OStream &operator<<(unsigned short);
	OStream &operator<<(unsigned char);
	
	OStream &operator<<(void*);
	OStream &operator<<(const char*);

	int reset();

	const char *str() const { return buf.str(); }
	char *str() { return buf.str(); }
    private:
	DBuf buf;
};

#endif
