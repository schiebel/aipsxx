#-----------------------------------------------------------------------------
# error.g: Error handling functions for the ATCA pipeline
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

global NONE := 0
const NONE := NONE
global FATAL := 5
const FATAL := FATAL
global RECOVER := 4
const RECOVER := RECOVER
global WARNING := 3
const WARNING := WARNING

# error codes
global IOERR := 1
const IOERR := IOERR
global PARMERR := 2
const PARMERR := PARMERR

global error := [=]
error.stack := ''
error.file := ''
error.line := 0
error.message := ''
error.msg := ''
error.num := unset
error.severity := unset

const fatal := function(num, msg, failobj=F){
  global error

  if(is_record(failobj)){
    error.stack := failobj.stack
    error.file := failobj.file
    error.line := failobj.line
    if(has_field(failobj, 'message'))
      error.message := failobj.message
  }
  error.msg := msg
  error.num := num
  error.severity := FATAL

  if(DEBUG){
    if(is_record(failobj))
      fail
    else 
      fail 'No error message generated'
  }
  else
    fail msg
}

const recover := function(num, msg){
  global error
  error.msg := msg
  error.num := num
  error.severity := RECOVER

  fail msg
}

const clear_error := function(){
  global error
  error.msg := ''
  error.num := NONE
  error.severity := NONE
}

const print_fail := function(){
  printf('<fail>: %s\n', error.message)
  printf('        File:   %s, Line %d\n', error.file, error.line)
  printf('        Stack:  %s\n', error.stack)
  printf('\n')
}

const report_error_ui := function(pl=unset){
  if(DEBUG){
    print_fail()
    exit
  }
  else{
    printf('-----------------------------------------------\n')
    printf('ERROR: %s\n', error.msg)
    printf('-----------------------------------------------\n')

    if(error.severity == FATAL){
      note(error.msg, priority='SEVERE')
      if(pl)
        pl.done()
      else
        exit
    }
    else{
      note(error.msg, priority='WARN')
      return T
    }
  }
}

const report_error_ws := function(pl=unset){
  if(DEBUG){
    print_fail()
    exit
  }
  else{
    printf('-----------------------------------------------\n')
    printf('ERROR: %s\n', error.msg)
    printf('-----------------------------------------------\n')

    if(error.severity == FATAL)
      note(error.msg, priority='SEVERE')
    else
      note(error.msg, priority='WARN')
 
    if(!is_unset(pl))
      pl.done()
    else
      exit
  }
}
