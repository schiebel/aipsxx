//======================================================================
// convert.cc
//
// $Id: convert.cc,v 19.0 2003/07/16 05:17:48 aips2adm Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#include "sos/sos.h"
RCSID("@(#) $Id: convert.cc,v 19.0 2003/07/16 05:17:48 aips2adm Exp $")
#include "config.h"
#include "convert.h"

struct swap_ab_struct {
	char one;
	char two;
};

struct swap_abcd_struct {
	char one;
	char two;
	char three;
	char four;
};

struct swap_abcdefgh_struct {
	char  one;
	char  two;
	char  three;
	char  four;
	char  five;
	char  six;
	char  seven;
	char  eight;
};

char *swap_ab_ba(char *buffer, unsigned int len)
	{
	register struct swap_ab_struct *ptr = (swap_ab_struct *) buffer;
	for (register unsigned int i = 0; i < len; i++, ptr++)
		{
		register char tmp = ptr->one;
		ptr->one = ptr->two;
		ptr->two = tmp;
		}
	return buffer;
	}

char *swap_abcd_dcba(char *buffer, unsigned int len)
	{
	register struct swap_abcd_struct *ptr = (swap_abcd_struct *) buffer;
	for (register unsigned int i = 0; i < len; i++, ptr++)
		{
		register char tmp = ptr->one;
		ptr->one = ptr->four;
		ptr->four = tmp;
		tmp = ptr->two;
		ptr->two = ptr->three;
		ptr->three = tmp;
		}
	return buffer;
	}

char *swap_abcdefgh_hgfedcba(char *buffer, unsigned int len)
	{
	register struct swap_abcdefgh_struct *ptr = (swap_abcdefgh_struct *) buffer;
	for (register unsigned int i = 0; i < len; i++, ptr++)
		{
		register char tmp = ptr->one;
		ptr->one = ptr->eight;
		ptr->eight = tmp;
		tmp = ptr->two;
		ptr->two = ptr->seven;
		ptr->seven = tmp;
		tmp = ptr->three;
		ptr->three = ptr->six;
		ptr->six = tmp;
		tmp = ptr->four;
		ptr->four = ptr->five;
		ptr->five = tmp;
		}
	return buffer;
	}

char *swap_abcdefgh_efghabcd(char *buffer, unsigned int len)
	{
	register struct swap_abcdefgh_struct *ptr = (swap_abcdefgh_struct *) buffer;
	for (register unsigned int i = 0; i < len; i++, ptr++)
		{
		register char tmp = ptr->one;
		ptr->one = ptr->five;
		ptr->five = tmp;
		tmp = ptr->two;
		ptr->two = ptr->six;
		ptr->six = tmp;
		tmp = ptr->seven;
		ptr->three = ptr->seven;
		ptr->seven = tmp;
		tmp = ptr->four;
		ptr->four = ptr->eight;
		ptr->eight = tmp;
		}
	return buffer;
	}

float *vax2ieee_single(float *f, unsigned int len)
	{
	float tmp;
	ieee_single ieee(f);
	vax_single  vax(&tmp);

	for (int i=0; (unsigned int) i < len; ++i, ++ieee)
		{
		tmp = *ieee;
		if ( vax.exp() == vax.maxExp() && vax.mantissa() == vax.maxMantissa() )
			{
			ieee.exp(ieee.maxExp());
			ieee.mantissa(ieee.maxMantissa());
			}
		else
			{
			ieee.exp(vax.exp() - vax_single::BIAS + ieee_single::BIAS);
			ieee.mantissa(vax.mantissa());
			}
		ieee.sign(vax.sign());
		}
	return f;
	}

float *ieee2vax_single(float *f, unsigned int len)
	{
	float tmp;
	vax_single  vax(f);
	ieee_single ieee(&tmp);

	for (int i=0; (unsigned int) i < len; ++i, ++vax)
		{
		tmp = *vax;
		if ( ieee.exp() == ieee.maxExp() && ieee.mantissa() == ieee.maxMantissa() )
			{
			vax.exp(vax.maxExp());
			vax.mantissa(vax.maxMantissa());
			}
		else
			{
			vax.exp(ieee.exp() - ieee_single::BIAS + vax_single::BIAS);
			vax.mantissa(ieee.mantissa());
			}
		vax.sign(ieee.sign());
		}
	return f;
	}


double *vax2ieee_double(double *f, unsigned int len,char op)
	{
	double tmp;
	ieee_double ieee(f);
	vax_double  vax(&tmp,op);

	for (int i=0; (unsigned int) i < len; ++i, ++ieee)
		{
		tmp = *ieee;
		if ( vax.exp() == vax.maxExp() && vax.mantissa() == vax.maxMantissa() )
			{
			ieee.exp(ieee.maxExp());
			ieee.mantissa(ieee.maxMantissa());
			}
		else
			{
			ieee.exp(vax.exp() - (op == 'D' ? vax_double::D_BIAS : vax_double::G_BIAS) + ieee_double::BIAS);
			ieee.mantissa(op == 'D' ? (vax.mantissa() >> 3) : vax.mantissa());
			}
		ieee.sign(vax.sign());
		}
	return f;
	}

double *ieee2vax_double(double *f, unsigned int len, char op)
	{
	double tmp;
	vax_double  vax(f,op);
	ieee_double ieee(&tmp);

	for (int i=0; (unsigned int) i < len; ++i, ++vax)
		{
		tmp = *vax;
		if ( ieee.exp() == ieee.maxExp() && ieee.mantissa() == ieee.maxMantissa() )
			{
			vax.exp(vax.maxExp());
			vax.mantissa(vax.maxMantissa());
			}
		else
			{
			vax.exp(ieee.exp() - ieee_double::BIAS + (op == 'D' ? vax_double::D_BIAS : vax_double::G_BIAS));
			vax.mantissa(op == 'D' ? (ieee.mantissa() << 3) : vax.mantissa());
			}
		vax.sign(ieee.sign());
		}
	return f;
	}


