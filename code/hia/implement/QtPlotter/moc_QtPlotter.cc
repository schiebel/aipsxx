/****************************************************************************
** DataPlotter meta object code from reading C++ file 'QtPlotter.h'
**
** Created: Wed Dec 1 01:01:51 2004
**      by: The Qt MOC ($Id: moc_QtPlotter.cc,v 19.2 2004/12/01 16:42:17 ddebonis Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#if !defined(Q_MOC_OUTPUT_REVISION)
#define Q_MOC_OUTPUT_REVISION 9
#elif Q_MOC_OUTPUT_REVISION != 9
#error "Moc format conflict - please regenerate all moc files"
#endif

#include "/aips++/dailytst/code/hia/implement/QtPlotter/QtPlotter.h"
#include <qmetaobject.h>
#include <qapplication.h>



const char *DataPlotter::className() const
{
    return "DataPlotter";
}

QMetaObject *DataPlotter::metaObj = 0;

void DataPlotter::initMetaObject()
{
    if ( metaObj )
	return;
    if ( qstrcmp(QWidget::className(), "QWidget") != 0 )
	badSuperclassWarning("DataPlotter","QWidget");
    (void) staticMetaObject();
}

#ifndef QT_NO_TRANSLATION

QString DataPlotter::tr(const char* s)
{
    return qApp->translate( "DataPlotter", s, 0 );
}

QString DataPlotter::tr(const char* s, const char * c)
{
    return qApp->translate( "DataPlotter", s, c );
}

#endif // QT_NO_TRANSLATION

QMetaObject* DataPlotter::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    (void) QWidget::staticMetaObject();
#ifndef QT_NO_PROPERTIES
#endif // QT_NO_PROPERTIES
    typedef void (DataPlotter::*m1_t0)(const QMouseEvent&);
    typedef void (QObject::*om1_t0)(const QMouseEvent&);
    typedef void (DataPlotter::*m1_t1)(const QMouseEvent&);
    typedef void (QObject::*om1_t1)(const QMouseEvent&);
    typedef void (DataPlotter::*m1_t2)(const QMouseEvent&);
    typedef void (QObject::*om1_t2)(const QMouseEvent&);
    typedef void (DataPlotter::*m1_t3)();
    typedef void (QObject::*om1_t3)();
    typedef void (DataPlotter::*m1_t4)();
    typedef void (QObject::*om1_t4)();
    typedef void (DataPlotter::*m1_t5)();
    typedef void (QObject::*om1_t5)();
    m1_t0 v1_0 = &DataPlotter::plotMousePressed;
    om1_t0 ov1_0 = (om1_t0)v1_0;
    m1_t1 v1_1 = &DataPlotter::plotMouseReleased;
    om1_t1 ov1_1 = (om1_t1)v1_1;
    m1_t2 v1_2 = &DataPlotter::plotMouseMoved;
    om1_t2 ov1_2 = (om1_t2)v1_2;
    m1_t3 v1_3 = &DataPlotter::print;
    om1_t3 ov1_3 = (om1_t3)v1_3;
    m1_t4 v1_4 = &DataPlotter::zoom;
    om1_t4 ov1_4 = (om1_t4)v1_4;
    m1_t5 v1_5 = &DataPlotter::pause;
    om1_t5 ov1_5 = (om1_t5)v1_5;
    QMetaData *slot_tbl = QMetaObject::new_metadata(6);
    QMetaData::Access *slot_tbl_access = QMetaObject::new_metaaccess(6);
    slot_tbl[0].name = "plotMousePressed(const QMouseEvent&)";
    slot_tbl[0].ptr = (QMember)ov1_0;
    slot_tbl_access[0] = QMetaData::Private;
    slot_tbl[1].name = "plotMouseReleased(const QMouseEvent&)";
    slot_tbl[1].ptr = (QMember)ov1_1;
    slot_tbl_access[1] = QMetaData::Private;
    slot_tbl[2].name = "plotMouseMoved(const QMouseEvent&)";
    slot_tbl[2].ptr = (QMember)ov1_2;
    slot_tbl_access[2] = QMetaData::Private;
    slot_tbl[3].name = "print()";
    slot_tbl[3].ptr = (QMember)ov1_3;
    slot_tbl_access[3] = QMetaData::Private;
    slot_tbl[4].name = "zoom()";
    slot_tbl[4].ptr = (QMember)ov1_4;
    slot_tbl_access[4] = QMetaData::Private;
    slot_tbl[5].name = "pause()";
    slot_tbl[5].ptr = (QMember)ov1_5;
    slot_tbl_access[5] = QMetaData::Private;
    metaObj = QMetaObject::new_metaobject(
	"DataPlotter", "QWidget",
	slot_tbl, 6,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    metaObj->set_slot_access( slot_tbl_access );
#ifndef QT_NO_PROPERTIES
#endif // QT_NO_PROPERTIES
    return metaObj;
}
