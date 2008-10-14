# mydish_unijr.gp
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000,2001,2002,2003
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
#
#------------------------------------------------------------------------------
pragma include once;

mydish_unijr := [=];

mydish_unijr.attach := function (ref public) {
        #new function
const	public.dgetscan := ref public.getscan;
const	public.dopen    := ref public.open;
const	public.page     := ref public.plotter.clear;
const   public.signal   := function(scan,nif=1) {
		wider public;
		public.TPcal(scan);
	   	tmp:=public.getc(scan,nif=nif);
		public.uniput('globalscan1',tmp);
		public.uniput('vsig',tmp);
		return T;
	}
const	public.reference:= function(scan,nif=1) {
	   	wider public;
	   	public.TPcal(scan);
	   	tmp:=public.uniget('globalscan1');
	   	myref:=public.getc(scan,nif=nif);
	   	public.uniput('offscan1',myref);
		public.uniput('vref',myref);
	   	public.uniput('globalscan1',tmp);
		return T;
        };

const   public.temp := function() {
		wider public;
		vsig :=public.uniget('vsig')
    		vref :=public.uniget('vref')
		if (!all(vsig.data.arr::shape==vref.data.arr::shape)) {
			print 'ERROR: Array shapes are inconsistent';
			return F;
		};
    		if (!is_sdrecord(vsig) | !is_sdrecord(vref)) {
     		   print 'Invalid signal/reference data'
     		   return F
     		}
    		tsysref := vref.header.tsys
		for ( i in 1:vsig.data.arr::shape[1])
	     		vsig.data.arr[i,] := tsysref[i]*(vsig.data.arr[i,]-vref.data.arr[i,])/vref.data.arr[i,]
     		vsig.header.tsys := tsysref;
    		vsig.data.desc.units := 'Ta*'
    		vsig.header.duration +:= vref.header.duration
                elev:=vsig.header.azel.m1.value*180/pi;
                freq:=vsig.data.desc.restfrequency;
                effs:=public.eff(freq,elev);
                factor := exp(effs.tau*(1/sin(elev*pi/180.)))/effs.etal;
		vsig.data.arr *:=factor;
    		public.uniput('globalscan1',vsig)
    		return T
	}


const   public.moment := function() {
		wider public;
                public.saxis('index');
	        bmom:=public.uniget('bmoment');
		emom:=public.uniget('emoment');
		if (bmom!=emom) {
		   thisRange:=spaste('[',bmom,':',emom,']');
		   print public.stat(range=thisRange);
		} else {
		   print public.stat();
		};
		return T;
        }

const   public.getfsint := function(scan,intNo=F,flipsigref=F) {
		wider public;
		ok:=public.FScal(scan,flipsr=flipsigref);
		if (!ok) return F;
		tmp:=public.getc(scan,intNo);
		public.uniput('globalscan1',tmp);
		return T;
	};

const   public.getfs    := function(scan,flipsigref=F) {
		wider public;
		ok:=public.getfsint(scan,flipsigref=flipsigref);
		if (!ok) return F;
		tmp:=public.getc(scan);
                public.uniput('globalscan1',tmp);
		return ok;
	};

const   public.getir    := ref public.getc


#don't change past here
return T;

}
