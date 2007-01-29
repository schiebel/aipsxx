include 'table.g'

fixpnt := function(msname) {
  maintab := table(msname);
  ftab := table(maintab.getkeyword('FEED'), readonly=F);
  #fix polarization type to which receiver responds (R, L, X, or Y).
  pt := ftab.getcol('POLARIZATION_TYPE');
  pt[1:length(pt)]:='R';
  ftab.putcol('POLARIZATION_TYPE', pt);
  ftab.flush();
  ftab.done();
  
  ptab := table(maintab.getkeyword('POLARIZATION'), readonly=F);
  ct := ptab.getcol('CORR_TYPE');
  #fix correlation type based on Stokes class
  #5=RR
  ct[,]:=5;
  ptab.putcol('CORR_TYPE', ct);
  ptab.flush();
  ptab.done();
  
  ftab := table(maintab.getkeyword( 'SPECTRAL_WINDOW'), readonly=F);
  f := ftab.getcol('CHAN_FREQ');
  f[,]:=790000000.0;
  print ftab.putcol('CHAN_FREQ', f);
  f := ftab.getcol('REF_FREQUENCY');
  f:=array(790000000.0, length(f));
  print ftab.putcol('REF_FREQUENCY', f);
  for (col in "RESOLUTION CHAN_WIDTH EFFECTIVE_BW") {
    r := ftab.getcol(col);
    #puzzling at first - sets all values of r equal to 1000000.0
    r[r==r]:=1000000.0;
    print ftab.putcol(col, r);
  }
  ftab.flush();
  ftab.done();

  maintab.done();
  
  
  note(msname,' has been fixed for filler errors');
  
}
