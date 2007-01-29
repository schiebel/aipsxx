include 'tables.g';
include 'image.g';
include 'archive/imagecatalog.g';

directory := paste('/home/thuban/AIPS/DA01/vlbasurvey/GSFC/S10');
lst := shell('cd /home/thuban/AIPS/DA01/vlbasurvey/GSFC/S10;ls *.image');
nfiles := shape(lst);;

print "num files = ", nfiles;


for (i in 1:20) {
    imgfile  := spaste (lst[i]);
    fitsfile := spaste(directory, '/');
    fitsfile := spaste(fitsfile, lst[i]);
    img := imagefromfits(imgfile, fitsfile);
    img.done();
#
#    print "files  = ", lst[i], imgfile, i;
#
    imagecatalog(imgfile);
#
    tabledelete(imgfile);
}


