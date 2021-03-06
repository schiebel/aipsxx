# atomsnpoi.g: help atoms for the npoi package. 
# Copyright (C) 1999
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
# $Id: atomsnpoi.g,v 19.948 2006/09/29 01:49:20 wyoung Exp $

pragma include once
val help::pkg.npoi := [=];
help::pkg.npoi::d := 'NPOI-related Modules and Tools';

help::pkg.npoi.HDS := [=];
help::pkg.npoi.HDS.objs := [=];
help::pkg.npoi.HDS.funs := [=];
help::pkg.npoi.HDS.d := 'Module for manipulating HDS format files';
help::pkg.npoi.HDS.objs.HDS := [=];
help::pkg.npoi.HDS.objs.HDS.m := [=];
help::pkg.npoi.HDS.objs.HDS.c := [=];
help::pkg.npoi.HDS.objs.HDS.d := 'A tool for the manipulation of HDS files';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.d := 'Create a new HDS file';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.file := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.file.d := 'File name';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.file.def := '';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.file.a := 'string';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.name.d := 'Top-level object name';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.type := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.type.d := 'Top-level object type';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.type.def := '\' \' ';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.type.a := 'string';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.dims := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.dims.d := 'Top-level object dimensions';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.dims.def := '0';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.dims.a := 'integer';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.host := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.host.d := 'Host name';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.host.def := '\' \' ';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.host.a := 'string';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.forcenewserver := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.forcenewserver.d := 'Force-new-server flag';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.forcenewserver.def := 'F';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.a.forcenewserver.a := 'boolean';
help::pkg.npoi.HDS.objs.HDS.c.hdsnew.s := 'hdsnew(file, name, type, dims, host, forcenewserver)';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.d := 'Open an HDS file for read/update';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.file := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.file.d := 'File name';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.file.def := '';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.file.a := 'string';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.readonly := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.readonly.d := 'Read-only flag';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.readonly.def := 'T';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.readonly.a := 'boolean';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.host := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.host.d := 'Host name';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.host.def := '\' \' ';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.host.a := 'string';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.forcenewserver := [=];
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.forcenewserver.d := 'Force-new-server flag';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.forcenewserver.def := 'F';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.a.forcenewserver.a := 'boolean';
help::pkg.npoi.HDS.objs.HDS.c.hdsopen.s := 'hdsopen(file, readonly, host, forcenewserver)';
help::pkg.npoi.HDS.objs.HDS.m.done := [=];
help::pkg.npoi.HDS.objs.HDS.m.done.d := 'Closes an HDS file';
help::pkg.npoi.HDS.objs.HDS.m.done.s := 'done()';
help::pkg.npoi.HDS.objs.HDS.m.gui := [=];
help::pkg.npoi.HDS.objs.HDS.m.gui.d := 'Creates a read-only browser for generic HDS files';
help::pkg.npoi.HDS.objs.HDS.m.gui.s := 'gui()';
help::pkg.npoi.HDS.objs.HDS.m.alter := [=];
help::pkg.npoi.HDS.objs.HDS.m.alter.d := 'Alters the shape of an HDS object';
help::pkg.npoi.HDS.objs.HDS.m.alter.a.lastdim := [=];
help::pkg.npoi.HDS.objs.HDS.m.alter.a.lastdim.d := 'Size of last dimension';
help::pkg.npoi.HDS.objs.HDS.m.alter.a.lastdim.def := '';
help::pkg.npoi.HDS.objs.HDS.m.alter.a.lastdim.a := 'integer $>$ 1';
help::pkg.npoi.HDS.objs.HDS.m.alter.s := 'alter(lastdim)';
help::pkg.npoi.HDS.objs.HDS.m.annul := [=];
help::pkg.npoi.HDS.objs.HDS.m.annul.d := 'Annuls locator(s)';
help::pkg.npoi.HDS.objs.HDS.m.annul.a.locatorannul := [=];
help::pkg.npoi.HDS.objs.HDS.m.annul.a.locatorannul.d := 'Number of locators to annul';
help::pkg.npoi.HDS.objs.HDS.m.annul.a.locatorannul.def := '1';
help::pkg.npoi.HDS.objs.HDS.m.annul.a.locatorannul.a := 'integer $>$ 1';
help::pkg.npoi.HDS.objs.HDS.m.annul.s := 'annul(locatorannul)';
help::pkg.npoi.HDS.objs.HDS.m.cell := [=];
help::pkg.npoi.HDS.objs.HDS.m.cell.d := 'Goes to a single cell of a multidimensional HDS object';
help::pkg.npoi.HDS.objs.HDS.m.cell.a.dims := [=];
help::pkg.npoi.HDS.objs.HDS.m.cell.a.dims.d := 'Cell dimension of the HDS object';
help::pkg.npoi.HDS.objs.HDS.m.cell.a.dims.def := '';
help::pkg.npoi.HDS.objs.HDS.m.cell.a.dims.a := '1-dimensional integer';
help::pkg.npoi.HDS.objs.HDS.m.cell.s := 'cell(dims)';
help::pkg.npoi.HDS.objs.HDS.m.clen := [=];
help::pkg.npoi.HDS.objs.HDS.m.clen.d := 'Returns the number of characters need to represent an HDS primitive object';
help::pkg.npoi.HDS.objs.HDS.m.clen.s := 'clen()';
help::pkg.npoi.HDS.objs.HDS.m.copy := [=];
help::pkg.npoi.HDS.objs.HDS.m.copy.d := 'Recursively copy the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.copy.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.copy.a.name.d := 'Name of new object';
help::pkg.npoi.HDS.objs.HDS.m.copy.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.copy.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.copy.a.other := [=];
help::pkg.npoi.HDS.objs.HDS.m.copy.a.other.d := 'Name of other tool';
help::pkg.npoi.HDS.objs.HDS.m.copy.a.other.def := '\' \'  (the present tool)';
help::pkg.npoi.HDS.objs.HDS.m.copy.a.other.a := 'Another tool';
help::pkg.npoi.HDS.objs.HDS.m.copy.s := 'copy(name, other)';
help::pkg.npoi.HDS.objs.HDS.m.copy2file := [=];
help::pkg.npoi.HDS.objs.HDS.m.copy2file.d := 'Recursively copy an HDS object to a new HDS file';
help::pkg.npoi.HDS.objs.HDS.m.copy2file.a.file := [=];
help::pkg.npoi.HDS.objs.HDS.m.copy2file.a.file.d := 'File name';
help::pkg.npoi.HDS.objs.HDS.m.copy2file.a.file.def := '';
help::pkg.npoi.HDS.objs.HDS.m.copy2file.a.file.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.copy2file.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.copy2file.a.name.d := 'Top-level object name in new file';
help::pkg.npoi.HDS.objs.HDS.m.copy2file.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.copy2file.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.copy2file.s := 'copy2file(file, name)';
help::pkg.npoi.HDS.objs.HDS.m.create := [=];
help::pkg.npoi.HDS.objs.HDS.m.create.d := 'Puts data into a new non-scalar HDS primitive';
help::pkg.npoi.HDS.objs.HDS.m.create.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.create.a.name.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.create.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.create.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.create.a.type := [=];
help::pkg.npoi.HDS.objs.HDS.m.create.a.type.d := 'Object type';
help::pkg.npoi.HDS.objs.HDS.m.create.a.type.def := '\' \' ';
help::pkg.npoi.HDS.objs.HDS.m.create.a.type.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.create.a.data := [=];
help::pkg.npoi.HDS.objs.HDS.m.create.a.data.d := 'Glish variable containing data';
help::pkg.npoi.HDS.objs.HDS.m.create.a.data.def := '';
help::pkg.npoi.HDS.objs.HDS.m.create.a.data.a := 'numeric,boolean,string';
help::pkg.npoi.HDS.objs.HDS.m.create.a.replace := [=];
help::pkg.npoi.HDS.objs.HDS.m.create.a.replace.d := 'Replace flag';
help::pkg.npoi.HDS.objs.HDS.m.create.a.replace.def := 'F';
help::pkg.npoi.HDS.objs.HDS.m.create.a.replace.a := 'boolean';
help::pkg.npoi.HDS.objs.HDS.m.create.s := 'create(name, type, data, replace)';
help::pkg.npoi.HDS.objs.HDS.m.erase := [=];
help::pkg.npoi.HDS.objs.HDS.m.erase.d := 'Recursively erase an HDS object';
help::pkg.npoi.HDS.objs.HDS.m.erase.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.erase.a.name.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.erase.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.erase.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.erase.s := 'erase(name)';
help::pkg.npoi.HDS.objs.HDS.m.file := [=];
help::pkg.npoi.HDS.objs.HDS.m.file.d := 'Returns the HDS file name';
help::pkg.npoi.HDS.objs.HDS.m.file.s := 'file()';
help::pkg.npoi.HDS.objs.HDS.m.filetail := [=];
help::pkg.npoi.HDS.objs.HDS.m.filetail.d := 'Returns the HDS file name without the directory';
help::pkg.npoi.HDS.objs.HDS.m.filetail.s := 'filetail()';
help::pkg.npoi.HDS.objs.HDS.m.find := [=];
help::pkg.npoi.HDS.objs.HDS.m.find.d := 'Goes to an HDS object';
help::pkg.npoi.HDS.objs.HDS.m.find.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.find.a.name.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.find.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.find.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.find.s := 'find(name)';
help::pkg.npoi.HDS.objs.HDS.m.forcenewserver := [=];
help::pkg.npoi.HDS.objs.HDS.m.forcenewserver.d := 'Returns the force-new-server flag';
help::pkg.npoi.HDS.objs.HDS.m.forcenewserver.s := 'forcenewserver()';
help::pkg.npoi.HDS.objs.HDS.m.get := [=];
help::pkg.npoi.HDS.objs.HDS.m.get.d := 'Gets data from an HDS primitive object';
help::pkg.npoi.HDS.objs.HDS.m.get.s := 'get()';
help::pkg.npoi.HDS.objs.HDS.m.goto := [=];
help::pkg.npoi.HDS.objs.HDS.m.goto.d := 'Goes to an HDS object using the fully resolved path';
help::pkg.npoi.HDS.objs.HDS.m.goto.a.path := [=];
help::pkg.npoi.HDS.objs.HDS.m.goto.a.path.d := 'Path';
help::pkg.npoi.HDS.objs.HDS.m.goto.a.path.def := '';
help::pkg.npoi.HDS.objs.HDS.m.goto.a.path.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.goto.s := 'goto(path)';
help::pkg.npoi.HDS.objs.HDS.m.host := [=];
help::pkg.npoi.HDS.objs.HDS.m.host.d := 'Returns the host name';
help::pkg.npoi.HDS.objs.HDS.m.host.s := 'host()';
help::pkg.npoi.HDS.objs.HDS.m.id := [=];
help::pkg.npoi.HDS.objs.HDS.m.id.d := 'Returns the glish/aips++ object ID';
help::pkg.npoi.HDS.objs.HDS.m.id.s := 'id()';
help::pkg.npoi.HDS.objs.HDS.m.index := [=];
help::pkg.npoi.HDS.objs.HDS.m.index.d := 'Indexes into an HDS object';
help::pkg.npoi.HDS.objs.HDS.m.index.a.index := [=];
help::pkg.npoi.HDS.objs.HDS.m.index.a.index.d := 'Index number';
help::pkg.npoi.HDS.objs.HDS.m.index.a.index.def := '';
help::pkg.npoi.HDS.objs.HDS.m.index.a.index.a := 'integer';
help::pkg.npoi.HDS.objs.HDS.m.index.s := 'index(index)';
help::pkg.npoi.HDS.objs.HDS.m.len := [=];
help::pkg.npoi.HDS.objs.HDS.m.len.d := 'Returns the length of the present HDS primitive object';
help::pkg.npoi.HDS.objs.HDS.m.len.s := 'len()';
help::pkg.npoi.HDS.objs.HDS.m.list := [=];
help::pkg.npoi.HDS.objs.HDS.m.list.d := 'Returns the list of HDS objects beneath the present one';
help::pkg.npoi.HDS.objs.HDS.m.list.s := 'list()';
help::pkg.npoi.HDS.objs.HDS.m.locator := [=];
help::pkg.npoi.HDS.objs.HDS.m.locator.d := 'Returns the present locator number';
help::pkg.npoi.HDS.objs.HDS.m.locator.s := 'locator()';
help::pkg.npoi.HDS.objs.HDS.m.move := [=];
help::pkg.npoi.HDS.objs.HDS.m.move.d := 'Recursively move the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.move.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.move.a.name.d := 'Name of new object';
help::pkg.npoi.HDS.objs.HDS.m.move.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.move.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.move.a.other := [=];
help::pkg.npoi.HDS.objs.HDS.m.move.a.other.d := 'Name of other tool';
help::pkg.npoi.HDS.objs.HDS.m.move.a.other.def := '\' \'  (the present tool)';
help::pkg.npoi.HDS.objs.HDS.m.move.a.other.a := 'Another HDS tool';
help::pkg.npoi.HDS.objs.HDS.m.move.s := 'move(name, other)';
help::pkg.npoi.HDS.objs.HDS.m.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.name.d := 'Returns the name of the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.name.s := 'name()';
help::pkg.npoi.HDS.objs.HDS.m.ncomp := [=];
help::pkg.npoi.HDS.objs.HDS.m.ncomp.d := 'Returns the number of HDS objects beneath the present one';
help::pkg.npoi.HDS.objs.HDS.m.ncomp.s := 'ncomp()';
help::pkg.npoi.HDS.objs.HDS.m.new := [=];
help::pkg.npoi.HDS.objs.HDS.m.new.d := 'Makes space for a new HDS object';
help::pkg.npoi.HDS.objs.HDS.m.new.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.new.a.name.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.new.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.new.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.new.a.type := [=];
help::pkg.npoi.HDS.objs.HDS.m.new.a.type.d := 'Object type';
help::pkg.npoi.HDS.objs.HDS.m.new.a.type.def := '';
help::pkg.npoi.HDS.objs.HDS.m.new.a.type.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.new.a.dims := [=];
help::pkg.npoi.HDS.objs.HDS.m.new.a.dims.d := 'Object dimensions';
help::pkg.npoi.HDS.objs.HDS.m.new.a.dims.def := '';
help::pkg.npoi.HDS.objs.HDS.m.new.a.dims.a := 'integer';
help::pkg.npoi.HDS.objs.HDS.m.new.a.replace := [=];
help::pkg.npoi.HDS.objs.HDS.m.new.a.replace.d := 'Replace flag';
help::pkg.npoi.HDS.objs.HDS.m.new.a.replace.def := 'F';
help::pkg.npoi.HDS.objs.HDS.m.new.a.replace.a := 'boolean';
help::pkg.npoi.HDS.objs.HDS.m.new.s := 'new(name, type, dims, replace)';
help::pkg.npoi.HDS.objs.HDS.m.numdim := [=];
help::pkg.npoi.HDS.objs.HDS.m.numdim.d := 'Returns the number of dimensions';
help::pkg.npoi.HDS.objs.HDS.m.numdim.s := 'numdim()';
help::pkg.npoi.HDS.objs.HDS.m.obtain := [=];
help::pkg.npoi.HDS.objs.HDS.m.obtain.d := 'Gets data from an HDS primitive';
help::pkg.npoi.HDS.objs.HDS.m.obtain.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.obtain.a.name.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.obtain.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.obtain.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.obtain.s := 'obtain(name)';
help::pkg.npoi.HDS.objs.HDS.m.path := [=];
help::pkg.npoi.HDS.objs.HDS.m.path.d := 'Returns the present HDS fully resolved path name';
help::pkg.npoi.HDS.objs.HDS.m.path.s := 'path()';
help::pkg.npoi.HDS.objs.HDS.m.prec := [=];
help::pkg.npoi.HDS.objs.HDS.m.prec.d := 'Returns the machine precision for the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.prec.s := 'prec()';
help::pkg.npoi.HDS.objs.HDS.m.prim := [=];
help::pkg.npoi.HDS.objs.HDS.m.prim.d := 'Returns the primitive flag for the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.prim.s := 'prim()';
help::pkg.npoi.HDS.objs.HDS.m.put := [=];
help::pkg.npoi.HDS.objs.HDS.m.put.d := 'Puts data into an HDS primitive object';
help::pkg.npoi.HDS.objs.HDS.m.put.s := 'put()';
help::pkg.npoi.HDS.objs.HDS.m.recover := [=];
help::pkg.npoi.HDS.objs.HDS.m.recover.d := 'Recovers errors';
help::pkg.npoi.HDS.objs.HDS.m.recover.s := 'recover()';
help::pkg.npoi.HDS.objs.HDS.m.renam := [=];
help::pkg.npoi.HDS.objs.HDS.m.renam.d := 'Renames the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.renam.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.renam.a.name.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.renam.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.renam.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.renam.s := 'renam(name)';
help::pkg.npoi.HDS.objs.HDS.m.reset := [=];
help::pkg.npoi.HDS.objs.HDS.m.reset.d := 'Uninitialize the present HDS primitive object';
help::pkg.npoi.HDS.objs.HDS.m.reset.s := 'reset()';
help::pkg.npoi.HDS.objs.HDS.m.retyp := [=];
help::pkg.npoi.HDS.objs.HDS.m.retyp.d := 'Retypes the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.retyp.a.type := [=];
help::pkg.npoi.HDS.objs.HDS.m.retyp.a.type.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.retyp.a.type.def := '';
help::pkg.npoi.HDS.objs.HDS.m.retyp.a.type.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.retyp.s := 'retyp(type)';
help::pkg.npoi.HDS.objs.HDS.m.save := [=];
help::pkg.npoi.HDS.objs.HDS.m.save.d := 'Saves the present locator';
help::pkg.npoi.HDS.objs.HDS.m.save.s := 'save()';
help::pkg.npoi.HDS.objs.HDS.m.screate := [=];
help::pkg.npoi.HDS.objs.HDS.m.screate.d := 'Puts a datum into a new scalar HDS primitive';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.screate.a.name.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.type := [=];
help::pkg.npoi.HDS.objs.HDS.m.screate.a.type.d := 'Object type';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.type.def := '\' \' ';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.type.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.datum := [=];
help::pkg.npoi.HDS.objs.HDS.m.screate.a.datum.d := 'Glish scalar variable containing the datum';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.datum.def := '';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.datum.a := 'numeric,boolean,string';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.replace := [=];
help::pkg.npoi.HDS.objs.HDS.m.screate.a.replace.d := 'Replace flag';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.replace.def := 'F';
help::pkg.npoi.HDS.objs.HDS.m.screate.a.replace.a := 'boolean';
help::pkg.npoi.HDS.objs.HDS.m.screate.s := 'screate(name, type, datum, replace)';
help::pkg.npoi.HDS.objs.HDS.m.shape := [=];
help::pkg.npoi.HDS.objs.HDS.m.shape.d := 'Returns the shape of the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.shape.s := 'shape()';
help::pkg.npoi.HDS.objs.HDS.m.size := [=];
help::pkg.npoi.HDS.objs.HDS.m.size.d := 'Returns the size of the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.size.s := 'size()';
help::pkg.npoi.HDS.objs.HDS.m.slice := [=];
help::pkg.npoi.HDS.objs.HDS.m.slice.d := 'Goes to a slice of a multidimensional HDS object';
help::pkg.npoi.HDS.objs.HDS.m.slice.a.dims1 := [=];
help::pkg.npoi.HDS.objs.HDS.m.slice.a.dims1.d := 'Low dimension limits of the HDS object';
help::pkg.npoi.HDS.objs.HDS.m.slice.a.dims1.def := '';
help::pkg.npoi.HDS.objs.HDS.m.slice.a.dims1.a := '1-dimensional integer';
help::pkg.npoi.HDS.objs.HDS.m.slice.a.dims2 := [=];
help::pkg.npoi.HDS.objs.HDS.m.slice.a.dims2.d := 'High dimension limits of the HDS object';
help::pkg.npoi.HDS.objs.HDS.m.slice.a.dims2.def := '';
help::pkg.npoi.HDS.objs.HDS.m.slice.a.dims2.a := '1-dimensional integer';
help::pkg.npoi.HDS.objs.HDS.m.slice.s := 'slice(dims1, dims2)';
help::pkg.npoi.HDS.objs.HDS.m.state := [=];
help::pkg.npoi.HDS.objs.HDS.m.state.d := 'Return the state of the present HDS primitive object';
help::pkg.npoi.HDS.objs.HDS.m.state.s := 'state()';
help::pkg.npoi.HDS.objs.HDS.m.struc := [=];
help::pkg.npoi.HDS.objs.HDS.m.struc.d := 'Returns the structure flag for the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.struc.s := 'struc()';
help::pkg.npoi.HDS.objs.HDS.m.there := [=];
help::pkg.npoi.HDS.objs.HDS.m.there.d := 'Checks for the existence of an HDS object';
help::pkg.npoi.HDS.objs.HDS.m.there.a.name := [=];
help::pkg.npoi.HDS.objs.HDS.m.there.a.name.d := 'Object name';
help::pkg.npoi.HDS.objs.HDS.m.there.a.name.def := '';
help::pkg.npoi.HDS.objs.HDS.m.there.a.name.a := 'string';
help::pkg.npoi.HDS.objs.HDS.m.there.s := 'there(name)';
help::pkg.npoi.HDS.objs.HDS.m.top := [=];
help::pkg.npoi.HDS.objs.HDS.m.top.d := 'Returns HDS tool to the top HDS object';
help::pkg.npoi.HDS.objs.HDS.m.top.s := 'top()';
help::pkg.npoi.HDS.objs.HDS.m.type := [=];
help::pkg.npoi.HDS.objs.HDS.m.type.d := 'Returns the type of the present HDS object';
help::pkg.npoi.HDS.objs.HDS.m.type.s := 'type()';
help::pkg.npoi.HDS.objs.HDS.m.valid := [=];
help::pkg.npoi.HDS.objs.HDS.m.valid.d := 'Return the locator validity flag';
help::pkg.npoi.HDS.objs.HDS.m.valid.s := 'valid()';
help::pkg.npoi.HDS.objs.HDS.m.version := [=];
help::pkg.npoi.HDS.objs.HDS.m.version.d := 'Return HDS tool version';
help::pkg.npoi.HDS.objs.HDS.m.version.s := 'version()';
help::pkg.npoi.HDS.objs.HDS.m.web := [=];
help::pkg.npoi.HDS.objs.HDS.m.web.d := 'View the ``Aips++ Reference Manual  ';
help::pkg.npoi.HDS.objs.HDS.m.web.s := 'web()';
help::pkg.npoi.HDS.objs.HDS.m.dimmax := [=];
help::pkg.npoi.HDS.objs.HDS.m.dimmax.d := 'Returns the maximum number of dimensions';
help::pkg.npoi.HDS.objs.HDS.m.dimmax.s := 'dimmax()';
help::pkg.npoi.HDS.objs.HDS.m.locatormax := [=];
help::pkg.npoi.HDS.objs.HDS.m.locatormax.d := 'Returns the maximum number of locators';
help::pkg.npoi.HDS.objs.HDS.m.locatormax.s := 'locatormax()';
help::pkg.npoi.HDS.objs.HDS.m.nolocator := [=];
help::pkg.npoi.HDS.objs.HDS.m.nolocator.d := 'Returns the ``no-locator   string';
help::pkg.npoi.HDS.objs.HDS.m.nolocator.s := 'nolocator()';
help::pkg.npoi.HDS.objs.HDS.m.sizelocator := [=];
help::pkg.npoi.HDS.objs.HDS.m.sizelocator.d := 'Returns the locator size';
help::pkg.npoi.HDS.objs.HDS.m.sizelocator.s := 'sizelocator()';
help::pkg.npoi.HDS.objs.HDS.m.sizemode := [=];
help::pkg.npoi.HDS.objs.HDS.m.sizemode.d := 'Returns the mode size';
help::pkg.npoi.HDS.objs.HDS.m.sizemode.s := 'sizemode()';
help::pkg.npoi.HDS.objs.HDS.m.sizename := [=];
help::pkg.npoi.HDS.objs.HDS.m.sizename.d := 'Returns the name size';
help::pkg.npoi.HDS.objs.HDS.m.sizename.s := 'sizename()';
help::pkg.npoi.HDS.objs.HDS.m.sizetype := [=];
help::pkg.npoi.HDS.objs.HDS.m.sizetype.d := 'Returns the type size';
help::pkg.npoi.HDS.objs.HDS.m.sizetype.s := 'sizetype()';

