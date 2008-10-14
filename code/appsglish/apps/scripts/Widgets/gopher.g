# gopher: get info from various places
# Copyright (C) 1996,1997,1998,1999,2000,2001
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
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
# $Id: gopher.g,v 19.2 2004/08/25 02:14:25 cvsmgr Exp $


pragma include once
    
include 'widgetserver.g';
include 'viewer.g';

gopher := function(widgetset=ddlws) {
  
  public := [=];
  private := [=];
  private.widgetset := widgetset;

  private.callbacks := [=];

  private.gc := [=];

  private.lim := [=];

  private.whenevers := [=];
  private.pushwhenever := function(name) {
    wider private;
    if(!has_field(private.whenevers, name)) {
      private.whenevers[name] := [];
    }
    private.whenevers[name][len(private.whenevers[name]) + 1] :=
	last_whenever_executed();
  }
  
  # Get the file name and callback as appropriate
  private.getfile := function(file, type, callback) {
    wider private;
    include 'os.g';
    if(is_unset(file)||!dos.fileexists(file)) {
      note('Please select a valid ', type, ' and press Send&dismiss');
      include 'catalog.g';
      private.catalog := catalog();
      private.catalog.gui();
      private.catalog.show(show_types=type);
      private.catalog.setselectcallback(callback);
      return T;
    }
    else {
      return callback(file);
    }
  }

  private.processmsreturns := function(what, value) {
    if(what=='fieldnames') {
      if(is_record(value)&&has_field(value, 'labels')) {
	return value.labels;
      }
      else {
	return value;
      }
    }
    else if(what=='baselines') {
      if(is_record(value)&&has_field(value, 'selection')&&
	 !is_boolean(value.selection)) {
	return 1000*value.selection[1,]+value.selection[2,];
      }
      else {
	return value;
      }
    }
    else {
      if(is_record(value)&&has_field(value, 'selection')) {
	return value.selection;
      }
      else {
	return value;
      }
    }
  }
  
  public.fromms := function(file=unset, what='antennas', cb=unset) {
    wider private;
    include 'ms.g';

    private.what := what;
    private.callbacks[what] := cb;

    file := private.getfile(file, 'Measurement Set', private.fromms);
    return T;
  }

  private.fromms := function(file=unset) {
    wider private;
    include 'ms.g';

    include 'table.g';
    if(!tableexists(file)) {
      return throw (spaste('MeasurementSet ', file, ' does not exist'));
    }
    localms := table(spaste(file), ack=F);
    if(!is_table(localms)) {
      return throw (spaste('Failed to open ', file, ' as a table'));
    }

    # msselect ##################################################
    if(private.what=='msselect') {
      include 'taqlwidget.g';
      cdesc := localms.getdesc();
      localms.done();
      tw := taqlwidget(cdesc, 'MS Selection', cangiving=F,
		       widgetset=private.widgetset);
      if(!is_unset(private.callbacks[private.what])) {
        whenever tw->returns do {
	  value := $value;
	  private.callbacks['msselect'](value);
	  deactivate private.whenevers['msselect'];
	} private.pushwhenever('msselect');
	return T;
      }
      else {
	await tw->returns;
	value := $value;
	return $value.where;
      }
    }
    # antennas  ##################################################
    # baselines ##################################################
    else if(private.what=='antennas'||private.what=='baselines') {
      # Get the baselines actually in the measurement set
      note('Finding antennas actually present in the MeasurementSet');
      ants1 :=localms.getcol('ANTENNA1')+1;
      ants2 :=localms.getcol('ANTENNA2')+1;
      ants:= unique(sort([ants1,ants2]));
      ifrs  :=unique(sort(1000*ants1+ants2));

      # Now get the locations
      anttable := table(spaste(localms.name(), '/ANTENNA'), ack=F);
      localms.done();
      name := anttable.getcol('NAME');
      station := anttable.getcol('STATION');
      antids := 1:length(name);
      if(private.what=='baselines') {
	if(length(ants)==1) {
	  if(!is_unset(private.callbacks[private.what])) {
	    private.callbacks[private.what](1000*ants[1]+ants[1]);
	  }
	  else {
	    return 1000*ants[1]+ants[1];
	  }
	}
	include 'combochooser.g';
	nant := length(antids);
	labels := array('', nant);
	for (ant in antids) {
	  if(any(ant==ants)) {
	    labels[ant] := spaste(name[ant],'=',station[ant]);
	  }
	}
        ifrs  :=unique(sort(1000*ants1+ants2));
        ifrmask:=array(F,nant,nant);
        for (i in 1:length(ifrs)) {
	  ifrmask[as_integer(ifrs[i]/1000),ifrs[i]%1000]:=T;
        }
	ifrmask::shape:=nant*nant;

	private.gc[private.what] := combochooser(parent=unset, 
                           idx1=antids, labels1=labels, 
                           idx2=antids, labels2=labels, imask=ifrmask,
			   xlabel='Antenna1', ylabel='Antenna2',
			   plottitle='Baselines',
			   title='Baseline chooser (AIPS++)',
			   width=500, height=500,
                           pad=0.3,
			   widgetset=private.widgetset);
      }
      else {
	if(length(ants)==1) {
	  if(!is_unset(private.callbacks[private.what])) {
	    private.callbacks[private.what](ants[1]);
	  }
	  else {
	    return ants[1];
	  }
	}
	include 'gchooser.g';
        include 'mathematics.g';
	position := anttable.getcol('POSITION');
	posref := anttable.getcolkeyword('POSITION','MEASINFO').Ref;
	posunit := anttable.getcolkeyword('POSITION','QuantumUnits');
	anttable.close();
	if(length(name)==1) {
	  if(!is_unset(private.callbacks[private.what])) {
	    private.callbacks[private.what](1);
	  }
	  else {
	    return 1;
	  }
	}

        # size of the array as a quantity
	arraysize:= dq.quantity(sqrt(
                      (max(position[1,])-min(position[1,]))^2 +
                      (max(position[2,])-min(position[2,]))^2 +
                      (max(position[3,])-min(position[3,]))^2),posunit[3]); 


        # Actual number of ants (may be fewer than in ANTENNA table)
	nant := length(ants);

	# If array larger than 100km, show long/lat, else local distances
	if ( dq.getvalue(dq.convert(arraysize,'km'))>100.0 ) {
          xlabel:='Longitude (deg)'
          ylabel:='Latitude (deg)'
	  x := array(0.0, nant);
	  y := array(0.0, nant);
	  labels := array('', nant);
	  i := 0;
	  include 'quanta.g';
	  for (ant in antids) {
	    if(any(ant==ants)) {
	      i+:=1;
	      # put position coords into measure from which long/lat extractable:
	      posmeas:=dm.position(posref,dq.quantity(position[1,ant],posunit[1]),
				 dq.quantity(position[2,ant],posunit[2]),
				 dq.quantity(position[3,ant],posunit[3]));
	    
	      x[i] := dq.convert(posmeas.m0,'deg').value; # long in degrees
	      y[i] := dq.convert(posmeas.m1,'deg').value; # lat in degrees
	      labels[i] := spaste('Name=',name[ant],', Station=',station[ant]);
	    }
	  }
	} else {
          xlabel:= 'X (m)'
          ylabel:= 'Y (m)'

          mposition:=[mean(position[1,]),mean(position[2,]),mean(position[3,])];
          long:=atan(mposition[2]/mposition[1]);
	  if (mposition[1] < 0.0) long:=long+pi;
          lat:=atan(mposition[3]/sqrt(mposition[1]^2 + mposition[2]^2));


          include 'matrix.g'
	  i:=0;
	  for (ant in antids) {
            if (any(ant==ants)) {
              i+:=1;
              position[,ant]:=position[,ant]-mposition;
              position[[1,2],ant]:=mx.rotate(position[[1,2],ant],-long);
              position[[1,3],ant]:=mx.rotate(position[[1,3],ant],-lat);

	      x[i]:=position[2,ant];
	      y[i]:=position[3,ant];

	      labels[i] := spaste('Name=',name[ant],', Station=',station[ant]);
            }
          }
        }

	private.gc[private.what] := gchooser(parent=unset, 
                       indices=ants, 
                       labels=labels, 
                       x=x, y=y,
		       plottitle='Antenna locations (labeled by ms indices)',
                       xlabel=xlabel, ylabel=ylabel,
		       title='Antenna chooser (AIPS++)',
		       width=500, height=500,
		       widgetset=private.widgetset);
      }
    }
    # fields     ##################################################
    # fieldnames ##################################################
    else if ((private.what=='fields')||(private.what=='fieldnames')) {
      fieldtable := table(spaste(localms.name(), '/FIELD'), ack=F);
      name := fieldtable.getcol('NAME');
      fields := localms.getcol('FIELD_ID')+1;
      localms.done();
      note('Finding fields actually present in the MeasurementSet');
      fields := unique(sort(fields));
      if(length(fields)==1) {
        note('Using the only field found in the MeasurementSet');        
	if(private.what=='fields') {
	  if(!is_unset(private.callbacks[private.what])) {
	    private.callbacks[private.what](fields[1]);
	  }
	  return fields[1];
	}
	else {
	  if(!is_unset(private.callbacks[private.what])) {
	    private.callbacks[private.what](name[fields[1]]);
	  }
	  return name[fields[1]];
	}
      }
      
      note('Found multiple fields in the MeasurementSet');
      note('Launching the graphical chooser');

      # Now get the locations
      position := fieldtable.getcol('PHASE_DIR');
      posref := fieldtable.getcolkeyword('PHASE_DIR','MEASINFO').Ref;
      posunit := fieldtable.getcolkeyword('PHASE_DIR','QuantumUnits');
      fieldids :=1:length(name);
      include 'gchooser.g';
      nfields := length(fields);
      labels := array('', nfields);
      x := array(0, nfields);
      y := array(0, nfields);
      i:=0;
      include 'quanta.g';
      for (field in fieldids) {
	if(any(field==fields)) {
          i+:=1;
	  labels[i] := spaste(name[field],' (',as_string(field),')');
	    # put position coords into measure from which long/lat extractable:
	  posmeas:=
	      dm.direction(posref,
			   dq.quantity(position[1,1,field],posunit[1]),
			   dq.quantity(position[2,1,field],posunit[2]));
	    
	  x[i] := dq.convert(posmeas.m0,'rad').value; # long in degrees
	  y[i] := dq.convert(posmeas.m1,'rad').value; # lat in degrees
	}
      }
      title:='Field chooser (AIPS++)';
      plottitle:='Fields';
      if(private.what=='fieldnames') {
	title:='Field name chooser (AIPS++)';
	plottitle:='Fieldnames';
      }

      private.gc[private.what] := gchooser(parent=unset, indices=fields, labels=labels, x=x, y=y,
		     xlabel='Right Ascension', ylabel='Declination',
		     title=title, plottitle=plottitle,
		     axes='sky',
		     width=500, height=500,
		     widgetset=private.widgetset);
    }
    # polarizations ##################################################
    else if (private.what=='polarizations') {

      # Now get the locations
      poltable := table(spaste(localms.name(), '/POLARIZATION'), ack=F);
      localms.done();
      numcorr := poltable.getcol('NUM_CORR');
      corrprod := poltable.getcol('CORR_PRODUCT');
      if(length(numcorr)==1) {
	if(!is_unset(private.callbacks[private.what])) {
	  private.callbacks[private.what](1);
	}
	return 1;
      }
      polids :=1:length(corrprod);
      include 'gchooser.g';
      npols := length(corrprod);
      labels := array('', npols);
      x := array(0.0, npols);
      y := array(0.0, npols);
      for (pol in polids) {
	labels[pol] := spaste('Correlations: ', corrprod[pol]);
	x[pol] := numcorr[pol];
	y[pol] := pol;
      }
      private.gc[private.what] := gchooser(parent=unset, indices=polids, labels=labels,
		     x=x, y=y, xlabel='Number of correlations', ylabel='Polarization',
		     plottitle='Polarizations',
		     title='Polarization chooser (AIPS++)',
		     width=500, height=500,
		     widgetset=private.widgetset);
    }
    else if (private.what=='datadescriptions') {
      dds := localms.getcol('DATA_DESC_ID')+1;
      note('Finding datadescriptions actually present in the MeasurementSet');
      dds := unique(sort(dds));
      
      # Now get the locations
      ddtable := table(spaste(localms.name(), '/DATA_DESCRIPTION'), ack=F);
      spwids := ddtable.getcol('SPECTRAL_WINDOW_ID')+1;
      ddtable.close();
      if(length(spwids)==1) {
	if(!is_unset(private.callbacks[private.what])) {
	  private.callbacks[private.what](1);
	}
	return 1;
      }
      ddids := 1:length(spwids);
      polids := ddtable.getcol('POLARIZATION_ID')+1;
      poltable := table(spaste(localms.name(), '/POLARIZATION'), ack=F);
      numcorr := poltable.getcol('NUM_CORR');
      corrprod := poltable.getcol('CORR_PRODUCT');
      poltable.close();
      spwtable := table(spaste(localms.name(), '/SPECTRAL_WINDOW'), ack=F);
      localms.done();
      numchan := spwtable.getcol('NUM_CHAN');
      freq := spwtable.getcol('REF_FREQUENCY');
      spwtable.close();
      polids :=1:length(corrprod);
      spwids :=1:length(numchan);
      include 'gchooser.g';
      ndds := length(spwids);
      labels := array('', length(dds));
      i:=0;
      for (dd in ddids) {
	if(any(dd==dds)) {
	  i+:=1;
	  x[i] := spwids[dd];
	  y[i] := polids[dd];
	  labels[i] := spaste(numchan[dd], ' chan, ', numcorr[dd], ' corr');
	}
      }
      private.gc[private.what] := gchooser(parent=unset, indices=dds, labels=labels,
		     x=x, y=y, xlabel='Spectral Window', ylabel='Polarization',
		     plottitle='Data Descriptions',
		     title='Data Description chooser (AIPS++)',
		     width=500, height=500, 
		     widgetset=private.widgetset);
    }
    # spectralwindows ################################################
    else if (private.what=='spectralwindows') {
      # Now get the locations
      spwtable := table(spaste(localms.name(), '/SPECTRAL_WINDOW'), ack=F);
      localms.done();
      numchan := spwtable.getcol('NUM_CHAN');
      freq := spwtable.getcol('REF_FREQUENCY');
      if(length(numchan)==1) {
	if(!is_unset(private.callbacks[private.what])) {
	  private.callbacks[private.what](1);
	}
	return 1;
      }
      spwids :=1:length(numchan);
      include 'gchooser.g';
      nspws := length(numchan);
      labels := array('', nspws);
      x := array(0.0, nspws);
      y := array(0.0, nspws);
      for (spw in spwids) {
	labels[spw] := spaste(numchan[spw], ' channels');
	x[spw] := freq[spw];
	y[spw] := as_float(spw);
      }
      private.gc[private.what] := gchooser(parent=unset, indices=spwids, labels=labels,
		     x=x, y=y,
		     xlabel='Reference frequency', ylabel='Spectral Window',
		     plottitle='Spectral Windows',
		     title='SpectralWindow chooser (AIPS++)',
		     width=500, height=500, pad=0.25,
		     widgetset=private.widgetset);
    }
    # Now process returns
    if(!is_agent(private.gc[private.what])) {
      if(is_fail(private.gc[private.what])) {
	return throw('Failed to construct chooser : ', private.gc[private.what]::message);
      }
      else {
	return throw('Failed to construct chooser');
      }
    }
    # We have a callback
    if(!is_unset(private.callbacks[private.what])) {
      private.gc[private.what].what := private.what;
      whenever private.gc[private.what]->values do {
	what := $agent.what;
	agent := $agent;
        value := private.processmsreturns(what, $value);
	private.callbacks[what](value);
	agent.done();
	deactivate private.whenevers[what];
      } private.pushwhenever(private.what);
      return T;
    }
    # No callback: just await
    else {
      await private.gc[private.what]->values;
      value := $value;
      private.gc[private.what].done();
      private.gc[private.what] := F;
      return private.processmsreturns(private.what, value);
    }
  }

  public.fromimage := function(file=unset, what='region', cb=unset) {
    wider private;
    private.what := what;
    private.callbacks[what] := cb;

    file := private.getfile(file, 'Image', private.fromimage);
  }

  private.fromimage := function(file=unset) {
    wider private;

    include 'table.g';
    if(is_unset(file)) {
      return throw ('Image name must be set')
    }
    if(!tableexists(file)) {
      return throw (spaste('Image ', file, ' does not exist'));
    }
    note('Opening and displaying Image ', file);
    include 'image.g';
    private.lim[private.what] := image(file);
    if(is_image(private.lim[private.what])) {
      private.lim[private.what].view(raster=T, activatebreak=T,
		   hasdismiss=F, widgetset=private.widgetset);
      if(private.what=='measure') {
	note('Please select a point on the viewer');
	if(!is_unset(private.callbacks[private.what])) {
          whenever private.lim['measure']->position do {
	    name := $name;
	    value := $value;
	    note('Received position: Press Done on viewer when done');
	    private.callbacks['measure'](value);
          } private.pushwhenever('measure');
          whenever private.lim['measure']->viewerdone,
	      private.lim['measure']->breakfromviewer do {
	    private.lim['measure'].done();
	    deactivate private.whenevers['measure'];
          } private.pushwhenever('measure');
	  return T;
	} else {
	  await private.lim['measure']->*,
	      private.lim['measure']->position,
	      private.lim['measure']->viewerdone,
	      private.lim['measure']->breakfromviewer;
	  name := $name;
	  value := $value;
	  private.lim['measure'].done();
	  if(name!='position') {
	    return throw('User exited without selecting a point ', name);
	  }
	  else {
	    note('Received position');
	    return value;
	  }
	}
      }
      # region ################################################
      else if (private.what=='region') {
	note('Please select a region on the viewer');
	if(!is_unset(private.callbacks[private.what])) {
          whenever private.lim['region']->region do {
	    name := $name;
	    value := $value;
	    if(has_field(value, 'region')) {
	      note('Received region: Press Done on viewer when done');
	      private.callbacks['region'](value.region);
	    }
          } private.pushwhenever('region');

          whenever private.lim['region']->viewerdone,
	      private.lim['region']->breakfromviewer do {
	    private.lim['region'].done();
	    deactivate private.whenevers['region'];
          } private.pushwhenever('region');
	  return T;
	} else {
	  await  private.lim['region']->*,
	      private.lim['region']->region, private.lim['region']->viewerdone,
	      private.lim['region']->breakfromviewer;
	  name := $name;
	  value := $value;
	  private.lim['region'].done();
	  if(name!='region') {
	    return throw('User exited without selecting a region ', name);
	  }
	  else {
	    note('Received region');
	    return value.region;
	  }
	}
      }
      # statistics #############################################
      else if (private.what=='statistics') {
	note('Please open the statistics window on the viewer');
	if(!is_unset(private.callbacks[private.what])) {
          whenever private.lim['statistics']->viewerdone do {
	    name := $name;
	    value := $value;
	    note('Received statistics: Press Done on viewer when done');
	    private.callbacks['statistics'](value);
          } private.pushwhenever('statistics');
          whenever private.lim['statistics']->viewerdone,
	      private.lim['statistics']->breakfromviewer do {
	    name := $name;
	    private.lim['statistics'].done();
	    deactivate private.whenevers['statistics'];
          } private.pushwhenever('statistics');
	  return T;
	}
	else {
	  await  private.lim['statistics']->*,
	      private.lim['statistics']->statistics,
		  private.lim['statistics']->viewerdone,
	      private.lim['statistics']->breakfromviewer;
	  name := $name;
	  value := $value;
	  private.lim['statistics'].done();
	  if(name!='statistics') {
	    return throw('User exited without selecting statistics ', name);
	  }
	  else {
	    note('Received statistics');
	    return value;
	  }
	}
      }
    }
    else {
      return throw(spaste('Failed to open image ', file));
    }
  }

  return public;
}

const gophermstest := function(async=T) {
  include 'imager.g';
  if(!tableexists('XCAS.ms')) imagermaketestmfms('XCAS.ms');
  private := [=];
  global printit := function(x) {print x;};
  for (s in "msselect antennas baselines fields fieldnames spectralwindows polarizations") {
    if(async) {
      print s, dgo.fromms('XCAS.ms', s, printit);
    }
    else {
      print s, dgo.fromms('XCAS.ms', s);
    }
  }
}

const gopherimagetest := function(async=T) {
  include 'image.g';
  if(!tableexists('testimage.im')) {
    im:=imagemaketestimage('testimage.im');
    im.done();
  }
  private := [=];
  global printit := function(x) {print x;};
  for (s in "measure region statistics") {
    if(async) {
      print s, dgo.fromimage('testimage.im', s, printit);
    }
    else {
      print s, dgo.fromimage('testimage.im', s);
    }
  }
}

const defaultgopher := gopher();
const dgo := ref defaultgopher;

note('defaultgopher (dgo) ready', priority='NORMAL', origin='gopher.g');
