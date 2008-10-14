#
pragma include once;
#
include 'table.g';
include 'archive/read_obs_file.g';
#
lst := shell('cd /home/banshee/observe/obsArchive;ls *.OBS');
nfiles := shape(lst);
#
print "num obs files in directory= ", nfiles;    
#
#tbl := table('OBSCATALOG.obsfiles');
#filenames := tbl.getcol('FILENAME');
#n_entries := len(filenames);
#
#print "num obs files in catalog  = ", n_entries;
#
#
for (i in 1:nfiles) {
    obsArchFile := spaste(lst[i]);
    ifound := 0;
#    for (j in 1:n_entries) {
#        if (obsArchFile == filenames[j]) {
#           ifound := 1;
#           break;
#        }
#    }
    if (ifound == 0) {
       read_obs_file(obsfile=obsArchFile);
    }
}
