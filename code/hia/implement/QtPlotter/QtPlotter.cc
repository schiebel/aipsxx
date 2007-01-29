//# QtPlotter.cc: implementation of QWT Plot widget with zoom etc
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

//-----------------------------------------------------------------
//
//	adapted from the 'bode' demo program distributed with QWT
//
//-----------------------------------------------------------------

#include <qapp.h>
#include <math.h>
#include <hia/QtPlotter/QtPlotter.h>
#include <qlabel.h>
#include <qwt_counter.h>
#include <qwt_plot.h>
#include <qwt_math.h>
#include <qprinter.h>
#include <qpdevmet.h>


const int ArraySize = 200;
QString zoomInfo("Zoom: Press mouse button and drag");
QString cursorInfo("Cursor Pos: Press mouse button in plot region");


InputFrame::InputFrame(QWidget *p, const char* name)
: QFrame(p, name)
{
    lblInfo = new QLabel(cursorInfo, this);
    btnZoom = new QPushButton("Zoom", this);
    btnPrint = new QPushButton("Print", this);
    btnPause = new QPushButton("Pause", this);
    btnZoom->setGeometry(10,20,80,20);
    btnPrint->setGeometry(90,20,80,20);
    btnPause->setGeometry(170, 20, 80, 20);

    lblInfo->setFont(QFont("Helvetica", 8));
    lblInfo->setGeometry(20, 5, 230, 10);

    corNum = new QLCDNumber(this, "lcd");
    corNum->setGeometry(255,10,50,30);
    corNum->setMinimumSize(0,0);
    corNum->setFont(QFont("helvetica", 25, 75, true));
    corNum->display(5);
    corNum->setNumDigits(3);

}

InputFrame::~InputFrame()
{
    delete lblInfo;
    delete btnZoom;
    delete btnPrint;
    delete btnPause;
    delete corNum;
}



DataPlotter::DataPlotter(int size, QWidget *p , const char *name)
: QWidget(p, name)
{
    
    d_zoomActive = d_zoom = 0;
    pausetemp = pause0 = 0;

    ArraySize = size;

    x = new double[ArraySize];
    y = new double[ArraySize];
    //  Initialize data
    for (int i = 0; i< ArraySize; i++)
    {
        x[i] = double(i);               // time axis
        y[i] = 0;
    }

    
    plt = new QwtPlot(this);
    frmInp = new InputFrame(this);

    frmInp->setFrameStyle(QFrame::Panel|QFrame::Raised);
    frmInp->setLineWidth(2);

    plt->setTitle("Simple QwtPlot Demo");
    
    crv1 = plt->insertCurve("Data");

    plt->setCurvePen(crv1, QPen(yellow));

    plt->enableGridXMin();
    plt->setGridMajPen(QPen(white, 0, DotLine));
    plt->setGridMinPen(QPen(gray, 0 , DotLine));

    plt->setAxisTitle(QwtPlot::xBottom, "Channel No");
    plt->setAxisTitle(QwtPlot::yLeft, "Signal");

    //Add marker
    mrk = plt->insertMarker();
    plt->setMarkerLineStyle(mrk, QwtMarker::VLine);
    plt->setMarkerPos(mrk, 10,20);
    plt->setMarkerLabelAlign(mrk, AlignRight|AlignTop);
    plt->setMarkerPen(mrk, QPen(red, 0, DashDotLine));
    plt->setMarkerLinePen(mrk, QPen(black, 0, DashDotLine));
    plt->setMarkerFont(mrk, QFont("Helvetica", 10, QFont::Bold));

    // Attach (don't copy) data. Both curves use the same x array.
    plt->setCurveRawData(crv1, x, y, ArraySize);
    
    plt->setPlotBackground(darkBlue);

    connect(frmInp->btnPrint, SIGNAL(clicked()), SLOT(print()));
    connect(frmInp->btnZoom, SIGNAL(clicked()), SLOT(zoom()));
    connect(frmInp->btnPause, SIGNAL(clicked()), SLOT(pause()));
    connect(plt, SIGNAL(plotMouseMoved(const QMouseEvent&)),
	    SLOT(plotMouseMoved( const QMouseEvent&)));
    connect(plt, SIGNAL(plotMousePressed(const QMouseEvent &)),
	    SLOT(plotMousePressed( const QMouseEvent&)));
    connect(plt, SIGNAL(plotMouseReleased(const QMouseEvent &)),
	    SLOT(plotMouseReleased( const QMouseEvent&)));
    
    plt->enableOutline(TRUE);
    plt->setOutlinePen(green);
}

DataPlotter::~DataPlotter()
{
    delete plt;
    delete frmInp;
    delete[] x;
    delete[] y;
}



void DataPlotter::print()
{

    QBrush br(red);
    QPen pn(yellow);
    
    QwtSymbol sym1;
    sym1.setBrush(br);
    sym1.setPen(pn);
    sym1.setSize(11);

    QPrinter p;

    if (p.setup(0))
    {
	plt->print(p, QwtFltrDim(200));
    }


}

