# componentlist.g:
# Copyright (C) 1997,1998,1999,2000,2001,2003
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
#
# $Id: componentlist.g,v 19.5 2006/06/02 00:56:25 mvoronko Exp $

pragma include once

include 'note.g';
include 'plugins.g';
include 'quanta.g';
include 'unset.g';

const _define_componentlist := subsequence(ref agent, id) {
  private := [=];
  include 'defaultattributes.g';
  defaultattributes(self);
  private.agent := ref agent;
  private.id := id;

  private.activeguis := [];
  const self.guis := function() {
    wider private;
    return private.activeguis; 
  }
  
  const self.sendevents := function(which) {
    wider private;
    private.activeguis := [private.activeguis, which];
  }
  
  const self.stopevents := function(which) {
    wider private;
    newguis :=  [];
    for (i in private.activeguis) {
      if (i != which) {
	newguis := [newguis,i];
      }
    }
    private.activeguis := newguis;
  }
  
  const self.dismiss := function(which=unset) {
    wider self, private;
    if (len(private.activeguis) > 0) {
      if (is_unset(which)) {
	which := private.activeguis;
      }
      for (i in which) {
	if (any(private.activeguis == i)) { 
#	  print 'Sending  a dismiss event to component', i;
	  self->dismiss(i);
	}
	self.stopevents(i);
      }
    }
    return T;
  }

  const private.changed := function(which) {
    wider self, private;
    for (i in which) {
      if (any(private.activeguis == i)) { 
#	print 'Sending changed events to component', i;
	self->changed(i);
      }
    }
  }
# The add function is scheduled to be removed in a future revision of
# this tool. Hence it is undocumented. Instead use the simulate
# function to add components to the list
  private.addRec := [_method = 'add',
		     _sequence = private.id._sequence];
  const self.add := function(component, iknow=F) {
    wider private;
    if (iknow == F) {
      note('The "add" function in the componentlist tool will be removed', 
	   ' in a future version of AIPS++.', 
	   priority='WARN', origin='componentlist.add');
    }
    private.addRec.component := component;
    ok := defaultservers.run(private.agent, private.addRec);
    private.changed([self.length()]);
    return ok;
  }

  private.componentRec := [_method = 'component',
			   _sequence = private.id._sequence];

# The component function is scheduled to be removed in a future
# revision of this tool. Hence it is undocumented. Instead use the
# get* functions to enquire about component properties.
  const self.component := function(which, iknow=F) {
    wider private;
    if (iknow == F) {
      note('The "component" function in the componentlist tool will be ',
	   'removed in a future version of AIPS++.', 
	   priority='WARN', origin='componentlist.component');
    }
    private.componentRec.which := which;
    return defaultservers.run(private.agent, private.componentRec);
  }

  private.replaceRec := [_method = 'replace',
			 _sequence = private.id._sequence];
  const self.replace := function(which, list=unset, whichones, log=T) {
    wider private;

# Allowing an unset Componentlist is to work around toolmanager deficiencies
# with tool inputs

    if (is_unset(list)) {
       note('No input componentlist given - nothing to do', origin='componentlist.replace',
            priority='WARN')
       return T;
    }

    if (!is_componentlist(list)) {
      throw('The list argument must be a componentlist tool');
    }
    private.replaceRec.which := which;
    private.replaceRec.list := list.id();
    private.replaceRec.whichones :=  whichones;
    ok := defaultservers.run(private.agent, private.replaceRec);
    ok := T;
    if (ok & log) {
      note('Replaced component(s) ', which, origin='componentlist.replaced');
    }
    private.changed(which);
    return ok;
  }

  private.concatenateRec := [_method = 'concatenate',
			     _sequence = private.id._sequence];
  const self.concatenate := function(list=unset, which=unset, log=T) {
    wider private, self;

# Allowing an unset Componentlist is to work around toolmanager deficiencies
# with tool inputs

    if (is_unset(list)) {
       note('No input componentlist given - nothing to do', origin='componentlist.concatenate',
            priority='WARN')
       return T;
    }
    if (!is_componentlist(list)) {
      throw('The list argument must be a componentlist tool');
    }
    if (is_unset(which)) {
      const totalLen := list.length();
      if (totalLen > 0) {
	which := [1:totalLen]
      } else {
	which := [];
      }
    }
    const curLen := self.length();
    private.concatenateRec.list := list.id();
    private.concatenateRec.which := which;
    ok := defaultservers.run(private.agent, private.concatenateRec);
    if (ok & log) {
      note('Concatenated ', len(which),
	   ' component(s) to the end of the list.\n',
           'The list now has ', self.length(), ' components',
	   origin='componentlist.concatenate');
    }
    
    private.changed([curLen: (curLen+len(which)-1)]);
    return ok;
  }

  private.removeRec := [_method = 'remove',
			_sequence = private.id._sequence];
  const self.remove := function(which, log=T) {
    wider private, self;
    private.removeRec.which := which;
    oldLen := self.length();
    ok := defaultservers.run(private.agent, private.removeRec);
    if (ok & log) {
      note('Removed component(s) ', which, ' from the list.\n', 
           'The list now has ', self.length(), ' components',
	   origin='componentlist.remove');
    }
    changed := [];
    removed := [];
    newLen := self.length();
    minwhich := min(which);
    if (minwhich <= newLen) changed := [minwhich:newLen];
    if (newLen < oldLen) removed := [(newLen+1):oldLen];
    private.changed(changed);
    self.dismiss(removed);
    return ok;
  }

  private.purgeRec := [_method = 'purge',
		       _sequence = private.id._sequence];
  const self.purge := function() {
    wider private;
    return defaultservers.run(private.agent, private.purgeRec);
  }

  private.recoverRec := [_method = 'recover',
			 _sequence = private.id._sequence];
  const self.recover := function(log=T) {
    wider private;
    const oldLen := self.length();
    ok := defaultservers.run(private.agent, private.recoverRec);
    const newLen := self.length();
    if (ok & log) {
      note('Recovered ', newLen - oldLen, ' elements.',
	   origin='componentlist.recover');
    }
    private.changed(oldLen:(newLen-1)) ;
    return ok;
  }

  private.lengthRec := [_method = 'length',
			_sequence = private.id._sequence];
  const self.length := function() {
    wider private;
    return defaultservers.run(private.agent, private.lengthRec);
  }

  private.indicesRec := [_method = 'indices',
			 _sequence = private.id._sequence];
  const self.indices := function() {
    wider private;
    return defaultservers.run(private.agent, private.indicesRec);
  }

  private.sortRec := [_method = 'sort',
		      _sequence = private.id._sequence];
  const self.sort := function(criteria='flux', log=T) {
    wider private;
    private.sortRec.criteria := criteria;
    ok := defaultservers.run(private.agent, private.sortRec);
    if (ok & log) {
      note('Sorting the list using the ', criteria , ' criteria.',
	   origin='componentlist.sort');
    }
    private.changed(1:self.length());
    return ok;
  }

  private.is_physicalRec := [_method = 'is_physical',
			     _sequence = private.id._sequence];
  const self.is_physical := function(which) {
    wider private;
    private.is_physicalRec.which := which;
    return defaultservers.run(private.agent, private.is_physicalRec);
  }

  private.sampleRec := [_method = 'sample',
			_sequence = private.id._sequence];
  const self.sample := function(direction, pixellatsize, pixellongsize, 
			    frequency) {
    wider private;
    private.sampleRec.direction := direction;
    private.sampleRec.pixellatsize := pixellatsize;
    private.sampleRec.pixellongsize := pixellongsize;
    private.sampleRec.frequency := frequency;
    return defaultservers.run(private.agent, private.sampleRec);
  }

  private.renameRec := [_method = 'rename',
			_sequence = private.id._sequence];
  const self.rename := function(filename, log=T) {
    wider private;
    private.renameRec.filename := filename;
    ok := defaultservers.run(private.agent, private.renameRec);
    if (ok & log) {
      note('The list will be stored in the table called ', filename, '.',
	   origin='componentlist.rename');
    }
    return ok;
  }

  private.simulateRec := [_method = 'simulate',
			  _sequence = private.id._sequence];
  const self.simulate := function(howmany=1, log=T) {
    wider private;
    private.simulateRec.howmany := howmany;
    ok := defaultservers.run(private.agent, private.simulateRec);
    if (ok & log) {
      note('Added ', howmany, ' simulated component(s) to the list.',
	   origin='componentlist.simulate');
    }
    return ok;
  }

  const self.addcomponent := function(flux=[1,0,0,0],
					fluxunit= 'Jy',
					polarization='Stokes',
					ra='00:00:00.00',
					raunit='time',
					dec='90.00.00.00',
					decunit='angle',
					dirframe='J2000',
					shape='point',
					majoraxis='2arcmin',
					minoraxis='1arcmin',
					positionangle='0deg',
					freq='1.415GHz',
					freqframe= 'LSRK',
					spectrumtype='constant',
					index=0,
					label='The default label') {
    wider self;
    ok := self.simulate(1);
    if(!ok) return throw('Failed to add new component');
    which := self.length();
    note('Adding component ', which);
    ok := self.setlabel(which, label);
    ok &:= self.setflux(which, flux, fluxunit, polarization);
    ok &:= self.setrefdir(which, ra, raunit, dec, decunit);
    ok &:= self.setrefdirframe(which, dirframe);
    ok &:= self.setshape(which, shape, majoraxis, minoraxis, positionangle);
    ok &:= self.setspectrum(which, spectrumtype, index);
    if(!dq.check(freq)) {
      return throw('Frequency must be a quantity');
    }
    cfreq := dq.quantity(freq);
    ok &:= self.setfreq(which, cfreq.value, cfreq.unit);
    ok &:= self.setfreqframe(which, freqframe);
    return ok;
  }
  
  const private.printFlux := function(which) {
    wider self;
    return spaste('Component ', which, 
		  ' has a flux of ', self.getfluxvalue(which),
		  self.getfluxunit(which), ' (', self.getfluxpol(which), 
		  ' representation).\n');
  }

  const private.printDir := function(which) {
    wider self;
    return spaste('Reference direction is, RA:', 
		  self.getrefdirra(which, 'time', 6), ', Dec:', 
		  self.getrefdirdec(which, 'angle', 6), ' (', 
		  self.getrefdirframe(which), ').\n'); 
  }

  const private.printShape := function(which) {
    wider private, self;
    shapeline := spaste('A ', self.shapetype(which), ' shape.');
    if (self.shapetype(which) != 'Point') {
      shape := self.getshape(which);           
      shapeline := spaste(shapeline, 
			  ' Major axis=', shape.majoraxis.value, 
			  shape.majoraxis.unit, '.',
			  ' Minor axis=', shape.minoraxis.value,
			  shape.minoraxis.unit, '.',
			  ' Position angle=', shape.positionangle.value,
			  shape.positionangle.unit, '.');
    }
    shapeline := spaste(shapeline, '\n', private.printDir(which));
    return shapeline;
  }

  const private.printFreq := function(which) {
    wider self;
    return spaste('Reference frequency is, ', 
		  self.getfreqvalue(which), 
		  self.getfrequnit(which), ' (', 
		  self.getfreqframe(which), ').\n');
  }

  const private.printSpectrum := function(which) { 
    wider private, self;
    spectrumline := spaste('A ', self.spectrumtype(which), 
			   ' spectral shape.');
    if (self.spectrumtype(which) != 'Constant') {
      spectrum := self.getspectrum(which);           
      spectrumline := spaste(spectrumline, 
			     ' Spectral indices=', spectrum.index, '.\n');
      spectrumline := spaste(spectrumline, private.printFreq(which));
    }
    return spectrumline;
  }

  const self.print := function(which=unset) {
    const l := self.length();
    if (is_unset(which)) {
       which := 1:l;
    }
#
    for (c in which) {
      if (!is_integer(c) || c < 1 || c > l) {
        note('You must specify which components you want to print using',
             ' integers between one and the list length.\n',
             'The index "', c, '" is not an integer between 1 and ', l,
             priority='WARN', origin='componentlist.print');
      } else {
	note(spaste(private.printFlux(c), private.printShape(c),
		    private.printSpectrum(c)), origin='componentlist.print');
      }
    }
#
    return T;
  }
  
  private.closeRec := [_method = 'close',
		       _sequence = private.id._sequence];
  const self.close := function(log=T) {
    wider private;
    ok := defaultservers.run(private.agent, private.closeRec);
    if (ok & log) {
      note('Closing the component list.', origin='componentlist.close');
    }
    return ok;
  }

  private.selectRec := [_method = 'select',
			_sequence = private.id._sequence];
  const self.select := function(which) {
    wider private;
    private.selectRec.which := which;
    return defaultservers.run(private.agent, private.selectRec);
  }

  private.deselectRec := [_method = 'deselect',
			 _sequence = private.id._sequence];
  const self.deselect := function(which) {
    wider private;
    private.deselectRec.which := which;
    return defaultservers.run(private.agent, private.deselectRec);
  }

  private.selectedRec := [_method = 'selected',
			 _sequence = private.id._sequence];
  const self.selected := function() {
    wider private;
    return defaultservers.run(private.agent, private.selectedRec);
  }

  private.getlabelRec := [_method = 'getlabel',
			 _sequence = private.id._sequence];
  const self.getlabel := function(which) {
    wider private;
    private.getlabelRec.which := which;
    return defaultservers.run(private.agent, private.getlabelRec);
  }

  private.setlabelRec := [_method = 'setlabel',
			 _sequence = private.id._sequence];
  const self.setlabel := function(which, value, log=T) {
    wider private;
    private.setlabelRec.which := which;
    private.setlabelRec.value := value;
    ok := defaultservers.run(private.agent, private.setlabelRec);
    if (ok & log) {
      note('Set the label of component(s) ', which, ' to ', value, '.',
	   origin='componentlist.setlabel');
    }
    private.changed(which);
    return ok;
  }

  private.getfluxvalueRec := [_method = 'getfluxvalue',
			      _sequence = private.id._sequence];
  const self.getfluxvalue := function(which) {
    wider private;
    private.getfluxvalueRec.which := which;
    local flux := defaultservers.run(private.agent, private.getfluxvalueRec);
    if (self.getfluxpol(which) == 'Stokes') {
      return real(flux);
    } else {
      return flux;
    }
  }

  private.getfluxunitRec := [_method = 'getfluxunit',
			     _sequence = private.id._sequence];
  const self.getfluxunit := function(which) {
    wider private;
    private.getfluxunitRec.which := which;
    return defaultservers.run(private.agent, private.getfluxunitRec);
  }

  private.getfluxpolRec := [_method = 'getfluxpol',
			    _sequence = private.id._sequence];
  const self.getfluxpol := function(which) {
    wider private;
    private.getfluxpolRec.which := which;
    return defaultservers.run(private.agent, private.getfluxpolRec);
  }

  private.getfluxerrorRec := [_method = 'getfluxerror',
			      _sequence = private.id._sequence];
  const self.getfluxerror := function(which) {
    wider private;
    private.getfluxerrorRec.which := which;
    error := defaultservers.run(private.agent, private.getfluxerrorRec);
    if (self.getfluxpol(which) == 'Stokes') {
      return real(error);
    } else {
      return error;
    }
  }

  private.setfluxRec := [_method = 'setflux',
			 _sequence = private.id._sequence];
  const self.setflux := function(which, value, unit='Jy',
			         polarization='stokes', error=[0,0,0,0],
			         log=T) {
    wider private;
    private.setfluxRec.which := which;
    private.setfluxRec.value := value;
    private.setfluxRec.unit := unit;
    private.setfluxRec.polarization := polarization;
    private.setfluxRec.error := error;
    ok := defaultservers.run(private.agent, private.setfluxRec);
    if (ok & log) {
      note('Setting the flux of component(s) ', which, ' to ', value, 
	   ' ', unit, ' (', polarization, ' representation).',
	   origin='componentlist.setflux');
    }
    private.changed(which);
    return ok;
  }

  private.convertfluxunitRec := [_method = 'convertfluxunit',
				 _sequence = private.id._sequence];
  const self.convertfluxunit := function(which, unit='Jy') {
    wider private;
    private.convertfluxunitRec.which := which;
    private.convertfluxunitRec.unit := unit;
    ok := defaultservers.run(private.agent, private.convertfluxunitRec);
    private.changed(which);
    return ok;
  }

  private.convertfluxpolRec := [_method = 'convertfluxpol',
				_sequence = private.id._sequence];
  const self.convertfluxpol := function(which, polarization = 'Stokes') {
    wider private;
    private.convertfluxpolRec.which := which;
    private.convertfluxpolRec.polarization := polarization;
    ok := defaultservers.run(private.agent, private.convertfluxpolRec);
    private.changed(which);
    return ok;
  }
 
 private.getrefdirRec := [_method = 'getrefdir',
			   _sequence = private.id._sequence];
  const self.getrefdir := function(which) {
    wider private;
    private.getrefdirRec.which := which;
    return defaultservers.run(private.agent, private.getrefdirRec);
  }

  private.getrefdirraRec := [_method = 'getrefdirra',
			     _sequence = private.id._sequence];
  const self.getrefdirra := function(which, unit='deg', precision=6) {
    wider private;
    private.getrefdirraRec.which := which;
    private.getrefdirraRec.unit := unit;
    private.getrefdirraRec.precision := precision;
    return defaultservers.run(private.agent, private.getrefdirraRec);
  }

  private.getrefdirdecRec := [_method = 'getrefdirdec',
			      _sequence = private.id._sequence];
  const self.getrefdirdec := function(which, unit='deg', precision=6) {
    wider private;
    private.getrefdirdecRec.which := which;
    private.getrefdirdecRec.unit := unit;
    private.getrefdirdecRec.precision := precision;
    return defaultservers.run(private.agent, private.getrefdirdecRec);
  }

  private.getdirerrorlongRec := [_method = 'getdirerrorlong',
			      _sequence = private.id._sequence];
  const self.getdirerrorlong := function(which) {
    wider private;
    return self.component(which, iknow=T).shape.direction.error.longitude;
  }

  private.getdirerrorlatRec := [_method = 'getdirerrorlat',
			      _sequence = private.id._sequence];
  const self.getdirerrorlat := function(which) {
    wider private;
    return self.component(which, iknow=T).shape.direction.error.latitude;
  }

  private.getrefdirframeRec := [_method = 'getrefdirframe',
				_sequence = private.id._sequence];
  const self.getrefdirframe := function(which) {
    wider private;
    private.getrefdirframeRec.which := which;
    return defaultservers.run(private.agent, private.getrefdirframeRec);
  }

  private.setrefdirRec := [_method = 'setrefdir',
			   _sequence = private.id._sequence];
  const self.setrefdir := function(which, ra, raunit, dec, decunit, 
				   longerror='0arcmin', laterror='0arcmin',
				   log=T) {
    wider private;
    private.setrefdirRec.which := which;
    private.setrefdirRec.ra := as_string(ra);
    private.setrefdirRec.raunit := raunit;
    private.setrefdirRec.dec := as_string(dec);
    private.setrefdirRec.decunit := decunit;
    ok := defaultservers.run(private.agent, private.setrefdirRec);
    local comp := self.component(which, iknow=T);
    comp.shape.direction.error.longitude := dq.quantity(longerror);
    comp.shape.direction.error.latitude := dq.quantity(laterror);
    local cl := emptycomponentlist(log=F);
    cl.add(comp, iknow=T);
    comp := F;
    self.replace(which, cl, [1], log=F);
    cl.done();
    if (ok & log) {
      note('Set the direction of component(s) ', which, 
	   ' to (', ra, ', ', dec, ').',
	   origin='componentlist.setrefdir');
    }
    private.changed(which);
    return ok;
  }

  private.setrefdirframeRec := [_method = 'setrefdirframe',
				_sequence = private.id._sequence];
  const self.setrefdirframe := function(which, frame, log=T) {
    wider private;
    private.setrefdirframeRec.which := which;
    private.setrefdirframeRec.frame := frame;
    ok := defaultservers.run(private.agent, private.setrefdirframeRec);
    if (ok & log) {
      note('Set the reference frame for component(s) ', which, ' to ', 
	   frame, '.',
	   origin='componentlist.setrefdirframe');
    }
    private.changed(which);
    return ok;
  }

  private.convertrefdirRec := [_method = 'convertrefdir',
			       _sequence = private.id._sequence];
  const self.convertrefdir := function(which, frame) {
    wider private;
    private.convertrefdirRec.which := which;
    private.convertrefdirRec.frame := frame;
    ok := defaultservers.run(private.agent, private.convertrefdirRec);
    private.changed(which);
    return ok;
  }

  private.shapetypeRec := [_method = 'shapetype',
			   _sequence = private.id._sequence];
  const self.shapetype := function(which) {
    wider private;
    private.shapetypeRec.which := which;
    return defaultservers.run(private.agent, private.shapetypeRec);
  }

  private.getshapeRec := [_method = 'getshape',
			  _sequence = private.id._sequence];
  const self.getshape := function(which) {
    wider private;
    private.getshapeRec.which := which;
    return defaultservers.run(private.agent, private.getshapeRec);
  }

  private.getshapeerrorRec := [_method = 'getshapeerror',
			       _sequence = private.id._sequence];
  const self.getshapeerror := function(which) {
    wider private;
    private.getshapeerrorRec.which := which;
    return defaultservers.run(private.agent, private.getshapeerrorRec);
  }

  private.setshapeRec := [_method = 'setshape',
			 _sequence = private.id._sequence];
  const self.setshape := function(which, type='Point', majoraxis='1arcmin', 
			      	  minoraxis='1arcmin', positionangle='0deg',
			          majoraxiserror='0arcmin', 
			          minoraxiserror='0arcmin', 
			          positionangleerror='0deg', log=T) {
    wider private;
    private.setshapeRec.which := which;
    private.setshapeRec.type := type;
    private.setshapeRec.shape := [=];
    private.setshapeRec.shape.majoraxis := majoraxis;
    private.setshapeRec.shape.minoraxis := minoraxis;
    private.setshapeRec.shape.positionangle := positionangle;
    private.setshapeRec.shape.majoraxiserror := majoraxiserror;
    private.setshapeRec.shape.minoraxiserror := minoraxiserror;
    private.setshapeRec.shape.positionangleerror := positionangleerror;
    ok := defaultservers.run(private.agent, private.setshapeRec);
    if (ok & log) {
      note('Set the shape of component(s) ', which, ' to ', type, '.',
	   origin='componentlist.setshape');
    }
    private.changed(which);
    return ok;
  }

  private.convertshapeRec := [_method = 'convertshape',
			      _sequence = private.id._sequence];
  const self.convertshape := function(which, majoraxis='arcmin', 
				  minoraxis='arcmin', positionangle='deg') {
    wider private;
    private.convertshapeRec.which := which;
    private.convertshapeRec.shape := [=];
    private.convertshapeRec.shape.majoraxis := majoraxis;
    private.convertshapeRec.shape.minoraxis := minoraxis;
    private.convertshapeRec.shape.positionangle := positionangle;
    ok := defaultservers.run(private.agent, private.convertshapeRec);
    private.changed(which);
    return ok;
  }

  private.spectrumtypeRec := [_method = 'spectrumtype',
			      _sequence = private.id._sequence];
  const self.spectrumtype := function(which) {
    wider private;
    private.spectrumtypeRec.which := which;
    return defaultservers.run(private.agent, private.spectrumtypeRec);
  }

  private.getspectrumRec := [_method = 'getspectrum',
			     _sequence = private.id._sequence];
  const self.getspectrum := function(which) {
    wider private;
    private.getspectrumRec.which := which;
    return defaultservers.run(private.agent, private.getspectrumRec);
  }

  private.setspectrumRec := [_method = 'setspectrum',
			     _sequence = private.id._sequence];
  const self.setspectrum := function(which, type='Constant', index=1,
				     log=T) {
    wider private;
    private.setspectrumRec.which := which;
    private.setspectrumRec.type := type;
    private.setspectrumRec.spectrum := [=];
    private.setspectrumRec.spectrum.frequency := 'current';
    private.setspectrumRec.spectrum.index := index;
    ok := defaultservers.run(private.agent, private.setspectrumRec);
    if (ok & log) {
      note('Set the spectrum of component(s) ', which, ' to ', 
	   type, '.', origin='componentlist.setspectrum');
    }
    private.changed(which);
    return ok;
  }

  private.convertspectrumRec := [_method = 'convertspectrum',
				 _sequence = private.id._sequence];
  const self.convertspectrum := function(which, index='') {
    wider private;
    private.convertspectrumRec.which := which;
    private.convertspectrumRec.spectrum := [=];
    private.convertspectrumRec.spectrum.index := index;
    ok := defaultservers.run(private.agent, private.convertspectrumRec);
    private.changed(which);
    return ok;
  }
  
  private.getfreqRec := [_method = 'getfreq',
			 _sequence = private.id._sequence];
  const self.getfreq := function(which) {
    wider private;
    private.getfreqRec.which := which;
    ok := defaultservers.run(private.agent, private.getfreqRec);
    private.changed(which);
    return ok;
  }
  
  private.getfreqvalueRec := [_method = 'getfreqvalue',
			 _sequence = private.id._sequence];
  const self.getfreqvalue := function(which) {
    wider private;
    private.getfreqvalueRec.which := which;
    return defaultservers.run(private.agent, private.getfreqvalueRec);
  }
  
  private.getfrequnitRec := [_method = 'getfrequnit',
			     _sequence = private.id._sequence];
  const self.getfrequnit := function(which) {
    wider private;
    private.getfrequnitRec.which := which;
    return defaultservers.run(private.agent, private.getfrequnitRec);
  }
  
  private.getfreqframeRec := [_method = 'getfreqframe',
			      _sequence = private.id._sequence];
  const self.getfreqframe := function(which) {
    wider private;
    private.getfreqframeRec.which := which;
    return defaultservers.run(private.agent, private.getfreqframeRec);
  }
  
  private.setfreqRec := [_method = 'setfreq',
			 _sequence = private.id._sequence];
  const self.setfreq := function(which, value, unit='GHz', log=T) {
    wider private;
    private.setfreqRec.which := which;
    private.setfreqRec.value := value;
    private.setfreqRec.unit := unit;
    ok := defaultservers.run(private.agent, private.setfreqRec);
    if (ok & log) {
      note('Set the reference frequency for component(s) ', which, ' to ', 
	   value, ' ', unit, '.', origin='componentlist.setfreq');
    }
    private.changed(which);
    return ok;
  }
  
  private.setfreqframeRec := [_method = 'setfreqframe',
			      _sequence = private.id._sequence];
  const self.setfreqframe := function(which, frame, log=T) {
    wider private;
    private.setfreqframeRec.which := which;
    private.setfreqframeRec.frame := frame;
    ok := defaultservers.run(private.agent, private.setfreqframeRec);
    if (ok & log) {
      note('Set the frequency reference frame for component(s) ', which,
	   ' to ', frame, '.', origin='componentlist.setfreqframe');
    }
    private.changed(which);
    return ok;
  }
  
  private.convertfrequnitRec := [_method = 'convertfrequnit',
				 _sequence = private.id._sequence];
  const self.convertfrequnit := function(which, unit) {
    wider private;
    private.convertfrequnitRec.which := which;
    private.convertfrequnitRec.unit := unit;
    ok :=  defaultservers.run(private.agent, private.convertfrequnitRec);
    private.changed(which);
    return ok;
  }
  
  const self.edit := function(which, log=T) {
    include 'componenteditor.g';
    if (log) {
      note('Editing component(s) ', which, ' interactively.',
 	   origin='componentlist.edit');
    }
    for (i in which) {
      componenteditor(self, i);
    }
  }

  const self.view := function(which) {
    include 'componenteditor.g';
    for (i in which) {
      componenteditor(self, i, edit=F);
    }
  }

  const self.summary := function (which=unset)
  {
     n := self.length();
     if (is_unset(which)) {
        which := 1:n;
     }
#
     for (i in which) {
        ok := private.summary(i);
     }
#
     return T;
  }
#
  const private.summary := function (i)
  {

     note ('Listing for component ', i);

# Flux

     fluxValues := self.getfluxvalue(i);
     fluxUnit := self.getfluxunit(i);
     fluxErrors := self.getfluxerror(i);   
#
     s := spaste('Integral flux :  ', fluxValues, ' (', fluxErrors, ') ', fluxUnit);
     note(s, priority='NORMAL', origin='componentlist.summary');

# Reference Direction

     lon := self.getrefdirra(i, 'time', 10)
     lat := self.getrefdirdec(i, 'angle', 9);
     lonError := self.getdirerrorlong(i);
     latError := self.getdirerrorlat(i);   
     f := self.getrefdirframe(i);
#
     lonError := dq.convert(lonError, 'arcsec');
     v := dq.getvalue(lonError);
     lonStr := spaste (v, ' ', dq.getunit(lonError));
#
     latError := dq.convert(latError, 'arcsec');
     v := dq.getvalue(latError);
     latStr := spaste (v, ' ', dq.getunit(latError));
#
     s := spaste('Lon/Lat ', '(', f, ') : ', lon, '  ', lat, ' ', '(', lonStr, ' ', latStr, ')');
     note(s, priority='NORMAL', origin='componentlist.summary');

# Shape. 

     componentShape := self.getshape(i);
     componentShapeErrors := self.getshapeerror(i);
     componentType := to_upper(self.shapetype(i));
#
     note ('Shape type : ', componentType);
     if (componentType=='GAUSSIAN' || componentType=='DISK') {
        s := spaste('Major axis : ', componentShape.majoraxis.value,
                     ' (', componentShapeErrors.majoraxis.value, ') ',
                     componentShape.majoraxis.unit);
        note(s, priority='NORMAL', origin='componentlist.summary');
#
        s := spaste('Minor axis : ', componentShape.minoraxis.value,
                    ' (', componentShapeErrors.minoraxis.value, ') ',
                    componentShape.minoraxis.unit);
        note(s, priority='NORMAL', origin='componentlist.summary');
#
        s := spaste('Position angle : ', componentShape.positionangle.value,
                    ' (', componentShapeErrors.positionangle.value, ') ',
                    componentShape.positionangle.unit);
        note(s, priority='NORMAL', origin='componentlist.summary');
     } else if (componentType=='POINT') {
     }

# Spectrum

     spectrumType := self.spectrumtype(i);
     freq := self.getfreq (i);
     note ('Spectrum type : ', spectrumType);
     note ('Reference frequency : ',freq);
#

     note(' ', priority='NORMAL', origin='componentlist.summary');
     return T;
  }

  const self.type := function() {
    return 'componentlist';
  }

  const self.id := function() {
    wider private;
    return private.id.objectid;
  }

  const self.done  := function() {
    wider private, self;
    self.dismiss();
    ok := defaultservers.done(private.agent, private.id.objectid);
    if (ok) {
      val private := F;
      val self := F;
    }
    return ok;
  }
  plugins.attach('componentlist', self);
}

