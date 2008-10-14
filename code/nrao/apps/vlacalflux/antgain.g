include "tables.g"
include "pgplotwidget.g"
antgain := function(tablename, antid){
   t := table(tablename);
   myPlotter := [=];
   myPlotter.myFrame := frame(width=620, height=900);
   myPlotter.pg1 := pgplotwidget(myPlotter.myFrame, [600,200],havemessages=F);
   myPlotter.pg2 := pgplotwidget(myPlotter.myFrame, [600,200],havemessages=F);
   myPlotter.pg3 := pgplotwidget(myPlotter.myFrame, [600,200],havemessages=F);
   myPlotter.pg4 := pgplotwidget(myPlotter.myFrame, [600,200],havemessages=F);
     # Get the antennas do the observing
   a := t.getcolshapestring('alist');
     # Now find when we don't match
   b := a[1:(len(a)-1)] != a[2:len(a)];
   if(any(b==T))
      arrays := ind(b)[b == T];
    else
      arrays := [=]
   theTime := F;
   antflux_a := F;
   antflux_b := F;
   antflux_c := F;
   antflux_d := F;
   band := VLABand(t.getcol('skyfreq'));
   print shape(band);
   for (i in 0:len(arrays)) {
       if(len(arrays) > 1){
          if(i == 0){
             startIntegration := 1;
             numIntegrations := arrays[1];
          }else if(i==len(arrays)){
            numIntegrations := -1;
            startIntegration := arrays[i]+1;
          }else{
             numIntegrations := arrays[i+1]-arrays[i];
             startIntegration := arrays[i]+1;
	   }
        } else {
           startIntegration := 1;
           numIntegrations := -1;
        }
       
       alist := t.getcol('alist', startIntegration, numIntegrations);
       flux_ifa := abs(t.getcol('flux_ifa', startIntegration, numIntegrations));
       flux_ifb := abs(t.getcol('flux_ifb', startIntegration, numIntegrations));
       flux_ifc := abs(t.getcol('flux_ifc', startIntegration, numIntegrations));
       flux_ifd := abs(t.getcol('flux_ifd', startIntegration, numIntegrations));
       print shape(flux_ifa);
       
       newTime := t.getcol('iat', startIntegration, numIntegrations)*24.0/(2*3.14159);
       newantflux_a := flux_ifa[ind(alist)[alist==antid]];
       newantflux_b := flux_ifb[ind(alist)[alist==antid]];
       newantflux_c := flux_ifc[ind(alist)[alist==antid]];
       newantflux_d := flux_ifd[ind(alist)[alist==antid]];
       if(is_boolean(theTime)){
          theTime := newTime;
          antflux_a := newantflux_a;
          antflux_b := newantflux_b;
          antflux_c := newantflux_c;
          antflux_d := newantflux_d;
       } else {
          cpts := len(theTime);
          npts := len(newTime);
          theTime[(cpts+1):(cpts+npts)] := newTime;
          antflux_a[(cpts+1):(cpts+npts)] := newantflux_a;
          antflux_b[(cpts+1):(cpts+npts)] := newantflux_b;
          antflux_c[(cpts+1):(cpts+npts)] := newantflux_c;
          antflux_d[(cpts+1):(cpts+npts)] := newantflux_d;
       }
   }
#
# OK so to get different colors for freqs we need to sort each array by freq
# and then plot, this is crude but it gets the entire day plotted.
#
   myPlotter.pg1.plotxy(theTime, antflux_a, F, T, 'UT - Hours', 'Flux Amplitude', paste('Flux for antenna', antid, "IF A"), linecolor=2);
   myPlotter.pg2.plotxy(theTime, antflux_b, F, T, 'UT - Hours', 'Flux Amplitude', paste('Flux for antenna', antid, "IF B"), linecolor=2);
   myPlotter.pg3.plotxy(theTime, antflux_c, F, T, 'UT - Hours', 'Flux Amplitude', paste('Flux for antenna', antid, "IF C"), linecolor=2);
   myPlotter.pg4.plotxy(theTime, antflux_d, F, T, 'UT - Hours', 'Flux Amplitude', paste('Flux for antenna', antid, "IF D"), linecolor=2);
   theBands := "90cm 20cm 6cm 4cm 2cm 1cm 7mm";
   i := 2;
   for(curBand in theBands){
      obsInBand := ind(band[1,])[band[1,]==curBand]
      if(len(obsInBand) > 0){
         print len(obsInBand), 'observations in ', curBand, ' band';
         myPlotter.pg1.plotxy(theTime[obsInBand], antflux_a[obsInBand], F, F, linecolor=i, ptsymbol=2);
         myPlotter.pg2.plotxy(theTime[obsInBand], antflux_b[obsInBand], F, F, linecolor=i, ptsymbol=3);
         myPlotter.pg3.plotxy(theTime[obsInBand], antflux_c[obsInBand], F, F, linecolor=i, ptsymbol=4);
         myPlotter.pg4.plotxy(theTime[obsInBand], antflux_d[obsInBand], F, F, linecolor=i, ptsymbol=5);
         i := i+1;
      }
   }
   return myPlotter;
   # print band[1,];
}
VLABand := function(freq){
   #Frequency in GHz
  Band90cm :=[0.295,0.350];
  Band20cm := [1.22,1.75];
  Band06cm :=[4.20,5.1];
  Band04cm :=[6.8,9.6];
  Band02cm := [13.5,16.3]
  Band01cm := [20.8,25.8]
  Band07mm := [38.0,51.9];
  print shape(freq);
  Band := array('Unknown', len(freq));
  print shape(Band);
  inband := nBand(freq, Band90cm);
  if(any(inband)){
     Band[ind(inband)[inband]] := '90cm';
  }
  inband := nBand(freq, Band20cm);
  if(any(inband)){
     Band[ind(inband)[inband]] := '20cm';
  }
  inband := nBand(freq, Band06cm);
  if(any(inband)){
     Band[ind(inband)[inband]] := '6cm';
  }
  inband := nBand(freq, Band04cm);
  if(any(inband)){
     Band[ind(inband)[inband]] := '4cm';
  }
  inband := nBand(freq, Band02cm);
  if(any(inband)){
     Band[ind(inband)[inband]] := '2cm';
  }
  inband := nBand(freq, Band01cm);
  if(any(inband)){
     Band[ind(inband)[inband]] := '1cm';
  }
  inband := nBand(freq, Band07mm);
  if(any(inband)){
     Band[ind(inband)[inband]] := '7mm';
  }
  Band::shape := freq::shape
  return Band;
}
nBand := function(freq, bandFreq){
   tt1 := freq >= bandFreq[1];
   tt2 := freq <= bandFreq[2];
   return(tt1==tt2);
}
