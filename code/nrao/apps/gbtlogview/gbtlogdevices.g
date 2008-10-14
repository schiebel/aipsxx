# gbtlogdevices.g: temporary means for finding log device FITS files
#
#   Copyright (C) 1995,1996,1997,1999,2000
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
#   $Id: gbtlogdevices.g,v 19.0 2003/07/16 03:42:27 aips2adm Exp $
#-----------------------------------------------------------------------------
# in green bank:

i := 1;

devices [i] := [=];
devices [i].name := '4-6 GHz Receiver';
devices [i].directory := '/home/GBlogs/Rcvr4_6-Rcvr4_6-gregorian';
devices [i].selected := F;

i := i+1;
devices [i] := [=];
devices [i].name := '8-10 GHz Receiver';
devices [i].directory := '/home/GBlogs/Rcvr8_10-Rcvr8_10-gregorian';
devices [i].selected := F;
 
i := i+1;
devices [i] := [=];
devices [i].name := '12-18 GHz Receiver';
devices [i].directory := '/home/MUlogs/Rcvr12_18-Rcvr12_18-cryogenics';
devices [i].selected := F;
 
i := i+1;
devices [i] := [=];
devices [i].name := '18-26 GHz Receiver';
devices [i].directory := '/home/GBlogs/Rcvr18_26-Rcvr18_26-gregorian';
devices [i].selected := F;
 
i := i+1;
devices [i] := [=];
devices [i].name := '140 Cryo Monitor';
devices [i].directory := '/home/GBlogs/Mon140Cryo-Mon140Cryo-Mon140CryoSampler';
devices [i].selected := F;

i := i+1;
devices [i] := [=];
devices [i].name := 'Weather1 (At ICB)';
devices [i].directory := '/home/GBlogs/Weather1-Weather1-weather1';
devices [i].selected := F;

i := i+1;
devices [i] := [=];
devices [i].name := 'Weather2 (At 140)';
devices [i].directory := '/home/GBlogs/Weather2-Weather2-weather2';
devices [i].selected := F;
#
i := i+1;
devices [i] := [=];
devices [i].name := 'Specify Device';
devices [i].directory := '';
devices [i].selected := F;
specifyDeviceIndex := i;
#
i := i+1;
devices [i] := [=];
devices [i].name := 'Specify ASCII table';
devices [i].directory := '';
devices [i].selected := F;
specifyAsciiIndex := i;
#
i := i+1;
devices [i] := [=];
devices [i].name := 'Maser';
devices [i].directory := '/home/GBTlogs/Maser';
devices [i].selected := F;

i := i+1;
devices [i] := [=];
devices [i].name := 'OnePpsDeltas';
devices [i].directory := '/home/GBlogs/SiteTime-OnePps-OnePpsDeltas';
devices [i].selected := F;

i := i+1;
devices [i] := [=];
devices [i].name := 'OnePpsStatus';
devices [i].directory := '/home/GBlogs/SiteTime-OnePps-OnePpsStatus';
devices [i].selected := F;

i := i+1;
devices [i] := [=];
devices [i].name := 'RtpmJansky';
devices [i].directory := '/home/GBlogs/SiteTime-Rtpm140-Rtpm';
devices [i].selected := F;
#
i := i+1;
devices [i] := [=];
devices [i].name := 'Tipper (Integrated)';
devices [i].directory := '/home/GBlogs/Tipper-Tipper-integratedData';
devices [i].selected := F;
#
i := i+1;
devices [i] := [=];
devices [i].name := 'Tipper (Slow Mon)';
devices [i].directory := '/home/GBlogs/Tipper-Tipper-slowMonitor/';
devices [i].selected := F;
#
i := i+1;
devices [i] := [=];
devices [i].name := 'MU Temperatures';
devices [i].directory := '/home/MUlogs/MotorRack-MotorRack-temperature';
devices [i].selected := F;

