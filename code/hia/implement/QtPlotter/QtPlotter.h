//# QtPlotter.h: class for embedding four Qwt plot widgets
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

#if !defined(AIPS_QTPLOTTER_H)
#define AIPS_QTPLOTTER_H

#include <qwidget.h>
#include <qframe.h>
#include <qpushbt.h>
#include <qlcdnumber.h>
#include <casa/Arrays/Vector.h>

#include <casa/namespace.h>
class QwtPlot;
class QwtCounter;
class QLabel;
class QwtPlot;

class InputFrame : public QFrame
{

public:

    QwtCounter *cntDamp;
    QLabel *lblInfo;
    QPushButton *btnPrint;
    QPushButton *btnZoom;
    QPushButton *btnPause;
    QLCDNumber *corNum;
    InputFrame(QWidget *p = 0, const char *name = 0);
    ~InputFrame();
    
};


class DataPlotter : public QWidget
{
    Q_OBJECT

   private:
    int ArraySize;                      // size of arrays
    double *x;                          // x axis values
    double *y;                          // y axis values

    QwtPlot *plt;
    InputFrame *frmInp;
    QPoint p1;
    int d_zoom;

    int d_zoomActive;


    long crv1, crv2;
    long mrk, mrk1, mrk2;
    
public:
    
    QLabel *lblInfo;
    QPushButton *btnPrint;
    QPushButton *btnZoom;
    QPushButton *btnPause;
    QString position;
    
    int pausetemp;
    int pause0;

    DataPlotter(int size, QWidget *p = 0, const char *name = 0);
    ~DataPlotter();
    void updateEvent(double new_value, QString q_pos_str);
    void updateEvent(Vector<Double> spectrum, QString q_pos_str);
    void updateNumPoints(int num_points); // needed eventually
    void updateTitle(QString S);
    void updateXAxisTitle(QString S);
    void updateYAxisTitle(QString S);

protected:
    
    void resizeEvent(QResizeEvent *e);

    private slots:

    void plotMousePressed(const QMouseEvent &e);
    void plotMouseReleased(const QMouseEvent &e);
    void plotMouseMoved(const QMouseEvent &e);
    
    void print();
    void zoom();
    void pause();
};

#endif    // define AIPS_QTPLOTTER_H
