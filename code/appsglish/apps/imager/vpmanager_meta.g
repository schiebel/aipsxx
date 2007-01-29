# vpmanager_meta.g: Standard meta information for vpmanager
#
#   Copyright (C) 1996,1997,1998,1999,2003
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: vpmanager_meta.g,v 19.1 2004/08/25 01:21:26 cvsmgr Exp $
#

pragma include once;

include 'types.g';
include 'measures.g';

types.class('vpmanager').includefile('vpmanager.g');

# Constructors
types.method('ctor_vpmanager');

types.method('setcannedpb').
    choice('telescope', 'VLA', options=["ALMA", "ATCA", "GBT", "GMRT", "HATCREEK", 
    "NMA", "NRAO12M", "NRAO140FT", "OVRO", "VLA", "WSRT", "OTHER"]).
    string('othertelescope', '').
    boolean('dopb', F).
    choice('commonpb', 'DEFAULT', options=["UNKNOWN", "DEFAULT", "ALMA", "ATCA_L1", 
    "ATCA_L2", "ATCA_L3", "ATCA_S", "ATCA_C", "ATCA_X", "GBT", "GMRT", "HATCREEK", 
    "NRAO12M", "NRAO140FT", "OVRO", "VLA", 
    "VLA_INVERSE", "VLA_NVSS", "VLA_2NULL", "VLA_4", "VLA_P", "VLA_L", "VLA_C", 
    "VLA_X", "VLA_U", "VLA_K", "VLA_Q", "WSRT", "WSRT_LOW"]).
    boolean('dosquint', F).
    quantity('paincrement', '720deg').
    boolean('usesymmetricbeam', F);

types.method('setpbairy').
    choice('telescope', 'VLA', options=["ALMA", "ATCA", "GBT", "GMRT", "HATCREEK", 
    "NMA", "NRAO12M", "NRAO140FT", "OVRO", "VLA", "WSRT", "OTHER"]).
    string('othertelescope', '').
    boolean('dopb', F).
    quantity('dishdiam', '25m').
    quantity('blockagediam', '2.5m').
    quantity('maxrad', '0.8deg').
    quantity('reffreq', '1.0GHz').
    direction('squintdir', dm.direction('azel', '0d', '0d'), dir="in").
    quantity('squintreffreq', '1.0GHz').
    boolean('dosquint', F).
    quantity('paincrement', '720deg').
    boolean('usesymmetricbeam', F);

types.method('setpbgauss').
    choice('telescope', 'VLA', options=["ALMA", "ATCA", "GBT", "GMRT", "HATCREEK", 
    "NMA", "NRAO12M", "NRAO140FT", "OVRO", "VLA", "WSRT", "OTHER"]).
    string('othertelescope', '').
    boolean('dopb', F).
    quantity('halfwidth', '0.5deg').
    quantity('maxrad', '0.8deg').
    quantity('reffreq', '1.0GHz').
    choice('isthispb', 'PB', options=["PB", "VP"]).
    direction('squintdir', dm.direction('azel', '0d', '0d'),
	    dir="in").
    quantity('squintreffreq', '1.0GHz').
    boolean('dosquint', F).
    quantity('paincrement', '720deg').
    boolean('usesymmetricbeam', F);

types.method('setpbcospoly').
    choice('telescope', 'VLA', options=["ALMA", "ATCA", "GBT", "GMRT", "HATCREEK", 
    "NMA", "NRAO12M", "NRAO140FT", "OVRO", "VLA", "WSRT", "OTHER"]).
    string('othertelescope', '').
    boolean('dopb', F).
    vector_float('coeff', 0.0).
    vector_float('scale', 0.0).
    quantity('maxrad', '0.8deg').
    quantity('reffreq', '1.0GHz').
    choice('isthispb', 'PB', options=["PB", "VP"]).
    direction('squintdir', dm.direction('azel', '0d', '0d'),
	      dir="in").
    quantity('squintreffreq', '1.0GHz').
    boolean('dosquint', F).
    quantity('paincrement', '720deg').
    boolean('usesymmetricbeam', F);

types.method('setpbinvpoly').
    choice('telescope', 'VLA', options=["ALMA", "ATCA", "GBT", "GMRT", "HATCREEK", 
    "NMA", "NRAO12M", "NRAO140FT", "OVRO", "VLA", "WSRT", "OTHER"]).
    string('othertelescope', '').
    boolean('dopb', F).
    vector_float('coeff', 0.0).
    quantity('maxrad', '0.8deg').
    quantity('reffreq', '1.0GHz').
    choice('isthispb', 'PB', options=["PB", "VP"]).
    direction('squintdir', dm.direction('azel', '0d', '0d'),
	      dir="in").
    quantity('squintreffreq', '1.0GHz').
    boolean('dosquint', F).
    quantity('paincrement', '720deg').
    boolean('usesymmetricbeam', F);


types.method('setpbpoly').
    choice('telescope', 'VLA', options=["ALMA", "ATCA", "GBT", "GMRT", "HATCREEK", 
    "NMA", "NRAO12M", "NRAO140FT", "OVRO", "VLA", "WSRT", "OTHER"]).
    string('othertelescope', '').
    boolean('dopb', F).
    vector_float('coeff', 0.0).
    quantity('maxrad', '0.8deg').
    quantity('reffreq', '1.0GHz').
    choice('isthispb', 'PB', options=["PB", "VP"]).
    direction('squintdir', dm.direction('azel', '0d', '0d'),
	      dir="in").
    quantity('squintreffreq', '1.0GHz').
    boolean('dosquint', F).
    quantity('paincrement', '720deg').
    boolean('usesymmetricbeam', F);

types.method('setpbnumeric').
    choice('telescope', 'VLA', options=["ALMA", "ATCA", "GBT", "GMRT", "HATCREEK", 
    "NMA", "NRAO12M", "NRAO140FT", "OVRO", "VLA", "WSRT", "OTHER"]).
    string('othertelescope', '').
    boolean('dopb', F).
    vector_float('vect', 0.0).
    quantity('maxrad', '0.8deg').
    quantity('reffreq', '1.0GHz').
    choice('isthispb', 'PB', options=["PB", "VP"]).
    direction('squintdir', dm.direction('azel', '0d', '0d'),
	      dir="in").
    quantity('squintreffreq', '1.0GHz').
    boolean('dosquint', F).
    quantity('paincrement', '720deg').
    boolean('usesymmetricbeam', F);

types.method('setpbimage').
    choice('telescope', 'VLA', options=["ALMA", "ATCA", "GBT", "GMRT", "HATCREEK", 
    "NMA", "NRAO12M", "NRAO140FT", "OVRO", "VLA", "WSRT", "OTHER"]).
    string('othertelescope', '').
    boolean('dopb', F).
    image('realimage').
    image('imagimage');

types.method('summarizevps').
	boolean('verbose');

types.method('saveastable').
    string('tablename');





