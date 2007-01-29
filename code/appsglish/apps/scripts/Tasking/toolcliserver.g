# toolcliserver: Serves CLIs for tools
#
#   Copyright (C) 1998,1999,2000
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
#   $Id: toolcliserver.g,v 19.2 2004/08/25 02:05:48 cvsmgr Exp $
#

pragma include once;

const toolcliserver := subsequence() {
  
  include 'types.g';
  include 'note.g';
  include 'choice.g';
  include 'sh.g';
  include 'aipsrc.g';
  include 'autocli.g';
  include 'servers.g';

  private := [=];
  
  private.subs := [=];
  private.subs.ctor := [=];
  private.subs.tool := [=];
  private.subs.toolfunction := [=];
  private.subs.execute := [=];
  
  include 'toolmanagersupport.g';
  private.tms := toolmanagersupport;

# Constructor CLI: this simply stores and calls the subsequence
  const self.constructor := function(type, ref tool=unset, 
				       script=F) {
    wider private;
    if(has_field(private.subs.ctor, type)&&is_agent(private.subs.ctor[type])) {
      private.subs.ctor[type].loop();
    }
    else {
      include 'toolclibasefunction.g';
      private.subs.ctor[type] :=
	  toolclibasefunction(type=type, tool=unset, 
			      title=spaste('Create AIPS++ ', type),
			      mode='construct');
      if(is_fail(private.subs.ctor[type])) fail;
      return private.subs.ctor[type].loop();
    }
  }
  
# Tool CLI: this simply stores and calls the subsequence
  const self.tool := function(tool, type, title=unset, script=F) {
    
    title:=spaste('AIPS++ tool ', tool);
    meta := types.meta(type);
    methods := sort(field_names(meta));
    wider private;
    if(has_field(private.subs.tool, tool)&&
       !is_boolean(private.subs.tool[tool])) {
      private.subs.tool[tool].loop();
    }
    else {
      include 'toolclibasefunction.g';
      private.subs.tool[tool] :=
	  toolclibasefunction(type=type, tool=tool, title=title,
			       methods=methods, 
			       mode='tool')
      if(is_fail(private.subs.tool[tool])) fail;
      private.subs.tool[tool].loop();
    }
  }
  
# Manager CLI
  const self.showmanager := function() {
    
    global types;
    
    tools := tm.tools();
    
    widthpackage:=13;
    widthmodule:=13;
    widthtools:=13;
    widthsize:=15;
    widthtype:=15;
    widthdescription:=80;
    typenames := sort(types.classes());
    if(0) {
    line := 'Available tools:\n';
    line := spaste(line, sprintf('%*s', widthtype, 'Tool type'));
    line := spaste(line, sprintf('%*s', widthpackage, 'Package'));
    line := spaste(line, sprintf('%*s', widthmodule, 'Module'));
    line := spaste(line, sprintf('%*s', widthdescription, 'Description'));
    line := spaste(line, '\n');
    for (i in typenames) {
      meta := types.meta(i, ctors=T, addhelp=F);
      if (length(meta)>0) {
	rec:=private.tms.where(i);
	line := spaste(line, sprintf('%*s', widthtype, i));
	line := spaste(line, sprintf('%*s', widthpackage, rec.package));
	line := spaste(line, sprintf('%*s', widthmodule, rec.module));
	line := spaste(line, sprintf('%*s', widthdescription,
				     rec.description));
	line := spaste(line, '\n');
      }
    }
    line:=spaste(line, 'Tools in use:\n');
    }
    line:='Tools in use:\n';
    line := spaste(line, sprintf('%*s', widthtools, 'Tool name'));
    line := spaste(line, sprintf('%*s', widthtype, 'Tool type'));
    line := spaste(line, sprintf('%*s', widthdescription, 'Description'));
    line := spaste(line, '\n');
    
    for (tool in sort(field_names(tools))) {
      line := spaste(line, sprintf('%*s', widthtools, tool));
      line := spaste(line, sprintf('%*s', widthtype, tools[tool].type));
      line := spaste(line, sprintf('%*s', widthdescription,
				   tools[tool].description));
      line := spaste(line, '\n');
    }
    print line;
  }
  
  const self.help := function(package='', module='', type='')
  {
    wider private;
    helptxt:='';
    if(package!='')
    {
      helptxt:=package;
      if(module!='') {
	helptxt:=spaste(helptxt, '.', module);
	if(type!='') {
	  helptxt:=spaste(helptxt,'.', type, '\$');
	}
      }
    }
    note('Show help for ', helptxt);
    print help(helptxt);
  }
  
}
