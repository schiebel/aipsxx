# AIPS++ Recipes Repository script recipe template
#
#RECIPE: Script to calibrate Frequency Switched GBT mapping data
#
#CATEGORY: Single Dish
#
#GOALS: Calibrate GBT Frequency Switched Mapping data (RALong, DECLat maps)
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


#SCRIPTNAME: fswitch_maprec.g

#SCRIPT:
d.open('exampleSP')			      #open the desired MS
d.gms()                                       #provide brief summary
d.plotr(304,1)                                #plot the raw(observed) data
                                                #for the first phase of scan
                                                #303. Since no integration
                                                #value is specified, it averages
                                                #all phase 1 data (in this case
                                                #this is all data with CAL ON.
d.calib(304)                                  #this will calibrate scan 304
                                                #according to the way the
                                                #the data were taken (i.e., the
                                                #observing procedure
d.plotc(303)                                  #plot the calibrated data for
                                                #scan 303. Since no integration
                                                #was specified, all data is
                                                #averaged.
d.plotc(303,1)                                #plots the first integration of
                                                #the calibrated data for 303.
d.plotc(303,3,2)                              #plots the third integration of
                                                #the second polarization for
                                                #scan 303.
d.plotc(scan=303,int=3,pol=2);                #same using the explicit names
                                                #for the arguments.
                                              #NOTE: if you are unhappy with 
                                                #the calibration, you can simply
                                                #reapply it using different 
                                                #attributes
d.calib(303,baseline=T,range=[300:600,800:1000]);
                                              #Apply calibration but also
                                                #baseline the data using the
                                                #specified range (defaults
                                                #to first order but this can
                                                #also be specified.
- #This will over-write the calibration data with the new calibration data.
d.plotc(303)                                  #re-examine the data

d.makeim(304,600,900,imname='ralong')         #Make an image. This needs the
                                                #  first scan in the map
                                                #  the beginning (600) and end
                                                #  (900) channels to include.
                                                #  step determines the 
                                                #  averaging over channel 
                                                #  (none here) and imname
                                                #  specifies the output image
m:=image('ralong')                            #Make an image tool - lots of
                                                #functions here!
im.view()                                     #View the image

#OUTPUT:
#output from d.gms();
#Scan     Object   Proctype    SWState   SWtchsig   Procseqn   Procsize
# 303         S6      Track    FSWITCH      FSW01          1          1
# 304     G250p8  RALongMap    FSWITCH      FSW01          1         41
# 
# The MS is written too and now contains the calibration results for the scan.
# An image, ralong, is created on disk.

#CONCLUSION: 
#
#

#SUBMITTER: J. McMullin
#SUBMITAFFL: NRAO-AOC
#SUBMITDATE: 2002-Aug-31
