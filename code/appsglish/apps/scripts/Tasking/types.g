# types.g: Enter meta information for classes and methods.
#
#   Copyright (C) 1998,1999,2000,2001
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
#   $Id: types.g,v 19.2 2004/08/25 02:06:40 cvsmgr Exp $
#

pragma include once
    
    include 'note.g'
    include 'unset.g'
    
    valuetypes := function()
{
  public := [=];
  private := [=];
  private.types := "integer float string boolean record table file directory double vector_string complex dcomplex untyped tool";
  private.defaults := [integer=0, float=as_float(0), string="", boolean=F,
		       record=[=], table='', file='', double=0,
		       vector_string="", complex=as_complex(0+0i),
		       dcomplex=as_dcomplex(0+0i), tool=unset,
		       untyped=unset];
  private.checktype := [integer=is_numeric, float=is_numeric, 
			string=is_string,boolean=is_boolean,
			record=is_record, table=is_string, file=is_string,
			directory=is_string, 
			double=is_numeric, vector_string=is_string,
			complex=is_complex, dcomplex=is_dcomplex];
  
  
  public.types := function()
  {
    wider private;
    return private.types;
  }
  
  public.istype := function(type)
  {
    wider private;
    if (!is_string(type) || length(type)!=1) 
	return throw('valuetypes.istype - illegal argument');
    return any(private.types == type);
  }
  
  # If it isn't a 'type' and is a string if checkeval is true then the
  # string is eval'ed and the result is check, otherwise we assume it's
  # OK but cannot be eval'ed yet.
  public.checktype := function(value, type, checkeval=T)
  {
    wider public, private;
    if (!public.istype(type)) {
      return throw('valuetypes.checktype - ', type, 
		   ' is not a type');
    }
    if (has_field(private.checktype, type)) {
      ok := private.checktype[type](value);
      if (!ok && is_string(value)) {
	if (!checkeval) return T;
	tmp := eval(value);
	ok := private.checktype[type](tmp);
      }
      return ok;
    } else {
      # Assume OK if we don't have a verification function
      return T;
    }
  }
  
  public.default := function(type)
  {
    wider private;
    if (!is_string(type) || length(type)!=1) 
	return throw('valuetypes.istype - illegal argument');
    if (has_field(private.defaults, type))
	return private.defaults[type];
    else
	return unset;
  }
  return ref public;
}

# Make singleton
const valuetypes := const valuetypes();

