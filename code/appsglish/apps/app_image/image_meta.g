# image_meta.g: Standard meta information for image.g
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
#   $Id: image_meta.g,v 19.21 2005/09/15 02:34:47 nkilleen Exp $

pragma include once

include 'types.g';
include 'quanta.g';


dq.define('pix', "100%");



types.class('image').includefile('image.g');

# Constructors

types.method('ctor_image').
    image('infile', allowunset=F);

types.method('ctor_imagecalc').
    string('pixels', allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F);

types.method('ctor_imageconcat').
    string('infiles', [''], allowunset=F).
    integer('axis', default=unset, allowunset=T).
    boolean('relax', F, allowunset=F).
    boolean('tempclose', T, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F);

types.method('ctor_imagefromarray').
    vector_float('pixels', allowunset=F).
    coordinates('csys', allowunset=T, default=unset, dir='in',
                help='Coordinate System (a Coordsys tool)').
    boolean('linear', F, allowunset=F).
    boolean('log', T, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F);

types.method('ctor_imagefromascii').
    file('infile', allowunset=F).
    vector_integer('shape', allowunset=F).
    string('sep', allowunset=F, default=' ').
    coordinates('csys', allowunset=T, default=unset, dir='in',
                help='Coordinate System (a Coordsys tool)').
    boolean('linear', F, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F);

types.method('ctor_imagefromfits').
    file('infile', allowunset=F).
    integer('whichhdu', 1, allowunset=F).
    boolean('zeroblanks', F, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F);

types.method('ctor_imagefromforeign').
    file('infile', allowunset=F).
    choice('format', options=['miriad', 'gipsy'], default='miriad',
           allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F);

types.method('ctor_imagefromimage').
    image('infile', allowunset=F).
    region('region', dir='in', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', dir='in', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    boolean('dropdeg', F, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F);

types.method('ctor_imagefromshape').
    vector_integer('shape', allowunset=F).
    coordinates('csys', allowunset=T, default=unset, 
                help='Coordinate System (a Coordsys tool)').
    boolean('linear', F, allowunset=F).
    boolean('log', T, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F);

types.method('ctor_imagemaketestimage').
    file('outfile', 'testimage.im', allowunset=T);


# Tool functions

#
# Group 'Analysis'
#
types.group('Analysis').method('image.addnoise').
    choice('type', 
           options="normal poisson uniform binomial discreteuniform erlang geometric hypergeometric lognormal negativeexponential weibull",
           default='normal',
           allowunset=F).
    vector_double('pars', default=[0,1], allowunset=F).
    region('region', dir='in', default=unset, allowunset=T).
    boolean('zero', default=F);

types.method('image.deconvolvecomponentlist').
    tool('complist', default=unset, allowunset=T, checkeval=T,
         help='Componentlist to deconvolve (a Componentlist tool)').
    tool('return', 'mycomplist', dir='inout',
         help='The deconvolved Componentlist (a Componentlist tool)');

types.method('image.fft').
    region('region', dir='in', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', dir='in', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    vector_integer('axes', default=unset, allowunset=T,
                   help='The axes (1-rel) to FFT; e.g. [1,3]').
    string('real', allowunset=T, default=unset).
    string('imag', allowunset=T, default=unset).
    string('amp', allowunset=T, default=unset).
    string('phase', allowunset=T, default=unset);

types.method('image.findsources').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', dir='in', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    integer('nmax', 20, allowunset=F).
    float('cutoff', 0.1, allowunset=F).
    boolean('point', T, allowunset=F).
    integer('width', 5, allowunset=F).
    boolean('negfind', F, allowunset=F).
    tool('return', 'mycomplist', dir='inout',
         help='The Componentlist (a Componentlist tool)');

types.method('image.fitsky').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    string('models', default='gaussian', allowunset=F,
           help=spaste('Simultaneous model types to fit (only gaussian presently)\n',
           'e.g. to fit 2 simultaneous models enter gaussian gaussian')).
    tool('estimate', allowunset=T, default=unset, checkeval=T,
         help='The initial estimate for the models (a Componentlist tool)').
    string('fixed', allowunset=T, default=unset,
           help='Parameters to hold fixed per model; choose from \'fxyabp\', e.g. for 2 models xy fp').
    vector_float('includepix', allowunset=T, default=unset,
                 help='Range of pixel values to include; e.g. [0.2, 100.0]').
    vector_float('excludepix', allowunset=T, default=unset,
                 help='Range of pixel values to exclude; e.g. [-0.2,0.2]').
    boolean('fit', default=T, allowunset=F).
    boolean('deconvolve', default=F, allowunset=F).
    boolean('list', default=T, allowunset=F).
    boolean('converged', dir='out').
    vector_float('pixels', dir='out').
    vector_boolean('pixelmask', dir='out').
    tool('return', 'mycomplist', dir='inout',
         help='The fitted models (a Componentlist tool)');

types.method('image.continuumsub').
    file('outline', default=unset, allowunset=T).
    file('outcont', default='continuumsub.im', allowunset=F).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    vector_integer('channels',default=unset,allowunset=T).
    string('pol',default=unset,allowunset=T).
    integer('fitorder',default=0,allowunset=F).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'myconsub', dir='inout',
         help='The continuum-subtracted image (an Image tool)');

