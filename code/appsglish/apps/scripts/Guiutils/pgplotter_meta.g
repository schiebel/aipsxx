# pgplotter_meta.g: meta information for pgplotter tool
# Copyright (C) 1999,2000,2001
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
# $Id: pgplotter_meta.g,v 19.2 2004/08/25 02:00:34 cvsmgr Exp $

pragma include once;

include 'types.g';

types.class('pgplotter').includefile('pgplotter.g');

types.method('ctor_pgplotter').
    table('plotfile', unset, allowunset=T, options='Plot file').
    vector_integer('size', '[600,450]').
    string('foreground', 'black').
    string('background', 'lightgrey');

#### gplot1d-like methods
types.group('gplot1d').
    method('ploty', 'Plot Y vectors with auto-scaling').
    vector_float("y").
    string("xlab ylab tlab", '');

types.method('plotxy1', 'Plot X and Y vectors with auto-scaling').
    vector_float("x y").
    string("xlab ylab tlab", '');

types.method('ploty2', 'Plot Y vectors against the right Y axis with auto-scaling').
    vector_float("y").
    string("xlab ylab tlab", '');

types.method('plotxy2', 'Plot X and Y vectors against the right and upper axes with autoscaling').
    vector_float("x y").
    string("xlab ylab tlab", '');

types.method('timey', 'Plot X and Y vectors with autoscaling and X axis values as times').
    vector_float("x y").
    string("xlab ylab tlab", '');

types.method('timey2', 'Plot X and Y vectors with autoscaling and X axis values as times against the right and upper axes.').
    vector_float("x y").
    string("xlab ylab tlab", '');

types.method('setxscale', 'Set the viewable X range of an already existing plot').
    float("xmin xmax");

types.method('setyscale', 'Set the viewable Y range of an already existing plot').
    float("ymin ymax");

types.method('sety2scale', 'Set the viewable Y range of the right Y axis an already existing plot using that axis.').
    float("ymin ymax");

types.method('setxaxisgrid', 'Turn on or off display of X-axis grid lines').
    boolean("on", T);

types.method('setyaxisgrid', 'Turn on or off display of Y-axis grid lines').
    boolean("on", T);

types.method('title', 'Set the pgplotter window title').
    string("msg", '');

types.method('sety2axisgrid', 'Turn on or off display of right Y-axis grid lines').
    boolean("on", T);

types.method('setplottitle',' Set a plot title').
    string("title",'');

types.method('setxaxislabel','Set the x-axis label').
    string("xlabel",'');

types.method('setyaxislabel','Set the y-axis label').
    string("ylabel",'');
# More
#### Non-standard methods
types.group('aips++').
    method('plotxy', 'Plot X,Y vectors as lines or points with auto-scaling').
    vector_float("x y").
    boolean("plotlines", T).
    boolean("newplot", T).
    string("xtitle ytitle title", '');
types.method('settings', 'Set many setting values at once').
    boolean('ask', F).
    integer("nxsub nysub", 1).
    integer('arrowfs', 1).float('arrowangle', 45).float('arrowvent', 0.3).
    integer('font', 1).
    float('ch', 1).
    integer('ci', 1).
    integer('fs', 1).
    float('hsangle', 45).float('hssepn', 1).float('hsphase', 0).
    integer('ls', 1).
    integer('lw', 1).
    integer('tbci', -1);
types.method('postscript', 'save as a postscript file', 
	     'Postscript', category='AIPS++').
    file('file', unset, options='Postscript', allowunset=T).
    boolean('color', T).
    boolean('landscape', T);
types.method('plotfile', 'save plot commands to file', 'Plotfile').
    file('file', unset, options='Postscript', allowunset=T);
types.method('restore', 
     'retrieve commands from file (deletes current plot list)', 'Restore').
    file('file', unset, allowunset=T, options='Plot file');
types.method('refresh', 'redraw screen', 'Refresh');
types.method('resetplotnumber', 'reset internal plot counter to 0');
types.method('clear', 'Clear: erase everything', 'Clear');
types.method('message', 'write informative message', 'Message').
    string('text');
    

#### Standard PGPLOT methods
types.group('standard').
    method('arro', 'draw an arrow', category='pgplot.draw').
    float('x1').float('y1').float('x2').float('y2');
types.method('ask', 'control new page prompting', category='pgplot.settings').
    boolean('flag', F);
