# dynamicsched_meta.g: Standard meta information for dynamicsched
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: dynamicsched_meta.g,v 19.1 2004/08/25 01:51:53 cvsmgr Exp $
#

pragma include once;

include 'types.g';


types.class('dynamicsched').includefile('dynamicsched.g');
#
#
# Constructors
types.method('ctor_dynamicsched');


# Methods
types.method('setsitedata').
        string('sitedatafile', 'CH.9506.INT+ALL').
        string('headerfile', 'header.sitedata').
	string('observatory', 'ALMA').
	quantity('seeinglambda', '26.79mm').
	quantity('seeingel', '36deg').
	quantity('seeingbaseline', '300m');

types.method('settaudata').
        string('tautermsfile', 'CH.LIEBE.TERMS');

types.method('setchangeinfo').
        quantity('azslewrate', '2deg/s').
        quantity('elslewrate', '1deg/s').
        quantity('changeoverhead', '60s');


types.method('settimes').
	quantity('dt', '0.25h').
	choice('timeref', 'relative', options=['relative', 'absolute']).
	epoch('absolutestart').
	quantity('relativestart', '0.0d').
	quantity('duration', '1.0d');

types.method('setphasecalinfo').
        choice('phasecalmethod', 'RADIOMETRIC', options=['RADIOMETRIC', 'FASTSWITCH']).
	quantity('baselevel', '50um').
	float('fraclevel', 0.10).
	quantity('windvelocity', '10m/s').
	quantity('timescale', '30s');

types.method('setschedcriteria').
	quantity('hatozenith', '2h').
	quantity('hafromzenith', '1.5h').
	quantity('phasecutoff', '30deg');

types.method('setsensitivity').
	quantity('dishdiameter', '12m').
	integer('nantennas', 64).
	integer('npol', 2);

types.method('setbandsensitivity').
	integer('whichband', 1).
	string('bandname', 'band1').
	quantity('freqlow', '0GHz'). 
	quantity('freqhigh', '100GHz').
	float('bandwidth', '8GHz').
	quantity('tsys', '100K').
	float('efficiency', 0.80);

types.method('viewsensitivity');

types.method('generateprojects').
	integer('nprojects', 100).
	integer('ratingmin', 1).
	integer('ratingmax', 10).
	quantity('timemode', '5h').
	quantity('timesigma', '10h').
	quantity('timemax', '20h').
	float('freqtransexponent', 2.0).
	float('freqwt', 2.0).
	float('freqexponent', 1.5). 
	quantity('decmin', '-90deg'). 
	quantity('decmax', '52deg');

types.method('probview').
	choice('whichone', 'freq', options=['freq', 'rating', 'radec', 'time']);

types.method('saveprojects').
	string('projecttable', '').
	boolean('allprojects', T).
	vector_integer('whichprojects', 1);

types.method('recoverprojects').
	string('projecttable', '');

types.method('saveschedule').
	string('scheduletable', '');

types.method('recoverschedule').
	string('scheduletable', '');

types.method('defaultinitialize');

types.method('done');

types.method('getpgplotter');

types.method('schedule');

types.method('reobserveschedule');

types.method('evaluateobservations');