types.method('image.fitpolynomial').
    integer('axis', default=unset, allowunset=T).
    integer('order', default=0, allowunset=F).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    file('sigmafile', allowunset=T, default=unset).
    file('residfile', allowunset=T, default=unset).
    file('fitfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'mycomplist', dir='inout',
         help='The residual image (an Image tool)');

types.method('image.histograms').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    vector_integer('axes', default=unset, allowunset=T,
                   help='Axes to compute histograms over; e.g. [1,3]').
    integer('nbins', 25, allowunset=F).
    vector_float('includepix', default=unset, allowunset=T,
                 help='Range of pixel values to include; e.g. [0.2,100.0]').
    boolean('gauss', F, allowunset=F).
    boolean('cumu', F, allowunset=F).
    boolean('log', T, allowunset=F).
    boolean('list', T, allowunset=F).
    string('plotter', default=unset, allowunset=T,
           help='PGPlot plotter; e.g. 1/glish').
    integer("nx ny", 1, allowunset=F).
    vector_integer('size', default=[600,450], allowunset=F).
    boolean('force', F, allowunset=F).
    boolean('disk',F, allowunset=F).
#    boolean('async',F).
    record('histout', [=], dir='out');

types.method('image.insert').
    file('infile', allowunset=T, default=unset).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    vector_double('locate', default=unset, allowunset=T);

types.method('image.maxfit').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    boolean('point', T, allowunset=F).
    integer('width', 5, allowunset=F).
    boolean('negfind', F, allowunset=F).
    boolean('list', T, allowunset=F).
    tool('return', 'mycomplist', dir='inout',
         help='The ComponentList (a Componentlist tool)');

types.method('image.modify').
    tool('model', allowunset=T, default=unset,
         help='The model (a Componentlist tool)').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    boolean('subtract', T, dir='in').
    boolean('list', T, dir='in');
#    boolean('async', F);

