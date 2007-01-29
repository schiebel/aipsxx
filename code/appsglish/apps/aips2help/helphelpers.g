# helphelpers.g: helper functions for the definition of help atoms
# Copyright (C) 1996,1997,1999
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
#   $Id: helphelpers.g,v 19.1 2004/08/25 00:54:31 cvsmgr Exp $
#


pragma include once

const makeroot:=function(head, tail) {
  if(head=='') {
    return tail;
  }
  else {
    return spaste(head,'.',tail);
  }
}

const sethelpatom:=function(ref ha, category, type, helpAtom, version, keywords,
  onelineDescription='', returnValue='', seeAlso='', inc='') {
  ha::category:=category;
  ha::type:=type;
  ha::helpAtom:=helpAtom;
  ha::version:=version;
  ha::objects:=[=];
  ha::methods:=[=];
  ha::args:=[=];
  ha::help:=[=];
  ha::help.keywords:=keywords;
  ha::help.onelineDescription:=onelineDescription;
  ha::help.fullDescription:=onelineDescription;
  ha::help.returnValue:=returnValue;
  ha::help.include:=inc;
  ha::help.seeAlso:=seeAlso;
  ha::help.example:=[=];
  ha::help.example.code:='';
  ha::help.example.comments:='';
}

const addfulldescription:=function(ref ha, fullDescription) {
  ha::help.fullDescription:=fullDescription;
}

const addexample:=function(ref ha, code, comments) {
  ha::help.example.code:=code;
  ha::help.example.comments:=comments;
}

const addarg:=function(ref ha, helpAtom, authorDefault, currentDefault, legalValues,
  onelineDescription) {
  ha.helpAtom:=helpAtom;
  ha.help.currentDefault:=currentDefault;
  ha.help.legalValues:=legalValues;
  ha.help.onelineDescription:=onelineDescription;
  ha.help.fullDescription:=onelineDescription;
}

const addmethod:=function(ref object, ref objectmethod, method) {
  objectmethod:::=method::;
  objectmethod::helpAtom:=spaste(object::helpAtom, '.', method::helpAtom);
};

const addobject:=function(ref package, ref packageobject, object) {
  packageobject:::=object::;
  packageobject::parent := package::helpAtom;
};

const addfunction:=function(ref package, ref packagefunc, f) {
  packagefunc:::=f::;
  packagefunc::parent := package::helpAtom;
};

