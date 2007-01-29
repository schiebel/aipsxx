
include 'ionosphere.g'

# pimsurvey: example function for using PIM to model the ionosphere.
# Usage: pimsurvey(observatory_name,year)
# E.g.:  pimsurvey('WSRT',1988)
#
# Results are written to file observatory_name.year.log
#
pimsurvey := function( observatory='WSRT',year=1988 ) {

# set up observatory position, make sure it's converted to ITRF
pos := [=]
pos[1] := dm.measure( dm.observatory(observatory),'itrf' )

# set up second position (at other end of baseline)
baseline := 300000     # meters
pos[2] := pos[1]
    # an offset to longtitude, in radians, is just baseline/radius
pos[2].m0.value := pos[2].m0.value + baseline/pos[2].m2.value

# set up the two epochs
ep := [=]
date := spaste('22jul',as_string(year))
# offset for utc -> local time ( = - longtitude / 2pi )
offset := -pos[1].m0.value/(2*pi)
ep[1] := dm.epoch('utc',spaste(date,'/0:00'))
ep[2] := dm.epoch('utc',spaste(date,'/12:00'))
ep[1].m0.value := ep[1].m0.value+offset
ep[2].m0.value := ep[2].m0.value+offset
ep_labels := [ 'local midnight','local midday' ]

# set up arrays of interesting elevations and azimuths
azimuths := [ 90,135,180,225,270 ]
elevations := [ 20,40,60,80 ]

# put together the slants record
slants := [=]
isl := 1
for( iep in 1:2 ) {
  for( el in elevations ) {
    for( az in azimuths ) {
      qel1 := dq.quantity(el+5,'deg')
      qel2 := dq.quantity(el-5,'deg')
      qaz  := dq.quantity(az,'deg')
      dir1 := dm.direction('azel',qaz,qel1)
      dir2 := dm.direction('azel',qaz,qel2)
      for( ipos in 1:2 ) {
        slants[isl]   := diono.slant( ep[iep],pos[ipos],dir1 )
        slants[isl+1] := diono.slant( ep[iep],pos[ipos],dir2 )
        isl +:= 2
      }
    }
  }
}

# run the computations
edp := diono.compute( slants,tec,rmi )

# set frequency [GHz]
freq := .075 

# compute FR at given frequency [in GHz]
fr := rmi/(freq^2)

# compute phase delay, in cycles
phdel := 1.344536*tec/freq
# And here is phase delay in nanoseconds:
# phdel_ns := 1.344536*tec/(freq^2)

# open file for writing stats
filename := spaste(">","pim.",observatory,".",as_string(year))
flog := open(filename)
print 'Dumping stats to file',filename
# collect min/max statistics
isl := 1
fprintf(flog,'Observatory: %s   Baseline: %d km   Frequency: %d MHz\n',
      observatory,baseline/1000,freq*1000)
for( iep in 1:2 ) {
  label := ep_labels[iep]
  fprintf(flog,'-------------- %s %s\n',date,label)
  printf('-------------- %s %s\n',date,label)
  fprintf(flog,'%2s%4s%8s%8s%7s%7s%7s%8s%8s%7s%7s\n',
      'EL','AZ','min FR','max FR','DFR','DFRb','DFRp','min PD','max PD','DPDb','DPDp')
  for( el in elevations ) {
    for( az in azimuths ) {
      # four slants per sample (two locations by +- 5 deg elevation)
      # index[1:2] is +- 5 deg at first location
      # index[3:4] is +- 5 deg at second location
      index := isl:(isl+3)
      isl +:= 4

      # compute stats for FR
      f := fr[index]
      # min/max overall
      minfr := min( f )
      maxfr := max( f )
      # variation of FR across beam
      dfrpos  := max( abs( f[[1,2]] - f[[3,4]] ) )
      # variation of FR between locations
      dfrbeam := max( abs( f[[1,3]] - f[[2,4]] ) )

      # compute same stats for phase delay
      pd := phdel[index]
      minpd := min( pd )
      maxpd := max( pd )
      dpdpos  := max( abs( pd[[1,2]] - pd[[3,4]] ) )
      dpdbeam := max( abs( pd[[1,3]] - pd[[2,4]] ) )
      
      # print results
      fprintf(flog,'%2.0f%4.0f%8.2f%8.2f%7.2f%7.2f%7.2f%8.1f%8.1f%7.2f%7.2f\n', \
          el,az,minfr,maxfr,maxfr-minfr,dfrbeam,dfrpos, \
          minpd,maxpd,dpdbeam,dpdpos)
    }
  }
}

return rmi
}