types.method('bbuf', 'begin batch of output (buffer)', category='pgplot.misc');
types.method('bin', 'histogram of binned data',category='pgplot.draw').
    vector_float('x').vector_float('data').vector_float('center');
types.method('box', 'draw labeled frame around viewport',
	     category='pgplot.label').
    vector_float('x').vector_float('data').boolean('center');
types.method('circ', 'draw a filled or outline circle', 
	     category='pgplot.draw').
    float('xcent').float('ycent').float('radius');
types.method('conb', 'contour map of a 2D array, with blanking',
	     category='pgplot.raster').
    vector_float("a c blank").
    vector_float("tr", [1,0,0,1,0,0]);
types.method('conl', 'label a contour map of a 2D array').
    vector_float("a c").vector_float("tr", [1,0,0,1,0,0]).
    string('label').integer("intval minint");
types.method('cons', 'contour map of a 2D data array (fast algorithm').
    vector_float("a c").vector_float("tr", [1,0,0,1,0,0]);
types.method('cont', 'contour map of a 2D data array (contour following)').
    vector_float("a c").vector_float("tr", [1,0,0,1,0,0]).
    boolean("nc");
types.method('ctab', 'install the color table to be used by IMAG').
    vector_float("l r g b contra bright");
types.method('curs', 'read the cursor position', category='pgplot.cursor').
    record("return", dir='out');
types.method('draw', 'draw a line from the current pen position to a point',
	     category='pgplot.draw').
    float("x y");
types.method('ebuf', 'end batch of output (buffer)', category='pgplot.misc');
types.method('env', 'set window and viewport and draw labeled frame',
	     category='pgplot.label').
    float('xmin', 0).float('xmax', 1).float('ymin', 0).
    float('ymax', 1).float('just',0).float('axis',0)
types.method('eras', 'erase all graphics from the current page',
	     category='pgplot.misc');
types.method('errb', 'horizontal or vertical error bar',
	     category='pgplot.draw').
    integer('dir').float("x y e t");
types.method('errx', 'horizontal error bar').
    float("x1 x2 y t");
types.method('erry', 'vertical error bar').
    float("x y1 y2 t");
types.method('gray', 'gray-scale map of a 2D data array',
	     category='pgplot.raster').
    vector_float("a fg bg").vector_float("tr", [1,0,0,1,0,0]);
types.method('hi2d', 'cross-sections through a 2D data array',
	     category='pgplot.raster').
    vector_float("data x").integer("ioff").float("bias").boolean("center").
    vector_float("ylims");
types.method('hist', 'histogram of unbinned data',category='pgplot.draw').
    vector_float("data datmin datmax").integer("nbin pcflag");
types.method('iden', 'write username, data, and time at bottom of plot',
	     category='pgplot.misc');
types.method('imag', 'color image from a 2D data array',
	     category='pgplot.raster').
    vector_float("a a1 a2").vector_float("tr", [1,0,0,1,0,0]);
types.method('lab', 'write labels for x-axis, y-axis, and top of plot',
	     category='pgplot.label').
    string("xlbl ylbl toplbl");
types.method('ldev', 'list available device types',category='pgplot.misc');
types.method('len', 'find length of a string in a variety of units',
	     category='pgplot.inquiry').
    float('return').integer('units').string('string');
types.method('line', 'draw a polyline (curve defined by line-segments)',
	     category='pgplot.draw').
    vector_float("xpts ypts");
types.method('move', 'move pen (change current pen position)').float("x y");
types.method('mtxt', 'write text at position relative to viewport',
	     	     category='pgplot.label').
    string('side').float("disp coord fjust").string('text');
types.method('numb', 'convert a number into a plottable character string',
	     category='pgplot.misc').
    string('return').integer("mm pp form");
types.method('page', 'advance to a new page');
types.method('panl', 'switch to a different panel on the view surface').
    integer("ix iy");
types.method('pap', 'change the size of the view surface').
    float("width aspect");
types.method('pixl', 'draw pixels', category='pgplot.raster').
    integer('ia').vector_float("x1 x2 y1 y2");
types.method('pnts', 'draw one or more graph markers, not all the same',
    category='pgplot.draw').
    vector_float("x y").integer('symbol');
types.method('poly', 'fill a polygonal area with shading').
    vector_float("xpts ypts");
types.method('pt', 'draw one or more graph markers').
    vector_float("xpts ypts").integer('symbol');