types.method('image.moments', gui='momentsgui').
    vector_integer('moments', 0, allowunset=F).
    integer('axis', unset, allowunset=T).
    boolean('drop', T, allowunset=F).
    region('region', dir='in', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', dir='in', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    check('method', options=['window', 'fit', 'interactive'], allowunset=F).
    vector_integer('smoothaxes', default=unset, allowunset=T).
    string('smoothtypes', default=unset, allowunset=T).
    vector_float('smoothwidths', default=unset, allowunset=T).
    file('smoothout', allowunset=T, default=unset).
    vector_float('includepix', allowunset=T, default=unset,
                 help='Range of pixel values to include; e.g. [0.2, 100.0]').
    vector_float('excludepix', allowunset=T, default=unset,
                 help='Range of pixel values to exclude; e.g. [-0.2,0.2]').
    float('peaksnr', 3.0, allowunset=F).
    float('stddev', 0.0, allowunset=F).
    measurecodes('doppler', default='radio', options='doppler', allowunset=F).
    string('plotter', default=unset, allowunset=T, help='PGPlot plotter; e.g. 1/glish').
    integer("nx ny", 1, allowunset=F).
    boolean('yind', F, allowunset=F).
    boolean('async',F).
    file('outfile',allowunset=T,default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'mymomim', dir='inout', help='An Image tool');

types.method('image.rebin').
    vector_integer('bin', allowunset=F).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    boolean('dropdeg', default=F, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'myrebinim', dir='inout', help='An Image tool');

types.method('image.regrid').
    vector_integer('shape', allowunset=T, default=unset).
    coordinates('csys', allowunset=T, default=unset,
                help='Coordinate System (a Coordsys tool)').
    vector_integer('axes', allowunset=T, default=unset).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    choice('method', options=['nearest', 'linear', 'cubic'], default='linear', allowunset=F).
    boolean('replicate', default=F, allowunset=F).
    integer('decimate', default=10, allowunset=F).
    boolean('doref', default=T, allowunset=F).
    boolean('dropdeg', default=F, allowunset=F).
#    boolean('async', default=F, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    boolean('force', F, allowunset=F).
    tool('return', 'myregridim', dir='inout', help='An Image tool');

types.method('image.rotate').
    vector_integer('shape', allowunset=T, default=unset).
    quantity('pa', allowunset=F, default='0.0deg', options='angle',
             help='Angle through which to rotate Coordinate System').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    choice('method', options=['nearest', 'linear', 'cubic'], default='cubic', allowunset=F).
    boolean('replicate', default=F, allowunset=F).
    integer('decimate', default=0, allowunset=F).
#    boolean('async', default=F, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'myrotateim', dir='inout', help='An Image tool');

types.method('image.statistics').
    vector_integer('axes', default=unset, allowunset=T).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    check('plotstats', ['mean', 'sigma'],
	  options=['npts', 'sum', 'sumsq', 'min', 'max', 'mean',
		   'sigma', 'rms', 'median', 'medabsdevmed', 'quartile']).
    vector_float('includepix', default=unset, allowunset=T).
    vector_float('excludepix', default=unset, allowunset=T).
    boolean('list', T, allowunset=F).
    string('plotter', default=unset, allowunset=T).
    integer("nx ny", 1, allowunset=F).
    boolean('force', F, allowunset=F).
    boolean('disk', F, allowunset=F).
    boolean('robust',F, allowunset=F).
    boolean('verbose', T, allowunset=F).
#    boolean('async', F).
    record('statsout', [=], dir='out');

types.method('image.twopointcorrelation').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    vector_integer('axes', allowunset=T, default=unset).
    choice('method', options=['structurefunction'], default='structurefunction',
           allowunset=F).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'myregridim', dir='inout', help='An Image tool');

