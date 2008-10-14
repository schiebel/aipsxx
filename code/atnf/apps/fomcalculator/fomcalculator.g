#---------------------------------------------------------------------------
# fomcalculator.g: Calculation of Figures of Merit (FOMs) for a given
# antenna layout using a C++ server. These script and client is intended for
# interferometer configuration studies
#---------------------------------------------------------------------------
# Copyright (C) 1996-2005
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: fomcalculator.g,v 1.2 2005/08/12 03:26:04 mvoronko Exp $
#-----------------------------------------------------------------------------
# -------------------------------------------------------------------- <USAGE>
#
# Description of methods provided:
#
# fomcalculator(host,forcenewserver)   - object constructor
#   Input: host - host name to run the C++ server (this machine is a default)
#          forcenewserver - if T, a new C++ server will be started (default is F)
#   Return: an object in the case of success, F otherwise
#
# setlayout(x,y,z,diam) - set a new array layout
#   Input: x,y,z - geocentric positions of stations in meters
#          diam  - station diameter in meters
#   Output: T in the case of success, F otherwise
#
# setlayoutfromfile(fname) - set a new array layout from either an AIPS++
#          table or an ASCII file in the GIS format
#          The table should have columns named X,Y,Z and DIAM.
#   Input: fname - a name of the AIPS++ table or the file in the GIS format
#   Output: T in the case of success, F otherwise
#
# getuvstats(nradbox,nangbox,duration,declination,fracband,dologscale,
#            domfs, dosnapshot)   -  calculate and return uv-plane coverage
#                                    statistics in annuli and radial boxes
#   Input: nradbox - a number of bins in radial direction (no default)
#          nangbox - a number of bins in angular direction (no default)
#          duration - a duration of observations in hours (no default)
#          declination - a declination of the source in degrees
#          fracband - df/f (a fractional bandwith), used if domfs=T,
#                     default is 0.
#          dologscale - if T, a logarithmic scale is used for radial bins
#                       default is F
#          domfs - if T, a multifrequency synthesis is assumed, default is F
#          dosnapshot - if T, only one visibility per baseline is simulated
#                       regardless on the duration specified, default is F
#  Output: a record containing the following fields,
#          or F if method has failed
#             uvsamples - an array (nradbox x nangbox) containing a number of
#                        measurements in this part of the uv-plane
#             uvcoords -  an array (nradbox x nangbox) containing positions
#                         of each cell in the uv-plane used to calculate the
#                         number of measurements in uvsamples. Positions are
#                         stored as a complex value, so real(uvcoords) would
#                         give an array of u's and imag(uvcoords) would
#                         gives an array of v's (abs and arg can be used for
#                         polar coordinates).
#             meansamp - a mean coverage (a mean of uvsamples)
#             varsamp  - a variance of the coverage (a variance of uvsamples)
#             radmean  - an array (1..nradbox) containing a mean angular
#                        coverage for each annulus
#             radvar   - an array (1..nradbox) containing variances
#                        corresponding to radmean
#             angmean  - an array (1..nangbox) containing a mean radial
#                        coverage for each angular sector
#             angvar   - an array (1..nangbox) containing variances
#                        corresponding to angmean
#             
# getsizestats()   - calculate and return the baseline length and
#                     area distribution  statistics
#  Input:  none
#  Output: a record containing the following fields or F if the method
#          has failed
#            maxbaseline - a length of the longest baseline in meters
#            maxnsbaseline - a length of the longest North-South baseline
#                            component in meters
#            maxewbaseline - a length of the longest East-West  baseline
#                            component in meters
#            areain5km     - a fraction of the total area contained in the
#                            5 km circle around the core
#            areain25km    - a fraction of the total area contained in the
#                            25 km circle around the core
#            areain150km    - a fraction of the total area contained in the
#                            150 km circle around the core
#            totalarea     - total collecting area in meters squared,
#                            calculated assuming circular stations
#            area, distance - two arrays containing a distribution of the
#                            collecting area versus the distance from the core
#            rabaseline    - a harmonic mean of the baseline length
#                            (used for RFI studies, see SKA Memo 58 or
#                             EVLA Memo 49).
# done()    - object destructor
#
# Example:
#         include 'fomcalculator.g'
#         include 'pgplotter.g'
#         fom:=fomcalculator()
#         fom.setlayoutfromfile('wa_3_coords.dat')
#         uvstat:=fom.getuvstats(10,10,1,-50)
#         szstat:=fom.getsizestats()
#         fom.done()
#         print szstat.maxbaseline,szstat.areain150km
#         plt:=pgplotter()
#         plt.plotxy(arg(uvstat.uvcoords[1,]),uvstat.radmean)
#         plt.done()
#
# -------------------------------------------------------------------- <USAGE>
#

