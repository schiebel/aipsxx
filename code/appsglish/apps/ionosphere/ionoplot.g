include 'logger.g'
include 'ionosphere.g'
include 'pgplotter.g'

ionoplot := function ( az,el,date='1988/07/22/12:00',obs='WSRT' ) {
  az := spaste(az,'deg');
  el := spaste(el,'deg');
  title := paste(obs,date,'Az =',az,'El =',el);
  rec := [ sl1 = diono.slant(date,obs,[az,el]) ];
  print rec;
  fq := '75Mhz';
  fq2 := dq.mul(fq,fq);
  # fix:=[bz=-1,ap=1];
  diono.compute(rec,tec=tec1,rmi=rmi1,emf=emf,alt=alt,edp=edp1,opt=[bz=1,by=1]);
  M := (alt.value < 1000);
  fr := dq.convert(dq.div(rmi1,fq2),'deg').value
  lab := sprintf('IMF Bz N, By 1 (Ap=4): TEC=%5.1f   RMI=%4.1f',tec1.value,rmi1.value);

  pg := pgplotter();
  pg.plotxy1(alt.value[M],edp1.value[1,M],xlab='Altitude, km',ylab=lab,tlab=title);
  pg.plotxy2(alt.value[M],emf.value[1,M],ylab='Bpar, Gauss')

#  diono.compute(rec,tec=tec1,rmi=rmi1,edp=edp1,opt=[bz=1,by=-1]);
#  M := (alt.value < 1000);
#  lab := sprintf('IMF Bz N, By -1 (Ap=4): TEC=%5.1f   RMI=%4.1f',tec1.value,rmi1.value);
#  pg.plotxy1(alt.value[M],edp1.value[1,M],xlab='Altitude, km',ylab=lab,tlab=title);

  aps := [ 10,50,100,200 ];

  for( ap in aps ) {
    diono.compute(rec,tec=tec2,rmi=rmi2,edp=edp2,opt=[bz=-1,ap=ap]);
    lab := sprintf('IMF Bz S, Ap=%d: TEC=%5.1f   RMI=%4.1f',ap,tec2.value,rmi2.value);
    print lab;
    pg.plotxy1(alt.value[M],edp2.value[1,M],ylab=lab);
  }
}

ionoplot_time := function ( az,el,date='1988/07/22',obs='WSRT' ) {
  az := spaste(az,'deg');
  el := spaste(el,'deg');
  pos := dm.observatory(obs)
  
  dt := dm.epoch('utc',spaste(date,'/','0:00'))
  offset := -pos.m0.value/(2*pi)
  dt.m0.value +:= offset

  fq := '75MHz';
  fq2 := dq.mul(fq,fq);
  
  title := paste(obs,date,'Az =',az,'El =',el);
  rec := [ sl1 = diono.slant(dt,pos,[az,el]) ];
  # fix:=[bz=-1,ap=1];
  diono.compute(rec,tec=tec1,rmi=rmi1,emf=emf,alt=alt,edp=edp1);
  fr := dq.convert(dq.div(rmi1,fq2),'deg').value
  M := (alt.value < 1000);
  lab := sprintf('0:00: TEC=%5.1f  FR=%4ddeg @%s',tec1.value,fr,fq);

  pg := pgplotter();
#  pg.setxaxislabel('Electron content')
#  pg.setyaxislabel('Altitude, km')
  pg.plotxy1(edp1.value[1,M],alt.value[M],ylab=lab,xlab='Electron density',tlab=title);
  pg.plotxy2(emf.value[1,M],alt.value[M],ylab='Bpar, Gauss',tlab=title)

#  diono.compute(rec,tec=tec1,rmi=rmi1,edp=edp1,opt=[bz=1,by=-1]);
#  M := (alt.value < 1000);
#  lab := sprintf('IMF Bz N, By -1 (Ap=4): TEC=%5.1f   RMI=%4.1f',tec1.value,rmi1.value);
#  pg.plotxy1(alt.value[M],edp1.value[1,M],xlab='Altitude, km',ylab=lab,tlab=title);

  times := [ '6:00','12:00','18:00' ];

  for( tt in times ) {
    dt := dm.epoch('utc',spaste(date,'/',tt))
    dt.m0.value +:= offset
    rec := [ sl1 = diono.slant(dt,pos,[az,el]) ]
    diono.compute(rec,tec=tec2,rmi=rmi2,edp=edp2);
    fr := dq.convert(dq.div(rmi2,fq2),'deg').value
    lab := sprintf('%s: TEC=%5.1f   FR=%4ddeg @%s',tt,tec2.value,fr,fq);
    print lab
    print rmi2
    pg.plotxy1(edp2.value[1,M],alt.value[M],xlab=lab,ylab=lab);
  }
}

ionoplot_time( 90,60,obs='VLA',date='1994/07/22' );
