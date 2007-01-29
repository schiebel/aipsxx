# autocli.g: build a CLI processor from a record
# Copyright (C) 1996,1997,1998,1999,2000
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
# $Id: autocli.g,v 19.2 2004/08/25 02:11:25 cvsmgr Exp $

pragma include once;

include 'clientry.g'

autocli := subsequence(ref params, title='autocli',
		       cliset=dce) : [reflect=T] {
  
  ############################################################
  ## store constructor arguments                            ##
  ############################################################
  its := [=];
  its.params := params;
  its.title := title;
  
  its.clielem := [=];
  
  its.callbacks := [=];

  ############################################################
  ## whenever pusher                                        ##
  ############################################################
  its.whenevers := [];
  self.pushwhenever := function() {
    wider its;
    its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
  }
  
  ############################################################
  ## build the CLI                                          ##
  ############################################################
  
  xfn_tmp := field_names(its.params);
  
  # first, deal with contexts:
  its.contexts := '';
  for (i in xfn_tmp) {
    if (has_field(its.params[i], 'context')) {
      if (!any(split(its.contexts) == its.params[i].context)) {
	its.contexts := paste(its.contexts, its.params[i].context);
      }
    }
  }

  # Loop creating widget for each field in params
  for (i in xfn_tmp) {
    allowunset := T;
    if (has_field(its.params[i], allowunset)) {
      allowunset := its.params[i].allowunset;
    }
    its.clielem[i] := [=];
    its.clielem[i].label := its.params[i].listname;
    if(has_field(its.params[i], 'help')) {
      its.clielem[i].shorthelp := its.params[i].help;
    }
    
    editable := T;
    if (has_field(its.params[i], 'dir')&&its.params[i].dir == 'out') {
      editable := F;
    }
    if (its.params[i].ptype == 'choice') {
      its.clielem[i].cliagent := cliset.choice(options=its.params[i].popt,
					       value=its.params[i].value,
					       default=its.params[i].default,
					       editable=editable,
					       allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->select do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'check') {
      its.clielem[i].cliagent :=
	  cliset.check(options=its.params[i].popt,
		       value=its.params[i].value,
		       default=its.params[i].default,
		       editable=editable,
		       allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->select do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'boolean') {
      its.clielem[i].cliagent := cliset.boolean(value=its.params[i].value,
		       default=its.params[i].default,
		       editable=editable,
		       allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->select do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'table') {
      its.clielem[i].cliagent :=
	  cliset.file(value=its.params[i].value,
		  default=its.params[i].default,
		  editable=editable,
		  allowunset=allowunset)
	      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->select do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'file') {
      its.clielem[i].cliagent :=
	  cliset.file(value=its.params[i].value,
		  default=its.params[i].default,
		  allowunset=allowunset,
		  editable=editable)
	      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->select do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'directory') {
      its.clielem[i].cliagent :=
	  cliset.file(value=its.params[i].value,
		  default=its.params[i].default,
		  editable=editable)
	      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->select do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if ((its.params[i].ptype == 'scalar')||
	       (its.params[i].ptype == 'floatrange')) {
      its.clielem[i].cliagent :=
	  cliset.scalar(editable=editable,
		    value=its.params[i].value,
		    default=its.params[i].default);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->value do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'array') {
      its.clielem[i].cliagent :=
	  cliset.array(editable=editable,
			value=its.params[i].value,
			default=its.params[i].default);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->value do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'quantity') {
      its.clielem[i].cliagent :=
	  cliset.quantity(value=its.params[i].value,
		      editable=editable,
		      default=its.params[i].default,
		      allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->value do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'region') {
      its.clielem[i].cliagent :=
	  cliset.region(value=its.params[i].value,
		    editable=editable,
		    default=its.params[i].default,
		    allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->value do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'measure') {
      its.clielem[i].cliagent :=
	  cliset.measure(editable=editable,
			 value=its.params[i].value,
			 default=its.params[i].default,
			 allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->value do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'record') {
      its.clielem[i].cliagent :=
	  cliset.record(editable=editable,
		    value=its.params[i].value,
		    default=its.params[i].default,
		    allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->value do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if (its.params[i].ptype == 'untyped') {
      its.clielem[i].cliagent :=
	  cliset.untyped(editable=editable,
		     value=its.params[i].value,
		     default=its.params[i].default,
		     allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->value do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else if ((its.params[i].ptype == 'string')||
	       (its.params[i].ptype == 'vector_string')) {
      its.clielem[i].cliagent :=
	  cliset.string(editable=editable,
		    value=its.params[i].value,
		    default=its.params[i].default,
		    allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->value do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    } else {
      its.clielem[i].cliagent :=
	  cliset.untyped(editable=editable,
			 value=its.params[i].value,
			 default=its.params[i].default,
			 allowunset=allowunset);
      if(is_fail(its.clielem[i].cliagent)) fail;
      whenever its.clielem[i].cliagent->return do {
	if (its.should_emit($agent)) {
	  self->changenotice($agent);
	}
      } self.pushwhenever();
    }
    
  }
  
  ############################################################
  ## fill the CLI                                           ##
  ############################################################
  self.fillcli := function(ref wparams, what='value') {
    wider its;      
    if(!is_record(wparams)) return;
    xfn_tmp := field_names(wparams);
    for (i in xfn_tmp) {
      its.clielem[i].cliagent.insert(wparams[i][what]);
    }
  }
  
# fill the cli...
  self.fillcli(its.params);
  
############################################################
## read the CLI                                           ##
############################################################
  its.readcli := function(ref rwparams) {
    wider its;
    xfn_tmp := field_names(rwparams);
    for (i in xfn_tmp) {
      rwparams[i].value := its.clielem[i].cliagent.get();
    }
  }
  
  its.readandemit := function() {
    wider its;
    its.check_dependencies(reread=T);
    rec := [=];
    xfn_tmp := field_names(its.params);
    for (i in xfn_tmp) {
      rec[its.params[i].dlformat] := its.params[i].value;
    }
    self->setoptions(rec);
    return rec;
  }
  
  its.should_emit := function(theagent) {
    it := F;
    for (i in field_names(its.clielem)) {
      if (its.clielem[i].cliagent == theagent) {
	it := i;
	break;
      }
    }
    if (is_boolean(it)) {
      return F; # agent not found: don't emit.
    }
    # let's check the deps.
    its.check_dependencies(reread=T);
    
    return F;
  }
  
  ############################################################
  ## check all dependencies                                 ##
  ############################################################
  its.dependency_states := [=];
  its.check_dependencies := function(reread=F) {
    wider its;
    if (reread) {
      its.readcli(its.params);
    }
    for (i in field_names(its.params)) {
      if (has_field(its.params[i], 'dependency_group')) {
	its.dependency_states[its.params[i].dependency_group] :=
	    its.check_dependency_group(its.params[i].
				       dependency_group);
      }
    }
  }
  
  ############################################################
  ## check dependencies for this group                      ##
  ############################################################
  its.check_dependency_group := function(group, reread=F) {
    wider its;
    if (reread) {
      its.readcli(its.params);
    }
    fields := '';
    for (i in field_names(its.params)) {
      if (has_field(its.params[i], 'dependency_group') &&
	  its.params[i].dependency_group == group) {
	fields := paste(fields, i);
      }
    }
    fields := split(fields);
    if (len(fields) < 2) {
      return T; # not enough fields to compare!
    }
    # ignore dependency_type here, should check, following code
    # is for "exclusive"...
    for (i in 1:(len(fields) - 1)) {
      for (j in (i + 1):len(fields)) {
	if (its.params[fields[i]].value == 
	    its.params[fields[j]].value) {
	  its.show_dependency_validity(group, F);
	  return F;
	}
      }
    }
    its.show_dependency_validity(group, T);
    return T;
  }
  
  ############################################################
  ## show dependency state in the cli                       ##
  ############################################################
  its.show_dependency_validity :=  function(group, valid) {
    wider its;
    for (i in field_names(its.params)) {
      if (has_field(its.params[i], 'dependency_group') &&
	  its.params[i].dependency_group == group) {
	if ((its.params[i].ptype == 'choice') ||
	    (its.params[i].ptype == 'userchoice')) {
 #		    its.clielem[i].cliagent.blink(!valid, interval=0.6);
#	  its.clielem[i].label.blink(!valid, interval=0.6);
	} else {
	  print "don't know how to invalidate ", 
	  its.params[i].ptype;
	}
      }
    }
  }
  
  ############################################################
  ## dismiss self if displaydata was deleted                ##
  ############################################################
  whenever self->dismiss do {
    self.dismiss();
  } self.pushwhenever();
  
  ############################################################
  ## how to dismiss                                         ##
  ############################################################
  self.dismiss := function() {
    wider its;
    deactivate its.whenevers;
  }
  
  self.display := function(params=unset) {
    wider its;
    if(is_unset(params)) {
      xfn_tmp:=field_names(its.params);
    }
    else {
      xfn_tmp := params;
    }
    width:=max(strlen(xfn_tmp));
    for (i in xfn_tmp) {
      if(its.params[i].dir=='in') {
	dirstr := '[in]     '
      }
      else if(its.params[i].dir=='out') {
	dirstr := '[out]    '
      }
      else {
	dirstr := '[in/out] '
      }
      line := spaste(dirstr, sprintf('%*s', width, i), ' = ',
		     its.clielem[i].cliagent.display());
      print line;
    }
  }

  self.setcallbacks := function(callbacks) {
    wider its;
    its.callbacks := ref callbacks;
  }

  self.help := function() {
    wider its;
    rec := [=];
    xfn_tmp := field_names(its.params);
    width:=max(strlen(xfn_tmp));
    for (i in xfn_tmp) {
      if(has_field(its.params[i], 'help')) {
	line := spaste(sprintf('%*s', width, i), ' : ',
		       its.params[i].help);
	print line;
      }
    }
  }
  
  self.get := function() {
    wider its;
    return its.readandemit();
  }
  
  self.loop := function(header='Welcome to the Auto-CLI',
			prompt='> ',
			footer='Exiting to Glish')
  {
    
    wider self;

    print header;

    # Always show the inputs
    self.display();

    while(T) {

      # Keep reading until we get something
      command := readline(prompt);
      if(strlen(command)==0) return T;
      if(command~m/=/) {
	subcmd := split(command, '=');
      }
      else {
	subcmd := split(command);
      }
      
      first := subcmd[1]~s/[ ]//g;
      second := '';
      if(length(subcmd)>1) {
	second := paste(subcmd[2:length(subcmd)])~s/^[ ]//g;
      }
      
      # Check for standard commands
      if(has_field(its.callbacks, first)) {
	values := its.readandemit();
	print its.callbacks[first](values, second);
	self.display();
      }
      else if(first=='inp') {
	self.display();
      }
      # First must be a parameter name
      else if(any(field_names(its.params)==first)) {
	if(length(subcmd)==1) {
	  self.display(subcmd);
	}
	else {
	  its.clielem[first].cliagent.insert(second);
	}
	self->finished();
      }
      else if(first=='help') {
        self.help();
      }
      else if((first=='quit')||(first=='q')) {
	print footer;
	return T;
      }
      else {
	print "Unknown command : ", command;
      }
    }
  }
}

const autoclitest := function() {

  private := [=];

# we will put a "parameter set" into "parameters":
  private.parameters := [=];
  
# Set up various widgets:
  
# floatrange
# give min, max and resolution: it makes a scale widget
  p_power := [dlformat='power',
	      listname='Scaling power',
	      ptype='floatrange',
	      pmin=-5.0,
	      pmax=5.0,
	      presolution=0.1,
	      default=0.0,
	      value=1.5];
  private.parameters.power := p_power;
  
# choice
# give a list of options: it makes an optionmenu widget
  p_resample := [dlformat='resample',
		 listname='Resampling mode',
		 allowuset=T,
		 ptype='choice',
		 popt="nearest bilinear",
		 default='nearest',
		 value='nearest'];
  private.parameters.resample := p_resample;
  
# orderedvector
# give how many numbers, and the range: it makes "n" scale widgets,
# each constrained to have the slider between those above and below it.
  p_range := [dlformat='range',
	      listname='Data range',
	      ptype='orderedvector',
	      plength=2,
	      prange=[-10, 150],
	      default=[15, 85],
	      value=[15, 85]];
  private.parameters.range := p_range;
  
# boolean
# Only need to give default
  p_switch := [dlformat='switch',
	       listname='Plot contours',
	       ptype='boolean',
	       allowuset=T,
	       default=T,
	       value=F];
  private.parameters.switch := p_switch;

# vector
# just an entry box at the moment: needs some smarts like the ones
# in regionmanager and others.
  p_levels := [dlformat='levels',
	       listname='Contour levels',
	       ptype='vector',
	       default=[0.2, 0.4, 0.6, 0.8],
	       value=[0.2, 0.4, 0.6, 0.9]];
  private.parameters.levels := p_levels;
  
# scalar
# just an entry box at the moment - perhaps a scale or "winding entry
# box" in the future.
  p_scale := [dlformat='scale',
	      listname='Contour scale factor',
	      ptype='scalar',
	      default=0.5,
	      value=1.2];
  private.parameters.scale := p_scale;
  
# intrange
# give min/max: this makes a scale widget with step size 1.
  p_line := [dlformat='line',
	     listname='Line width',
	     ptype='intrange',
	     pmin=0,
	     pmax=6,
	     default=1,
	     value=1];
  private.parameters.line := p_line;
  
# userchoice
# just like 'choice', but allows extension by user via extendoptionmenu.
  p_color := [dlformat='color',
	      listname='Line color',
	      ptype='userchoice',
	      popt="black white red green blue yellow",
	      default='blue',
	      value='blue'];
  private.parameters.color := p_color;
  
# now for Axis selection example:
#
# any parameter can have a context field, which if it exists, forces
# the parameter to be put in a roll-up so it can be squirelled away
# for only occasional use.
#
# then there is also dependency_group, which can have any name, in
# this case "axes" and flags which parameters belong to a particular
# group.  Parameters in this group are only emitted if the dependencies
# are met.
#
# then there is dependency_type: exclusive is the only one known at
# the moment to the autocli.
#
# finally, dependency_list is a string list of the other parameters
# (actually their dlformat field values) which, in this case, must
# be exclusive of this value.
  
  p_xaxis := [dlformat='xaxis',
	      listname='X-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='R.A.',
	      value='R.A.',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="yaxis zaxis"];
  private.parameters.xaxis := p_xaxis;
  
  p_yaxis := [dlformat='yaxis',
	      listname='Y-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='Dec',
	      value='Dec',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="xaxis zaxis"];
  private.parameters.yaxis := p_yaxis;
  
  p_zaxis := [dlformat='zaxis',
	      listname='Z-axis',
	      ptype='choice',
	      popt="R.A. Dec Vel",
	      default='Vel',
	      value='Vel',
	      context='Axis_selection',
	      dependency_group='axes',
	      dependency_type='exclusive',
	      dependency_list="xaxis yaxis"];
  private.parameters.zaxis := p_zaxis;
  
  p_filename := [dlformat='file',
		 listname='File name',
		 ptype='file',
		 default=unset,
		 allowunset=T,
		 value='myfilename',
		 popt='All'];
  private.parameters.filename := p_filename;
  
  p_strings := [dlformat='strings',
		listname='Strings',
		ptype='vector_string',
		default=unset,
		allowunset=T,
		value="foo bar"]
  private.parameters.strings := p_strings;
  
  p_cellsize := [dlformat='quantity',
		 listname='Cell size',
		 ptype='quantity',
		 default=unset,
		 allowunset=T,
		 value='0.7arcsec'];
  private.parameters.cellsize := p_cellsize;
  
  p_imagesize := [dlformat='scalar',
		  listname='Image size',
		  ptype='scalar',
		  default=unset,
                  allowunset=T,
		  value=256];
  private.parameters.imagesize := p_imagesize;
  
  include 'measures.g';
  p_direction := [dlformat='measure',
		  listname='Phase Center',
		  ptype='measure',
		  default=unset,
		  value='dm.direction(\'sun\', \'0deg\', \'0deg\')',
		  allowunset=T];
  
  private.parameters.direction := p_direction;
  
    # Call back functions
  private.commands["go"] := function(values, command) {
    wider private;
    private.rec := [=];
  }

  private.commands["get"] := function(values, command) {
    wider private;
    label := command;
    if(label=='') label:='lastsave';
    include 'inputsmanager.g';
    values := inputs.getvalues('autocli', 'autoclitest', label);
    if(is_record(values)) {
      for (arg in field_names(values)) {
	if(has_field(private, 'parameters')&&
	   has_field(private.parameters, arg)&&
	   is_record(private.parameters[arg])) {
	  private.parameters[arg].value := values[arg];
	}
      }
    }
    private.mycli.fillcli(private.parameters);
    return T;
  }
    
  private.commands["save"] := function(values, command='lastsave') {
    wider private;
    values := private.mycli.get();
    if(is_record(values)) {
      label :=  command;
      if(label=='') label:='lastsave';
      include 'inputsmanager.g';
      inputs.savevalues('autocli', 'autoclitest', values, label);
    }
  } 
  
  # Copy button
  private.commands["copy"] := function(values, command='lastsave') {
    dcb.copy(values);
  } 
  
  # Paste button
  private.commands["paste"] := function(values, command) {
    wider private;
    values := dcb.paste();
    if(is_record(values)) {
      private.setvalues(values);
    }
    else {
      note ('Clipboard does not contain an inputs record');
      return F;
    }
  }
  
  # Paste button
  private.commands["web"] := function(values, command) {
    note(spaste('Driving browser to help on utility.widgets.autocli'));
  }

  private.commands["?"] := function(values, command) {
    printf('Available commands:\n');
    printf('   inp                    - show current inputs\n');
    printf('   help                   - show help for current inputs\n');
    printf('   web                    - show web help for autocli\n');
    printf('   quit                   - quit this function\n');
    printf('   save [keyword]         - save current inputs to keyword\n');
    printf('   get  [keyword]         - get inputs from keyword\n');
    printf('   copy                   - copy current inputs to clipboard\n');
    printf('   paste                  - paste current inputs from clipboard\n');
    return T;
  }
    
  private.mycli := autocli(private.parameters, 'My demonstration autocli');
  if(is_fail(private.mycli)) fail;
  
  private.mycli.setcallbacks(private.commands);

  whenever private.mycli->setoptions do {
    print "New options for", field_names($value), "emitted";
  }

  private.mycli.loop()
}

