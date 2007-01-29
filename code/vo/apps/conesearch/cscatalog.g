# cscatalog:: NVO conesearch access
# Copyright (C) 2002,2003
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: APS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: cscatalog.g,v 19.0 2003/07/16 06:10:44 aips2adm Exp $

pragma include once
    

include 'note.g';

cscatalog := function() {

  private := [=];
  public  := [=];

  private.supported := "NVSS FIRST WENSS";

  include 'conesearch.g';
  private.cs:=conesearch();

  private.idtorow := function(id) {
    if(id==1) {
      return "TR";
    }
    else {
      return spaste("TR_", id-1);
    }
  }

  private.idtofield := function(id) {
    if(id==1) {
      return "TD";
    }
    else {
      return spaste("TD_", id-1);
    }
  }

  private.getfluxunit := function(catalog='NVSS') {
    wider public, private;
    note('Querying meta-data to determine flux units for catalog ', catalog);
    md := private.query(sr=0.0, catalog=catalog);
    ret:=private.findinfo(md.fields, 'FLUX');
    if(is_fail(ret)||!has_field(ret, 'unit')) {
      return throw('Failed to find units for FLUX column');
    }
    note('Flux units in catalog are ', ret.unit);
    return ret.unit;
  }

  private.findinfo := function(fields, name) {
    for (field in field_names(fields)) {
      if(fields[field]::.ID==name) {
	ret := [id=field ~ s/FIELD/TD/g];
	if(has_field(fields[field]::, 'unit')) {
	  ret['unit']:=fields[field]::['unit'];
	  ret['unit']~:=s/degree/deg/;
	  ret['unit']~:=s!/beam!!;
	  ret['unit']~:=s!jy!Jy!;
	  ret['unit']~:=s!JY!Jy!;
	}
	return ret;
      }
    }
    return throw('Cannot find column called ', name);
  }
#
# This works for any catalog
#
  private.query := function(ra=200, dec=40, sr=1, catalog='NVSS', fluxrange=F) {
    wider private, public;
    
    if(!is_numeric(ra)) {
      return throw('ra must be a numeric value');
    }
    if(!is_numeric(dec)) {
      return throw('dec must be a numeric value');
    }
    if(!is_numeric(sr)) {
      return throw('se must be a numeric value');
    }
    if(!is_string(catalog)) {
      return throw('catalog must be a string');
    }
    if(!any(private.supported==catalog)) {
      return throw('Catalog ', catalog, ' is not supported');
    }
#
# Hard coded until we register the service
#
    catalog := to_upper(catalog);

    url := spaste('http://www.aoc.nrao.edu/e2e/java/', catalog, 'ConeSearchServlet?');
#
    include 'quanta.g';
    fluxstring := F;
    if(!is_boolean(fluxrange)) {
      fluxunit := private.getfluxunit(catalog);
      if(!is_string(fluxunit)) {
	return throw('Unable to determine units of Flux column')
      }
      qfluxrange := [=];
      if(is_string(fluxrange)) {
	if(length(fluxrange)==1) {
	  qfluxrange := dq.quantity(fluxrange);
	  if(is_fail(qfluxrange)) {
	    return throw('fluxrange is not a valid quantity');
	  }
	  qfluxrange := dq.convert(qfluxrange, fluxunit);
	  if(is_fail(qfluxrange)) {
	    return throw('fluxrange is not a valid flux quantity');
	  }
	  fluxstring := spaste('flux=', qfluxrange.value);
	}
	else if(length(fluxrange)==2) {
	  qfluxrange := [=];
	  for (i in 1:2) {
	    qfluxrange[i] := dq.quantity(fluxrange[i]);
	    if(is_fail(qfluxrange[i])) {
	      return throw('fluxrange is not a valid quantity');
	    }
	    qfluxrange[i] := dq.convert(qfluxrange[i], fluxunit);
	    if(is_fail(qfluxrange[i])) {
	      return throw('fluxrange is not a valid flux quantity');
	    }
	    fluxstring := spaste('flux=between ',
				 qfluxrange[1].value,
				 ' and ',
				 qfluxrange[2].value);
	  }
	}
	else {
	  return throw('fluxrange is not a valid quantity');
	}
      }
      else if(is_record(fluxrange)) {
	if(length(fluxrange)==2) {
	  if(is_record(fluxrange[1])&&is_record(fluxrange[2])) {
	    qfluxrange := [=];
	    for (i in 1:2) {
	      qfluxrange[i] := dq.quantity(fluxrange[i]);
	      if(is_fail(qfluxrange[i])) {
		return throw('fluxrange is not a valid quantity');
	      }
	      qfluxrange[i] := dq.convert(fluxrange[i], fluxunit);
	      if(is_fail(qfluxrange[i])) {
		return throw('fluxrange is not a valid flux quantity');
	      }
	      fluxstring := spaste('flux=between ',
				   qfluxrange[1].value,
				   ' and ',
				   qfluxrange[2].value);
	    }
	  }
	  else {
	    qfluxrange := dq.quantity(fluxrange);
	    if(is_fail(qfluxrange)) {
	      return throw('fluxrange is not a valid quantity');
	    }
	    qfluxrange := dq.convert(qfluxrange, fluxunit);
	    if(is_fail(qfluxrange)) {
	      return throw('fluxrange is not a valid flux quantity');
	    }
	    fluxstring := spaste('flux=', qfluxrange.value);
	  }
	}
      }
      if(is_boolean(fluxstring)||is_fail(fluxstring)) {
	return throw('fluxrange ', fluxrange, ' is not a quantity or record of quantities');
      }
    }
    private.rec := private.cs.query(ra=ra, dec=dec, sr=sr, url=url, extra=fluxstring);
    if(is_fail(private.rec)) {
      return throw('Query failed : ', private.rec::message);
    }
    if(!is_record(private.rec.VOTABLE.RESOURCE)) {
      return throw('Query failed to produce readable VOTable');
    }
    rec := private.rec.VOTABLE.RESOURCE.TABLE;
    coosys := private.rec.VOTABLE.DEFINITIONS.COOSYS::
    names := field_names(rec);
    mask := names ~ m/FIELD*/;
    return [fields=rec[names[mask]], data=rec[names[!mask]].TABLEDATA,
	    coosys=coosys];
  }
#
# Query a given direction
#
  public.querydirection := function(direction, sr='1deg', catalog='NVSS', fluxrange=F) {
    wider private, public;
    include 'measures.g';

    if(!is_measure(direction)) {
      return throw('direction is not a measure');
    }
    if(direction.type!='direction') {
      return throw('direction is not a direction measure');
    }
    if(is_string(sr)) {
      sr := dq.quantity(sr);
    }
    if(!is_quantity(sr)) {
      return throw('Search radius must be a quantity');
    }
    sr := dq.convert(sr, 'deg')
    if(!is_quantity(sr)) {
      return throw('Search radius must be an angle quantity');
    }
    sr := sr.value;
    if(!is_string(catalog)) {
      return throw('catalog must be a string');
    }
    if(!any(private.supported==catalog)) {
      return throw('Catalog ', catalog, ' is not supported');
    }

    direction := dm.measure(direction, 'J2000');
    ra := dq.convert(direction.m0, 'deg').value;
    dec := dq.convert(direction.m1, 'deg').value;
    note('Querying catalog ', catalog, ' for cone of ', sr, ' deg around direction ',
	 dm.show(direction));

    catalog := to_upper(catalog);

    if(!any(private.supported==catalog)) {
      return throw('Catalog ', catalog, ' is not supported');
    }

    rec := private.query(ra, dec, sr, catalog, fluxrange=fluxrange);
    if(is_fail(rec)) fail;
    if(length(rec.data)==0) {
      return throw('No sources found', origin='cscatalog.queryimageascomplist');
    }

#
# Find mappings between FIELD*s and keywords: this should be done via UCD's
# Hard code these until it is running
#
    private.fieldinfo := [=];
    if(catalog=='NVSS') {
      private.fields := "RA DEC FLUX MAJOR_AX MINOR_AX POSANGLE FIELD_ID";
    }
    else if(catalog=='WENSS') {
      private.fields := "NAME RA DEC FLUX RMS MAJOR_AX MINOR_AX POSANGLE FIELD_ID";
    }
    else {
      private.fields := "RA DEC FLUX MAJOR_AX MINOR_AX POSANGLE FIELD_ID RMS fMAJOR_AX fMINOR_AX fPOSANGLE ";
    }
    
    for (field in private.fields) {
      ret:=private.findinfo(rec.fields, field);
      if(is_fail(ret)) {
	return throw('Failed to find FIELD information for column ', field, ' : ', ret::message);
      }
      private.fieldinfo[field] := ret;
    }

    include 'componentlist.g';
    cl := emptycomponentlist();
    ncomp := length(field_names(rec.data) ~ m/TR*/);
    if(ncomp==0) {
      return throw('No sources found', origin='cscatalog.queryimage');
    }
    note('Found ', ncomp, ' rows in VOTable');

#
# Now convert the data into components
#
    ndeselect := 0;
    for (rowid in field_names(rec.data)) {
      if(rowid ~ m/TR*/) {
	thiscomp := rec.data[rowid];
	ok := cl.simulate(1, log=F);
	which := cl.length();

        if(catalog=='NVSS') {
	}
        else if(catalog=='WENSS') {
	}
	else {
	  id := private.fieldinfo["WARN"].id;
	  warn := thiscomp[id];
	  if(warn!='') {
	    cl.deselect(which, log=F);
	    ndeselect +:= 1;
	  }
	}

	id := private.fieldinfo["FLUX"].id; unit:= private.fieldinfo["FLUX"].unit;
	flux:=[as_float(thiscomp[id]), 0, 0, 0];
	error:=[0.0, 0.0, 0.0, 0.0];
	if((catalog=='FIRST')||(catalog=='WENSS')) {
	  id := private.fieldinfo["RMS"].id; 
	  error:=[as_float(thiscomp[id]), 0.0, 0.0, 0.0];
	}
	ok := ok && cl.setflux(which, value=flux, unit=unit, polarization='Stokes', error=error, log=F);
#
# Do position information
#
	id := private.fieldinfo["RA"].id; unit:= private.fieldinfo["RA"].unit;
	ra := dq.time(dq.totime(dq.quantity(as_float(thiscomp[id]), unit)), prec=9);
	id := private.fieldinfo["DEC"].id; unit:= private.fieldinfo["DEC"].unit;
	dec := dq.angle(dq.toangle(dq.quantity(as_float(thiscomp[id]), unit)), prec=9);
	ok := ok && cl.setrefdir(which, ra=ra, raunit='time', dec=dec, decunit='angle', log=F);
	ok := ok && cl.setrefdirframe(which, frame='J2000', log=F);

#
# Now do the shape
#
	id := private.fieldinfo["MAJOR_AX"].id; unit:= private.fieldinfo["MAJOR_AX"].unit;
	majoraxis := dq.quantity(as_float(thiscomp[id]), unit);
	if(as_float(thiscomp[id])<=0.0) {
	    ok := ok && cl.setshape(which, type='Point', log=F);
	}
	else {
	  id := private.fieldinfo["MINOR_AX"].id; unit:= private.fieldinfo["MINOR_AX"].unit;
	  minoraxis := dq.quantity(as_float(thiscomp[id]), unit);
	  id := private.fieldinfo["POSANGLE"].id; unit:= private.fieldinfo["POSANGLE"].unit;
	  positionangle := dq.quantity(as_float(thiscomp[id]), unit);
	  if(majoraxis.value<minoraxis.value) {
	    id := private.fieldinfo["MINOR_AX"].id; unit:= private.fieldinfo["MINOR_AX"].unit;
	    majoraxis := dq.quantity(as_float(thiscomp[id]), unit);
	    id := private.fieldinfo["MAJOR_AX"].id; unit:= private.fieldinfo["MAJOR_AX"].unit;
	    minoraxis := dq.quantity(as_float(thiscomp[id]), unit);
	    id := private.fieldinfo["POSANGLE"].id; unit:= private.fieldinfo["POSANGLE"].unit;
	    positionangle := dq.quantity(90.0+as_float(thiscomp[id]), unit);
	  }
	  
	  if(catalog=='FIRST') {
	    id := private.fieldinfo["fMAJOR_AX"].id; unit:= private.fieldinfo["fMAJOR_AX"].unit;
	    fmajoraxis := dq.quantity(as_float(thiscomp[id]), unit);
	    id := private.fieldinfo["fMINOR_AX"].id; unit:= private.fieldinfo["fMINOR_AX"].unit;
	    fminoraxis := dq.quantity(as_float(thiscomp[id]), unit);
	    id := private.fieldinfo["fPOSANGLE"].id; unit:= private.fieldinfo["fPOSANGLE"].unit;
	    fpositionangle := dq.quantity(as_float(thiscomp[id]), unit);
	    if(majoraxis.value<minoraxis.value) {
	      id := private.fieldinfo["fMINOR_AX"].id; unit:= private.fieldinfo["fMINOR_AX"].unit;
	      fmajoraxis := dq.quantity(as_float(thiscomp[id]), unit);
	      id := private.fieldinfo["fMAJOR_AX"].id; unit:= private.fieldinfo["fMAJOR_AX"].unit;
	      fminoraxis := dq.quantity(as_float(thiscomp[id]), unit);
	    }
	    ok := ok && cl.setshape(which, type='Gaussian', majoraxis=majoraxis, minoraxis=minoraxis,
				    positionangle=positionangle, majoraxiserror=fmajoraxis,
				    minoraxiserror=fminoraxis, positionangleerror=fpositionangle,
				    log=F);
	  }
	  else {
	    ok := ok && cl.setshape(which, type='Gaussian', majoraxis=majoraxis, minoraxis=minoraxis,
				    positionangle=positionangle, log=F);
	  }
	}
#
# Fill in the label information
#
	if(catalog=='WENSS') {
	  id := private.fieldinfo["NAME"].id;
	  label := thiscomp[id];
	  ok := ok && cl.setlabel(which, label, log=F);
	}
	else {
	  id := private.fieldinfo["FIELD_ID"].id;
	  label := thiscomp[id];
	  ok := ok && cl.setlabel(which, label, log=F);
	}

	if(catalog=='NVSS') {
	  ok := ok && cl.setfreq(which, 1.415, 'GHz', log=F);
	}
	else if(catalog=='WENSS') {
	  ok := ok && cl.setfreq(which, 0.325, 'GHz', log=F);
	}
	else {
	  ok := ok && cl.setfreq(which, 1.415, 'GHz', log=F);
	}

	if(is_fail(ok)) return throw('Failed to add component ', ok::message);
      }
    }
    if(ndeselect>0) {
      note('Deselected ', ndeselect, ' components because of warnings', priority='WARN');
    }
    note('Finished converting query VOTable to componentlist');
    return cl;
  }
#
# Query for an image
#
  public.queryimage := function(im, catalog='NVSS', fluxrange=F) {
    wider private, public;
    include 'image.g';

    if(!is_image(im)) {
      return throw('im must be an image');
    }
    if(!is_string(catalog)) {
      return throw('catalog must be a string');
    }
    if(!any(private.supported==catalog)) {
      return throw('Catalog ', catalog, ' is not supported');
    }

    cs := im.coordsys();
    if(is_fail(cs)) {
      return throw('Failed to open image coordinate system  :', cs::message);
    }
#
# Change coordinate system as needed
#
    refcode := cs.referencecode('dir');
    if(refcode!='J2000') {
      note('Reference system of image is not J2000 - need to convert');
      cs.setreferencecode(value='J2000', type='dir', adjust=T);
    }

    include 'quanta.g';
    pcen := [im.shape()[1]/2, im.shape()[2]/2]; 
    qcen := cs.toworld(pcen, 'q');
    racen := dq.convert(qcen[1], 'deg').value;
    deccen := dq.convert(qcen[2], 'deg').value;
    deccenrad := dq.convert(qcen[2], 'rad').value;

    pcorn := [1, 1];
    qcorn := cs.toworld(pcorn, 'q');
    racorn := dq.convert(qcorn[1], 'deg').value;
    deccorn := dq.convert(qcorn[2], 'deg').value;

    if((racen-racorn)>180.0) racen-:=360.0;
    if((racen-racorn)<-180.0) racen+:=360.0;

    sr := sqrt((cos(deccenrad)*(racen-racorn)*cos(deccenrad)*(racen-racorn))
	       +(deccen-deccorn)*(deccen-deccorn));
    sr := spaste(sr, 'deg');

    if(racen<0.0) racen+:=360.0;
    direction := dm.direction('J2000', qcen[1], qcen[2]);
    return public.querydirection(direction=direction, sr=sr, catalog=catalog,
				 fluxrange=fluxrange);
  }

  public.type := function() {return 'cscatalog'};

  public.done := function() {
    wider private, public;
    private.cs.done();
  }
  
  return ref public;
}
