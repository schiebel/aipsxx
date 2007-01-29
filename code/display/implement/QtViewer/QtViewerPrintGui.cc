//# QtViewerPrintGui.cc:  Printing dialog for QtViewer
//# Copyright (C) 2005
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
//# $Id: QtViewerPrintGui.cc,v 1.1 2006/06/22 18:39:13 dking Exp $

#include <graphics/X11/X_enter.h>
#include   <QtGui/QtGui>
#include   <QtCore/QDebug>
#include   <QFile>
#include <graphics/X11/X_exit.h>

#include <display/QtViewer/QtViewerPrintGui.qo.h>
#include <display/QtViewer/QtViewerBase.qo.h>
#include <display/QtViewer/QtPixelCanvas.qo.h>
#include <display/QtViewer/QtDisplayData.qo.h>
#include <display/QtAutoGui/QtGuiEntry.qo.h>
#include <display/QtAutoGui/QtLayout.h>
#include <display/Display/PanelDisplay.h>
#include <display/DisplayDatas/DisplayData.h>
#include <display/DisplayEvents/PCITFiddler.h>
#include <display/DisplayEvents/MWCRTZoomer.h>
#include <display/Display/AttributeBuffer.h>
#include <casa/BasicSL/String.h>

namespace casa { //# NAMESPACE CASA - BEGIN

////////////////////////  QtViewerPrintGui /////////////////////////////////

QtViewerPrintGui::QtViewerPrintGui(QtDisplayPanel *dp) 
	 : m_doc(), printer(0), pDP(dp)
{
    setWindowTitle("Viewer Print Manager");
    setObjectName(QString::fromUtf8("PrintManager"));
    //Q_INIT_RESOURCE(QtAutoGui);
    setGeometry(QRect(10, 0, 560, 260));

    vboxLayout = new QVBoxLayout;
    vboxLayout->setSpacing(6);
    vboxLayout->setMargin(0);
    vboxLayout->setObjectName(QString::fromUtf8("vboxLayout"));

    vboxLayout->setSizeConstraint(QLayout::SetFixedSize);
    this->setLayout(vboxLayout);
    m_doc.setContent(QtViewerPrintGui::printRecord);
    load(m_doc);
}

QtViewerPrintGui::~QtViewerPrintGui()
{}

void QtViewerPrintGui::loadRecord(Record rec)
{
    QtXmlRecord xmlRecord;
    xmlRecord.recordToDom(&rec, m_doc);
    load(m_doc);
    //cout << "\nRecord:\n";
    //xmlRecord.printRecord(&rec);
    //cout << endl;
    update();
}

bool QtViewerPrintGui::load(QDomDocument &doc)
{

    //cout << "------------doc: " << doc.toString().toStdString() << endl;
    if (doc.isNull())
        return false;
    QDomElement root = doc.firstChildElement();
    if (root.isNull())
        return false;
    QWidget *wgt = new QWidget();
    QVBoxLayout *vLayout = new QVBoxLayout;
    vLayout->setMargin(10);
    vLayout->setSpacing(6);
    vLayout->setSpacing(1);

    QDomElement widget_ele = root.firstChildElement();
    QSettings settings("CASA", "Viewer");
    QString mda = settings.value("Print/media").toString();
    for (; !widget_ele.isNull(); widget_ele = widget_ele.nextSiblingElement())
    {
        if (widget_ele.tagName() == "printmedia")
        {
            widget_ele.setAttribute("default", mda);
            widget_ele.setAttribute("value", mda);
            break;
        }
    }

    QHBoxLayout *titleLayout = new QHBoxLayout;
    QWidget *ttl = new QWidget;
    QLabel *pwd = new QLabel("Working Directory: " + QDir::currentPath());  
    titleLayout->addWidget(pwd);
    ttl->setLayout(titleLayout);
    vboxLayout->addWidget(ttl);
    
    widget_ele = root.firstChildElement();
    for (; !widget_ele.isNull();
            widget_ele = widget_ele.nextSiblingElement())
    {
        //cout << "item=" << widget_ele.tagName().toStdString() << endl;
        QString ptype = widget_ele.attribute("ptype", "noType");

        if (ptype == "intrange" || ptype == "floatrange")
        {
            if (// ele.attribute("editable") == "1" &&
                widget_ele.attribute("provideentry") == "1")
            {
                QtSliderEditor *item = new  QtSliderEditor(widget_ele);
                vLayout->addWidget(item);
                connect(item,
                        SIGNAL(itemValueChanged(
                                   QString, QString, int, bool)),
                        this,
                        SLOT(itemValueChanged(
                                 QString,QString, int, bool)));
            }

            else
            {
                QtSliderLabel *item = new  QtSliderLabel(widget_ele);
                vLayout->addWidget(item);
                connect(item, SIGNAL(itemValueChanged(
                                         QString, QString, int, bool)),
                        this, SLOT(itemValueChanged(
                                       QString, QString, int, bool)));
            }
        }

        else if (ptype == "choice" || ptype == "userchoice")
        {
            QtCombo *item = new  QtCombo(widget_ele);
            // item->setObjectName(widget_ele.tagName());
            vLayout->addWidget(item);
            connect(item, SIGNAL(itemValueChanged(
                                     QString, QString, int, bool)),
                    this, SLOT(itemValueChanged(
                                   QString, QString, int, bool)));
        }

        else if (ptype == "string")
        {
            QtLineEditor *item = new  QtLineEditor(widget_ele);
            //item->setObjectName(widget_ele.tagName());
            vLayout->addWidget(item);
            connect(item, SIGNAL(itemValueChanged(
                                     QString, QString, int, bool)),
                    this, SLOT(itemValueChanged(
                                   QString, QString, int, bool)));
        }

        else if (ptype == "boolean")
        {
            QtBool *item = new  QtBool(widget_ele);
            vLayout->addWidget(item);
            connect(item, SIGNAL(itemValueChanged(
                                     QString, QString, int, bool)),
                    this, SLOT(itemValueChanged(
                                   QString, QString, int, bool)));
        }

        else
        {}
        emit itemValueChanged(widget_ele.tagName(), widget_ele.attribute("value"),
                              0, false);

        bool block = blockSignals(true);
        blockSignals(block);

    }

    wgt->setLayout(vLayout);
    vboxLayout->addWidget(wgt);

    QHBoxLayout *cmdLayout = new QHBoxLayout;
    QWidget *cmd = new QWidget;
    QPushButton *bSaveXPM = new QPushButton("save");
    bSaveXPM->setToolTip("Press this button to save an "
                         "X11 Pixmap image to disk");

    QMenu * saveTypeMenu = new QMenu;
    QStringList saveType;
    saveType << "PS" << "EPS" << "XPM" << "XBM"
                      << "PPM" << "JPG"  << "JPEG" << "PNG";
    for (int i = 0; i < saveType.size(); i++)
    {
        QString item = saveType.at(i).toLocal8Bit().constData();
        QAction *act = new QAction(item, this);
        saveTypeMenu->addAction(act);
        connect(act, SIGNAL(activated()), this, SLOT(saveXPM()));
    }
    bSaveXPM->setMenu(saveTypeMenu);
    cmdLayout->addWidget(bSaveXPM);

    /*
    QPushButton *bSaveXPM = new QPushButton("save XPM");
    bSaveXPM->setToolTip("Press this button to save an "
                         "X11 Pixmap image to disk");  
    connect(bSaveXPM, SIGNAL(clicked()), this, SLOT(saveXPM()));
    cmdLayout->addWidget(bSaveXPM);
    QPushButton *bSavePS = new QPushButton("save PS");
    bSavePS->setToolTip("Press this button to save a "
                        "PostScriptimage to disk");
    connect(bSavePS, SIGNAL(clicked()),  this, SLOT(savePS()));
    cmdLayout->addWidget(bSavePS);
    */
    QPushButton *bPrint = new QPushButton("Print");
    bPrint->setToolTip("Press this button to open a window which "
                       "will allow you to send a PostScript image "
                       "to a printer");
    connect(bPrint, SIGNAL(clicked()),  this, SLOT(print()));
    QPushButton *bDismiss = new QPushButton("Dismiss");
    connect(bDismiss, SIGNAL(clicked()),  this, SLOT(dismiss()));


    cmdLayout->addWidget(bPrint);
    cmdLayout->addWidget(bDismiss);

    cmd->setLayout(cmdLayout);
    vboxLayout->addWidget(cmd);

    return true;
}

QString QtViewerPrintGui::printFileName() const
{
    return printfilename;
}
QString QtViewerPrintGui::printerName() const
{
    if (printer)
        return printer->printerName();
    else
        return "";
}
/*
void QtViewerPrintGui::setOriginal()
{
    std::cout << "set original options" << std::endl;
    QDomElement ele = m_doc.firstChildElement().firstChildElement()
                      .firstChildElement();
    for (; !ele.isNull(); ele = ele.nextSiblingElement())
    {
        ele.setAttribute("value", ele.attribute("saved"));
    }
}
*/
void QtViewerPrintGui::dismiss()
{
    close();
}
void  QtViewerPrintGui::printPS(QPrinter *printer, const QString printerType)
{
    if (!printer)
        return;
    if (printorientation == "Landscape")
    {
        printer->setOrientation(QPrinter::Landscape);
    }
    else if (printorientation == "2-Up")
    {
        printer->setOrientation(QPrinter::Portrait);
    }
    else
    {
        printer->setOrientation(QPrinter::Portrait);
    }

    if (printmedia == "US Letter")
    {
        printer->setPageSize(QPrinter::Letter);
    }
    else if (printmedia == "A3")
    {
        printer->setPageSize(QPrinter::A3);
    }
    else
    {
        printer->setPageSize(QPrinter::A4);
    }

    if (printerType == "Ghostview" || printerType == "PS")
    {
        printer->setOutputFileName(printfilename);
    }
    else if (printerType == "EPS")
    {
        printer->setOutputFileName(printfilename);
    }
    else
    {
        printer->setPrinterName(printerType);
    }

    printer->setResolution(printresolution);
    if (!pDP)
        return;
    
    pDP->hold();
    QPixmap * mp = pDP->contents();

    if (!mp) return;
    QPainter painter(printer);
    QRect rect = painter.viewport();
    rect.adjust(72, 72, -72, -72);
    QSize size = mp->size();
    size.scale(rect.size(), Qt::KeepAspectRatio);
    painter.setViewport(rect.x(), rect.y(), size.width(), size.height());
    painter.setWindow(mp->rect());
    painter.drawPixmap(0, 0, *mp);
    pDP->release();
    delete mp; mp=0;
    painter.end();
    
    if ( printerType == "EPS")
    {
        rect.setWidth( int(ceil(rect.width() * 72.0/printresolution)) );
        rect.setHeight( int(ceil(rect.height() * 72.0/printresolution)) );
        ps2eps(printfilename, rect);
        return;
    }
    if ( printerType == "Ghostview")
    {
        QString program = "ghostview"; //usr/X11R6/bin/ghostview
        QStringList arguments;
        arguments << printfilename;
        QProcess *ghostProcess = new QProcess(this);
        ghostProcess->start(program, arguments);
        return;
    }
}
void QtViewerPrintGui::print()
{
    printer = new QPrinter;

    //cout << " printer before init: " << (*printer);

    QtViewerPrintCtl *ctl = new QtViewerPrintCtl(this);
    if (ctl->exec() == QDialog::Accepted)
    {
        printfilename = ctl->fileName();
        printmedia = ctl->paper();
        printorientation = ctl->orientation();
        printPS(printer, ctl->printerName());
    }

    //cout << " printer setting: " << (*this);
    delete printer;
}
void QtViewerPrintGui::saveXPM()
{
    QString ext;
    if (QAction *action = qobject_cast<QAction *>(sender()))
    {
        ext = action->text();
    }

    //cout << "save to printfilename=" << printfilename.toStdString() << endl;
    if (printfilename == "unset" || printfilename.isEmpty())
    {
        QDateTime qdt = QDateTime::currentDateTime();
        printfilename = "viewer-" + qdt.toString(Qt::ISODate) + "." + ext.toLower();
    }
    else
    {
        int last = printfilename.lastIndexOf("." + ext, -1, Qt::CaseInsensitive);
        if (last + ("." + ext).size() != printfilename.size())
            printfilename += "." + ext.toLower();
    }
    if (ext == "EPS" || ext == "PS")
    {
        printer = new QPrinter;
        printPS(printer, ext);
        delete printer;
    }
    else
    {
        if (!pDP)
	     return;     
        pDP->hold();
        QPixmap * mp = pDP->contents();

	if (!mp)
	    return;
        int width = mp->width();
        int height = mp->height();
        if (printmagnification > 0)
        {
            width  = int(printmagnification * width);
            height = int(printmagnification * height);
        }

        char* t = (char*)ext.toLocal8Bit().constData();
	
	mp->scaled(width, height, Qt::KeepAspectRatio).save(printfilename, t);
        
	//#dk if (mp->scaled(width, height, 
	//#dk                Qt::KeepAspectRatio).save(printfilename, t))
        //#dk     cout << "Image saved as " << printfilename.toStdString() << endl;
        //#dk else
        //#dk     cout << "Failed to save image, type: " << t << endl;
        
	pDP->release();
        delete mp; mp=0;
    }
    printfilename = "unset";
    findChild<QtLineEditor *>("LineEditorItem")->reSet(printfilename);

}
void QtViewerPrintGui::savePS()
{
    /*
    cout << "savePS clicked" << endl;
    printer = new QPrinter;
    printPS(printer, "Ghostview");
    delete printer;
    */
 
    /*
           its.writeps := function() {
            filename := its.params.printfilename.value;
            media := its.params.printmedia.value;
            if (its.params.printorientation.value == 'landscape') {
                landscape := T;
            } else {
                landscape := F;
            }
            resolution := its.params.printresolution.value;
            magnification := its.params.printmagnification.value;
            eps := its.params.printepsformat.value;
            return its.canvasprintmanager.writeps(filename, media, landscape,
                                                  resolution, magnification, eps);
        }
    */
    /*
          self.writeps := function(filename=unset, media='A4', landscape=F,
                                 dpi=100, zoom=1.0, eps=F) {
            __VCF_('viewercanvasprintmanager.writeps');
            wider its;
            if (is_unset(filename) || !is_string(filename)) {
                if (eps) {
                    filename := its.viewer.generatefilename(ext='eps');
                } else {
                    filename := its.viewer.generatefilename(ext='ps');
                }
            }
            note(spaste('Writing \'', filename, '\' ...'),
                 origin=its.viewer.title(), priority='NORMAL');
            its.viewer.hold();
            its.viewer.disable();
            local status := its.displaypanel.status();
            local pcw := status.pixelcanvas.width;
            local pch := status.pixelcanvas.height;
            local mcl;
            if (has_field(status.pixelcanvas, 'colorcubesize')) {
                mcl := status.pixelcanvas.colorcubesize;
            } else {
                mcl := status.pixelcanvas.colortablesize;
            }
            local mtp := status.pixelcanvas.maptype;
            p := its.viewer.widgetset().
              pspixelcanvas(filename, media, landscape, pch/pcw,
                            dpi, zoom, eps, mcl, mtp);
            if (is_fail(p)) { fail; }
     
            local pdstatus := status.paneldisplay;
            w := its.viewer.widgetset().
                paneldisplay(p, pdstatus.nxpanels,
                             pdstatus.nypanels,
                             pdstatus.xorigin,
                             pdstatus.yorigin,
                             pdstatus.xsize, pdstatus.ysize,                         
                             pdstatus.xspacing, pdstatus.yspacing,
                             foreground='black', background='white');
            if (is_fail(w)) { fail; }
            opts := its.displaypanel.getoptions();
            t := w->setoptions(opts);
            wdgori := opts.wedgeorientation.value;
            wdgcvi := [=];
            if (status.nwedges > 0) {
                wedgeextent := 0.18;
                wedgespace := 0.0;
                for (i in 1:status.nwedges) {
                    tmpval :=  1.0  -
                             i * (wedgeextent + wedgespace) + wedgespace;
                    rec := [=];
                    if (wdgori == 'vertical') {
                        xorigin := tmpval;
                        yorigin := pdstatus.yorigin;
                        xsize := wedgeextent;
                        ysize := pdstatus.ysize;
                        rec.leftmarginspacepg := 1;
                        rec.bottommarginspacepg :=
                            opts.bottommarginspacepg.value;
                        rec.topmarginspacepg :=
                            opts.topmarginspacepg.value;
                        rec.rightmarginspacepg := 10;
     
                    } else {
                        xorigin :=pdstatus.xorigin ;
                        yorigin := tmpval;
                        ysize := wedgeextent;
                        xsize := pdstatus.xsize;
                        rec.bottommarginspacepg := 1;
                        rec.leftmarginspacepg :=
                            opts.leftmarginspacepg.value;
                        rec.rightmarginspacepg :=
                            opts.rightmarginspacepg.value;
                        rec.topmarginspacepg := 6;
                    }
                    wdgcvi[i] := its.viewer.widgetset().
                        paneldisplay(p, 1, 1, xorigin, yorigin, xsize, ysize);
                    wdgcvi[i]->hold();
                    t := wdgcvi[i]->setoptions(rec);
                    wdgcvi[i]->release();
                }
            }
            t := w->hold();
            # set the animation frame
            dpani := its.displaypanel.animator();
            vani := its.viewer.widgetset().mwcanimator();
            vani->add(w);
     
            displaydatas := its.displaypanel.getdisplaydatas();
            registrationflags := its.displaypanel.registrationflags();
     
     
            # preserve order in which the dds are registered, in thefollowing.
     
            ddnames := "";  # names of registered dds.
            wddnames := ""; # names of registered dds with colorwedges on.
     
            for (ddnm in field_names(registrationflags)) {
              if (registrationflags[ddnm]) {
                ddnames[len(ddnames)+1] := ddnm;
                opt:= displaydatas[ddnm].getoptions();
                if(is_record(opt.wedge) && opt.wedge.value) {
                  wddnames[len(wddnames)+1] := ddnm;
                }
              }
            }
     
            for (str in ddnames) {
                t := w->add(displaydatas[str].ddproxy());
                if (displaydatas[str].hasbeam()) {
                    t := w->add(displaydatas[str].ddd().dddproxy());
                }
            }
     
            addd := its.displaypanel.annotationdd();
            if (is_agent(addd))
                t := w->add(addd.dddproxy());
     
     
            # Set the same zoom as is on displaypanel worldcanvas[es].
            # (Important to set zoom and animation index _after_ ddshave
            # been added and have initialized panel state; otherwisethe
            # dds might re-initialize these settings).
     
            wcst := status.paneldisplay;
            t := w->setzoom(wcst.linearblc[1], wcst.linearblc[2],
                            wcst.lineartrc[1], wcst.lineartrc[2]);
     
            # duplicate animator settings
     
            zindex := [=];
            zindex.name := "zIndex";
            zindex.value := dpani.currentzframe()-1;
            zindex.increment := 1;
     
            if(dpani.mode()=='blink') {
              bindex := [=];
              bindex.name := "bIndex";
              bindex.value := dpani.currentbframe()-1;
              bindex.increment := 1;
     
              vani->setlinearrestriction(bindex);
          
              zindex.increment := 0;
            }
     
            vani->setlinearrestriction(zindex);
     
     
     
            # release will refresh, i.e., create postscript for the main panel.
     
            t := w->release();
     
     
     
            # colormap wedge panels are separately populated and released.
     
            nw := min(status.nwedges, len(wddnames))  # (should be equal).
            if (nw > 0) {
              for (i in 1:nw) {
                wdgcvi[i]->hold();
     
                t := wdgcvi[i]->add(displaydatas[wddnames[i]].wedgedd());
     
                wdgcvi[i]->release();       # (writes wedge postscript).
              }
            }
     
     
            # destroy our objets d'art:
            vani->remove(w);
            vani := 0;
           if (status.nwedges > 0) {
                for (i in 1:status.nwedges) {
                    wdgcvi[i] := 0;
                }
            }
     
            # Add annotations to the paneldisplay
            if (has_field(its.displaypanel, 'annotator') &&
                is_agent(its.displaypanel.annotator())) {
                tmp := its.displaypanel.annotator().print(w);
                if (is_fail(tmp)) {
                    print tmp;
                }
                    } else {
                note(spaste('Couldn\'t add annotations to print out;
    annotations',
                            ' unavailable'), origin=its.viewer.title(
    ),
                     priority = 'WARN');
            }
            #
     
            w := 0;
            p := 0;
            its.viewer.enable();
            its.viewer.release();
            note(spaste('File \'', filename, '\' successfully written
    '),
                 origin=its.viewer.title(), priority='NORMAL');
            return filename;
        }
    }
    */
}


void QtViewerPrintGui::itemValueChanged(QString name, QString value,
                                        int action, bool autoApply)
{
    //std::cout << "received 4 parameters: name=" << name.toStdString()
    //<< " value=" << value.toStdString()
    //<< " action=" << action
    //<< " apply=" << autoApply
    //<< std::endl;
    QSettings settings("CASA", "Viewer");
    if (name == "printfilename")
    {
        printfilename = value;
    }
    else if (name == "printmedia")
    {
        printmedia = value;
        settings.setValue("Print/media", value);
    }
    else if (name == "printorientation")
    {
        printorientation = value;
    }
    else if (name == "printresolution")
    {
        printresolution = value.toInt();
    }
    else if(name == "printmagnification")
    {
        printmagnification = value.toFloat();
    }
    else if (name == "printepsformat")
    {
        printepsformat = value;
    }
    else
    {}

    //cout << "finished itemValueChanged" << std::endl;


}

void QtViewerPrintGui::ps2eps(const QString &filename, QRect rect)
{     
    //qDebug() << "current dir=" << QDir::currentPath();
    //QString fname = QDir::currentPath() + "/" + filename;
    //qDebug() << "epsfile " << fname << " exist=" << QFile::exists(fname);
        
    QFile epsfile(filename);    
    
    if (! epsfile.open(QIODevice::ReadOnly))
    {
        return;
    }    
    //qDebug() << " size=" << epsfile.size() << " atEnd=" << epsfile.atEnd(); 
    
    QTextStream ts(&epsfile);
    QString fileContent= ts.readAll();
    epsfile.close();

    //qDebug() << fileContent; 
    
    if (fileContent.indexOf("EPSF") > 0)
       return;
    
    QRegExp rx("%%BoundingBox:\\s*(-?[\\d\\.:]+)\\s*(-?[\\d\\.:]+)\\s*(-?[\\d\\.:]+)\\s*(-?[\\d\\.:]+)");
    const int pos = rx.indexIn(fileContent);
    if (pos < 0)
    {
        //#dk qDebug() << "QtViewerPrintGui::ps2eps(" << filename
        //#dk         << "): cannot find %%BoundingBox";
        return;
    }

    if (! epsfile.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        //#dk qDebug() << "QtViewerPrintGui::ps2eps(" << filename
        //#dk << "): cannot open file for writing";
        return;
    }

    const double epsleft = rx.cap(1).toFloat();
    const double epstop = rx.cap(4).toFloat();
    const int left = int(floor(epsleft));
    const int right = int(ceil(epsleft)) + rect.width();
    const int top = int(ceil(epstop)) + 1;
    const int bottom = int(floor(epstop)) - rect.height() + 1;

    fileContent.replace(pos,rx.cap(0).length(),
                        QString("%%BoundingBox: %1 %2 %3 %4")
			.arg(left).arg(bottom).arg(right).arg(top));

    ts << fileContent;
    epsfile.close();
}

void QtViewerPrintGui::printToFile(const QString &filename,bool isEPS)
{
    // because we want to work with postscript
    // user-coordinates, set to the resolution
    // of the printer (which should be 72dpi here)
    printresolution = 72;
    QPrinter *printer;

    if (isEPS == false)
    {
        printer = new QPrinter(QPrinter::PrinterResolution);
    }
    else
    {
        printer = new QPrinter(QPrinter::ScreenResolution);
    }

    printer->setOutputFileName(filename);
    printer->setColorMode(QPrinter::Color);

    QPainter *painter = new QPainter(printer);
    printer->setResolution(printresolution);

    pDP->hold();
    QPixmap * mp = pDP->contents();

    QRect rect = painter->viewport();
    //it may be necessary to remove preset left and top by translate
    rect.adjust(72, 72, -72, -72);
    QSize size = mp->size();
    size.scale(rect.size(), Qt::KeepAspectRatio);
    painter->setViewport(rect.x(), rect.y(), size.width(), size.height());
    painter->setWindow(mp->rect());
    painter->drawPixmap(0, 0, *mp);
    pDP->release();
    delete mp; mp=0;
    painter->end();
    int resolution = printer->resolution();

    delete painter;
    delete printer;
    if (isEPS)
    {
        rect.setWidth( int(ceil(rect.width() * 72.0/resolution)) );
        rect.setHeight( int(ceil(rect.height() * 72.0/resolution)) );
        ps2eps(filename,rect);
    }
}

ostream& operator << (ostream &os, const QtViewerPrintGui &obj)
{
    os << "print parameters: printfilename="
    << obj.printfilename.toStdString()
    <<  " printmedia="
    <<  obj.printmedia.toStdString()
    << " printorientation="
    <<  obj.printorientation.toStdString()
    << " printresolution="
    << obj.printresolution
    << " printmagnification="
    << obj.printmagnification
    //<< " printepsforma="
    //<< obj.printepsformat.toStdString()
    << " printername="
    << obj.printerName().toStdString()
    << endl;
    return os;
}

ostream& operator << (ostream &os, const QPrinter &printer)
{
    os << " creator=" << printer.creator().toStdString()
    << " docName=" << printer.docName().toStdString()
    //<< " fromPage=" << printer.fromPage().toStdString() //4.1
    << " fullPage=" << printer.fullPage()
    //<< " newPage=" << printer.newPage()
    << " numCopies=" << printer.numCopies()
    << " orientation=" << printer.orientation ()
    << " outputFileName=" << printer.outputFileName().toStdString()
    //<< " outputFormat=" << printer.outputFormat() //4.1
    << " pageOrder=" << printer.pageOrder()
    << " pageRect=" << printer.pageRect().x() << "," << printer.pageRect().y() << ","
    << printer.pageRect().width() << "," << printer.pageRect().height()
    << " pageSize=" << printer.pageSize()
    << " paperRect=" << printer.paperRect().x()  << "," << printer.paperRect().y() << ","
    << printer.paperRect().width() << "," << printer.paperRect().height()
    << " paperSource=" << printer.paperSource()
    << " printProgram=" << printer.printProgram().toStdString()
    //<< " printRange=" << printer.printRange() //4.1
    << " printerName=" << printer.printerName().toStdString()
    << " printerSelectionOption=" << printer.printerSelectionOption().toStdString()
    << " printerState=" << printer.printerState()
    << endl;
    return os;
}

const QString QtViewerPrintGui::printRecord =
    "<casa-Record>\n"
    "<printfilename "
    "dlformat=\"printfilename\" "
    "listname=\"Output file\" "
    "ptype=\"string\" "
    "default=\"unset\" "
    "value=\"unset\" "
    "allowunset=\"T\" "
    "autoapply=\"F\" "
    "/>\n"
    "<printmedia "
    "dlformat=\"printmedia\" "
    "listname=\"[PS] Output media\" "
    "ptype=\"choice\" "
    "popt=\"[A4, LETTER]\" "
    "default=\"A4\" "
    "value=\"A4\" "
    "allowunset=\"F\" "
    "autoapply=\"F\" "
    "/>\n"
    "<printorientation "
    "dlformat=\"printorientation\" "
    "listname=\"[PS] Orientation\" "
    "ptype=\"choice\" "
    "popt=\"[portrait, landscape]\" "
    "default=\"portrait\" "
    "value=\"portrait\" "
    "allowunset=\"F\" "
    "autoapply=\"F\" "
    "/>\n"
    "<printresolution "
    "dlformat=\"printresolution\" "
    "listname=\"[PS] Resolution (dpi)\" "
    "ptype=\"intrange\" "
    "pmin=\"60\" "
    "pmax=\"300\" "
    "default=\"72\" "
    "value=\"72\" "
    "allowunset=\"F\" "
    "autoapply=\"F\" "
    "/>\n"
    "<printmagnification "
    "dlformat=\"printmagnification\" "
    "listname=\"[PS] Magnification\" "
    "ptype=\"floatrange\" "
    "pmin=\"0.1\" "
    "pmax=\"1.0\" "
    "presolution=\"0.02\" "
    "default=\"1.0\" "
    "value=\"1.0\" "
    "allowunset=\"F\" "
    "autoapply=\"F\" "
    "/>\n"
    //"<printepsformat "
    //"dlformat=\"printepsformat\" "
    //"listname=\"[PS] Write EPS format?\" "
    //"ptype=\"boolean\" "
    //"default=\"F\" "
    //"value=\"F\" "
    //"allowunset=\"F\" "
    //"autoapply=\"F\" "
    //"/>\n"
    "</casa-Record>";


QtViewerPrintCtl::QtViewerPrintCtl(QtViewerPrintGui *parent)
        : QDialog(0)
{
    setupUi(this);

    QSettings settings("CASA", "Viewer");

    cbOrientation->addItem("Portrait");
    cbOrientation->addItem("Landscape");
    cbOrientation->addItem("2-Up");

    QString media = settings.value("Print/paper").toString();
    QStringList paperType;
    paperType << "US Letter" <<  "A4" << "A3";
    for (int i = 0; i < paperType.size(); i++)
    {
        QString item = paperType.at(i).toLocal8Bit().constData();
        cbPaper->addItem(item);
        if (item == media)
            cbPaper->setCurrentIndex(i);
    }

    rbPrinter->setChecked(true);

    QString name = parent->printFileName();
    //cout << "parent=" <<  (*parent);
    if (name.isEmpty() || name == "unset")
    {
        QDateTime qdt = QDateTime::currentDateTime();
        name = "viewer-" + qdt.toString(Qt::ISODate) + ".ps";
    }
    lPrinter->setText("");
    rbPrinter->setText("Printer Name: ");
     
    leFileName->setText(name);
    lePrinter->setText(settings.value("Print/printer").toString());

    QObject::connect(bPrint, SIGNAL(clicked()), this, SLOT(checkPrinter()));
    QObject::connect(this, SIGNAL(printIt()), this, SLOT(accept()));

}

QtViewerPrintCtl::~QtViewerPrintCtl()
{}

QString QtViewerPrintCtl::fileName() const
{
    return leFileName->text();
}

QString QtViewerPrintCtl::printerName() const
{
    if (rbPrinter->isChecked())
        return lePrinter->text();
    else
        return "Ghostview";
}

QString QtViewerPrintCtl::orientation() const
{
    return cbOrientation->currentText();
}

QString QtViewerPrintCtl::paper() const
{
    return cbPaper->currentText();
}

void QtViewerPrintCtl::checkPrinter()
{
    if (lePrinter->text().isEmpty()){
        //lePrinter->setBackgroundRole(QPalette::Highlight);
	QPalette palette( lePrinter->palette() );
	palette.setColor( QPalette::Base, Qt::red);
	lePrinter->setPalette(palette);
    }	
    else
    {
        QSettings settings("CASA", "Viewer");
        settings.setValue("Print/paper",  cbPaper->currentText());
        settings.setValue("Print/printer", lePrinter->text());
        emit printIt();
    }
}

} //# NAMESPACE CASA - END

