//# VLAFillerTask.cc: 
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
//# $Id: VLAFillerTask.cc,v 1.1 2005/05/20 00:23:20 ddebonis Exp $

#include <nrao/VLA/VLAFillerTask.h>
#include <nrao/VLA/VLAFiller.h>
#include <nrao/VLA/VLAFilterSet.h>
#include <nrao/VLA/VLAProjectFilter.h>
#include <nrao/VLA/VLAFrequencyFilter.h>
#include <nrao/VLA/VLACalibratorFilter.h>
#include <nrao/VLA/VLATimeFilter.h>
#include <nrao/VLA/VLASourceFilter.h>
#include <nrao/VLA/VLASubarrayFilter.h>
#include <nrao/VLA/VLADiskInput.h>
#include <nrao/VLA/VLAArchiveInput.h>
#include <nrao/VLA/VLATapeInput.h>
#include <nrao/VLA/VLAOnlineInput.h>
#include <casa/Containers/Block.h>
#include <casa/Exceptions/Error.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MFrequency.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/OS/SymLink.h>
#include <casa/Quanta/MVEpoch.h>
#include <casa/Quanta/MVFrequency.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>
#include <casa/iostream.h>

VLAFillerTask::VLAFillerTask()
 : CASATask(paramsDesc())
{
}

VLAFillerTask::VLAFillerTask(const Record &params)
 : CASATask(params)
{
}

VLAFillerTask::~VLAFillerTask()
{
}

RecordDesc VLAFillerTask::paramsDesc()
{
   RecordDesc psetDesc;
   psetDesc.addField("inputfile", TpString);
   psetDesc.addField("msname", TpString);
   psetDesc.addField("overwrite", TpBool);
   psetDesc.addField("start", TpString);
   psetDesc.addField("stop", TpString);
   psetDesc.addField("project", TpString);
   psetDesc.addField("centerfreq", TpString);
   psetDesc.addField("bandwidth", TpString);
   psetDesc.addField("calList", TpString);

   return psetDesc;
}

void VLAFillerTask::fill()
{
   const Record pset(getParams());

   VLALogicalRecord in;
   Int logProgress = 0;
   MeasurementSet *out = new MeasurementSet;
   char defcalcode;

   try
   {
      String msName("");
      if(pset.isDefined("msname"))
         msName = pset.asString("msname");

      Bool overWriteFlag(false);  
      if(pset.isDefined("overwrite"))
         overWriteFlag = pset.asBool("overwrite");  
      *out = VLAFiller::getMS(Path(msName), overWriteFlag);

      VLAFilterSet filters;

      String projectCode("");
      if(pset.isDefined("project"))
         projectCode = pset.asString("project");
      if(!(projectCode == String("all")))
      {
         filters.addFilter(VLAProjectFilter(projectCode));
      }

      String frequency("");
      if(pset.isDefined("centerfreq"))
         frequency = pset.asString("centerfreq");
      if(!frequency.empty())
      {
         istringstream iss(frequency);
         Quantity freq;
         iss >> freq;
         String bandwidth("");
         if(pset.isDefined("bandwidth"))
            bandwidth = pset.asString("bandwidth");  
         istringstream issbw(bandwidth);
         Quantity qbw;
         issbw >> qbw;
         MVFrequency rf(freq);
         MVFrequency bw(qbw);
         filters.addFilter(VLAFrequencyFilter(rf,bw));
      }

      String calList("");
      if(pset.isDefined("calList"))
         calList = pset.asString("calList");  
      if(!calList.empty())
      {
         defcalcode = '#';
      }
      else
      {
         defcalcode = calList[0];
      }
      filters.addFilter(VLACalibratorFilter(defcalcode));

      {
         VLATimeFilter tf;
         Quantum<Double> t;
         Bool timeFiltering = False;
         String startTime("");
         if(pset.isDefined("start"))
            startTime = pset.asString("start");  
         if(String(startTime) != String("blank"))
         {
            if(MVTime::read(t, startTime))
            {
               tf.startTime(MVEpoch(t));
               timeFiltering = True;
            }
            else
            {
               throw(AipsError("Cannot parse the start time"));
            }
         }
         String stopTime("");
         if(pset.isDefined("stop"))
            stopTime = pset.asString("stop");  
         if(!(stopTime == String("blank")))
         {
            if(MVTime::read(t, stopTime))
            {
               tf.stopTime(MVEpoch(t));
               timeFiltering = True;
            }
            else
            {
               throw(AipsError("Cannot parse the stop time"));
            }
         }
         if(timeFiltering)
            filters.addFilter(tf);
      }

      String inputName("");
      if(pset.isDefined("inputfile"))
         inputName = pset.asString("inputfile");
      const Path fileName (inputName);
      AlwaysAssert(fileName.isValid(), AipsError);
      File file(fileName);
      AlwaysAssert(file.exists(), AipsError);
      if(file.isSymLink())
      {
         SymLink link(file);
         Path realFileName = link.followSymLink();
         AlwaysAssert(realFileName.isValid(), AipsError);
         file = File(realFileName);
         AlwaysAssert(file.exists(), AipsError);
         DebugAssert(file.isSymLink() == False, AipsError);
      }
      if(file.isRegular())
      {
         in = VLALogicalRecord(new VLADiskInput(fileName));
         // Not dealing with tape!
         //
      }
      else if(file.isCharacterSpecial())
      {
         // in = VLALogicalRecord(new VLATapeInput(inputName, files));
      }
      else
      {
         throw(AipsError(String("vlatoms - cannot read from: ") +
         fileName.expandedName()));
      }
      VLAFiller *vla = new VLAFiller(*out, in);
      vla->setFilter(filters);
      vla->fill(logProgress);
      delete vla;
      delete out;
      vla = 0;
   }
   catch (AipsError x)
   {
      cerr << x.getMesg() << endl;
      return;
   }

   return;
}
