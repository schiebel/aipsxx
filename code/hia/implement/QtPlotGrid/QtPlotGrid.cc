//# QtPlotGrid.cc: implementation of QtPlotGrid class
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

#include <hia/QtPlotGrid/QtPlotGrid.h>

MyGridPlot::MyGridPlot( int num_plots, int plot_size, QWidget *parent, const char *name )
    : QWidget( parent, name )
{

// check needed that number of plots <= 4
   int nrows = 2;
   int ncols = 2;
   int j,k;
   int count = 0;
   QGridLayout* grid = new QGridLayout(this,nrows,ncols,10);
   for (int i =0; i < num_plots; i++) {
   	w[count] = new DataPlotter(plot_size,this);
	if (i <= 1) {
		j = i;
		k = 0;
 	}
	else {
		j = i - 2;
		k = 1;
	}
       	grid->addWidget(w[count],k,j);	
	count++;
   }
   grid->activate();
}

void MyGridPlot::MyGridPlotTitle(int sub_grid, QString s)
{
        (*w[sub_grid]).updateTitle(s);
}

void MyGridPlot::MyGridXAxisTitle(int sub_grid, QString s)
{
        (*w[sub_grid]).updateXAxisTitle(s);
}

void MyGridPlot::MyGridYAxisTitle(int sub_grid, QString s)
{
        (*w[sub_grid]).updateYAxisTitle(s);
}

void MyGridPlot::MyGridPlotUpdate(int sub_grid,double disp_val, QString q_pos_str)
{
        (*w[sub_grid]).updateEvent(disp_val, q_pos_str);
}

void MyGridPlot::MyGridPlotUpdate(int sub_grid,Vector<Double> spectrum, QString q_pos_str)
{
        (*w[sub_grid]).updateEvent(spectrum, q_pos_str);
}

void MyGridPlot::MyGridPlotNumPoints(int sub_grid, int num_points)
{
        (*w[sub_grid]).updateNumPoints(num_points);
}


MyGridPlot::~MyGridPlot()
{
    // All child widgets are deleted by Qt.
    // The top-level layout and all its sub-layouts are deleted by Qt.
}

