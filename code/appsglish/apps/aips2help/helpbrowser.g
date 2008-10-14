# helpbrowser: Browse AIPS++ help
#
#   Copyright (C) 1999
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
#   $Id: helpbrowser.g,v 19.1 2004/08/25 00:54:26 cvsmgr Exp $
#

pragma include once;

include 'widgetserver.g';
include 'aips2help.g';
include 'aips2logo.g';
include 'popuphelp.g';

const helpbrowser := function(widgetset=dws) {

  public := [=];

  public.type := function() {
    return 'helpbrowser';
  }

  if(!have_gui()) {
    public.gui := function() {
      return throw('No gui available', origin='helpbrowser.gui');
      return F;
    }
    return ref public;
  }
  
  widgetset.tk_hold();
  private := [frames=[packages=[=], modules=[=], functions=[=], objects=[=]],
	      labels=[packages=[=], modules=[=], functions=[=], objects=[=]],
	      listboxs=[packages=[=], modules=[=], functions=[=], objects=[=]],
	      whenevers=[packages=[=], modules=[=], functions=[=], objects=[=]]];
  

  private.frames['topframe'] := widgetset.frame(title='Help browser (AIPS++)',
						side='top', expand='y');

  private.frames['topframe']->unmap();

  private.frames['search'] := widgetset.rollup(private.frames['topframe'],
					       title='Search',
					       show=F,
					       side='top', relief='sunken');

  private.frames['searchstring'] := widgetset.frame(private.frames['search'].frame(),
						     side='left', relief='sunken');
  
  private.labels['searchstring'] := widgetset.label(private.frames['searchstring'],
						    'Search string: ');

  private.labels['search'].shorthelp := 'Search for keywords. Enter as many as you like, separated by spaces. You can use regular expression syntax if necessary.';

  private.entry['search'] := dge.string(private.frames['searchstring'], '');

  private.listboxs['search'] :=
      widgetset.scrolllistbox(private.frames['search'].frame(), height=10,
			      background='lightgrey');
  
  private.frames['subframe'] := widgetset.rollup(private.frames['topframe'],
						 title='Packages, Modules, Tools and Functions',
						 show=T,
						 side='left', relief='sunken');

  # Now make the frames for each column
  private.frames['packagesetc'] := widgetset.frame(private.frames['subframe'].frame(),
						   side='left', relief='ridge');

  private.frames['packages'] := widgetset.frame(private.frames['packagesetc'],
						side='top', expand='y');
  
  private.labels['packages'] := widgetset.label(private.frames['packages'],
						'Packages',
						background='lightgrey');
  private.listboxs['packages'] :=
      widgetset.scrolllistbox(private.frames['packages'], height=10);
  
  private.frames['modulesetc'] := widgetset.frame(private.frames['packagesetc'],
						  side='left', relief='ridge');
    
  private.frames['modules'] := widgetset.frame(private.frames['modulesetc'],
					       side='top', relief='ridge');
    
  private.labels['modules'] := widgetset.label(private.frames['modules'],
					      'Modules',
					      background='lightgrey');
    
  private.listboxs['modules'] := widgetset.scrolllistbox(private.frames['modules'], height=10);

  private.frames['toolsandfunctions'] := widgetset.frame(private.frames['modulesetc'],
							 side='left', relief='ridge');
    
  private.frames['tools'] := widgetset.frame(private.frames['toolsandfunctions'],
					     side='top', expand='y');
  
  private.labels['tools'] := widgetset.label(private.frames['tools'],
					     'Tools',
					     background='lightgrey');
  
  private.listboxs['tools'] :=
      widgetset.scrolllistbox(private.frames['tools'], height=10);
  
  private.frames['functions'] := widgetset.frame(private.frames['toolsandfunctions'],
					    side='top', expand='y');
  
  private.labels['functions'] := widgetset.label(private.frames['functions'],
					    'Global functions',
					    background='lightgrey');
  
  private.listboxs['functions'] :=
      widgetset.scrolllistbox(private.frames['functions'], height=10);

  # Now make the frame for constructors, methods and arguments

  private.frames['lower'] := widgetset.rollup(private.frames['topframe'],
					      title='Tool constructors, Tool functions, Function arguments',
					      side='left', expand='y',
					      relief='sunken');

  private.frames['constructorsandmethods'] := widgetset.frame(private.frames['lower'].frame(),
					       side='top', expand='y', relief='ridge');
  private.labels['constructorsandmethods'] := widgetset.label(private.frames['constructorsandmethods'],
					       'Tool',
					       background='lightgrey');
  private.frames['constructorsetc'] := widgetset.frame(private.frames['constructorsandmethods'],
					       side='left', expand='y');
  private.frames['constructors'] := widgetset.frame(private.frames['constructorsetc'],
					       side='top', expand='y');
  private.labels['constructors'] := widgetset.label(private.frames['constructors'],
					       'Tool constructors',
					       background='lightgrey');
  private.frames['constructors'].listbox := widgetset.frame(private.frames['constructors'],
						       side='left', expand='none');
    
  private.listboxs['constructors'] :=
      widgetset.scrolllistbox(private.frames['constructors'].listbox,
			      height=10);

  private.frames['methods'] := widgetset.frame(private.frames['constructorsetc'],
					       side='top', expand='y');
  private.labels['methods'] := widgetset.label(private.frames['methods'],
					       'Tool functions',
					       background='lightgrey');
  private.frames['methods'].listbox := widgetset.frame(private.frames['methods'],
						       side='left', expand='none');
    
  private.listboxs['methods'] :=
      widgetset.scrolllistbox(private.frames['methods'].listbox,
			      height=10);

  private.frames['arguments'] := widgetset.frame(private.frames['lower'].frame(),
					       side='top', expand='y', relief='ridge');
    
  private.labels['arguments'] := widgetset.label(private.frames['arguments'],
					         'Function arguments');
    
  private.listboxs['arguments'] :=
      widgetset.synclistboxes(private.frames['arguments'], 4,
			      ['Argument name', 'Argument description', 'Argument type', 'Default value'],
                              width=[10,40,20,20],
			      height=10,
			      background='lightgrey');

  private.frames['bottom'] := widgetset.frame(private.frames['topframe'],
					      side='left', expand='x');

  private.buttons['web'] := widgetset.button(private.frames['bottom'], 'web');

  whenever private.buttons['web']->press do {private.web();}

  private.frames['bottomright'] := widgetset.frame(private.frames['bottom'],
						   side='right', expand='x');

  private.buttons['dismiss'] := widgetset.button(private.frames['bottomright'], 'Dismiss',
						 type='dismiss');

  whenever private.buttons['dismiss']->press do {private.frames['topframe']->unmap();}

  whenever private.entry['search']->value do {
    private.listboxs['search']->delete('start', 'end');
    if(is_string($value)) {
      string := $value;
      hits := public.search(string);
      private.listboxs['search']->insert(hits);
      top:=private.listboxs['search']->get(0);
      if(is_string(top)&&strlen(top)) {
        private.showcompound();
      }
    }
  }

  whenever private.listboxs['search']->select do {
    widgetset.tk_hold();
    if(is_numeric($value)&&length($value)==1) {
      compound := $agent->get($value);
      private.showcompound(compound);
    }
    widgetset.tk_release();
  }

  whenever private.listboxs['methods']->select do {
    widgetset.tk_hold();
    if(is_numeric($value)&&length($value)==1) {
      method := $agent->get($value);
      private.showmethod(method);
    }
    widgetset.tk_release();
  }

  whenever private.listboxs['constructors']->select do {
    widgetset.tk_hold();
    if(is_numeric($value)&&length($value)==1) {
      constructor := $agent->get($value);
      private.showconstructor(constructor); 	# Reset selection
    }
    widgetset.tk_release();
  }

  whenever private.listboxs['tools']->select do {
    widgetset.tk_hold();
    private.showfunctions(private.module);	# Reset selection
    if(is_numeric($value)&&length($value)==1) {
      tool := $agent->get($value);
      private.showconstructors(tool);	# Show constructors
      private.showmethods(tool);	# Show methods
    }
    widgetset.tk_release();
  }

  whenever private.listboxs['functions']->select do {
    widgetset.tk_hold();
    private.showtools(private.module);	# Reset selection
    if(is_numeric($value)&&length($value)==1) {
      fun := $agent->get($value);
      private.showfunction(fun);	# Show function
    }
    widgetset.tk_release();
  }

  whenever private.listboxs['modules']->select do {
    widgetset.tk_hold();
    if(is_numeric($value)&&length($value)==1) {
      module := $agent->get($value);
      private.showtools(module);	# Show tools
      private.showfunctions(module);	# Show functions
    }
    widgetset.tk_release();
  }
  
  whenever private.listboxs['packages']->select do {
    widgetset.tk_hold();
    if(is_numeric($value)&&length($value)==1) {
      package := $agent->get($value)
      private.showmodules(package);	# Show modules
    }
    widgetset.tk_release();
  }

  private.reset := function() {
    wider private;
    private.package := '';
    private.module := '';
    private.tool := '';
    private.function := '';
    private.constructor := '';
    return T;
  }

  private.web := function() {
    wider private;

    command := 'Refman:';
    if(private.module!='') {
      command := spaste(command,private.module);
      if(private.tool!='') {
	command := spaste(command,'.',private.tool);
      }
      else if(private.function!='') {
	command := spaste(command,'.',private.function);
      }
    }
    return help(command);
  }

  private.showcurrent := function() {
    wider private;
    
    if(private.package!='') {
      name := private.package;
      if(private.module!='') {
	name := spaste(name,'.',private.module);
	if(private.tool!='') {
	  name := spaste(name,'.',private.tool);
	}
	else if(private.function!='') {
	  name := spaste(name,'.',private.function);
	}
      }
    }
    else {
      name := '';
    }
    return name;
  }

  private.insert := function(ref lb, list) {
    lb.list := list;
    lb->insert(list);
    lb->view('0');
    return T;
  }

  private.select := function(lb, value) {
    lb->delete('start', 'end');
    lb->insert(lb.list);
    index :=-1;
    if(has_field(lb, 'list')) {
      for (item in split(lb.list)) {
        index +:= 1;
        if(item==value) {
          break;
	}
      }
      if(index<0) return F;
      lb->select(as_string(index));
    }
    return T;
  }

  private.showarguments := function(fun, rec) {

    wider private;

    if(has_field(rec, 'd')) {
      private.labels['arguments']->text(paste(fun, ':', rec.d));
    }
    else {
      private.labels['arguments']->text(fun);
    }
    private.listboxs['arguments']->delete('start', 'end');

    if(has_field(rec, 'a')&&length(rec.a)) {
      names := field_names(rec.a);
      for (arg in 1:length(rec.a)) {
        values := array('', 4);
        values[1] := names[arg];
        if(has_field(rec.a[arg], 'd')) values[2]:=rec.a[arg].d;
        if(has_field(rec.a[arg], 'a')) values[3]:=rec.a[arg].a;
        if(has_field(rec.a[arg], 'def')) values[4]:=rec.a[arg].def;
        private.insert(private.listboxs['arguments'], values);
      }
    }
    private.listboxs['arguments']->view(0);
    return T;
  }

  private.showmethod := function(method='') {
    wider private;

    if(method=='') method := private.listboxs['methods']->get('0');
    if(has_field(private.packmod, 'objs')&&
       has_field(private.packmod.objs, private.tool)&&
       has_field(private.packmod.objs[private.tool], 'm')&&
       has_field(private.packmod.objs[private.tool].m, method)) {
      private.select(private.listboxs['methods'], method);
      private.method := method;
      rec := private.packmod.objs[private.tool].m[method];
      private.showarguments(spaste('Method : ', method), rec);
    }
    else {
      return F;
    }

  }

  private.showconstructor := function(constructor='') {
    wider private;

    if(constructor=='') constructor := private.listboxs['constructors']->get('0');
    if(has_field(private.packmod, 'objs')&&
       has_field(private.packmod.objs, private.tool)&&
       has_field(private.packmod.objs[private.tool], 'c')&&
       has_field(private.packmod.objs[private.tool].c, constructor)) {
      private.select(private.listboxs['constructors'], constructor);
      private.constructor := constructor;
      rec := private.packmod.objs[private.tool].c[constructor];
      private.showarguments(spaste('Constructor : ', constructor), rec);
    }
    else {
      return F;
    }

  }

  private.showfunction := function(fun='') {
    wider private;

    for(field in ['methods', 'constructors']) {
      private.listboxs[field]->delete('start', 'end');
      private.listboxs[field]->disable();
      private.listboxs[field]->background('lightgrey');
    }
    private.labels['constructorsandmethods']->text('');

    if(fun=='') fun := private.listboxs['functions']->get('0');
    if(has_field(private.packmod, 'funs')&&
       has_field(private.packmod.funs, fun)) {
      private.select(private.listboxs['functions'], fun);
      private.function := fun;
      rec := private.packmod.funs[fun];
      private.showarguments(spaste('Function ', fun), rec);
    }
    else {
      return F;
    }

    return T;

  }

  # Show all methods
  private.showmethods := function(tool='') {
    wider private;

    private.listboxs['methods']->delete('start', 'end');
    private.listboxs['methods']->enable();
    private.listboxs['methods']->background('white');

    if(tool=='') tool := private.listboxs['tools']->get('0');
    if(has_field(private.packmod, 'objs')&&
       has_field(private.packmod.objs, tool)) {
      private.select(private.listboxs['tools'], tool);
      private.tool := tool;
    }
    else {
      return F;
    }

    if(has_field(private.packmod.objs[tool], 'd')) {
      private.labels['constructorsandmethods']->text(private.packmod.objs[tool].d);
    }

    if(has_field(private.packmod, 'objs')&&
       has_field(private.packmod.objs, tool)&&
       has_field(private.packmod.objs[tool], 'm')) {
      names := sort(field_names(private.packmod.objs[tool].m));
      private.insert(private.listboxs['methods'], names);
      name:=names[1];
      rec := private.packmod.objs[tool].m[name];
      if(name!='') {
	private.showarguments(spaste('Tool function ', tool, '.', name), rec);
	private.method := name;
	private.select(private.listboxs['methods'], name);
        return T;
      }
      else {
        return F;
      }
    }
    return T;
  }

  # Show all tool constructors
  private.showconstructors := function(tool='') {
    wider private;

    private.listboxs['constructors']->delete('start', 'end');
    private.listboxs['constructors']->enable();
    private.listboxs['constructors']->background('white');

    if(tool=='') tool := private.listboxs['tools']->get('0');
    if(has_field(private.packmod, 'objs')&&
       has_field(private.packmod.objs, tool)) {
      private.select(private.listboxs['tools'], tool);
      private.tool := tool;
    }
    else {
      return F;
    }

    if(has_field(private.packmod.objs[tool], 'd')) {
      private.labels['constructorsandmethods']->text(private.packmod.objs[tool].d);
    }

    if(has_field(private.packmod, 'objs')&&
       has_field(private.packmod.objs, tool)&&
       has_field(private.packmod.objs[tool], 'c')) {
      names := sort(field_names(private.packmod.objs[tool].c));
      private.insert(private.listboxs['constructors'], names);
      name:=names[1];
      rec := private.packmod.objs[tool].c[name];
      if(name!='') {
	private.showarguments(spaste('Tool constructor: ', name), rec);
	private.constructor := name;
	private.select(private.listboxs['constructors'], name);
      }
      else {
	return F;
      }
    }
    return T;
  }

  # Show all tools
  private.showtools := function(module='') {
    wider private;

    private.listboxs['tools']->delete('start', 'end');
    private.listboxs['tools']->enable();
    private.listboxs['tools']->background('white');

    if(module=='') module := private.listboxs['modules']->get('0');
    if(has_field(help::pkg[private.package], module)) {
      private.module := module;
      private.select(private.listboxs['modules'], module);
    }
    else {
      return F;
    }

    private.packmod := ref help::pkg[private.package][private.module];
    if(has_field(private.packmod, 'd')) {
      private.labels['toolsetc']->text(private.packmod.d);
    }

    if(has_field(private.packmod, 'objs')) {
      private.insert(private.listboxs['tools'], sort(field_names(private.packmod.objs)));
    }

    result1:=private.showmethods();
    result2:=private.showconstructors();

    return (result1||result2);

  }


  # Show all (global) functions
  private.showfunctions := function(module='') {
    wider private;

    private.listboxs['functions']->delete('start', 'end');

    if(module=='') module := private.listboxs['modules']->get('0');
    if(has_field(help::pkg[private.package], module)) {
      private.module := module;
      private.select(private.listboxs['modules'], module);
    }
    else {
      return F;
    }

    private.packmod := ref help::pkg[private.package][private.module];
    if(has_field(private.packmod, 'd')) {
      private.labels['toolsetc']->text(private.packmod.d);
    }

    if(has_field(private.packmod, 'funs')) {
      private.insert(private.listboxs['functions'], sort(field_names(private.packmod.funs)));
    }

    return private.showfunction();

  }

  # Show all modules
  private.showmodules := function(package='') {
    wider private;

    private.listboxs['modules']->delete('start', 'end');

    if(package=='') package := private.listboxs['packages']->get('0');
    if(has_field(help::pkg, package)) {
      private.package := package;
      private.select(private.listboxs['packages'], package);
    }
    else {
      return F;
    }
    
    if(has_field(help::pkg[private.package], 'd')) {
      private.labels['modulesetc']->text(help::pkg[private.package].d);
    }

    private.insert(private.listboxs['modules'], sort(field_names(help::pkg[private.package])));
    
    result1:=private.showtools();
    result2:=private.showfunctions();

    return (result1||result2);

  }


  # Show all packages
  private.showpackages := function() {
    wider private;

    private.reset();
    private.listboxs['packages']->delete('start', 'end');

    # Ensure that the system is initialized
    if(length(help::pkg)==0) hs:=showhelp();
  
    private.insert(private.listboxs['packages'], sort(field_names(help::pkg)));

    private.showmodules();
    return T;

  }

  # Search for string what. This has no memory of the previous 
  # search
  public.search := function(what){
    wider private;

    target := split(what);
    
    hits := '';
    for(i in 1:len(what)){
      hitFlags := help::atoms ~ eval(spaste('m/',what[i],'/'));
      if(sum(hitFlags)) {
	found := help::atoms[hitFlags];
	if(length(found)&&is_string(found)) {
	  hits := paste(hits, found);
	}
      }
    }
    return split(hits);
  }

  public.show := function(package='', module='', tool='', method='') {
    wider private;
    private.reset();
    if(package!='') {
      if(private.showmodules(package)) {
	if (module!='') {
	  result1 := private.showtools(module);
	  result2 := private.showfunctions(module);
	  if(result1||result2) {
            if(tool!='') {
	      result1 := private.showmethods(tool)
	      result2 := private.showconstructors(tool);
	      if(result1||result2) {
                if(method!='') {
		  if(!private.showmethod(method)) {
		    return private.showconstructor(method);
		  }
		}
	      }
	      else {
		return private.showfunction(tool);
	      }
	    }
	  }
	}
      }
    }
    else {
      private.showpackages();
    }
    return T;
  }

  private.showcompound := function(string) {
    wider private;
    private.reset();
    parts := split(string, '.');
    if(length(parts)>0) {
      package:=parts[1];
      if(private.showmodules(package)&&(length(parts)>1)) {
	module:=parts[2];
        result1:=private.showtools(module);
	result2:=private.showfunctions(module);
        if((result1||result2)&&length(parts)>2) {
	  tool:=parts[3];
          result1:=private.showmethods(tool);
	  result2:=private.showconstructors(tool);
	  if((result1||result2)&&(length(parts)>3)) {
	    fun := parts[4];
	    if(!private.showmethod(fun)) {
              return private.showconstructor(fun);
	    }
	  }
	  else {
	    return private.showfunction(tool);
	  }
	}
      }
    }
    else {
      private.showpackages();
    }
    return T;
  }

  public.type := function() {
    return 'helpbrowser';
  }

  public.gui := function() {
    wider private;

    # Ensure that the system is initialized
    if(length(help::pkg)==0) hs:=showhelp();
  
    private.frames['topframe']->map();
    result := private.showpackages();
    return T;
  }
  
  public.debug := function() {return ref private;};

  result := widgetset.tk_release();

  addpopuphelp(private, 5);

  return ref public;

}

const defaulthelpbrowser := helpbrowser();
const dh := ref defaulthelpbrowser;

