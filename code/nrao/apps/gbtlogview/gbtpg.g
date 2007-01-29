# gbtpg.g: convenience functions for gbt pgplotter
#
#   Copyright (C) 1995,1996,1997,1999,2001
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
#   $Id: gbtpg.g,v 19.0 2003/07/16 03:42:30 aips2adm Exp $
#
#-----------------------------------------------------------------------------
#pragma include once

include 'pgplotter.g'
 
const pg:=pgplotter(); 

const pgploty := function(yy,xlab='',ylab='Arbs',tlab='GBT logview plot',
                 lineflag=T) {
	numy1:=yy::shape[1];
	leny1:=yy::shape[2];
	xx:=1:leny1;
	pg.slw(3);
	minx:=min(xx);
	maxx:=max(xx);
	ymin:=min(yy)-0.2*(max(yy)-min(yy));
	ymax:=max(yy)+0.2*(max(yy)-min(yy));
	pg.bbuf()
	pg.sci(1);
	pg.env(minx,maxx,ymin,ymax,0,0);
	pg.box('',0,0,'',0,0);
	for (i in 1:numy1) {
		pg.sci(i+1);
		if (lineflag) pg.line(xx,yy[i,]);
		else (pg.pt(xx,yy[i,],1))
		if (i%2!=0) {
			labloc:=-.8-i;
			pg.mtxt('t',labloc,0.02,0,ylab[i]);
		}  else {
			pg.mtxt('t',labloc,0.52,0,ylab[i]);
		}
	}
	pg.sci(1)
	pg.lab(xlab,ylab[1],tlab)
	pg.ebuf();
}

const pgplotxy := function(xx,yy,xlab='',ylab='Arbs',tlab='GBT logview plot',
                  lineflag=T) {
        numy1:=yy::shape[1];
        leny1:=yy::shape[2];
        pg.slw(3);
        minx:=min(xx);
        maxx:=max(xx);
        ymin:=min(yy)-0.2*(max(yy)-min(yy));
        ymax:=max(yy)+0.2*(max(yy)-min(yy));
        pg.bbuf()
        pg.sci(1);
        pg.env(minx,maxx,ymin,ymax,0,0);
        pg.box('',0,0,'',0,0);
        for (i in 1:numy1) {
                pg.sci(i+1);
		if (lineflag) pg.line(xx,yy[i,]);
		else (pg.pt(xx,yy[i,],1))
                if (i%2!=0) {
                        labloc:=-.8-i;
                        pg.mtxt('t',labloc,0.02,0,ylab[i]);
                }  else {
                        pg.mtxt('t',labloc,0.52,0,ylab[i]);
                }
	}
	pg.sci(1);
	pg.lab(xlab,ylab[1],tlab);
	pg.ebuf();
}

const pgploty2 := function(yy,xlab='',ylab='Arbs',tlab='GBT logview plot',
                  lineflag=T) {
        numy1:=yy::shape[1];
        leny1:=yy::shape[2];
	xx:=1:leny1;
        pg.slw(3);
        minx:=min(xx);
        maxx:=max(xx);
        ymin:=min(yy)-0.2*(max(yy)-min(yy));
        ymax:=max(yy)+0.2*(max(yy)-min(yy));
        pg.bbuf()
        pg.sci(1);
        pg.swin(minx,maxx,ymin,ymax);
        pg.box('cstm',0,0,'cstm',0,0);
        for (i in 1:numy1) {
                pg.sci(12-i);
		if (lineflag) pg.line(xx,yy[i,]);
		else (pg.pt(xx,yy[i,],1))
                if (i%2!=0) {
                        labloc:=-.8-i;
                        pg.mtxt('b',labloc,0.02,0,ylab[i]);
                }  else {
                        pg.mtxt('b',labloc,0.52,0,ylab[i]);
                }
        }
        pg.sci(1);
#        pg.lab(xlab,ylab[1],tlab);
        pg.ebuf();
}

const pgplotxy2 := function(xx,yy,xlab='',ylab='Arbs',tlab='GBT logview plot',
                   lineflag=T) {
        numy1:=yy::shape[1];
        leny1:=yy::shape[2];
        pg.slw(3);
        minx:=min(xx);
        maxx:=max(xx);
        ymin:=min(yy)-0.2*(max(yy)-min(yy));
        ymax:=max(yy)+0.2*(max(yy)-min(yy));
        pg.bbuf()
        pg.sci(1);
        pg.swin(minx,maxx,ymin,ymax);
        pg.box('cstm',0,0,'cstm',0,0);
        for (i in 1:numy1) {
                pg.sci(12-i);
		if (lineflag) pg.line(xx,yy[i,]);
		else (pg.pt(xx,yy[i,],1))
                if (i%2!=0) {
                        labloc:=-.8-i;
                        pg.mtxt('b',labloc,0.02,0,ylab[i]);
                }  else {
                        pg.mtxt('b',labloc,0.52,0,ylab[i]);
                }
        }
        pg.sci(1);
        pg.ebuf();
}

const pgtimey := function(xx,yy,xlab='',ylab='Arbs',tlab='GBT logview plot',
                 lineflag=T) {
        numy1:=yy::shape[1];
        leny1:=yy::shape[2];
        pg.slw(3);
        minx:=min(xx);
        maxx:=max(xx);
        ymin:=min(yy)-0.2*(max(yy)-min(yy));
        ymax:=max(yy)+0.2*(max(yy)-min(yy));
        pg.bbuf()
        pg.sci(1);
        pg.env(minx,maxx,ymin,ymax,0,-1);
        pg.swin(minx,maxx,ymin,ymax);
        pg.tbox('bstzhn',0,0,'bstn',0,0);
        for (i in 1:numy1) {
                pg.sci(i+1);
		if (lineflag) pg.line(xx,yy[i,]);
		else (pg.pt(xx,yy[i,],1))
                if (i%2!=0) {
                        labloc:=-.8-i;
                        pg.mtxt('t',labloc,0.02,0,ylab[i]);
                }  else {
                        pg.mtxt('t',labloc,0.52,0,ylab[i]);
                }

        }
        pg.sci(1)
        pg.lab(xlab,ylab[1],tlab)
        pg.ebuf();
}


const pgtimey2 := function(xx,yy,xlab='',ylab='Arbs',tlab='GBT logview plot',
                  lineflag=T) {
        numy1:=yy::shape[1];
        leny1:=yy::shape[2];
        pg.slw(3);
        minx:=min(xx);
        maxx:=max(xx);
        ymin:=min(yy)-0.2*(max(yy)-min(yy));
        ymax:=max(yy)+0.2*(max(yy)-min(yy));
        pg.bbuf()
        pg.sci(1);
        pg.swin(minx,maxx,ymin,ymax);
        pg.tbox('cstmz',0,0,'cstm',0,0);
        for (i in 1:numy1) {
                pg.sci(12-i);
		if (lineflag) pg.line(xx,yy[i,]);
		else (pg.pt(xx,yy[i,],1))
                if (i%2!=0) {
                        labloc:=-.8-i;
                        pg.mtxt('b',labloc,0.02,0,ylab[i]);
                }  else {
                        pg.mtxt('b',labloc,0.52,0,ylab[i]);
                }
 
        }
        pg.sci(1);
        pg.ebuf();
}


makepublic := function() {
	return pg;}