types.method('image.subimage').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    boolean('dropdeg', F, allowunset=F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    boolean('list', T, allowunset=F).
    tool('return', 'mysubim', dir='inout', help='An Image tool');

types.method('image.decompose').
    region('region',allowunset=T, default=unset, help='Region of interest').
    string('mask', allowunset=T, default=unset,help='Boolean mask expression').
    boolean('simple', default=F, 
             help='Skip contour deblending and scan for local maxima to determine components').
    float('threshold', default=1.0, help='Value of minimum contour').
    integer('ncontour',default=11, help='Number of contours to use in deblending').
    integer('minrange',default=1, help='Number of closed contours required to define a component').
    integer('naxis',default=2, help='Max number of perpendicular axis steps between adjacent pixels').
    boolean('fit',default=T, help='Fit to the data after deblending?').
    float('maxrms',default=0.5, help='Maximum RMS permissible for the fit.  Retries if RMS is too high').
    integer('maxretry', allowunset=T, default=unset, help='Maximum number of times to retry the fit').
    integer('maxiter',default=256, help='Maximum number of iterations to allow in a single fit attempt').
    float('convcriteria',default=0.0001, help='Criterion to establish convergence');

#
# Group 'Conversion'
#
types.group('Conversion').method('image.toascii').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    string('sep', default=' ', allowunset=F).
    string('format', default='%e', allowunset=F).
    float('maskvalue', default=unset, allowunset=T).
    string('outfile', default=unset, allowunset=T);

types.method('image.tofits').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    boolean('velocity', F, allowunset=F).
    boolean('optical', T, allowunset=F).
    integer('bitpix', -32, allowunset=F).
    float('minpix', allowunset=T, default=unset).
    float('maxpix', allowunset=T, default=unset).
    string('outfile', default=unset, allowunset=T).
    boolean('overwrite', F, allowunset=F).
    boolean('dropdeg', F, allowunset=F);
# 
# Group 'Coordinates'
#
types.group('Coordinates').method('image.coordmeasures').
    vector_double('pixel', allowunset=T, default=unset,
                 help='Absolute pixel coordinate (1-rel); e.g. [10,20]').
    record('intensity', dir='out', allowunset=T).
    direction('direction', dir='out', allowunset=T).
    measure('frequency', options='frequency', dir='out', allowunset=T).
    measure('velocity', options='radialvelocity', dir='out', allowunset=T).
    record('return', help='A Glish record');

types.method('image.coordsys').
    vector_integer('axes', allowunset=T, default=unset).
    tool('return', 'mycoordsys', dir='inout', help='A Coordsys tool');

types.method('image.setcoordsys').
    coordinates('csys', allowunset=T, default=unset,
                help='Coordinate System (a Coordsys tool)');

hlp := spaste ('World coordinate formatted in many ways\n',
               'String e.g. 3h2m4.0s -23d5m20.0s 1.4e9Hz\n',
               'Numeric vector e.g. 0.001 20.1234\n',
               'Quantity vector (from toworld)\n',
               'Record of measures (from toworld(type=\'m\')');
types.method('image.topixel').
    untyped('value', default=unset, allowunset=T, help=hlp).
    vector_double('return', help='A Glish numeric array');

types.method('image.toworld').
    vector_double('value', default=unset, allowunset=T,
                  help='Absolute pixel coordinate (1-rel); e.g. [10,20]').
    check('format', 'n', options="n q m s", allowunset=F).
    untyped('return', help='A Glish numeric vector, quantity vector, record of measures or string');
#
# Group 'Display'
#
# Don't include activatebreak argument as
# user shouldn't need to set it.  DOn't 
# include parent and widgetset arguments

types.group('Display').method('image.view').
    boolean('raster', allowunset=T, default=unset).
    boolean('contour', allowunset=T, default=unset).
    boolean('vector', allowunset=T, default=unset).
    boolean('marker', allowunset=T, default=unset).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    tool('model', default=unset, allowunset=T, help='Model (a Componentlist tool)').
    vector_float('includepix', allowunset=T, default=unset,
                 help='Range of pixel values to include; e.g. [0.2, 100.0]').
    boolean('adjust', default=F, allowunset=F).
    boolean('axislabels', default=F, allowunset=F).
    vector_integer('order', default=unset, allowunset=T);
# 
# Group 'Filtering'
#
types.group('Filtering').method('image.convolve').
    vector_float('kernel', allowunset=F).
    float('scale', default=unset, allowunset=T).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
#    boolean('async',F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'myarrcon', dir='inout', help='An Image tool');

types.method('image.convolve2d').
    vector_integer('axes', default=[1,2], allowunset=F).
    choice('type', options=['gaussian'], allowunset=F).
    string('major', allowunset=F,       # Should be type free quantity
           help='Enter major axis e.g. 10pix or 10.5arcsec or 20km').
    string('minor', allowunset=F,
           help='Enter minor axis e.g. 10pix or 10.5arcsec or 20km').
    quantity('pa', allowunset=F, default='0.0deg', options='angle').
    float('scale', allowunset=T, default=unset).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
#    boolean('async', F).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'myconvolve2dim', dir='inout', help='An Image tool');

types.method('image.hanning').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    integer('axis', unset, allowunset=T).
    boolean('drop', T, allowunset=F).
#    boolean('async',F).
    string('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'myhannim', dir='inout', help='An Image tool');

types.method('image.sepconvolve', gui='sepconvolvegui').
    vector_integer('axes', allowunset=T, default=unset).
    string('types', default=unset, allowunset=T,
           help='Type of kernel (currently only gaussian), one for each axis; e.g. gaussian gaussian').
    string('widths', allowunset=F,
           help='Kernel widths; e.g. 20arcsec 10km').
    float('scale', allowunset=T, default=unset).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    boolean('async', F).
    string('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'mysepconvolveim', dir='inout', help='An Image tool');
#
# Group 'Inquiry'
#
types.group('Inquiry').method('image.boundingbox').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    record('return', help='A Glish record');

types.method('image.brightnessunit').
    string('return', help='A Glish string');

types.method('image.haslock').
    vector_boolean('return', help='A Glish vector');

types.method('image.history').
    boolean('list', allowunset=F, default=F).
    boolean('browse', allowunset=F, default=T).
    vector_string('return');

types.method('image.ispersistent').
    boolean('return', help='A Glish boolean');

types.method('image.isopen').
    boolean('return', help='A Glish boolean');

types.method('image.name').
    boolean('strippath', F, allowunset=F).
    string('return', dir='out', help='A Glish string');

types.method('image.restoringbeam').
    record('return', help='A Glish record');

types.method('image.shape').
    vector_integer('return', help='A Glish vector');

types.method('image.summary').
    measurecodes('doppler', default='radio', options='doppler', allowunset=F).
#    boolean('list', T, allowunset=F).
    boolean('pixelorder',T, allowunset=F).
    record('header', dir='out');
#
# Group 'Masks'
#
types.group('Masks').method('image.calcmask').
    string('mask', allowunset=F,
            help='Mask expression; e.g. $myim>0').
    string('name', default=unset, allowunset=T).
    boolean('default',T, allowunset=F);

types.method('image.maskhandler', gui='maskhandlergui').
    choice('op', options=['set', 'default', 'delete', 'rename', 'get', 'copy']).
    string('name', dir='inout').
    untyped('return', dir='out', help='A Glish string or boolean');

types.method('image.replacemaskedpixels').
    string('pixels', allowunset=F).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    boolean('update', F, allowunset=F).
    boolean('list', F, allowunset=F);
#
# Group 'Pixel Access'
#
types.group('Pixel Access').method('image.calc').
    string('pixels', allowunset=F);
#    boolean('async',F);

types.method('image.getchunk').
    vector_integer("blc trc inc axes", default=unset, allowunset=T).
    boolean('list', F, allowunset=F).
    boolean('dropdeg', F, allowunset=F).
    boolean('getmask', F, allowunset=F).
    vector_float('return', help='A Glish array');

types.method('image.getregion').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    vector_integer('axes', default=unset, allowunset=T).
    string('mask', default=unset, allowunset=T,
            help='On-the-fly mask boolean expression; e.g. $myim>0').
    boolean('list',F, allowunset=F).
    boolean('dropdeg', F, allowunset=F).
    vector_float('pixels', dir='out').
    vector_boolean('pixelmask', dir='out');

types.method('image.getslice').
    vector_float("x y", allowunset=F).
    vector_integer("coord axes", default=unset, allowunset=T).
    integer('npts', default=unset, allowunset=T).
    choice('method', options=['nearest', 'linear', 'cubic'], default='linear', allowunset=F).
    boolean('plot', F, allowunset=F).
    vector_float('return', help='A Glish array');

types.method('image.pixelvalue').
    vector_integer('pixel', allowunset=T, default=unset).
    record('return', allowunset=T, help='A Glish record');

types.method('image.putchunk').
    vector_float('pixels', allowunset=F).
    vector_integer("blc inc", allowunset=T, default=unset).
    boolean('list', F, allowunset=F).
    boolean('locking', T, allowunset=F).
    boolean('replicate', F, allowunset=F);

types.method('image.putregion').
    vector_float('pixels', default=unset, allowunset=T).
    vector_boolean('pixelmask', default=unset, allowunset=T).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    boolean('list', F, allowunset=F).
    boolean('usemask', T, allowunset=F).
    boolean('locking', T, allowunset=F).
    boolean('replicate', F, allowunset=F);

hlp := spaste('The pixel value given as \n',
              'A scalar LEL expression e.g. min($myim)\n',
              'A numeric scalar e.g. 10.32');
types.method('image.set').
    string('pixels', default=unset, allowunset=T,
           help=hlp).
    boolean('pixelmask', default=unset, allowunset=T).
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    boolean('list',F, allowunset=F);
#
# Group 'Utility'
#
types.group('Utility').method('image.adddegaxes').
    boolean('direction', F).
    boolean('spectral', F).
    boolean('linear', F).
    boolean('tabular', F).
    choice('stokes', options="I Q U V XX YY XY YX RR LL RL LR", allowunset=T, default=unset).
    file('outfile', allowunset=T, default=unset).
    boolean('overwrite', F, allowunset=F).
    tool('return', 'myadddegim', dir='inout', help='An Image tool');
 
types.method('image.close');

types.method('convertflux').
    quantity('value', allowunset=F, default='1.0Jy/beam').
    quantity('major', allowunset=F, default='20arcsec', options='angle').
    quantity('minor', allowunset=F, default='10arcsec', options='angle').
    choice('type', options="Gaussian Disk", allowunset=F).
    boolean('topeak', allowunset=F, default=T);

types.method('image.open').
    image('infile', allowunset=F);

types.method('image.lock').
    boolean('write', F, allowunset=F).
    integer('nattempts', allowunset=T, default=unset);

types.method('image.makecomplex').
    region('region', default=unset, allowunset=T,
           help='Region of interest (a Region tool)').
    string('imag', allowunset=F,
           help='Imaginary disk-based image file namedd').
    file('outfile', allowunset=F).
    boolean('overwrite', default=F, allowunset=F);

types.method('image.miscinfo').
    record('return', help='A Glish record');

types.method('image.rename').
    table('name', allowunset=F).
    boolean('overwrite', F);

types.method('image.setbrightnessunit').
    string('unit', allowunset=F);

types.method('image.sethistory').
    string('history', allowunset=F);

types.method('image.setmiscinfo').
    record('info', allowunset=F);

types.method('image.setrestoringbeam').
    quantity('major', default=unset, allowunset=T, options='angle').
    quantity('minor', default=unset, allowunset=T, options='angle').
    quantity('pa', default=unset, options='angle',  allowunset=T).
    record('beam', allowunset=T, default=unset).
    boolean('delete', F).
    boolean('log', T);

types.method('image.unlock');

# Global functions

types.method('global_is_image').
   untyped('thing', allowunset=F).
   boolean('return', help='A Glish boolean');

types.method('global_imagetools').
   boolean('showname', F).
   boolean('showclosed', T).
   vector_string('return', help='A Glish vector of strings');

types.method('global_imagedones').
    string('which', default=unset, allowunset=T);

types.method('global_imagefiles').
   string('files', default='.', allowunset=F).
   boolean('strippath', T, allowunset=F).
   boolean('foreign', F, allowunset=F).
   vector_string('return', help='A Glish vector of strings');

types.method('global_imagedemo');

types.method('global_imagetest').
   vector_integer('which', default=unset, allowunset=T);
