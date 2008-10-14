#-----------------------imager-ss433.g------------------------------
#
# Image ss433 from the UVFITS files
#
include 'general.g'					# include general script
include 'imager.g'				# Include imager script 


dowait:=T

					# Tell the Object system to
                                                # wait for a method to finish

#Make a MeasurementSet from a UVFITS file using the fitstoms constructor of
#ms. Remember to close the ms object.
m:=fitstoms('ss433.ms', 'ss433u0383.uvfits'); 

m.close()	

imgr:=imager('ss433.ms')			# Make an imager tool from
                                                # the MeasurementSet
for (i in [1,2]) { 				# Loop over both Spectral windows

  imgr.setimage(cellx='0.05arcsec', celly='0.05arcsec', nx=128, ny=128, 
		stokes='I', spwid=i, fieldid=1)	# Set the image properties. 
  imgr.setdata(spwid=i, mode="none")		# Select the data 
  imgr.summary()                                # Show state of imgr
  imgr.plotvis()				# Plot the visibility data
  model:=spaste('ss433.clean',i)		# Make the name of the model image
  restored:=spaste('ss433.clean', i, '.restored')
                                                # Make the name of the restored image
residual:=spaste('ss433.clean', i, '.residual')
                                                # Make a name for residual image
  bmaj:=F; bmin:=F; bpa:=F;			# Set up some return variables
  imgr.image('psf', spaste('ss433.psf', i))	# Make the PSF
  imgr.fitpsf(spaste('ss433.psf', i), bmaj, bmin, bpa);
                                                # Fit the beam size
  print "Beam parameters ", "bmaj= ", bmaj, "bmin= ", bmin, "bpa= ", bpa;
                                          	# Print out the beam size
  imgr.clean(algorithm='hogbom', model=model, gain=0.1,
	     niter=1000, threshold='0.2mJy', image=restored,
              residual=residual)	
                                                # Do 1000 Clean iterations of the Hogbom 
						# algorithm, stopping at the 0.2mJy level. 
                                           	# 


  myim:=image(restored)				# Creating imagetool for image
  myim.view()    				# Display the restored image
  timer.wait(20)				#wait for 20 seconds
  myim.done()                                   #closing imagetool.

}						# End the loop over spectral windows
imgr.close()	# Close the imager object
imgr.done()	#
dowait:=F	# Tell the Object system not to wait for a method to finish
