# AIPS++ Recipes Repository script recipe template
#
#RECIPE: Script to calibrate Position Switched GBT data with specified refs
#
#CATEGORY: Single Dish
#
#GOALS: Calibrate a GBT Position Switched scan
#
#USING: dish tool
#
#RESULTS: AIPS++ MeasurementSet has the calibration results written to it.
#
#ASSUME: There is a dish tool running (d). GBT data is a M&C v3.6, FITS v.x, 
filler v.x
#
#SYNOPSIS:
# First open AIPS++ MS. Review the contents, calibrate  and display the data.
#


#SCRIPTNAME: pswitch2_rec.g

#SCRIPT:

d.open('exampleSP')			      #open the desired MS
d.gms()                                       #provide brief summary

d.plotr(39,1)                                 #plot the raw(observed) data
                                                #for the first phase of scan
                                                #38. Since no integration
                                                #value is specified, it averages
                                                #all phase 1 data (in this case
                                                #this is all data with CAL ON.
d.calib(39)                                   #this will calibrate scan 38/39
                                                #(since both compose the 
                                                #the OffOn procedure), 
                                                #according to the way the
                                                #the data were taken (i.e., the
                                                #observing procedure
d.plotc(39)                                   #plot the calibrated data for
                                                #scan 39. Since no integration
                                                #was specified, all data is
                                                #averaged.
                                                #The (sig-ref)/ref data is 
                                                #only stored in the 'On' scans
                                                #data record; the 'Off' scan
                                                #contains only the calibrated
                                                #TPwCal data.
d.plotc(39,1)                                 #plots the first integration of
                                                #the calibrated data for 39.
d.plotc(39,3,2)                               #plots the third integration of
                                                #the second polarization for
                                                #scan 39.
d.plotc(scan=39,int=3,pol=2)                  #same using the explicit names
                                                #for the arguments.

                                                #Now, if you wanted to use a 
                                                #different reference scan for 
                                                #this on, you could do the 
                                                #following:
d.TPcal(41)                                     #calibrate 'Off' scan 41.
d.SRcal(39,41)                                  #perform (sig-ref)/ref with
                                                #signal=39, reference=41
d.SRcal(39,[38,41]);                            #perform (sig-ref)/ref with
                                                #signal scan=39, reference=
                                                #the average of 38 and 41.
                                                #in general:
#d.SRcal([vector of signal scans],
#         [vector of reference scans])           #all reference scans will be
#                                                #averaged and subtracted from
#                                                #each signal scan.
#
#OUTPUT:
#output from d.gms();
#Scan     Object   Proctype    SWState   SWtchsig   Procseqn   Procsize
#  35         S8      Track    FSWITCH      FSW01          1          1
#  36         S8      Track    FSWITCH      FSW12          1          1
#  37         S8      Track    FSWITCH      FSW12          1          1
#  38         S8      OffOn PSWITCHOFF   TPWCALSP          1          2
#  40         S8      OnOff  PSWITCHON   TPWCALSP          1          2
#  42         S8      Track       NONE   TPWCALSP          1          1
# 
# The MS is written to and now contains the calibration results for the scan.

#CONCLUSION: 
#
#

#SUBMITTER: J. McMullin
#SUBMITAFFL: NRAO-AOC
#SUBMITDATE: 2002-Aug-31