types.method('ptxt', 'write text at arbitrary position and angle',
    category='pgplot.label').
    float("x y angle fjust").string("text");
types.method('qah', 'inquire arrow-head style', category='pgplot.inquiry').
    float('return');
types.method('qcf', 'inquire character font').
    integer('return');
types.method('qch', 'inquire character height').
    float('return');
types.method('qci', 'inquire color index').
    integer('return');
types.method('qcir', 'inquire color index range').
    integer('return');
types.method('qcol', 'inquire color capability').
    integer('return');
types.method('qcr', 'inquire color representation').
    float('return').integer('ci');
types.method('qcs', 'inquire character height in a variety of units').
    integer("return units");;
types.method('qfs', 'inquire fill style').
    integer('return');
types.method('qhs', 'inquire hatching style').
    float('return');
types.method('qid', 'inquire current device identifier').
    integer('return');
types.method('qinf', 'inquire PGPLOT general information').
    string("return item");
types.method('qitf', 'inquire image transfer function').
    integer('return');
types.method('qls', 'inquire current line style').
    integer('return');
types.method('qlw', 'inquire current line width').
    integer('return');
types.method('qpos', 'inquire current pen position').
    float('return');
types.method('qtbg', 'inquire text background color index').
    float('return');
types.method('qtxt', 'find bounding box of text string').
    float('return').float("x y angle fjust").string('text');
types.method('qvp', 'inquire viewport size and position').
    float('return').integer('units');
types.method('qvsz', 'find the window defined by the full view surface').
    float('return').integer('units');
types.method('qwin', 'inquire window boundary coordinates').
    float('return');
types.method('rect', 'draw a rectangle, using fill-area attributes',
	     category='pgplot.draw').
    float("x1 x2 y1 y2");
types.method('rnd', 'find the smallest \'round\' number greater than x',
	     category='pgplot.inquiry').
    float('return').float('x').integer('nsub');
types.method('rnge', 'choose axis limits').
    float('return').float("x1 x2");
types.method('sah', 'set arrow-head style', category='pgplot.settings').
    integer('fs').float("angle vent");
types.method('save', 'save PGPLOT attributes');
types.method('unsa', 'restore PGPLOT attributes');
types.method('scf', 'set character font').
    integer('font');
types.method('sch', 'set character height').
    float('size');
types.method('sci', 'set color index').
    integer('ci');
types.method('scir', 'set color index range').
    integer("icilo icihi");
types.method('scr', 'set color representation').
    integer('ci').float("cr cg cb");
types.method('scrn', 'set color representation by name').
    integer('ci').string('name');
types.method('sfs', 'set fill style').
    integer('fs');
types.method('shls', 'set color representation using HSL system').
    integer('ci').float("ch cl cs");
types.method('shs', 'set hatching style').
    float("angle sepn phase");
types.method('sitf', 'set image transfer function').
    integer('itf');
types.method('sls', 'set line style').
    integer('ls');
types.method('slw', 'set line width').
    integer('lw');
types.method('stbg', 'set background color index').
    integer('tbci');
types.method('subp', 'subdivide view surface into panels',
    category='pgplot.settings').
    integer("nxsub nysub");
types.method('svp', 'set viewport (normalized device coordinate)',
    category='pgplot.settings').
    float("xleft xright ybot ytop");
types.method('swin', 'set window').
    float("x1 x2 y1 y2");
types.method('tbox', 'draw frame and write (DD) HH MM SS.S labelling',
	     category='pgplot.label').
    string('xopt').float('xtick').integer('nxsub').
    string('yopt').float('ytick').integer('nysub');
types.method('text', 'write text (horizontal, left-justified)').
    float("x y").string('text');
types.method('updt', 'update display',category='pgplot.misc');
types.method('vect', 'vector map of a 2D array, with blanking',
    category='pgplot.raster').
    vector_float("a b c").integer("nc").vector_float("tr blank");
types.method('vsiz', 'set viewport (inches)', category='pgplot.settings').
    float("xleft xright ybot ytop");
types.method('vstd', 'set standard (default) viewport');
types.method('wedg', 'annotate an image plot with a wedge',
	     category='pgplot.raster').
    string('side').float("disp width fg bg").string('label');
types.method('wnad', 'set window and adjust viewport to same aspect ratio').
    float("x1 x2 y1 y2");

types.method('global_pgplottertest').boolean('autodestruct', T);
