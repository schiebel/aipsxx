//# QtXmlRecord.cc:  translations between aips++ options Records and xml.
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
//# $Id: QtXmlRecord.cc,v 1.2 2006/05/19 22:58:16 dking Exp $

#include <graphics/X11/X_enter.h>
#  include <QtXml>
#  include <QMessageBox>
#include <graphics/X11/X_exit.h>

#include "QtXmlRecord.h"
#include <casa/IO/AipsIO.h>

namespace casa { //# NAMESPACE CASA - BEGIN

QtXmlRecord::QtXmlRecord() : rootName("casa-Record")
{}
QtXmlRecord::~QtXmlRecord()
{}

bool QtXmlRecord::recordToDom(Record *rec, QDomDocument &doc)
{
    QDomElement root = doc.createElement(rootName);
    recordToElement(rec, &root, doc);
    doc.appendChild(root);
    formatXml(doc);
    //cout << "after create doc: " <<  doc.toString().toStdString() << endl;
    return true;
}
void QtXmlRecord::formatXml(QDomDocument &domDocument)
{
    QDomElement root = domDocument.documentElement();
    QDomNode rootb = domDocument.removeChild(root);
    root = domDocument.createElement(rootName);
    domDocument.appendChild(root);
    //cout << domDocument.toString().toStdString() << endl;
    //cout << "root=" << root.tagName().toStdString() << endl;
    QDomNode n = rootb.firstChild();
    while(!n.isNull())
    {
        QDomElement e = n.toElement();
        if(!e.isNull())
        {
            QString attr = e.attribute("context", "Basic_Settings");
            if (root.elementsByTagName(attr).count() == 0)
            {
                root.appendChild(domDocument.createElement(attr));
            }
            QString eName = e.attribute("dlformat", "no-name");
            //cout << "attr=" << attr.toStdString() << " eName="
            //     << eName.toStdString() << endl;
            QDomElement elem = (QDomElement)e.cloneNode().toElement();
            elem.removeAttribute("context");
            elem.removeAttribute("dlformat");
            elem.setTagName(eName);
            /*
            QString help = e.attribute("help");
            QDomElement helpElement = domDocument.createElement("help");
            QDomText helpElementText =domDocument.createTextNode(help);
            helpElement.appendChild(helpElementText);
            elem.appendChild(helpElement);	    
            elem.removeAttribute("help");

            QString value = e.attribute("value");
            QDomElement valueElement = domDocument.createElement("value");
               QDomText valueElementText =domDocument.createTextNode(value);
            valueElement.appendChild(valueElementText);
            elem.appendChild(valueElement);
            elem.removeAttribute("value");
            */

            elem.setAttribute("saved", e.attribute("value"));
            root.elementsByTagName(attr).item(0).appendChild(elem);
        }
        n = n.nextSibling();
    }

}


bool QtXmlRecord::recordToElement(const Record *rec, QDomElement *parent,
                                  QDomDocument &doc)
{

    Int nFields = rec->nfields();

    for (Int i = 0; i < nFields; i++)
    {
        if (rec->type(i) == TpRecord)
        {
            QDomElement subRec = doc.createElement("record");
            parent->appendChild(subRec);
            recordToElement( &(rec->subRecord(i)), &subRec, doc);
        }
        else
        {
            ostringstream oss;
            QString datatype;

            switch (rec->type(i))
            {
                {
                case TpBool:
                    Bool value = rec->asBool(i);
                    oss << value;
                    datatype = "Bool";
                    break;
                }
                {
                case TpUChar:
                    uChar value = rec->asuChar(i);
                    oss << value;
                    datatype = "uChar";
                    break;
                }
                {
                case TpShort:
                    Short value = rec->asShort(i);
                    oss << value;
                    datatype = "Short";
                    break;
                }
                {
                case TpInt:
                    Int value = rec->asInt(i);
                    oss << value;
                    datatype = "Int";
                    break;
                }
                {
                case TpUInt:
                    uInt value = rec->asuInt(i);
                    oss << value;
                    datatype = "uInt";
                    break;
                }
                {
                case TpFloat:
                    Float value = rec->asFloat(i);
                    oss << value;
                    datatype = "Float";
                    break;
                }
                {
                case TpDouble:
                    Double value = rec->asDouble(i);
                    oss << value;
                    datatype = "Double";
                    break;
                }
                {
                case TpComplex:
                    Complex value = rec->asComplex(i);
                    oss << value;
                    datatype = "Complex";
                    break;
                }
                {
                case TpDComplex:
                    DComplex value = rec->asDComplex(i);
                    oss << value;
                    datatype = "DComplex";
                    break;
                }
                {
                case TpString:
                    String value = rec->asString(i);
                    oss << value;
                    datatype = "String";
                    break;
                }
                {
                case TpArrayBool:
                    Array<Bool> value = rec->asArrayBool(i);
                    oss << value;
                    datatype = "ArrayBool";
                    break;
                }
                {
                case TpArrayUChar:
                    Array<uChar> value = rec->asArrayuChar(i);
                    oss << value;
                    datatype = "ArrayuChar";
                    break;
                }
                {
                case TpArrayShort:
                    Array<Short> value = rec->asArrayShort(i);
                    oss << value;
                    datatype = "ArrayShort";
                    break;
                }
                {
                case TpArrayInt:
                    Array<Int> value = rec->asArrayInt(i);
                    oss << value;
                    datatype = "ArrayInt";
                    break;
                }
                {
                case TpArrayUInt:
                    Array<uInt> value = rec->asArrayuInt(i);
                    oss << value;
                    datatype = "ArrayuInt";
                    break;
                }
                {
                case TpArrayFloat:
                    Array<Float> value = rec->asArrayFloat(i);
                    oss << value;
                    datatype = "ArrayFloat";
                    break;
                }
                {
                case TpArrayDouble:
                    Array<Double> value = rec->asArrayDouble(i);
                    oss << value;
                    datatype = "ArrayDouble";
                    break;
                }
                {
                case TpArrayComplex:
                    Array<Complex> value = rec->asArrayComplex(i);
                    oss << value;
                    datatype = "ArrayComplex";
                    break;
                }
                {
                case TpArrayDComplex:
                    Array<DComplex> value = rec->asArrayDComplex(i);
                    oss << value;
                    datatype = "ArrayDComplex";
                    break;
                }
                {
                case TpArrayString:
                    Array<String> value = rec->asArrayString(i);
                    oss << value;
                    datatype = "ArrayString";
                    break;
                }
                {
                case TpChar:
                    ;
                }
                {
                case TpUShort:
                    ;
                }
                {
                case TpTable:
                    ;
                }
                {
                case TpArrayChar:
                    ;
                }
                {
                case TpArrayUShort:
                    ;
                }
                {
                case TpRecord:
                    ;
                }
                {
                case TpOther:
                    ;
                }
                {
                case TpQuantity:
                    ;
                }
                {
                case TpArrayQuantity:
                    ;
                }
                {
                case TpNumberOfTypes:
                    ;
                }
                {
                default:
                    Array<String>value = rec->asArrayString(i);
                    oss << value;
                    datatype = "Other";
                }
            }
            //the datatype may have a use for some complex items.
            parent->setAttribute("datatype", datatype);
            String value(oss);
            String name = rec->name(i);
            parent->setAttribute(name.chars(), value.chars());
        }
    }

    return true;
}
 
