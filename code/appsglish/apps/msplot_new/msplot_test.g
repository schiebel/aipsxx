# This script tests the msplot_new tool
# create a msplot tool, set tables and plot amplitude vs uvdist.
# 
# In multiple panel case( when using iterplot ), flagdata() fails!
# In multiple panel case( when using iterplot ), zoomplot() fails!
#
  include 'msplot.g';
# define the control variables
  PLOT_DATA := T;
  ITER_PLOT := F;
  MARK_FLAG := F;
  FLAG_DATA := F;
  ZOOM_PLOT := F;
  CLEAR_FLAG := F;
  msp := msplot( msname=['./data/3C273XC1.ms']);
  #msp.settables(tabnames=['3c273.ms','3c48.ms']);
  #msp := msplot( msname=['./data/ngc7538.ms']);
#
# Plot data
  if( PLOT_DATA ){
     plotopts.nxpanels := 1;      
     plotopts.nypanels := 1; 
     plotopts.plotcolour := 2;
     #plotopts.plotstyle := 1;     
     plotopts.windowsize := 8;    
     plotopts.aspectratio := 0.7; 
     plotopts.fontsize := 2.0; 
##
     ## msp.setdata();  # if failed, falles to next command, i.e. msp.setaxes().
     ## msp.setdata( antennaNames=[ '1', '2', '3', '4' ]); ## works. Input vector<string>
     ## msp.setdata( antennaNames='5 & 6');                ## works.
     ## msp.setdata( antennaNames='5,6,7');                ## works.
     ## msp.setdata( antennaNames='5 & *' );               ## works.
     ## msp.setdata( antennaNames='(5-8) & (9,10)' );      ## works.
     ## msp.setdata( antennaNames='(5-8) & *' );           ## works.
     ## msp.setdata( antennaNames='VLA:N*' );              ## works. 
     ## msp.setdata( antennaNames='5:R & *');              ## works.
     ## msp.setdata( antennaNames='5:R & 7:L');            ## did not work.
     ## msp.setdata( antennaNames='5:R & (3,4,7,8):L');    ## did not work.
     ## msp.setdata( antennaIndex=[1,2,3,4]);              ## works after modifing MsPlot::antennaSelection(). # input vector<int>
     ## msp.setdata( spwNames=['63*'] );                   ## did not work, tried ngc7538.ms. Input vector<string>
     ## msp.setdata( spwIndex=[0,1] );                     ## works for 3C273XC1.ms and ngc7538.ms. Input vector<int>
     ## msp.setdata( spwIndex=[0] );                       ## works for 3C273XC1.ms
     ## msp.setdata( spwNames='(1,2):[16-40]' );                 ## did not work.
     ## msp.setdata( fieldNames=['3C*'] );                 ## works for 3C273XC1.ms. Input vector<string>
     ## msp.setdata( fieldIndex=[0]);                      ## works for 3C273XC1.ms. Index starts from 0!
     ## msp.setdata( fieldNames=['NGC*,1328*'] );          ## works for ngc7538.ms.
     ## msp.setdata( fieldNames=['A'] );                   ## works for ngc7538.ms. select all fields with CODE='A'.
     ## msp.setdata( fieldIndex= [0-3] );                  ## did not work.
     ## msp.setdata( fieldNames=['>3'] );                  ## did not work.
     ## msp.setdata( fieldIndex=[0,1,3] );                 ## works for ngc7538.ms
     ## msp.setdata( uvDists=['>0l'] );                    ## works.
     ## msp.setdata( uvDists=['>25kl'] );                  ## works.
     ## msp.setdata( uvDists=['<25kl'] );                  ## works.
     ## msp.setdata( uvDists=['10-25kl'] );                ## works.
     ## msp.setdata( uvDists=['25kl:5%'] );                ## works.
     ## msp.setdata( uvDists=['0.02Ml:5%'] );              ## did not work.
     ## msp.setdata( times=['1989/06/27/03:31:40'] );      ## did not work. type mismatch!
     ## msp.setdata( correlations=[ 'RL'] );               ## works for 3C273XC1.ms. only works for RR, RL, LR, LL.
     ## msp.setdata( correlations=[ 'RR'] );               ## only works for RR, RL, LR, LL.
     ## next statement tested working.
     ## msp.setdata( antennaNames=[''], antennaIndex=[-1], spwNames=[''], spwIndex=[0],fieldNames=['3C273'], fieldIndex=[0],uvDists=[''],times=[''],correlations=['RR'] )

##
     labels := ['Amplitude vs UVdist','uvdist','amplitude'];
     ## labels := ['Amplitude vs UVdist ( antenna 5 & 6 only )','uvdist','amplitude'];
     ## labels := ['Amplitude vs Time','time','amplitude'];
     ## labels := ['Amplitude vs Antenna1','Antenna1','amplitude'];
     msp.setlabels( poption=plotopts, labels=labels );
     ##msp.setaxes( xAxes='SQRT(SUMSQUARE(UVW[1:2]))',yAxes='AMPLITUDE(DATA[1:2,1])');   # works for 3C273XC1.ms
     ##msp.setaxes( xAxes='SQRT(SUMSQUARE(UVW[1:2]))',yAxes='AMPLITUDE(DATA[1,1])');   # works for 3C273XC1.ms
## switched the x and y coordinates
     ##msp.setaxes( xAxes='AMPLITUDE(DATA[1,1])',yAxes='SQRT(SUMSQUARE(UVW[1:2]))');   # works for 3C273XC1.ms
## when leaving the indices for DATA[,] empty, all the polarization( first index ) and channels( second index ) will be used!
     ##msp.setaxes( xAxes='SQRT(SUMSQUARE(UVW[1:2]))',yAxes='AMPLITUDE(DATA[,])');       # works for 3C273XC1.ms
     ##msp.setaxes( xAxes='SQRT(SUMSQUARE(UVW[1:2]))',yAxes='AMPLITUDE(DATA[1,1])');   # works for 3C273XC1.ms
     ##msp.setaxes( xAxes='SQRT(SUMSQUARE(UVW[1:2]))',yAxes='AMPLITUDE(DATA[1,1])');   # works for ngc7538.ms
     ##msp.setaxes( xAxes='SQRT(SUMSQUARE(UVW[1:2]))',yAxes='PHASE(DATA[1:2,1])');     # works for 3C273XC1.ms
     ##msp.setaxes( xAxes='ANTENNA1',yAxes='AMPLITUDE(DATA[1:2,1])');                  # works for 3C273XC1.ms
     ##msp.setaxes( xAxes='ANTENNA2',yAxes='AMPLITUDE(DATA[1:2,1])');                  # works for 3C273XC1.ms
     baseline := 'ANTENNA2*(ANTENNA2-1)/2+ANTENNA1+1';
     msp.setaxes( xAxes=baseline,yAxes='AMPLITUDE(DATA[1:2,1])');                  # works for 3C273XC1.ms
     ##msp.setaxes( xAxes='ANTENNA1+ANTENNA2',yAxes='AMPLITUDE(DATA[1:2,1])');         # works for 3C273XC1.ms
     ##msp.setaxes( xAxes='FIELD_ID',yAxes='AMPLITUDE(DATA[1,1])');                    # works for ngc7538.ms
     ##msp.setaxes( xAxes='TIME',yAxes='AMPLITUDE(DATA[1:2,1])');                      # works for 3C273XC1.ms
#
     msp.plot();
   }
