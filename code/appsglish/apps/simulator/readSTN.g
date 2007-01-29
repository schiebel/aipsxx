
readSTN:=function(stnfile) {

  f:=open(spaste('< ', stnfile));
  line:=read(f); nstations:=as_float(line);
  line:=read(f);
  line:=read(f);
  xx := array(0, nstations);
  yy := array(0, nstations);
  zz := array(0, nstations);
  diam := array(0, nstations);
  for (i in 1:nstations) {
    line:=read(f);
    parts:=split(line);
    xx[i]:=as_float(parts[2]);
    yy[i]:=as_float(parts[3]);
    diam[i]:=as_float(parts[5]);
  }
  f:=F;
  return [xx=xx, yy=yy, zz=zz, diam=diam];
}
