#RECIPE: Multi-scale deconvolution using deconvolver tool
#
#CATEGORY: Synthesis
#
#GOALS: Perform simplest form of multi-scale deconvolution
#
#USING: image deconvolver
#
#RESULTS: Deconvolved image, restored image, residual image
#
#ASSUME: Data files N1058.IMAP.fits and N1058.IPSF.fits exist in the 
#data respository
#
#SYNOPSIS:
# The dirty image and point spread function are loaded from FITS files
# in the data respository. A deconvolver tool is constructed. The scale
# sizes for the CLEAN blobs are then set (this takes a while because it is
# pre-computing a number of convolutions). Then the CLEAN is done. Note that
# a large loop gain is possible. Finally the restored ans residual images
# are made.
#

#SCRIPTNAME: msclean.g

#SCRIPT:

include 'sysinfo.g';
aipsroot := sysinfo().root(); # Locate AIPS++ root directory

include 'image.g';
im1:=imagefromfits('n1058.dirty',  # Get dirty image from repository
		   spaste(aipsroot, '/data/demo/N1058.IMAP.fits'))
im1.done();
im2:=imagefromfits('n1058.psf',    # Get PSF from repository
		   spaste(aipsroot, '/data/demo/N1058.IPSF.fits'));
im2.done();

include 'deconvolver.g';
mydeconvolver:=deconvolver(dirtyname="n1058.dirty" , # Make a deconvolver tool
			   psfname="n1058.psf" ); 
ok:=mydeconvolver.setscales(scalemethod="uservector" ,	# Set the scale sizes
			    uservector=[0.0, 3.0, 10.0, 30.0] );
mydeconvolver.clean(algorithm="msclean",niter=1000,gain=1, # Do deconvolution
	    threshold='2mJy',displayprogress=T,model="n1058.msclean", mask='');
mydeconvolver.restore(model="n1058.msclean" , image="n1058.msclean.restored"); # Restore
mydeconvolver.residual(model="n1058.msclean" , image="n1058.msclean.residual" ); # Find residuals
mydeconvolver.done(); # Done the tool

#OUTPUT:
# n1058.msclean: CLEAN raw image
# n1058.msclean.restored: CLEAN restored image
# n1058.msclean.residual: CLEAN residual image
# 
# 

#CONCLUSION: Note that the CLEAN residuals are very low and close to the 
# noise level.
#
#

#SUBMITTER: Tim Cornwell
#SUBMITAFFL: NRAO
#SUBMITDATE: 2001-02-08