const emptycomponentlist := function(host='', forcenewserver=F, log=T) {
  include 'servers.g';
  agent := defaultservers.activate('componentlist', 
                                   host, forcenewserver);
  id := defaultservers.create(agent, 'componentlist',
                              'emptycomponentlist', [=]);
  if (is_fail(id)) fail;
#
  cl := ref _define_componentlist(agent, id);
  if (is_fail(cl)) fail;
#
  if (is_componentlist(cl) & log) {
    note('Creating an empty componentlist tool.', origin='emptycomponentlist');
  }
  return ref cl;
};

const componentlist := function(filename='', readonly=F,
				host='', forcenewserver=F, log=T) {
  include 'servers.g';
  agent := defaultservers.activate('componentlist', 
                                   host, forcenewserver);
  id := defaultservers.create(agent, 'componentlist',
                              'readcomponentlist', 
                              [filename=filename, readonly=readonly]);
  cl := ref _define_componentlist(agent, id);
  if (is_componentlist(cl) & log) {
    message := spaste('Creating a componentlist tool using the data in the ', 
		      filename, ' table.\n');
    if (readonly) {
      message := spaste(message , 'The list cannot be modified.');
    } else {
      message := spaste(message , 'The list can be edited.');
    }
    note(message, origin='componentlist');
  }
  return ref cl;
};

const asciitocomponentlist := function(filename, asciifile,
				       refer='J2000', format='ST',
				       flux=unset, direction=unset, 
				       spectrum=unset, readonly=F,
				       host='', forcenewserver=F, log=T) {
  include 'ascii2complist.g';
  ok := ascii2complist(complist=filename, asciifile=asciifile, refer=refer,
		       format=format, flux=flux, direction=direction, 
		       spectrum=spectrum);
  if(is_fail(ok)) fail;
  cl := componentlist(filename, readonly, host, forcenewserver);
  if (is_componentlist(cl) & log) {
    note('Creating a componentlist tool using the data in the ', 
		      asciifile, ' file.', origin='asciitocomponentlist');
  }
  return ref cl;
}

const is_componentlist := function(tool) {
  return is_record(tool) && has_field(tool, 'type') && 
    is_function(tool.type) && tool.type() == 'componentlist';
}
