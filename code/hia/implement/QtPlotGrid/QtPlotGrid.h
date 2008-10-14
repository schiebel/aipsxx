//# QtPlotGrid.h: class for setting up a grid of QWT Plotters
//# Copyright (C) 1994,1995,1997,1998,1999,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#

#ifndef AIPS_QTGRIDDER_H
#define AIPS_QTGRIDDER_H          

#include <qapplication.h>
#include <qlabel.h>
#include <qcolor.h>
#include <qpushbutton.h>
#include <qlayout.h>
#include <qlineedit.h>
#include <qmultilinedit.h>
#include <qmenubar.h>
#include <qpopupmenu.h>
#include <hia/QtPlotter/QtPlotter.h>

#include <casa/namespace.h>
class MyGridPlot : public QWidget
{
public:
    MyGridPlot( int num_plots, int plot_size, QWidget *parent = 0, const char *name = 0 );
    ~MyGridPlot();
    void MyGridPlotUpdate(int, double, QString);
    void MyGridPlotUpdate(int, Vector<Double>, QString);
    void MyGridPlotTitle(int, QString);
    void MyGridYAxisTitle(int, QString);
    void MyGridXAxisTitle(int, QString);
    void MyGridPlotNumPoints(int, int);

private:
    DataPlotter *w[4];                          
};

#endif // define AIPS_QTGRIDDER_H
