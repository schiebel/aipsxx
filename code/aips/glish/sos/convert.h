//======================================================================
// header.h
//
// $Id: convert.h,v 19.0 2003/07/16 05:17:51 aips2adm Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#ifndef sos_convert_h
#define sos_convert_h

#include "longint.h"

//
//   31              23 22                                           0
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   |S|   EXP         |                 FRAC                        |
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//
//
class ieee_single {
    public:
	enum {BIAS=0x7f};

	ieee_single(float *f) : buf((unsigned int*)f) { }
	ieee_single &operator++() { buf++; return *this; }
	ieee_single &operator++(int) { buf++; return *this; }
	unsigned int sign() const { return ((*buf) & 0x80000000) >> 31; }
	void sign(unsigned int val) { *buf &= ~0x80000000; *buf |= 0x80000000 & val << 31; }
	unsigned int exp() const { return ((*buf) & 0x7f800000) >> 23; }
	void exp(unsigned int val) { *buf &= ~0x7f800000; *buf |= 0x7f800000 & val << 23; }
	unsigned int mantissa() const { return ((*buf) & 0x007fffff); }
	void mantissa(unsigned int val) { *buf &= ~0x007fffff; *buf |= 0x007fffff &val; }

	unsigned int maxExp() const { return 0xff; }
	unsigned int maxMantissa() const { return 0x7fffff; }

	float operator*() const { return *((float*)buf); }

    private:
	unsigned int *buf;
};

//
//   31                            16   14            7 6            0
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   |  FRAC(low)                    |S| EXP           | FRAC(high)  |
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//
//
class vax_single {
    public:
	enum {BIAS=0x81};

	vax_single(float *f) : buf((unsigned int*)f) { }
	vax_single &operator++() { buf++; return *this; }
	vax_single &operator++(int) { buf++; return *this; }
	unsigned int sign() const { return ((*buf) & 0x00008000) >> 15; }
	void sign(unsigned int val) { *buf &= ~0x00008000; *buf |= 0x00008000 & val << 15; }
	unsigned int exp() const { return ((*buf) & 0x00007f80) >> 7; }
	void exp(unsigned int val) { *buf &= ~0x00007f80; *buf |= 0x00007f80 & val << 7; }
	unsigned int mantissa() const { return ((*buf) & 0xffff0000) >> 16 | ((*buf) & 0x7f) << 16; }
	void mantissa(unsigned int val) { *buf &= ~0xffff007f; *buf |= (0x0000ffff & val) << 16 |
								       (0x007f0000 & val) >> 16; }
	unsigned int maxExp() const { return 0xff; }
	unsigned int maxMantissa() const { return 0x7fffff; }

	float operator*() const { return *((float*)buf); }

    private:
	unsigned int *buf;
};

//
//   64                                                             32
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   |                             FRAC2                             |
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   |S|        EXP          |           FRAC1                       |
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   31                    20 19                                     0
//
class ieee_double {
    public:
	enum {BIAS=0x3ff};

	ieee_double(double *d) : buf((unsigned int*)d) { }
	ieee_double &operator++() { ++buf; return *this; }
	ieee_double &operator++(int) { ++buf; return *this; }
	unsigned int sign() const { return (buf[0] & 0x80000000) >> 31; }
	void sign(unsigned int val) { buf[0] &= ~0x80000000; buf[0] |= 0x80000000 & val << 31; }
	unsigned int exp() const { return (buf[0] & 0x7ff00000) >> 20; }
	void exp(unsigned int val) { buf[0] &= ~0x7ff00000; buf[0] |= 0x7ff00000 & val << 20; }
	long_int mantissa() const { return long_int(buf[0] & 0x000fffff, buf[1]); }
	void mantissa(const long_int &val) { buf[0] &= ~0x000fffff; buf[0] |= 0x000fffff & val[1]; buf[1] = val[0]; }

	unsigned int maxExp() const { return 0x7ff; }
	long_int maxMantissa() const { return long_int( 0xfffff, 0xffffffff ); }

	double operator*() const { return *((double*)*buf); }

    private:
	long_int buf;
};

//
//   D floating point:
//
//   64                                                             32
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   |                             FRAC2  (lowest)                   |
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   |  FRAC(low)                    |S| EXP           | FRAC(high)  |
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   31                            16   14            7 6            0
//
//   G floating point:
//
//   64                                                             32
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   |                             FRAC2  (lowest)                   |
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   |  FRAC(low)                    |S| EXP                 |FRAC(h)|
//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//   31                            16   14                  4 3      0
//
//
//
class vax_double {
    public:
	enum {D_BIAS=0x81, G_BIAS=0x401};

	vax_double(double *f, char type='D' ) : exp_mask(type == 'D' ? 0x00007f80 : 0x00007ff0),
		exp_off(type == 'D' ? 7 : 4), exp_max(type == 'D' ? 0xff : 0x7ff),
		mantissa_mask(type == 'D' ? 0x7f : 0xf),
		mantissa_max(type == 'D' ? 0x7fffff : 0xfffff), buf((unsigned int*)f) { }
	vax_double &operator++() { ++buf; return *this; }
	vax_double &operator++(int) { ++buf; return *this; }

	unsigned int sign() const { return (buf[0] & 0x00008000) >> 15; }
	void sign(unsigned int val) { buf[0] &= ~0x00008000; buf[0] |= 0x00008000 & val << 15; }
	unsigned int exp() const { return (buf[0] & exp_mask) >> exp_off; }
	void exp(unsigned int val) { buf[0] &= ~exp_mask; buf[0] |= exp_mask & val << exp_off; }
	long_int mantissa() const { return long_int((buf[0] & 0xffff0000) >> 16 | (buf[0] & mantissa_mask) << 16,buf[1]); }
	void mantissa(const long_int &val) { buf[0] &= ~(0xffff0000 | mantissa_mask);
					     buf[0] |= (0x0000ffff & val[1]) << 16 | ((mantissa_mask << 16) & val[1]) >> 16;
					     buf[1] = val[0]; }
	unsigned int maxExp() const { return exp_max; }
	long_int maxMantissa() const { return long_int( mantissa_max, 0xffffffff ); }

	double operator*() const { return *((double*)*buf); }

    private:
	unsigned int exp_mask;
	int exp_off;
	unsigned int exp_max;
	unsigned int mantissa_mask;
	unsigned int mantissa_max;
	long_int buf;
};

extern float *vax2ieee_single(float *, unsigned int);
extern float *ieee2vax_single(float *, unsigned int);
extern double *vax2ieee_double(double *, unsigned int, char op = 'D');
extern double *ieee2vax_double(double *, unsigned int, char op = 'D');
extern char *swap_ab_ba(char *, unsigned int);
extern char *swap_abcd_dcba(char *, unsigned int);
extern char *swap_abcdefgh_hgfedcba(char *, unsigned int);
extern char *swap_abcdefgh_efghabcd(char *, unsigned int);

#endif
