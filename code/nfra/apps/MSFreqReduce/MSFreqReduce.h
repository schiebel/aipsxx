//# MSFreqReduce: Reduce Frequency resolution
//# Copyright (C) 1998,1999,2000,2001,2002,2003
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#

#define MHz 1000000.0

class Channel {
private:
  Int ch0, ch1;
  Double F;

public:
  Channel(){};
  Channel(Int c0, Int c1, Double f){ch0 = c0; ch1 = c1; F = f;}

  Int getCh0(){return ch0;}
  Int getCh1(){return ch1;}
  Double getF(){return F;}
};

class FreqReduce {
  String MSin, MSout;
  uInt redFct;
  Double oldChanWidth, newChanWidth;
  uInt startChan, endChan;
  uInt newNrChan, oldNrChan;
  uInt nrPols;
  void getInfo();
  Bool verbose_val;

public:
  vector<Channel> ChanMap;
  FreqReduce(){verbose_val = False; startChan = 0; endChan = 0;}
  ~FreqReduce(){}

  void setVerbose(Bool v){verbose_val = v;}
  void setMSin(String in){MSin = in; getInfo();}
  void setMSout(String out){MSout = out;}
  void setRedFct(uInt rf){redFct = rf;}
  void setOldChanWidth(Double x){oldChanWidth = x;}
  void setNewChanWidth(Double x){newChanWidth = x;}
  void setStartChan(uInt u){startChan = u;}
  void setEndChan(uInt u){endChan = u;}
  void setNewNrChan(uInt u){newNrChan = u;}
  void setOldNrChan(uInt u){oldNrChan = u;}
  void setNrPols(uInt u){nrPols = u;}

  Bool getVerbose(){return verbose_val;}
  String getMSin(){return MSin;}
  String getMSout(){return MSout;}
  uInt getRedFct(){return redFct;}
  Double getOldChanWidth(){return oldChanWidth;}
  Double getNewChanWidth(){return newChanWidth;}
  uInt getStartChan(){return startChan;}
  uInt getEndChan(){return endChan;}
  uInt getNewNrChan(){return newNrChan;}
  uInt getOldNrChan(){return oldNrChan;}
  uInt getNrPols(){return nrPols;}


  void updateRedFct(){redFct = uInt(newChanWidth / oldChanWidth);}

  //
  // Channel methods
  //

  void redFct_mapping();
  void nchan_mapping();

  uInt addChannel(Int c0, Int c1, Double f){
    Channel C(c0, c1, f);
    ChanMap.push_back(C);
    return ChanMap.size();
  }
  uInt getChanMapSize(){return ChanMap.size();}
  Channel getChannel(uInt i){return ChanMap[i];}

  void show(){
    if (!verbose_val){
      cout << endl << "General info:" << endl;
      cout << "Input MS:" << MSin << endl;
      cout << "Output MS:" << MSout << endl;
      cout << "Number of polarizations: " << nrPols << endl;
      cout << "Reduction factor: " << redFct << endl;
      cout << "From " << oldNrChan << " to " << newNrChan << " channels" << endl;
      cout << "From " << oldChanWidth/MHz << " to " << newChanWidth/MHz << " MHz" << endl;
      cout << "From channel " << startChan << " to " << endChan << endl;
      cout << "Channel mapping:" << endl;
    }
    uInt cml = ChanMap.size();
    for (uInt i = 0; i < cml; i++){
      cout << i << ": " << ChanMap[i].getCh0() << " - " << ChanMap[i].getCh1() << endl;
    }
    cout << endl;

  }

  void verbose(String msg){
    if (verbose_val) cout << "Verbose: " << msg << endl;
  }
  void verbose(String msg, String s){
    if (verbose_val) cout << "Verbose: " << msg << ": " << s << endl;
  }
  void verbose(String msg, Int i){
    if (verbose_val) cout << "Verbose: " << msg << ": " << i << endl;
  }
  void verbose(String msg, uInt i){
    if (verbose_val) cout << "Verbose: " << msg << ": " << i << endl;
  }
  void verbose(String msg, Double x){
    if (verbose_val) cout << "Verbose: " << msg << ": " << x << endl;
  }

};