# iterplotstart()--iterplotnext()--iterplotstop()
  if( ITER_PLOT ){
     plotopts.nxpanels := 1;
     plotopts.nypanels := 3;
     plotopts.windowsize := 8;    
     plotopts.aspectratio := 0.8; 
     plotopts.fontsize := 3.0;  
     msp.setdata( fieldNames=['3C273'] );                 ## works. Input vector<string>  
     labels := ['Amplitude vs UVdist (iterating over Antenna1)','uvdist','amplitude'];
     xystr := ['SQRT(SUMSQUARE(UVW[1:2]))','AMPLITUDE(DATA[1,1])'];
     iteraxes := ['ANTENNA1'];
     msp.iterplotstart(poption=plotopts,labels=labels,datastr=xystr,iteraxes=iteraxes);
     ## interplotstart() calls iterplotnext() once already!
     ret := msp.iterplotnext();
     ret := msp.iterplotnext();
     msp.iterplotstop();
  }

# Mark flag
  if( MARK_FLAG ){
     msp.markflags(panel=1);
     #msp.markflags(panel=2);
  }
# Perform flagging
  if( FLAG_DATA ){
     msp.flagdata(diskwrite=1,rowflag=0);
  }
# Zoom data
  if( ZOOM_PLOT ){
     msp.zoomplot(panel=1,direction=1);
     #msp.zoomplot(panel=1,direction=0);
  }
# Clear all flags
  if( CLEAR_FLAG ){
     msp := msplot( msname=['./data/3C273XC1.ms']);
     ##msp.setdata( fieldIndex=[0] );
     msp.clearflags();
     #msp.done();
  }

#  msp.done();
#