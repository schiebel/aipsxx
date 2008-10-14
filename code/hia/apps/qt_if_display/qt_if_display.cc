//# qt_if_display: program to generate strip charts of IF data
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

#include <math.h>
#include <qapplication.h>
#include <qpushbutton.h>
#include <qscrollbar.h>
#include <qlcdnumber.h>
#include <qlayout.h>
#include <qfont.h>
#include <qstring.h>
#include <hia/QtPlotGrid/QtPlotGrid.h>
#include <hia/QtGlishEvent/QtGlishEvent.h>
#include <casa/Arrays/Vector.h>
#include <hia/ACSIS/if_full.h>
#include <tasking/Glish.h>
#include <fstream.h>

#include <casa/namespace.h>
MyGridPlot *plotter;
Int num_if_data = 4;
Int dcm_selector;
Int exhaust_selector;
Vector<Bool> if_data_display(num_if_data);
QString q_pos_str;

QtGlishSysEventSource *glishStream=0;

#define IF_SIZE 200

// handle exit command
Bool exit_event(GlishSysEvent &event, void *) {
    exit(0); 
    return True;
}

// process a data request from the real time display
/*+
Routine name:
rt_display_event

Function:
handle setup requests for IF data from the real time display

Activating Message:
rt_if_req

Method:
Get contents of rt display specification from message 
Set up appropriate sampling intervals
Set appropriate post_rt_data flag to true 
*-
*/
Bool rt_display_event (GlishSysEvent &e, void *) {

    GlishRecord record = e.val();

    if (record.exists("ifdata_type")) {
        GlishArray tmp;
        tmp = record.get("ifdata_type");
        tmp.get(if_data_display);
    }
     
    if (record.exists("dcm_selector")) {
        GlishArray tmp;
        tmp = record.get("dcm_selector");
        tmp.get(dcm_selector);
    }
    if (record.exists("exhaust_selector")) {
        GlishArray tmp;
        tmp = record.get("exhaust_selector");
        tmp.get(exhaust_selector);
    }
    if (record.exists("exit")) {
        GlishArray tmp;
        tmp = record.get("exit");
        Bool display_exit;
        tmp.get(display_exit);
        if (display_exit) {
            cout<<"qt_if_display exiting "<<endl;
            exit(0);
        }
    }
    return True;
}    


// update the strip chart display when new IF data received
Bool update_strips(GlishSysEvent &event, void *) {
    GlishSysEventSource *glishBus = event.glishSource();
    GlishValue glishVal = event.val();

    // CHECK THAT ARGUMENT IS A RECORD:
    if (glishVal.type() != GlishValue::RECORD) {
        if (glishBus->replyPending())
            glishBus->reply(GlishArray(False));
        return True;
    }

    // extract IF parameters

    GlishRecord glishRec = glishVal;

    Vector<Float> DCM_TP_IN(DCM);
    Vector<Float> DCM_TP_OUT(DCM);
    Vector<Float> DCM_TEMP(DCM);
    Vector<Float> INLET_TEMP(2);
    Vector<Float> EXHAUST_TEMP(2);

    int if_seq_num;
    if (glishRec.exists("SEQ_NUM")) 
    {
        GlishArray tmp;
        tmp = glishRec.get("SEQ_NUM");
        tmp.get(if_seq_num);
        QString temp;
        &temp.setNum(if_seq_num,10); 
         
        q_pos_str = "Seq. #:  " + temp;
    }

    if (glishRec.exists("DCM_TP_IN")) {
        GlishArray tmp;
        tmp = glishRec.get("DCM_TP_IN");
        tmp.get(DCM_TP_IN);
    }

    if (glishRec.exists("DCM_TP_OUT")) {
        GlishArray tmp;
        tmp = glishRec.get("DCM_TP_OUT");
        tmp.get(DCM_TP_OUT);
    }

    if (glishRec.exists("DCM_TEMP")) {
        GlishArray tmp;
        tmp = glishRec.get("DCM_TEMP");
        tmp.get(DCM_TEMP);
    }

    if (glishRec.exists("INLET_TEMP")) {
        GlishArray tmp;
        tmp = glishRec.get("INLET_TEMP");
        tmp.get(INLET_TEMP);
    }

    if (glishRec.exists("EXHAUST_TEMP")) {
        GlishArray tmp;
        tmp = glishRec.get("EXHAUST_TEMP");
        tmp.get(EXHAUST_TEMP);
    }
    if (if_data_display(0))
        plotter->MyGridPlotUpdate(0,EXHAUST_TEMP(exhaust_selector-1), q_pos_str);
    if (if_data_display(1))
        plotter->MyGridPlotUpdate(1,DCM_TEMP(dcm_selector-1), q_pos_str);
    if (if_data_display(2))
        plotter->MyGridPlotUpdate(2,DCM_TP_IN(dcm_selector-1), q_pos_str);
    if (if_data_display(3))
        plotter->MyGridPlotUpdate(3,DCM_TP_OUT(dcm_selector-1), q_pos_str);

    return True;
}


int main( int argc, char **argv )
{
    QApplication a( argc, argv );

    glishStream = new QtGlishSysEventSource (argc, argv);
    //  define callback event handlers
    (*glishStream).addTarget(update_strips, "synctask_ifdata");
    (*glishStream).addTarget(rt_display_event,"rtd_if_req");
    (*glishStream).addTarget(exit_event, "exit");
    // send message that the client started ok
    (*glishStream).postEvent("qt_initialized","dummy");

     
    // create a plotter
    plotter = new MyGridPlot(4, IF_SIZE);
    (*plotter).MyGridPlotTitle(0,"EXHAUST_TEMP");
    (*plotter).MyGridPlotTitle(1,"DCM_TEMP");
    (*plotter).MyGridPlotTitle(2,"DCM_TP_IN");
    (*plotter).MyGridPlotTitle(3,"DCM_TP_OUT");
    (*plotter).MyGridXAxisTitle(0,"event number");
    (*plotter).MyGridXAxisTitle(1,"event number");
    (*plotter).MyGridXAxisTitle(2,"event number");
    (*plotter).MyGridXAxisTitle(3,"event number");
    (*plotter).MyGridYAxisTitle(0,"degrees (C)");
    (*plotter).MyGridYAxisTitle(1,"degrees (C)");
    (*plotter).MyGridYAxisTitle(2,"power level (mW)");
    (*plotter).MyGridYAxisTitle(3,"power level (mW)");
    (*plotter).resize(650,510);
    (*plotter).show();

    return a.exec();
}

