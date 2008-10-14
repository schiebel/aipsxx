# atomsvo.g: help atoms for the vo package. 
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
# $Id: atomsvo.g,v 19.948 2006/09/29 01:49:21 wyoung Exp $

pragma include once
val help::pkg.vo := [=];
help::pkg.vo::d := 'VO-related modules and tools';

help::pkg.vo.conesearch := [=];
help::pkg.vo.conesearch.objs := [=];
help::pkg.vo.conesearch.funs := [=];
help::pkg.vo.conesearch.d := 'Module for VO conesearch processing';
help::pkg.vo.conesearch.objs.conesearch := [=];
help::pkg.vo.conesearch.objs.conesearch.m := [=];
help::pkg.vo.conesearch.objs.conesearch.c := [=];
help::pkg.vo.conesearch.objs.conesearch.d := 'tool for VO conesearch queries';
help::pkg.vo.conesearch.objs.conesearch.c.conesearch := [=];
help::pkg.vo.conesearch.objs.conesearch.c.conesearch.d := 'Construct an conesearch tool';
help::pkg.vo.conesearch.objs.conesearch.c.conesearch.s := 'conesearch()';
help::pkg.vo.conesearch.objs.conesearch.m.list := [=];
help::pkg.vo.conesearch.objs.conesearch.m.list.d := 'List all registered conesearches';
help::pkg.vo.conesearch.objs.conesearch.m.list.s := 'list()';
help::pkg.vo.conesearch.objs.conesearch.m.info := [=];
help::pkg.vo.conesearch.objs.conesearch.m.info.d := 'Print information about a particular conesearch service';
help::pkg.vo.conesearch.objs.conesearch.m.info.s := 'info()';
help::pkg.vo.conesearch.objs.conesearch.m.query := [=];
help::pkg.vo.conesearch.objs.conesearch.m.query.d := 'Query a conesearch';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.i := [=];
help::pkg.vo.conesearch.objs.conesearch.m.query.a.i.d := 'Service to be queried';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.i.def := '1';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.i.a := 'Integer';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.ra := [=];
help::pkg.vo.conesearch.objs.conesearch.m.query.a.ra.d := 'Right ascension (degrees)';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.ra.def := '200.0';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.ra.a := 'Double';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.dec := [=];
help::pkg.vo.conesearch.objs.conesearch.m.query.a.dec.d := 'Declination (degrees)';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.dec.def := '45.0';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.dec.a := 'Double';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.sr := [=];
help::pkg.vo.conesearch.objs.conesearch.m.query.a.sr.d := 'Search radius (degrees)';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.sr.def := '10';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.sr.a := 'Float';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.url := [=];
help::pkg.vo.conesearch.objs.conesearch.m.query.a.url.d := 'Alternative to service: URL to query';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.url.def := 'F';
help::pkg.vo.conesearch.objs.conesearch.m.query.a.url.a := 'String';
help::pkg.vo.conesearch.objs.conesearch.m.query.s := 'query(i, ra, dec, sr, url)';
help::pkg.vo.conesearch.objs.conesearch.m.done := [=];
help::pkg.vo.conesearch.objs.conesearch.m.done.d := 'Terminate the tool';
help::pkg.vo.conesearch.objs.conesearch.m.done.s := 'done()';
help::pkg.vo.conesearch.objs.cscatalog := [=];
help::pkg.vo.conesearch.objs.cscatalog.m := [=];
help::pkg.vo.conesearch.objs.cscatalog.c := [=];
help::pkg.vo.conesearch.objs.cscatalog.d := 'tool for VO conesearch queries';
help::pkg.vo.conesearch.objs.cscatalog.c.cscatalog := [=];
help::pkg.vo.conesearch.objs.cscatalog.c.cscatalog.d := 'Construct an cscatalog tool';
help::pkg.vo.conesearch.objs.cscatalog.c.cscatalog.s := 'cscatalog()';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.d := 'Query a catalog for an image';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.im := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.im.d := 'Image tool';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.im.def := 'None';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.im.a := 'Image tool';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.catalog := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.catalog.d := 'Catalog to be queried';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.catalog.def := 'NVSS';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.catalog.a := 'NVSS|FIRST|WENSS';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.fluxrange := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.fluxrange.d := 'Flux limitation';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.fluxrange.def := 'F';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.a.fluxrange.a := 'Vector of quantities';
help::pkg.vo.conesearch.objs.cscatalog.m.queryimage.s := 'queryimage(im, catalog, fluxrange)';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.d := 'Query a catalog for a direction return a componentlist';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.direction := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.direction.d := 'Direction measure';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.direction.def := 'none';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.direction.a := 'Measure';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.sr := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.sr.d := 'Search radius';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.sr.def := '\' 1deg\' ';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.sr.a := 'Quantity';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.catalog := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.catalog.d := 'Catalog to be queried';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.catalog.def := 'NVSS';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.catalog.a := 'NVSS|FIRST|WENSS';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.fluxrange := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.fluxrange.d := 'Flux limitation';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.fluxrange.def := 'F';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.a.fluxrange.a := 'Vector of quantities';
help::pkg.vo.conesearch.objs.cscatalog.m.querydirection.s := 'querydirection(direction, sr, catalog, fluxrange)';
help::pkg.vo.conesearch.objs.cscatalog.m.done := [=];
help::pkg.vo.conesearch.objs.cscatalog.m.done.d := 'Delete the tool';
help::pkg.vo.conesearch.objs.cscatalog.m.done.s := 'done()';