void DataPlotter::zoom()
{
    if (d_zoomActive)
    {
	// Disable Zooming.
	plt->setAxisAutoScale(QwtPlot::yLeft);
	plt->setAxisAutoScale(QwtPlot::xBottom);
	plt->replot();
	d_zoom = FALSE;
	d_zoomActive = 0;
	
    }
    else
       d_zoom = !d_zoom;
    
    if (d_zoom)
    {
	frmInp->btnZoom->setText("Unzoom");
	frmInp->lblInfo->setText(zoomInfo);
    }
    else
    {
	frmInp->btnZoom->setText("Zoom");
	frmInp->lblInfo->setText(cursorInfo);
    }
    
}

void DataPlotter::pause()
{
  if (!pause0)
    pause0 = 1;
  else
    pause0 = 0;
}

void DataPlotter::plotMouseMoved(const QMouseEvent &e)
{
    QString lbl = "Event=";
    QString lbl2;
    
    lbl2.setNum(plt->invTransform(QwtPlot::xBottom, e.pos().x() ), 'g', 3);
    lbl += lbl2 + ",  Signal=";
    
    lbl2.setNum(plt->invTransform(QwtPlot::yLeft, e.pos().y() ), 'g', 3);
    lbl += lbl2;

    frmInp->lblInfo->setText(lbl);
}

void DataPlotter::plotMousePressed(const QMouseEvent &e)
{
    // store position
    p1 = e.pos();
    
    // update cursor pos display
    plotMouseMoved(e);
    
    if (d_zoom && (!d_zoomActive))
    {
    	plt->setOutlineStyle(Qwt::Rect); 
    }
    else
    {
	plt->setOutlineStyle(Qwt::Cross);
    } 
    
}

void DataPlotter::plotMouseReleased(const QMouseEvent &e)
{
    int x1, x2, y1, y2;
    int lim;
    
    // some shortcuts
    int axl= QwtPlot::yLeft, axb= QwtPlot::xBottom;
    
    if (d_zoom && (!d_zoomActive))
    {
	d_zoomActive = 1;
	
	// Don't invert any scales which aren't inverted
	x1 = qwtMin(p1.x(), e.pos().x());
	x2 = qwtMax(p1.x(), e.pos().x());
	y1 = qwtMin(p1.y(), e.pos().y());
	y2 = qwtMax(p1.y(), e.pos().y());
	
	// limit selected area to a minimum of 11x11 points
	lim = 5 - (y2 - y1) / 2;
	if (lim > 0)
	{
	    y1 -= lim;
	    y2 += lim;
	}
	lim = 5 - (x2 - x1 + 1) / 2;
	if (lim > 0)
	{
	    x1 -= lim;
	    x2 += lim;
	}
	
	// Set fixed scales
	plt->setAxisScale(axl, plt->invTransform(axl,y1), plt->invTransform(axl,y2));
	plt->setAxisScale(axb, plt->invTransform(axb,x1), plt->invTransform(axb,x2));
	plt->replot();
	

    }
    frmInp->lblInfo->setText(cursorInfo);
    plt->setOutlineStyle(Qwt::Triangle);
    
}

void DataPlotter::resizeEvent(QResizeEvent *e)
{
    QRect r(0, 0, e->size().width(), e->size().height() - 50);
    
    plt->setGeometry(r);
    frmInp->setGeometry(0, r.bottom() + 1, r.width(), 50);
    
}

void DataPlotter::updateNumPoints(int num_points)
// nothing at present - needs array class
{
}

void DataPlotter::updateEvent(double new_value, QString q_pos_str)
{
    // y moves from left to right.
    // Shift y array right and assign new value to y[0].
    for (int i = ArraySize-1; i>0; i--)
        y[i] = y[i-1];

    y[0] = new_value;
    
    if (pause0 != pausetemp)
      {
	if (pause0)
	  frmInp->btnPause->setText("Resume");
	else
	  if (!pause0)
	    frmInp->btnPause->setText("Pause");
      }
    pausetemp = pause0;

    // update the display
    if (!pause0)
      {
	if (position != q_pos_str)
	  {
	    position = q_pos_str;
	    frmInp->corNum->display(position);
	  }
	plt->setMarkerLabel(mrk, position);
	plt->replot();
      }
}

void DataPlotter::updateEvent(Vector<Double> spectrum, QString q_pos_str)
{
    for (int i = 0; i < ArraySize; i++) 
    	y[i] = spectrum(i);
    
    if (pause0 != pausetemp)
      {
	if (pause0)
	  frmInp->btnPause->setText("Resume");
	else
	  if (!pause0)
	    frmInp->btnPause->setText("Pause");
      }
    pausetemp = pause0;

    // update the display
    if (!pause0)
      {
	if (position != q_pos_str)
	  {
	    position = q_pos_str;
	    frmInp->corNum->display(position);
	  }
	plt->setMarkerLabel(mrk, position);
	plt->replot();
      }
}

void DataPlotter::updateTitle(QString S)
{
    // Assign a title
    plt->setTitle(S);
}

void DataPlotter::updateYAxisTitle(QString S)
{
    plt->setAxisTitle(QwtPlot::yLeft, S);
}

void DataPlotter::updateXAxisTitle(QString S)
{
    plt->setAxisTitle(QwtPlot::xBottom, S);
}

