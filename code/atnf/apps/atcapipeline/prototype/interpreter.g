#-----------------------------------------------------------------------------
# interpreter.g: Provides a command line interpreter for the ATCA pipeline
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2004
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
# $Id:
#-----------------------------------------------------------------------------
#

pragma include once

include 'os.g'

const interpreter := function(ref con){
  # a simple interpreter to edit options at the command line
  its := [=]
  its.exitedit := F
  dispatch := [=]

  its.check_type := function(rec, name, value){
    # NOTE also need to add measure/record 
    allowed := [=]
    allowed['boolean'] := ['boolean']
    allowed['double'] := ['double', 'integer']
    allowed['string'] := ['string']
    allowed['integer'] := ['integer']
    allowed['quantity'] := ['string']
 
    type := type_name(value)
    correct := rec[name].type
    for(i in allowed[correct]){
      if(type == i)
        return T
    }
    return F
  }

  its.show_cmd := function(rec, name, alt){
    if(is_fail(rec[name]))
      printf('Unknown variable %s\n', alt)
    else
      printf('%s = %s\n', alt, paste(rec[name].val, ' '))   
    return T
  }

  its.set_cmd := function(ref rec, name, alt, value_string, vislevel){
    if(is_fail(rec[name]))
      printf('Unknown variable %s\n', alt)
    else{
      # check if attribute can be changed
      if(rec[name].vis >= vislevel){
        if(rec[name].type == 'string')
          value := value_string
        else
          value := eval(value_string)

        # check that user input is of correct type
        allowed := its.check_type(rec, name, value)
        if(allowed){
          rec[name].val := value
          rec[name].mode := 'override'
          printf('%s = %s (set by user)\n', alt, paste(rec[name].val, ' '))
        }
        else{
          printf('%s is wrong type\n', alt)
          printf('It should be %s, you have entered %s\n', correct, type)
        }
      }
      else{
        printf('%s can not be modified at this level\n', alt)
        printf('%s = %s\n', alt, paste(rec[name].val, ' '))
      }
    }
    return T
  }

  dispatch['set'] := function(ref con, args){
    n := len(args)
    if(n < 3){
      printf('Invalid form of set command\n')
      printf('>> set variable value\n')
    }
    else{
      alt := args[2]
      value_string := args[3:n]
      if(has_field(con.varmap, alt)){
        # top level variable
        name := con.varmap[alt]
        ok := its.set_cmd(con, name, alt, value_string, con.vislevel.val)
        if(is_fail(ok)) fail
      }
      else if(has_field(con.ddesc.varmap, alt)){
        # variable within ddesc
        s := split(alt, '')
        ddescid := s[len(s)]
        name := con.ddesc.varmap[alt]
        ok := its.set_cmd(con.ddesc[ddescid], name, alt, value_string, con.vislevel.val)
        if(is_fail(ok)) fail
      }
      else
        printf('Unknown variable %s\n', alt)
    }
  }

  dispatch['show'] := function(ref con, args){
    if(len(args) != 2){
      printf('Invalid form of show command\n')
      printf('  >> show variable\n')
    }
    else{
      alt := args[2]
      if(has_field(con.varmap, alt)){
        # top level variable
        name := con.varmap[alt]
        ok := its.show_cmd(con, name, alt)
        if(is_fail(ok)) fail
      }
      else if(has_field(con.ddesc.varmap, alt)){
        # variable within ddesc
        s := split(alt, '')
        ddescid := s[len(s)]
        name := con.ddesc.varmap[alt]
        ok := its.show_cmd(con.ddesc[ddescid], name, alt)
        if(is_fail(ok)) fail
      }
      else
        printf('Unknown variable %s\n', alt)
    }
  }

  dispatch['showall'] := function(ref con, args){
    if(len(args) != 1){
      printf('Invalid form of showall command\n')
      printf('  >> showall\n')
    }
    else
      ok := con.show_config()
  }

  dispatch['help'] := function(ref con, args){
    if(len(args) != 2){
      printf('Invalid form of help command\n')
      printf('  >> help variable\n')
    }
    else{
      alt := args[2]
      if(has_field(con.varmap, alt)){
        # top level variable
        name := con.varmap[alt]
        if(is_fail(con[name]))
          printf('Unknown variable %s\n', alt)
        else
          printf('%s -> %s\n', alt, con[name].doc)

      }
      else if(has_field(con.ddesc.varmap, alt)){
        # variable within ddesc
        s := split(alt, '')
        ddescid := s[len(s)]
        name := con.ddesc.varmap[alt]
        ddesc := con.ddesc[ddescid]
        if(is_fail(ddesc[name]))
          printf('Unknown variable %s\n', alt)
        else
          printf('%s -> %s\n', alt, ddesc[name].doc)       
      }
      else
        printf('Unknown variable %s\n', alt)
    }
  }

  dispatch['continue'] := function(ref con, args){
    wider its
    its.exitedit := T
  }

  printf('\n')
  printf('You can now edit the configuration using the following commands:\n')
  printf('  >> set variable <value>     (sets the variable)\n')
  printf('  >> help variable            (brief definition of variable)\n')
  printf('  >> show variable            (show current value of variable)\n') 
  printf('  >> showall                  (show all values for configuration)\n')
  printf('  >> continue                 (continue processing with current settings)\n')
  printf('\n')

  while(its.exitedit == F){
    input := readline(prompt='>> ')
    words := split(input)
    if(len(words) < 1)
      continue
    cmd := to_lower(words[1])

    # check command exists
    if(is_fail(dispatch[cmd])){
      printf('Unrecognised command "%s"\n', cmd)
      continue
    }

    # if so run command
    ok := dispatch[cmd](con, words)
    if(is_fail(ok)) return fatal(PARMERR, 'Error running dispatch in config')
  }
  return T
}