types := function() {
  privatedata := [=];
  public := [=];
  
  privatedata.classes := [=];
  privatedata.includefiles := [=];
  privatedata.needhelp := [=];
  privatedata.needtitle := [=];
  privatedata.needtext  := [=];
  privatedata.group := unset;
  
  privatedata.havemeta := F;
  
  public.exists := function(class, method=unset, arg=unset)
  {
    wider privatedata;
    if (is_unset(method) || is_unset(arg)) {
      tmp := split(class, '.');
      if (length(tmp) == 0 || length(tmp) > 3)
	  return throw('types.exists - invalid name, should be',
		       ' class.method.arg, method and arg are ',
		       'optional');
      
      class := tmp[1];
      if (length(tmp) > 1) method := tmp[2];
      if (length(tmp) > 2) arg := tmp[3];
    }
    has_class := has_method := has_arg := T;
    has_class := has_field(privatedata.classes, class);
    if(!has_class) return F;       
    if (!is_unset(method)) {
      has_method := has_field(privatedata.classes[class], method);
      if(!has_method) return F;       
      if (!is_unset(arg)) {
	has_arg := has_field(privatedata.classes[class][method].data,
			     arg);
      }
      if(!has_arg) return F;       
    }
    return T;
  }
  
  public.classes := function()
  {
    wider privatedata;
    return field_names(privatedata.classes);
  }
  
  public.class := function(class)
  {
    wider public, privatedata;
    if (!is_string(class))
	return throw('types.class(class) - name must be a string');
    privatedata.lastclass := class;
    if (!public.exists(class)) {
      privatedata.classes[class] := [=];
      privatedata.needhelp[class] := T;
      privatedata.needtitle[class] := [=];
      privatedata.needtext[class] := [=];
      privatedata.group := 'basic';
    }
    return ref public;
  }
  
  public.includefile := function(file, class=unset) {
    wider public, privatedata;
    if (!is_string(file) || length(file) == 0) {
      return throw(paste('types.includefile - file is not valid:', file));
    }
    if (is_unset(class)) {
      class := privatedata.lastclass;
    }
    if (has_field(privatedata.includefiles, class)) {
      return throw(paste('type.includefile - includefile already defined for', class));
    }
    privatedata.includefiles[class] := split(file);
    return ref public;
  }
  
  public.getincludefile := function(class) {
    wider privatedata;
    if (!has_field(privatedata.includefiles, class)) {
      return F;
    } else {
      return privatedata.includefiles[class];
    }
  }
  
  public.group := function(group='basic') {
    wider privatedata;
    privatedata.group := group;
    return ref public;
  }
  
  # Automatically adds a variable_name output argument if it starts with
  # ctor_.
  public.method := function(method,title=unset,label=unset,category=unset,
			    gui='autogui', cli='autocli')
  {
    wider public, privatedata;
    if (!is_string(method) || length(method)!=1 || 	
	(dotcount := method ~ m/\./g)>1)
	return throw('public.method - illegal method name: ', method);
    if ((!is_unset(title) && !is_string(title)) ||
	(!is_unset(category) && !is_string(category)) ||
	(!is_unset(title) && !is_string(title)))
	return throw('public.method - illegal category, label or title');
    
    if (dotcount == 0) {
      class := privatedata.lastclass;
    } else {
      tmp := split(method, '.');
      class := tmp[1];
      method := tmp[2];
    }
    
    if (!public.exists(class)) {
      public.class(class);
    }
    if (public.exists(class, method))
	return throw('types.method(method) - ',class,'.',
		     method, ' is already defined');
    privatedata.classes[class][method] :=
	[data=[=],
	 gui=gui, cli=cli, group=privatedata.group];
    if (!is_unset(title)) {
      privatedata.classes[class][method].title := title;
      privatedata.needtitle[class][method] := F;
    } else {
      privatedata.needtitle[class][method] := T;
    }
    if (!is_unset(label)) privatedata.classes[class][method].label := label;
    if (!is_unset(category)) {
      privatedata.lastcategory := category;
      privatedata.classes[class][method].category := category;
    } else if (has_field(privatedata, 'lastcategory')) {
      privatedata.classes[class][method].category := privatedata.lastcategory;
    }
    
    privatedata.lastclass := class;
    privatedata.lastmethod := method;
    privatedata.needtext[class][method] := [=];
    
    if (method ~ m/^ctor_/) {
      public.tool('toolname', spaste('my', class),
		  help='Glish name for the constructed tool');
    }
    
    return ref public;
  }
  
  public.function := function(method,title=unset,label=unset,category=unset,
			      gui='autogui', cli='autocli') {
    return public.method (method,title,label,category, gui, cli);
  }
  
  # function to allow parameters from existing methods to
  # be transferred to pre-requisite parameter lists
  public.include := function(method)
  {
    wider public, privatedata;
    if (!is_string(method) || length(method) != 1 ||
	(dotcount := method ~ m/\./g)>1)
	return throw('public.include - illegal method name: ',method);
    
    if (dotcount == 0) {
      copyclass := privatedata.lastclass;
    } else {
      tmp := split (method, '.');
      copyclass := tmp[1];
      copymethod := tmp[2];
    }
    class := privatedata.lastclass;
    method := privatedata.lastmethod;
    
    if (!public.exists(copyclass,copymethod))
	return throw('public.include - data for class: ',copyclass,
		     '; method: ',copymethod,' not found');
    
    # concatenate parameter information
    fields := field_names(privatedata.classes[copyclass][copymethod].data);
    for (field in fields) {
      privatedata.classes[class][method].prereq[field] :=
	  privatedata.classes[copyclass][copymethod].data[field];
    }
    return ref public;
  }
  
  # args can be a string array
  # For autogui: parameters=[value=unset, default=unset,
  #                      dlformat=unset, listname=unset,
  #			   ptype=unset, popt=unset, pmin=unset, pmax=unset,
  #			   prange=unset, presolution=unset, 
  #			   context=unset, dependency_type=unset,
  #			   dependency_list=unset, allowunset=T]
  # For other: parameters as defined.
  public.arg := function(args, type, default=unset, dir=unset, checkeval=T,
			 help=unset, parameters=unset, allowunset=F,
			 context=unset)
  {
    wider public, privatedata;
    
    # Some preliminary work on parameters
    
    if(is_unset(parameters)) parameters:=[=];
    
    parameters.allowunset := allowunset;
    parameters.default := default;
    parameters.value := default;
    parameters.dir := dir;
    parameters.paramcontext := context;
    
    if (!is_string(args) || length(args)==0 || !is_string(type) ||
	!valuetypes.istype(type))
	return throw('public.arg - illegal argument');
    
    if (!is_unset(dir) && dir != 'in' && dir != 'out' && dir != 'inout') {
      return throw('public.arg - direction must be in, out, inout or the unset value');
    }
    
    class := privatedata.lastclass;
    method := privatedata.lastmethod;
    
    for (arg in args) {
      
      argparameters := parameters;
      
      argparameters.dlformat := arg;
      argparameters.listname := arg;
      
      if(is_unset(argparameters.dir)) {
	if(arg=='return') {
	  argparameters.dir := 'out';
	}
	else {
	  argparameters.dir := 'in';
	}
      }
      
      if(!has_field(argparameters, 'isliteral')) {
	argparameters.isliteral := F;
      }
      
      dotcount := arg ~ m/\./g ;
      if (dotcount != 0 && dotcount != 2)
	  return throw('public.arg - arg must have 0 or 2 \'.\'s');
      if (dotcount == 2) {
	tmp := split(arg, '.');
	class := tmp[1];
	method := tmp[2];
	arg := tmp[3];
      }
      
      if (has_field(privatedata.classes[class][method].data, arg))
	  return throw('types.arg - ', class,'.', method,'.', arg,
		       ' already exists');
      
      root := ref privatedata.classes[class][method].data[arg];
      if (is_unset(default)) {
	val root := [type=type, parameters=argparameters];
      } else {
	# Validate the default, but do not check if it is a string
	# which should be eval'ed at run time, since we might not
	# have included everything necessary yet.
	if (!valuetypes.checktype(default, type, checkeval=F))
	    return throw('types.arg - default value ', default, 
			 ' is not valid for type ', type);
	val root := [type=type, default=default, parameters=argparameters];
      }
      
      if (!is_unset(help)) {
	val root.help := [=];
	val root.help.text := help;
	privatedata.needtext[class][method][arg] := F;
      } else {
	privatedata.needtext[class][method][arg] := T;
      }
      
      privatedata.lastclass := class; 
      privatedata.lastmethod := method;
      privatedata.lastarg := arg;
      
    }
    return ref public;
  }
  
  public.integer := function(arg, default=1, dir=unset, checkeval=T,
			     help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='scalar'];
    return public.arg(arg, 'integer', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.vector_integer := function(arg, default='[]', dir=unset, checkeval=T,
				    help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='array'];
    return public.arg(arg, 'integer', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.vector_boolean := function(arg, default='[]', dir=unset,
				    checkeval=T,
				    help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='booleanarray'];
    return public.arg(arg, 'boolean', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.float := function(arg, default=0.0, dir=unset, checkeval=T,
			   help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='scalar'];
    return public.arg(arg, 'float', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.vector_float := function(arg, default='[]', dir=unset, checkeval=T,
				  help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='array'];
    return public.arg(arg, 'float', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.double := function(arg, default=0.0, dir=unset, checkeval=T,
			    help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='scalar'];
    return public.arg(arg, 'double', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.vector_double := function(arg, default='[]', dir=unset, checkeval=T,
				   help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='array'];
    return public.arg(arg, 'double', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.complex := function(arg, default=as_complex(0+0i, context=unset), dir=unset, checkeval=T,
			     help=unset, allowunset=F)
  {
    wider public;
    parameters := [ptype='complex'];
    return public.arg(arg, 'complex', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.vector_complex := function(arg, default='[]', dir=unset,
				    checkeval=T,
				    help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='array'];
    return public.arg(arg, 'complex', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.dcomplex := function(arg, default=as_dcomplex(0+0i, context=unset), dir=unset, checkeval=T,
			      help=unset, allowunset=F)
  {
    wider public;
    parameters := [ptype='complex'];
    return public.arg(arg, 'dcomplex', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.vector_dcomplex := function(arg, default='[]', dir=unset,
				     checkeval=T, help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='array'];
    return public.arg(arg, 'dcomplex', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  # Doing a checkeval on a string is dangerous if the string defines
  # a builtin so here we turn it off. I'm not happy about doing this
  # so reconsider this again sometime. - Tim
  public.string := function(arg, default='', dir=unset, checkeval=F,
			    help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='string'];
    return public.arg(arg, 'string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.vector_string := function(arg, default=[''], dir=unset, checkeval=T,
				   help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='vector_string'];
    return public.arg(arg, 'vector_string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.measure := function(arg, default=unset, dir=unset, checkeval=F,
			     help=unset, options=unset, allowunset=F,
			     context=unset)
  {
    wider public;
    parameters := [ptype='measure', popt=options];
    return public.arg(arg, 'record', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.measurecodes := function(arg, default=unset, dir=unset, checkeval=F,
				  help=unset, options=unset, allowunset=F,
				  context=unset)
  {
    wider public;
    parameters := [ptype='measurecodes', popt=options];
    return public.arg(arg, 'string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.epoch := function(arg, default=unset, dir=unset, checkeval=F,
			   help=unset, allowunset=F,
			   options=unset, context=unset)
  {
    wider public;
    parameters := [ptype='epoch', popt=options];
    return public.arg(arg, 'record', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.position := function(arg, default=unset, dir=unset, checkeval=F,
			      help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='position'];
    return public.arg(arg, 'record', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.direction := function(arg, default=unset, dir=unset, checkeval=F,
			       help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='direction'];
    return public.arg(arg, 'record', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.quantity := function(arg, default=unset, dir=unset, checkeval=F,
			      help=unset, options=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='quantity', popt=options];
    return public.arg(arg, 'string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.choice := function(arg, default='', dir=unset, checkeval=F,
			    help=unset, options=unset, allowunset=F, context=unset)
  {
    wider public;
    if(is_unset(options)) options:=default;
    parameters := [ptype='choice', popt=options];
    return public.arg(arg, 'string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.check := function(arg, default='', dir=unset, checkeval=F,
			   help=unset, options=unset, allowunset=F, context=unset)
  {
    wider public;
    if(is_unset(options)) options:=default;
    parameters := [ptype='check', popt=options];
    return public.arg(arg, 'string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.boolean := function(arg, default=T, dir=unset, checkeval=T,
			     help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='boolean'];
    return public.arg(arg, 'boolean', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.record := function(arg, default=[=], dir=unset, checkeval=T,
			    help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='record']
	return public.arg(arg, 'record', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.table := function(arg, default='', dir=unset, checkeval=T,
			   help=unset, options='<Any Table>', allowunset=F,
			   context=unset)
  {
    wider public;
    parameters := [ptype='table', popt=options];
    return public.arg(arg, 'table', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.taql := function(arg, default='', dir=unset, checkeval=T,
			  help=unset, options=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='string', popt=options];
    return public.arg(arg, 'string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.msselect := function(arg, default='', dir=unset, checkeval=T,
			      help=unset, options=unset, allowunset=F,
			      context=unset)
  {
    wider public;
    parameters := [ptype='string', popt=options];
    return public.arg(arg, 'string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.time := function(arg, default='', dir=unset, checkeval=T,
			  help=unset, options=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='string', popt=options];
    return public.arg(arg, 'string', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.file := function(arg, default='', dir=unset, checkeval=T,
			  help=unset, options='', allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='file', popt=options];
    return public.arg(arg, 'file', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.directory := function(arg, default='', dir=unset, checkeval=T,
			       help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='directory'];
    return public.arg(arg, 'directory', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  public.region := function(arg, default=unset, dir=unset,
			    checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='region', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.coordinates := function(arg, default=unset, dir=unset,
				 checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='coordinates', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.model := function(arg, default=unset, dir=unset,
			   checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='model', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.modellist := function(arg, default=unset, dir=unset,
			       checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='modellist', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.selection := function(arg, default=unset, dir=unset,
			       checkeval=T, help=unset, allowunset=T,
			       context=unset)
  {
    wider public;
    parameters := [ptype='selection', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.calibration := function(arg, default=unset, dir=unset,
				 checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='calibration', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.calibrationlist := function(arg, default=unset, dir=unset,
				     checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='calibrationlist', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.solver := function(arg, default=unset, dir=unset,
			    checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='solver', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.solverlist := function(arg, default=unset, dir=unset,
				checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='solverlist', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.freqsel := function(arg, default=unset, dir=unset,
			     checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='freqsel', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.restoringbeam := function(arg, default=unset, dir=unset,
				   checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='restoringbeam', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.deconvolution := function(arg, default=unset, dir=unset,
				   checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='deconvolution', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.imagingcoord := function(arg, default=unset, dir=unset,
				  checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='imagingcoord', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.imagingfield := function(arg, default=unset, dir=unset,
				  checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='imagingfield', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.imagingfieldlist := function(arg, default=unset, dir=unset,
				      checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='imagingfieldlist', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.imagingweight := function(arg, default=unset, dir=unset,
				   checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='imagingweight', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.mask := function(arg, default=unset, dir=unset,
			  checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='mask', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.transform := function(arg, default=unset, dir=unset,
			       checkeval=T, help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='transform', isliteral=T]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.tool := function(arg, default='', dir=unset, checkeval=F,
			  help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='tool', isliteral=T]
	return public.arg(arg, 'tool', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.antennas := function(arg, default='[]', dir=unset, checkeval=T,
			      help=unset, allowunset=F, context=unset) {
    wider public;
    parameters := [ptype='antennas'];
    return public.arg(arg, 'integer', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.baselines := function(arg, default='[]', dir=unset, checkeval=T,
			       help=unset, allowunset=F, context=unset) {
    wider public;
    parameters := [ptype='baselines'];
    return public.arg(arg, 'integer', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.fields := function(arg, default='[]', dir=unset, checkeval=T,
			    help=unset, allowunset=F, context=unset) {
    wider public;
    parameters := [ptype='fields'];
    return public.arg(arg, 'integer', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.fieldnames := function(arg, default="", dir=unset, checkeval=T,
			    help=unset, allowunset=F, context=unset) {
    wider public;
    parameters := [ptype='fieldnames'];
    return public.arg(arg, 'string', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.spectralwindows := function(arg, default='[]', dir=unset, checkeval=T,
				     help=unset, allowunset=F, context=unset) {
    wider public;
    parameters := [ptype='spectralwindows'];
    return public.arg(arg, 'integer', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.datadescriptions := function(arg, default='[]', dir=unset, checkeval=T,
				     help=unset, allowunset=F, context=unset) {
    wider public;
    parameters := [ptype='datadescriptions'];
    return public.arg(arg, 'integer', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.polarizations := function(arg, default='[]', dir=unset, checkeval=T,
				     help=unset, allowunset=F, context=unset) {
    wider public;
    parameters := [ptype='polarizations'];
    return public.arg(arg, 'integer', default, dir, checkeval, 
		      help, parameters, allowunset, context);
  }
  
  public.untyped := function(arg, default='', dir=unset, checkeval=F,
			     help=unset, options=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='untyped', popt=options]
	return public.arg(arg, 'untyped', default, dir, checkeval,
			  help, parameters, allowunset, context);
  }
  
  public.image := function(arg, default='', dir=unset, checkeval=T,
			   help=unset, allowunset=F, context=unset) {
    return public.table(arg, default, dir, checkeval,
			help, options=['Image','Miriad Image','FITS'], 
                        allowunset=allowunset, context=context);
  }
  
  public.ms := function(arg, default='', dir=unset, checkeval=T,
			help=unset, allowunset=F, context=unset) {
    return public.table(arg, default, dir, checkeval,
			help, options='Measurement Set', allowunset=allowunset,
			context=context);
  }
  
  public.fits := function(arg, default='', dir=unset, checkeval=T,
			  help=unset, allowunset=F, context=unset)
  {
    wider public;
    parameters := [ptype='file', popt='FITS'];
    return public.arg(arg, 'file', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.list := function(arg, types='', options=unset, name='', names='',
			  default=unset, dir=unset, checkeval=T,
			  help=unset, allowunset=T, context=unset)
  {
    wider public;
    parameters := [ptype='list', types=types, name=name, names=names,
		   popt=options];
    return public.arg(arg, 'record', default, dir, checkeval,
		      help, parameters, allowunset, context);
  }
  
  public.meta := function(class, ctors=F, addhelp=T, globals=F)
  {
    wider public, privatedata;
    ok := public.exists(class);
    if (ok) {
      
      tmp := [=];
      for (i in field_names(privatedata.classes[class])) {
	isctor := i~m/^ctor_/;
	isglob := i~m/^global_/;
	if (ctors) {
	  if(isctor) {
	    truncated := i ~ s/^ctor_//;
	    tmp[truncated] := privatedata.classes[class][i];
	  }
	}
	else if (globals) {
	  if(isglob) {
	    truncated := i ~ s/^global_//;
	    tmp[truncated] := privatedata.classes[class][i];
	  }
	}
	else {
	  if(!isctor&&!isglob) tmp[i] := privatedata.classes[class][i];
	}
      }
      return tmp;
    } else {
      return throw('types.meta - class ', class, 
		   ' has not been defined');
    }
  }
  
# Bulk copying of meta info is useful one one class inherits another
# methods
  public.addmeta := function(class, meta) {
    wider public, privatedata;
    if (!public.exists(class)) public.class(class);
    for (method in field_names(meta)) {
      if (public.exists(class, method)) {
	note('types.addmeta - over-riding method ', class, '.',
	     method);
      }
      privatedata.classes[class][method] := meta[method];
    }
    return T;
  }
  
  public.all := function()
  {
    wider privatedata;
    return privatedata.classes;
  }
  
# Note that we can't check signatures
  public.is_object := function(obj, type='unset')
  {
    wider public, privatedata;
    # The minimum we require of an object is that it only have public
    # functions.
    if (!is_record(obj) || length(obj)==0) return F;
    for (i in field_names(obj)) {
      if (!is_function(obj[i])) return F;
    }
    if (is_unset(type))
	return T; # Don't know the type
    
    if (!public.exists(type))
	return throw('types.is_object - unknown type specified');
    
    # OK, see that it is consistent with it's meta info. To allow for
    # inheritance/plugins/... we only insist that all functions in the
    # meta-info appear in the object, not the other way around.
    for (i in field_names(privatedata.classes[type])) {
      if (i ~ m/^ctor_/) continue;
      if (!has_field(obj, i)) return throw('Object is not a: ', type,
					   ' it has no \'', i, '\' method');
    }
    return T;
  }
  
  public.attachallhelp := function() {
    wider public, privatedata;
    for (type in field_names(privatedata.classes)) {
      public.attachhelp(type);
    };
  }
  
  public.attachhelp := function(type) {
    
    wider public, privatedata;
    global help;
    
    if (length(privatedata.classes) == 0) return T;
    
    if(!privatedata.needhelp[type]) return T;
    privatedata.needhelp[type] := F;
    
    if (!public.exists(type)) {
      return throw('types.attachhelp - no type named ', type, 
		   ' is defined');
    }
    
    tmp := eval('include \'aips2help.g\'');
    if (is_fail(tmp)) {
      return throw('types.attachhelp - failure including aips2help.g!');
    }
    if(length(help::pkg)==0) {
      hs:=showhelp();
    }
    
    found := F;
    for (package in field_names(help::pkg)) {
      for (module in field_names(help::pkg[package])) {
	if (has_field(help::pkg[package][module].objs, type)) {
	  found := T;
	  break;
	}
      }
      if (found) break;
    }
    
    if (!found) {
      return T; # No help to attach
    }
    
    # This is a mess but it should find information of the form:
    # help::pkg.synthesis.imager.objs.imager.c.imager.a.ms.d 
    for (ext in "c m") {
      helproot := ref help::pkg[package][module].objs[type];
      if(has_field(helproot, ext)) {
	for (method in field_names(privatedata.classes[type])) {
	  nonctormethod := method ~ s/^ctor_//;
	  nonctormethod ~:= s/^global_//;
	  if (has_field(helproot[ext], nonctormethod)) {
	    # Get method help
	    if (privatedata.needtitle[type][method]) {
	      privatedata.classes[type][method].title :=
		  helproot[ext][nonctormethod].d;
	    }
	    # Get help for arguments
	    if(has_field(helproot[ext][nonctormethod], 'a')) {
	      helproot2 := helproot[ext][nonctormethod].a;
	      metaroot := ref privatedata.classes[type][method].data
		  for (arg in field_names(helproot2)) {
		    if (has_field(metaroot, arg)) {
		      if (has_field(privatedata.needtext[type][method], arg)&&
			  privatedata.needtext[type][method][arg]) {
			val metaroot[arg].help := [=];
			val metaroot[arg].help.text := helproot2[arg].d;
		      }
		    }
		  }
	    }
	  }
	}
      }
    }
    
    privatedata.needhelp[type] := F;
    return T;
  }
  
# Force inclusion of all the meta information. This means that
# the global record types is fully up to date. This has to happen
# before any showing.
  public.includemeta := function(includepath=unset) {
    wider public, privatedata;
    if(privatedata.havemeta) return T;
    # Include all the *meta.g files we can find
    if(is_unset(includepath)) {
      global system;
      includepath := system.path.include;
    }
    include 'sh.g';
    mysh := sh();
    command := 'ls';
    for (dir in includepath) {
      command := spaste(command, ' ', dir, '/*_meta.g');
    }
    found := split(mysh.command(command).lines);
    mysh.done();
    if (length(found) > 0) {
      # This only works because privatedata is all data
      include 'os.g';
      include 'finclude.g'
	  if(!dfi.exists('types.gc')||!dfi.uptodate(found, 'types.gc')) {
	    for(file in found) {
	      # Just use the base name so that we don't pick up
	      # duplicates
	      file := dos.basename(file);
	      include file;
	    }
	    public.attachallhelp();
	    dfi.write(privatedata, 'types.gc');
	  }
      else {
	dfi.read(privatedata, 'types.gc');
      }
    }
    
    
    privatedata.havemeta := T;
    return T;
  }
  
  return ref public;
}

const types := types();

const typestest := function() {
  global types;
  
  global typestester := function(...) {
    print 'typestester contructor arguments are:', ...;

    public := [=];

    public.type := function() {return "typestester"};
    public.done := function() {wider public;public:=F;return T;};
    return public;
  }
  
  types.class('typestester').includefile('types.g');
  
  include 'measures.g';
  
  types.method('ctor_typestester').
      choice('resample', 'nearest', options="nearest bilinear").
      boolean('switch', T, allowunset=T).
      vector_float('levels', [0.2, 0.4, 0.6, 0.9]).
      float('contour', 1.2).
      region('region', unset, allowunset=T).
      file('Filename', 'myfilename', options='All', allowunset=T).
      vector_string('Strings', default="foo bar", allowunset=T).
      quantity('Cellsize', default='0.7arcsec', allowunset=T).
      quantity('Frequency', default=unset, options='freq', allowunset=T).
      integer('Imagesize', default=256, allowunset=T).
      direction('PhaseCenter', allowunset=T).
      epoch('Epoch', allowunset=T).
      measurecodes('Directioncodes', 'B1950', options='direction',
		   allowunset=T).
      untyped('Untyped', 0.0, options="region scalar").
      msselect('msselect').
      list('Sources', types=['string', 'direction'], names="Source Direction",
	   name='Source', default=[Name='3C273', Direction=dm.direction()],
           help=['Source name', 'Source direction'], allowunset=T,
	   options=unset);
  
  include 'toolmanager.g';
  include 'table.g';
  return tm.show('typestester');
}