 void QtXmlRecord::printRecord(const Record *rec)
{

    Int nFields = rec->nfields();
    cout << "[";
    for (Int i = 0; i < nFields; i++)
    {

        if (rec->type(i) == TpRecord)
        {
	    String name = rec->name(i);
            cout << " " << name.chars() << "=" ;
            printRecord( &(rec->subRecord(i)));
        }
        else
        {
            ostringstream oss;
            QString datatype;

            switch (rec->type(i))
            {
                {
                case TpBool:
                    Bool value = rec->asBool(i);
                    oss << value;
                    datatype = "Bool";
                    break;
                }
                {
                case TpUChar:
                    uChar value = rec->asuChar(i);
                    oss << value;
                    datatype = "uChar";
                    break;
                }
                {
                case TpShort:
                    Short value = rec->asShort(i);
                    oss << value;
                    datatype = "Short";
                    break;
                }
                {
                case TpInt:
                    Int value = rec->asInt(i);
                    oss << value;
                    datatype = "Int";
                    break;
                }
                {
                case TpUInt:
                    uInt value = rec->asuInt(i);
                    oss << value;
                    datatype = "uInt";
                    break;
                }
                {
                case TpFloat:
                    Float value = rec->asFloat(i);
                    oss << value;
                    datatype = "Float";
                    break;
                }
                {
                case TpDouble:
                    Double value = rec->asDouble(i);
                    oss << value;
                    datatype = "Double";
                    break;
                }
                {
                case TpComplex:
                    Complex value = rec->asComplex(i);
                    oss << value;
                    datatype = "Complex";
                    break;
                }
                {
                case TpDComplex:
                    DComplex value = rec->asDComplex(i);
                    oss << value;
                    datatype = "DComplex";
                    break;
                }
                {
                case TpString:
                    String value = rec->asString(i);
                    oss << value;
                    datatype = "String";
                    break;
                }
                {
                case TpArrayBool:
                    Array<Bool> value = rec->asArrayBool(i);
                    oss << value;
                    datatype = "ArrayBool";
                    break;
                }
                {
                case TpArrayUChar:
                    Array<uChar> value = rec->asArrayuChar(i);
                    oss << value;
                    datatype = "ArrayuChar";
                    break;
                }
                {
                case TpArrayShort:
                    Array<Short> value = rec->asArrayShort(i);
                    oss << value;
                    datatype = "ArrayShort";
                    break;
                }
                {
                case TpArrayInt:
                    Array<Int> value = rec->asArrayInt(i);
                    oss << value;
                    datatype = "ArrayInt";
                    break;
                }
                {
                case TpArrayUInt:
                    Array<uInt> value = rec->asArrayuInt(i);
                    oss << value;
                    datatype = "ArrayuInt";
                    break;
                }
                {
                case TpArrayFloat:
                    Array<Float> value = rec->asArrayFloat(i);
                    oss << value;
                    datatype = "ArrayFloat";
                    break;
                }
                {
                case TpArrayDouble:
                    Array<Double> value = rec->asArrayDouble(i);
                    oss << value;
                    datatype = "ArrayDouble";
                    break;
                }
                {
                case TpArrayComplex:
                    Array<Complex> value = rec->asArrayComplex(i);
                    oss << value;
                    datatype = "ArrayComplex";
                    break;
                }
                {
                case TpArrayDComplex:
                    Array<DComplex> value = rec->asArrayDComplex(i);
                    oss << value;
                    datatype = "ArrayDComplex";
                    break;
                }
                {
                case TpArrayString:
                    Array<String> value = rec->asArrayString(i);
                    oss << value;
                    datatype = "ArrayString";
                    break;
                }
                {
                case TpChar:
                    ;
                }
                {
                case TpUShort:
                    ;
                }
                {
                case TpTable:
                    ;
                }
                {
                case TpArrayChar:
                    ;
                }
                {
                case TpArrayUShort:
                    ;
                }
                {
                case TpRecord:
                    ;
                }
                {
                case TpOther:
                    ;
                }
                {
                case TpQuantity:
                    ;
                }
                {
                case TpArrayQuantity:
                    ;
                }
                {
                case TpNumberOfTypes:
                    ;
                }
                {
                default:
                    Array<String>value = rec->asArrayString(i);
                    oss << value;
                    datatype = "Other";
                }
            }
            String value(oss);
            String name = rec->name(i);
            cout << " " << name.chars() << "=" << value.chars() ;
        }
    }
    cout << "]";
    return ;
}

bool QtXmlRecord::elementToRecord(QDomElement *ele, Record &rec)
{
    if (!ele->isNull())
    {
        String name = ele->tagName().toStdString();
        String ptype = ele->attribute("ptype").toStdString();
	String datatype = ele->attribute("datatype").toStdString();
        QString value = ele->attribute("value");
        
	//#dk cout << " element name=" << name
        //#dk << " ptype=" << ptype
        //#dk << " value=" << value.toStdString() << endl;

	//#dk cout<<"QX:el2R "<<name<<" "<<value.toStdString()   //#diag
	//#dk     <<endl;  //#diag

        if (ptype == "choice" || ptype == "userchoice")
        {
            rec.define(name, value.toStdString());
        }
        else if(ptype == "floatrange")
        {
            rec.define(name, value.toFloat());
        }
        else if(ptype == "intrange")
        {
            rec.define(name, value.toInt());
        }
        else if(ptype == "string")
        {   
	    if (name == "mask") {
	        //#dk  Don't process this type of entry for now --
		//#dk  this is a more complex data type, which needs
		//#dk  further support; see LPADD.cc "mask" & vdd.g 'mask'.
	    }
	    else 
            rec.define(name, value.toStdString());
        }
        else if(ptype == "boolean")
        {
            rec.define(name, (value == "1"));
        }
        else if (ptype == "minmaxhist")
        {
            value.remove("[").remove("]");
            QStringList list = value.split(",");
            Vector<Float> tempinsert(2);
            bool ok1, ok2;
            if (list.size() == 2)
            {
                double d1 = list[0].toDouble(&ok1) ;
                double d2 = list[1].toDouble(&ok2);
                if (ok1 == true && ok2 == true && d1 < d2)
                {
                    tempinsert(0) = d1;
                    tempinsert(1) = d2;
                    rec.define(name, tempinsert);
                }
            }
        }
        else if (ptype == "button")
        {
            //#dk cout << " set " << name << endl;
            rec.define(name, "T");
            AipsIO ios("temp", ByteIO::New);
            ios << rec;
        }
        else if (ptype == "array")
        {
            //#dk cout << " set " << name << " value=" 
	    //#dk      << value.toStdString() << endl;           
	    QStringList list; // = value.remove('[').remove(']') .split(",",
	                      //         QString::SkipEmptyParts);
	
	    QRegExp rx("(\\d+)");
	    int pos = 0;	
	    while ((pos = rx.indexIn(value, pos)) != -1) {
		list << rx.cap(1);
		pos += rx.matchedLength();
	   }
	    //if (datatype == "String") {
            //   Vector<String> axisNames(list.size());
            //for(int i = 0; i < list.size(); i++)
            //    axisNames(i) = (list.at(i).toStdString()).c_str();
	   //	rec.define(name, axisNames);
	   //	}
	   // else {	
	       Vector<Int> axisNames(list.size());
               for(int i = 0; i < list.size(); i++) {
               axisNames(i) = atoi((list.at(i).toStdString()).c_str());	
	       //cout << "vec(" << i << ")=" << axisNames(i) << endl;
	       }
	       rec.define(name, axisNames);
	    //   }
            
        }
        else if (ptype == "check")
        {
            //#dk cout << " set " << name << endl;
            value.remove("[").remove("]");
            QStringList list = value.split(",");
            Vector<String> axisNames(list.size());
            for(int i = 0; i < list.size(); i++)
                axisNames(i) = list.at(i).toStdString();
            rec.define(name, axisNames);
        }
        else if (ptype == "region")
        {
            //#dk cout << " set " << name << endl;
            value.remove("[").remove("]");
            Record rrcd;
            rrcd.define("i_am_unset", "i_am_unset");
            //rec.addRecord(rrcd);
        }
        else if (ptype == "")
        {}
        /*
        String datatype = ele->attribute("datatype").toStdString();
               if (type == "Bool")
               {
                   Bool b = (value == "True") ? True : False;
                   rec.define(name, b);
               }
               else if (type == "uChar")
               {}
               else if (type == "Short")
               {}
               else if (type == "Int")
               {}
               else if (type == "uInt")
               {}
               else if (type == "Float")
               {}
               else if (type == "Double")
               {}
               else if (type == "Complex")
               {}
               else if (type == "DComplex")
               {}
               else if (type == "String")
               {
                   rec.define(name, value);
               }
               else if (type == "ArrayBool")
               {}
               else if (type == "ArrayuChar")
               {}
               else if (type == "ArrayShort")
               {}
               else if (type == "ArrayInt")
               {}
               else if (type == "ArrayuInt")
               {}
               else if (type == "ArrayFloat")
               {}
               else if (type == "ArrayDouble")
               {}
               else if (type == "ArrayComplex")
               {}
               else if (type == "ArrayDComplext")
               {}
               else if (type == "ArrayString")
               {}
               else if (type == "Char")
               {}
               else if (type == "uShort")
               {}
               else if (type == "Table")
               {}
               else if (type == "ArrayChar")
               {}
               else if (type == "ArrayUChar")
               {}
               else if (type =="Record")
               {}
               else if (type == "Quantity")
               {}
               else if (type =="ArrayQuantity")
               {}
               else if (type == "NumberOfTypes")
               {}
               else
               {
                   //type == "Other"
               }
               */
        // cout << " record=" << rec << endl;
    }
    return true;
}
bool QtXmlRecord::domToRecord(QDomDocument *doc, Record &rec)
{
    QDomElement grp = doc->firstChildElement().firstChildElement();
    for (; !grp.isNull(); grp = grp.nextSiblingElement())
    {
        QString grpName = grp.tagName();
        QDomElement ele = grp.firstChildElement();
        for (; !ele.isNull(); ele = ele.nextSiblingElement())
        {
            Record rcd;
            QDomNamedNodeMap map = ele.attributes();
            for (int i = 0; i < (int)(map.count()); i++)
            {
                QDomNode attr = map.item (i);
                if (attr.nodeName() == "value")
                    elementToRecord(&ele, rcd);
                else
                    rcd.define(String(attr.nodeName().toStdString()),
                               String(attr.nodeValue().toStdString()));
            }
            rcd.define("context", String(grpName.toStdString()));
            QString name = ele.tagName();
            rec.defineRecord(String(name.toStdString()), rcd);
        }
    }
    return true;
}

bool QtXmlRecord::readDomFrom(QDomDocument &doc, QIODevice *device)
{
    QString errorStr;
    int errorLine;
    int errorColumn;

    if (!doc.setContent(device, true, &errorStr, &errorLine,
                        &errorColumn))
    {
        QMessageBox::information(0, tr("Qt Options"),
                                 tr("Parse error at line %1, column%2:\n%3")
                                 .arg(errorLine)
                                 .arg(errorColumn)
                                 .arg(errorStr));
        return false;
    }

    QDomElement root = doc.documentElement();
    if (root.tagName() != rootName)
    {
        QMessageBox::information(0, tr("Qt Options"),
                                 tr("The file is not an Options file."));
        return false;
    }
    else if (root.hasAttribute("version")
             && root.attribute("version") != "1.0")
    {
        QMessageBox::information(0, tr("Qt Options"),
                                 tr("The file is not an Options "
                                    "version 1.0 file."));
        return false;
    }

    return true;

}
bool QtXmlRecord::writeDomTo(QDomDocument *doc, QIODevice *device)
{
    const int IndentSize = 4;
    QTextStream out(device);
    doc->save(out, IndentSize);
    return true;
}

QString QtXmlRecord::domToString(const QDomElement &elt)
{
    QString result;
    QTextStream stream(&result, QIODevice::WriteOnly);
    elt.save(stream, 2);
    stream.flush();
    return result;
}

QDomDocument QtXmlRecord::stringToDom(const QString &xml)
{
    QDomDocument result;
    result.setContent(xml);
    return result;
}

} //# NAMESPACE CASA - END