# include guard
if (!is_defined('fomcalculator_g_included')) {
    fomcalculator_g_included:='yes';

    include 'servers.g'
    include 'table.g'
    include 'measures.g'
    include 'catalog.g'

    const fomcalculator:=function(host='',forcenewserver=F) {
	  self:=[=];
	  public:=[=];

	  self.agent:=defaultservers.activate("fomcalculator",host,
		       forcenewserver);
	  self.id:=defaultservers.create(self.agent,"FOMCalculator");
	  self.setLayoutRec:=[_method="setlayout",_sequence=self.id._sequence];

	  const public.setlayout:=function(x,y,z,diam)
	  {
	     wider self;

	     self.setLayoutRec.x:=x;
	     self.setLayoutRec.y:=y;
             self.setLayoutRec.z:=z;
             self.setLayoutRec.diam:=diam;

	     defaultservers.run(self.agent,self.setLayoutRec);
	  }

	  # sets a layout as above, but perform a reading from either
	  # an AIPS++ table or an ASCII file in GIS format
	  const public.setlayoutfromfile:=function(fname)
	  {
	     wider self;

	     if (dc.whatis(fname).type == 'Non-existent') {
	        print "File ",fname," not found"
		return F;
	     }
	     if (tableexists(fname)) {   # fname is an AIPS++ table
	          mytab:=table(fname);
		  if (!is_table(mytab)) return F; 
	          self.setLayoutRec.x:=mytab.getcol('X');
	          self.setLayoutRec.y:=mytab.getcol('Y');
	          self.setLayoutRec.z:=mytab.getcol('Z');
	          self.setLayoutRec.diam:=mytab.getcol('DIAM');
	          mytab.done();
	     } else {  # fname is a file in GIS format
	          f:=open(spaste("< ",fname));
		  if (!is_file(f)) return F;
	          cnt:=1;
	          self.setLayoutRec.x:=[];
	          self.setLayoutRec.y:=[];
	          self.setLayoutRec.z:=[];
	          self.setLayoutRec.diam:=[];
	          self.setLayoutRec.name:=[];  # this field is not used
	          while (line:=read(f)) {
	                 pararr:=split(split(line,'\n')[1],',');
	                 if (len(pararr)!=5) {
	                     print "Bad format of the layout file (need 5 comma-separated values)"
	                     return F;
	                 }
	                 # WGS84 -> ITRF
	                 mxyz:=dm.measure(dm.position('wgs84',
	                        dq.quantity(as_double(pararr[1]),'deg'),
	               	        dq.quantity(as_double(pararr[2]),'deg'),
	               	        dq.quantity(as_double(pararr[3]),'m')),'itrf');
                         r:=mxyz.m2.value*cos(mxyz.m1.value);
	                 self.setLayoutRec.x[cnt]:=r*cos(mxyz.m0.value);
	                 self.setLayoutRec.y[cnt]:=r*sin(mxyz.m0.value);
	                 self.setLayoutRec.z[cnt]:=mxyz.m2.value*sin(mxyz.m1.value);
	                 self.setLayoutRec.diam[cnt]:=as_double(pararr[4]);
	                 self.setLayoutRec.name[cnt]:=as_double(pararr[5]);
	                 cnt+:=1;
	          }	  	         
	     }
	     defaultservers.run(self.agent,self.setLayoutRec);
	     return T;
	  }

	  self.getuvstatsRec:=[_method="getuvstats",_sequence=self.id._sequence];
	  # nradbox,nangbox - number of radial and angular boxes
	  # duration - duration of observations in hours
	  # declination - declination of the source in degrees
	  # fracband  - df/f (fractional bandwidth) if domfs=T
	  # dologscale, if =T, radial boxes are scaled logarithmically
	  # domfs, if =T, multifrequency synthesis is simulated
	  # dosnapshot, if =T, one visibility per baseline is simulated
	  const public.getuvstats:=function(nradbox,nangbox,duration,
	              declination,fracband=0.,dologscale=F,domfs=F,
		      dosnapshot=F)
	  {
	     wider self;

	     self.getuvstatsRec.nradbox:=nradbox;
	     self.getuvstatsRec.nangbox:=nangbox;
	     self.getuvstatsRec.duration:=duration;
	     self.getuvstatsRec.declination:=declination;
	     self.getuvstatsRec.fracband:=fracband;
	     self.getuvstatsRec.dologscale:=dologscale;
	     self.getuvstatsRec.domfs:=domfs;
	     self.getuvstatsRec.dosnapshot:=dosnapshot;

	     defaultservers.run(self.agent,self.getuvstatsRec);

	     return self.getuvstatsRec.uvstats;
	  }


	  self.getsizestatsRec:=[_method="getsizestats",_sequence=self.id._sequence];
          # return baseline size statistics, setLayout should be 
	  # executed first
	  const public.getsizestats:=function() 
	  {
	     wider self;
	     
	     defaultservers.run(self.agent,self.getsizestatsRec);

	     return self.getsizestatsRec.sizestats;
	  }

	  const public.done:=function()
	  {
	     wider self,public;
	     ok:=defaultservers.done(self.agent,self.id.objectid);
	     if (ok) {
		 self:=F;
		 val public:=F;
	     }
	     return ok;
	  }
	  return public;
    } # constructor
} #include guard
