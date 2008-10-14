# newsimhelper: various functions to help newsimulator do its thing
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
#   $Id: newsimhelper.g,v 1.1 2004/11/09 20:46:58 tcornwel Exp $
#

include 'unset.g';

pragma include once

newsimhelper:=function(schedtable=unset) {
  
  public:=[=];
  private:=[=];

  include 'table.g';
  include 'sysinfo.g';
  if(is_unset(schedtable)) {
    private.schedtable:=spaste(sysinfo().root(),'/data/geodetic/SCHED_locations');
    if(!tableexists(private.schedtable)) {
      return throw('SCHED locations table not present in data repository - ask your site manager to update');
    }
  }
  else {
    private.schedtable:=schedtable;
  }


#
# The array definitions are given in terms of the names of 
# telescopes in the SCHED location file. I don't use
# the CODEs since these are too terse.
#

##############################################################
#
# VLA Configurations
#  
  private.info.VLAA.names:=['VLA_N8', 'VLA_N16', 'VLA_N24', 'VLA_N32', 'VLA_N40', 'VLA_N48', 'VLA_N56', 'VLA_N64', 'VLA_N72', 'VLA_E8', 'VLA_E16', 'VLA_E24', 'VLA_E32', 'VLA_E40', 'VLA_E48', 'VLA_E56', 'VLA_E64', 'VLA_E72', 'VLA_W8', 'VLA_W16', 'VLA_W24', 'VLA_W32', 'VLA_W40', 'VLA_W48', 'VLA_W56', 'VLA_W64', 'VLA_W72', 'VLA_E8', 'VLA_E16', 'VLA_E24', 'VLA_E32', 'VLA_E40', 'VLA_E48', 'VLA_E56', 'VLA_E64', 'VLA_E72' ];
  private.info.VLAA.diam:=array(25.0,27);
  private.info.VLAB.names:=['VLA_N4', 'VLA_N8', 'VLA_N12', 'VLA_N16', 'VLA_N20', 'VLA_N24', 'VLA_N28', 'VLA_N32', 'VLA_N36', 'VLA_E4', 'VLA_E8', 'VLA_E12', 'VLA_E16', 'VLA_E20', 'VLA_E24', 'VLA_E28', 'VLA_E32', 'VLA_E36', 'VLA_W4', 'VLA_W8', 'VLA_W12', 'VLA_W16', 'VLA_W20', 'VLA_W24', 'VLA_W28', 'VLA_W32', 'VLA_W36', 'VLA_E4', 'VLA_E8', 'VLA_E12', 'VLA_E16', 'VLA_E20', 'VLA_E24', 'VLA_E28', 'VLA_E32', 'VLA_E36' ];
  private.info.VLAB.diam:=array(25.0,27);
  private.info.VLAC.names:=['VLA_N2', 'VLA_N4', 'VLA_N6', 'VLA_N8', 'VLA_N10', 'VLA_N12', 'VLA_N14', 'VLA_N16', 'VLA_N18', 'VLA_E2', 'VLA_E4', 'VLA_E6', 'VLA_E8', 'VLA_E10', 'VLA_E12', 'VLA_E14', 'VLA_E16', 'VLA_E18', 'VLA_W2', 'VLA_W4', 'VLA_W6', 'VLA_W8', 'VLA_W10', 'VLA_W12', 'VLA_W14', 'VLA_W16', 'VLA_W18', 'VLA_E2', 'VLA_E4', 'VLA_E6', 'VLA_E8', 'VLA_E10', 'VLA_E12', 'VLA_E14', 'VLA_E16', 'VLA_E18' ];
  private.info.VLAC.diam:=array(25.0,27);
  private.info.VLAD.names:=['VLA_N1', 'VLA_N2', 'VLA_N3', 'VLA_N4', 'VLA_N5', 'VLA_N6', 'VLA_N7', 'VLA_N8', 'VLA_N9', 'VLA_E1', 'VLA_E2', 'VLA_E3', 'VLA_E4', 'VLA_E5', 'VLA_E6', 'VLA_E7', 'VLA_E8', 'VLA_E9', 'VLA_W1', 'VLA_W2', 'VLA_W3', 'VLA_W4', 'VLA_W5', 'VLA_W6', 'VLA_W7', 'VLA_W8', 'VLA_W9', 'VLA_E1', 'VLA_E2', 'VLA_E3', 'VLA_E4', 'VLA_E5', 'VLA_E6', 'VLA_E7', 'VLA_E8', 'VLA_E9' ];
  private.info.VLAD.diam:=array(25.0,27);
  
##############################################################
#
# VLBA Configuration
#  
  private.info.VLBA.names:=['PIETOWN', 'BR-VLBA', 'FD-VLBA', 'HN-VLBA', 'KP-VLBA', 'LA-VLBA', 'MK-VLBA', 'NL-VLBA', 'OV-VLBA', 'SC-VLBA'];
  private.info.VLBA.diam:=array(25.0,10);
  
##############################################################
#
# EVN Configuration (from EVN STATUS TABLE)
#  
#  ----------------------------------------------------------------------
#   | EVN OBSERVATORIES  |    TELESCOPE    |      AVAILABILITY           |
#   |                    |Code  Diameter(m)| (see also TABLE II )        |
#   |--------------------|-----------------|-----------------------------|
#   |Jodrell Bank (UK)   |Jb-1  Lovell  76 | Wavelengths >=6cm (5cm 2004)|
#   |                    |Jb-2  Mk2     25 | Wavelengths < 18 cm         |
#   |Cambridge (UK)      |Cm            32 | For EVN+MERLIN only - see(a)|
#   |Westerbork (NL)     |Wb    Array Nx25 | See note (b)                |
#   |Effelsberg (D)      |Eb/Ef        100 |                             |
#   |Medicina (I)        |Mc            32 |                             |
#   |--------------------|-----------------|-----------------------------|
#   |Noto (I)            |Nt            32 |                             |
#   |Onsala (S)          |On-85         25 | Wavelengths >= 5 cm         |
#   |                    |On-60         20 | Wavelengths < 5 cm, + 13 cm |
#   |Sheshan(Shanghai,CH)|Sh            25 |                             |
#   |Nanshan(Urumqi,CH)  |Ur            25 |                             |
#   |Torun (PL)          |Tr            32 |                             |
#   |--------------------|-----------------|-----------------------------|
#   |Metsaehovi (FI)     |Mh            14 | Wav. 1.3, 0.7 cm. 13,3.6pend|
#   |Yebes (E)           |Yb            14 | Wavel. 13, 3.6, 0.7 cm only |
#   |Arecibo (USA)       |Ar           305 | see note (c)                |
#   |Hartebeesthoek (SA) |Hh            26 |                             |
#   |Wettzell (D)        |Wz            20 | Limited; 13, 3.6 cm only    |
#   ----------------------------------------------------------------------
  private.info.EVN.names:=['JODLMKI', 'CAMB32', 'WB_Tied', 'EFLSBERG', 'MEDICINA', 'NOTO',
			   'ONSALA85', 'SESHAN25', 'URUMQI', 'TORUN',
			   'METSAHOV', 'YEBES', 'HARTRAO',
			   'WETTZELL'];
  private.info.EVN.diam:=[76, 32, sqrt(14)*25, 100, 32, 32, 25, 25, 25, 32, 14, 14,
			  26, 20];

##############################################################
#
# ATCA Configurations (from ATCA Observing guide)
#  
  private.info.ATCA6point0A.names:=['ATCA_03', 'ATCA_11', 'ATCA_16' ,  'ATCA_30',  'ATCA_34', 'ATCA_37'];
  private.info.ATCA6point0A.diam:=array(22.0,6);
  private.info.ATCA6point0B.names:=['ATCA_02', 'ATCA_12', 'ATCA_25', 'ATCA_31', 'ATCA_35', 'ATCA_37'];
  private.info.ATCA6point0B.diam:=array(22.0,6);
  private.info.ATCA6point0C.names:=['ATCA_01', 'ATCA_06', 'ATCA_21', 'ATCA_24', 'ATCA_31', 'ATCA_37']
  private.info.ATCA6point0C.diam:=array(22.0,6);
  private.info.ATCA6point0D.names:=['ATCA_15', 'ATCA_10', 'ATCA_13', 'ATCA_28', 'ATCA_30', 'ATCA_37'];
  private.info.ATCA6point0D.diam:=array(22.0,6);
  private.info.ATCA1point5A.names:=['ATCA_15', 'ATCA_18', 'ATCA_25', 'ATCA_28', 'ATCA_35', 'ATCA_37'];
  private.info.ATCA1point5A.diam:=array(22.0,6);
  private.info.ATCA1point5B.names:=['ATCA_19', 'ATCA_21', 'ATCA_27', 'ATCA_31', 'ATCA_34', 'ATCA_37'];
  private.info.ATCA1point5B.diam:=array(22.0,6);
  private.info.ATCA1point5C.names:=['ATCA_14', 'ATCA_22', 'ATCA_30', 'ATCA_33', 'ATCA_34', 'ATCA_37'];
  private.info.ATCA1point5C.diam:=array(22.0,6);
  private.info.ATCA1point5D.names:=['ATCA_16', 'ATCA_17', 'ATCA_24', 'ATCA_31', 'ATCA_35', 'ATCA_37'];
  private.info.ATCA1point5D.diam:=array(22.0,6);
  private.info.ATCA0point75A.names:=['ATCA_25', 'ATCA_27', 'ATCA_29', 'ATCA_33', 'ATCA_34', 'ATCA_37'];
  private.info.ATCA0point75A.diam:=array(22.0,6);
  private.info.ATCA0point75B.names:=['ATCA_14', 'ATCA_17', 'ATCA_21', 'ATCA_24', 'ATCA_26', 'ATCA_37'];
  private.info.ATCA0point75B.diam:=array(22.0,6);
  private.info.ATCA0point75C.names:=['ATCA_12', 'ATCA_13', 'ATCA_15', 'ATCA_18', 'ATCA_21', 'ATCA_37'];
  private.info.ATCA0point75C.diam:=array(22.0,6);
  private.info.ATCA0point75D.names:=['ATCA_15', 'ATCA_16', 'ATCA_22', 'ATCA_24', 'ATCA_25', 'ATCA_37'];
  private.info.ATCA0point75D.diam:=array(22.0,6);
  private.info.ATCA0point375.names:=['ATCA_02', 'ATCA_06', 'ATCA_08', 'ATCA_09', 'ATCA_10', 'ATCA_37'];
  private.info.ATCA0point375.diam:=array(22.0,6);
  private.info.ATCA0point210.names:=['ATCA_14', 'ATCA_15', 'ATCA_16', 'ATCA_17', 'ATCA_20', 'ATCA_37'];
  private.info.ATCA0point210.diam:=array(22.0,6);
  private.info.ATCA0point122A.names:=['ATCA_01', 'ATCA_02', 'ATCA_03', 'ATCA_04', 'ATCA_05', 'ATCA_37'];
  private.info.ATCA0point122A.diam:=array(22.0,6);
  private.info.ATCA0point122B.names:=['ATCA_05', 'ATCA_06', 'ATCA_07', 'ATCA_08', 'ATCA_09', 'ATCA_37'];
  private.info.ATCA0point122B.diam:=array(22.0,6);
  private.info.ATCA0point244.names:=['ATCA_01', 'ATCA_03', 'ATCA_05', 'ATCA_07', 'ATCA_09', 'ATCA_37'];
  private.info.ATCA0point244.diam:=array(22.0,6);
  #
  # Get the known arrays
  #
  public.getarrays:=function() {
    wider private, public;
    return field_names(private.info)~s/point/\./g;
  }
  #
  # Get the array station information only
  #
  private.getstations:=function(arrayname) {
    wider private, public;

    arrayname~:=s/\./point/g;
    if(has_field(private.info, arrayname)) {
      return private.info[arrayname];
    }
    else {
      return throw('Array ', arrayname, ' not in list of known configurations');
    }
  }
  #
  # Get all the array information
  #
  public.getarray:=function(arrayname='VLAD'){
    wider private, public;

    arrayname~:=s/\./point/g;
    rec:=private.getstations(arrayname);
    rec.telescope:=arrayname;
    
    if(is_fail(rec)) {
      return throw('Array ', arrayname, ' not understood');
    }
    else {
      include 'table.g';
      t:=table(private.schedtable, ack=F);
      query:='DBNAME in [';
      for (name in rec.names) {
	query:=spaste(query, '\'', name, '\', ');
      }
      query~:=s/\, $//g;
      query:=spaste(query, ']');
      st:=t.query(query);
      if(st.nrows()) {
	rec.x:=st.getcol('X');
	rec.y:=st.getcol('Y');
	rec.z:=st.getcol('Z');
        # Ensure that the order is correct
	rec.names:=st.getcol('DBNAME');
	rec.mount:=st.getcol('AXISTYPE');
        rec.mount~:=s/alta/alt-az/g;
        rec.mount~:=s/altz/alt-az/g;
        rec.mount~:=s/equa/equatorial/g;
        rec.mount~:=s/xyEW/x-y/g;
        rec.mount~:=s/xyNS/x-y/g;
        rec.mount~:=s/spac/space/g;
	rec.offset:=st.getcol('AXISOFF');
	t.done();
	return rec;
      }
      else {
	t.done();
	return throw('Array ', arrayname, ' elements not present in SCHED table');	
      }
    }
  }
  #
  # Get all possible stations
  #
  public.getallstations:=function() {
    wider private, public;
    include 'table.g';
    include 'sysinfo.g';
    t:=table(private.schedtable, ack=F);
    allstations:=t.getcol('DBNAME');
    t.close();
    return allstations;
  }

  public.done:=function() {
    wider private, public;
    public:=F;
    return T;
  }

  public.type:=function() {return "newsimhelper"};

  return public;
}

testnewsimhelper:=function(schedtable=unset) {
   
  mynewsimhelper:=newsimhelper(schedtable);

  print mynewsimhelper.getallstations();

  arrays:=mynewsimhelper.getarrays();
  for (arr in arrays) {
    rec:=mynewsimhelper.getarray(arr);
    print arr, ':', rec.names;
    if(len(rec.x)!=len(rec.names)) {
      print "Array ", arr, " has a different number of coordinates than stations";
    }
    if(len(rec.diam)!=len(rec.names)) {
      print "Array ", arr, " has a different number of diameter specifications than stations";
    }
  }
  return T;
}
