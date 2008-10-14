# almati2ms.g: Glish proxy for almati2ms DO 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: almati2ms.g,v 19.4 2004/01/09 21:12:09 kgolap Exp $
#

pragma include once

include 'servers.g'
include 'os.g'
include 'catalog.g'

dowait:=T;
#defaultservers.suspend(T)
#defaultservers.trace(T)

##############################################################################
# Private function used by constructor
#
const _define_almati2ms := function(msfile, fitsin, append, ref agent, id) {
   self:= [=];
   public:= [=];

   self.agent:= ref agent;
   self.id:= id;
   self.msfile:= msfile;
   self.fitsin:= fitsin;
   self.append:= append;

#-----------------------------------------------------------------------------
# Method: setoptions
#
   self.setoptionsRec:= [_method="setoptions", _sequence = self.id._sequence];
   public.setoptions:= function (compress=T, combinebaseband=T) {
#
      wider self;
      self.setoptionsRec.compress:= compress;
      self.setoptionsRec.combinebaseband:= combinebaseband;
      return defaultservers.run (self.agent, self.setoptionsRec);
    }

#-----------------------------------------------------------------------------
# Method: select
#
   self.selectRec:= [_method="select", _sequence = self.id._sequence];
   public.select:= function (obsmode=unset, chanzero=unset) {
#
      wider self;
      if (is_unset(obsmode)) {
	self.selectRec.obsmode:= [""];
      } else {
        self.selectRec.obsmode:= obsmode;
      };
	
      if (is_unset(chanzero)) {
        self.selectRec.chanzero:= "NONE";
      } else {
	self.selectRec.chanzero:= chanzero;
      };

      return defaultservers.run (self.agent, self.selectRec);
    }

#-----------------------------------------------------------------------------
# Method: fill
#
   self.fillRec:= [_method = "fill", _sequence = self.id._sequence];
   public.fill:= function () {
#
      wider self;
      return defaultservers.run (self.agent, self.fillRec);
    }

#-----------------------------------------------------------------------------
# Method: type
#
    public.type := function() {
	return 'almati2ms';
    };

#-----------------------------------------------------------------------------
# Method: id
#
    public.id := function() {
       wider self;
       return self.id.objectid;
    };

#-----------------------------------------------------------------------------
# Method: done
#
    public.done := function() {
       wider self, public;
       ok := defaultservers.done(self.agent, public.id());
       if (ok) {
           self := F;
           val public := F;
       }
       return ok;
    };

   return public;

} #_define_almati2ms()

##############################################################################
# Constructor: create a new server for each invocation
#
   const almati2ms:= function (msfile, fitsin, append=T, host = '',
      forcenewserver = T) {
      agent:= defaultservers.activate ("almati2ms", host, forcenewserver);
      id:= defaultservers.create (agent, "almati2ms", "almati2ms", 
         [msfile = msfile, fitsin = fitsin, append=append]);
      return _define_almati2ms (msfile, fitsin, append, agent, id);
   };

##############################################################################
# Global function to fill ALMA-TI data files from a data directory
#
   const almatifiller:= function (msfile, fitsdir, pattern='', 
                                  append=F, compress=F, 
                                  combinebaseband=F, obsmode='CORR', 
                                  chanzero='TIME_AVG', 
				  dophcor=F, host='') {
   #
   # Function to fill ALMA-TI FITS files from a data directory
   # to an AIPS++ MeasurementSet (MS). The directory name can
   # be supplemented by a filename modifier.

      # Delete the MS if overwrite selected
      if (!append) dos.remove (pathname=msfile, mustexist=F);

      # Loop over all files in the data directory
      filelist:= dos.dir (directoryname=fitsdir, pattern=pattern);
      filelist:= sort (filelist);
      first:= T;
      for (filename in filelist) {
         print "filename= ", filename;
	 lengthofpath:=strlen(fitsdir);
	 a:=split(fitsdir,'');
	 if(a[lengthofpath]=='/'){
	    fullname:= spaste (fitsdir, filename);
	  }
	 else{   
	   fullname:= spaste (fitsdir, '/', filename);        
	 }
         print "fullname= ", fullname; 

         # Create an ALMA-TI filler tool
         ati2ms:= almati2ms (msfile=msfile, fitsin=fullname,
                             append=(!first | append), host=host);

         # Set the filler tool options

         ati2ms.setoptions (compress=compress, 
                            combinebaseband=combinebaseband);

         ati2ms.select (obsmode=obsmode, chanzero=chanzero);

         # Fill the data
         ati2ms.fill();
         first:= F;

         # Close the ALMA-TI filler tool
         ati2ms.done();
      };

      if(dophcor){
	include 'imager.g';
	myim:=imager(msfile); #fill in the scratch column
	myim.done();
	include 'iramcalibrater.g';
	ical:=iramcalibrater(msname=msfile, initcal=F);
	ical.phcor(trial=F);
	ical.done();
      }
      return;
   };

##############################################################################
# Test script
#
   const almati2mstest:= function () {
#
      fail "Not yet implemented"
    };

##############################################################################
# Demo script
#
   const almati2msdemo:= function () {
      fail "Not yet implemented"
    };

##############################################################################



