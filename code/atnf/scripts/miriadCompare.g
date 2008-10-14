#
# ATCA Calibration test script
# Tara Murphy 
# 
# Functions to compare Miriad gains and leakages 
# with AIPS++ ones.
# 

include 'table.g'
include 'os.g'

const compare_gains := function(tabG, mirfilename){
  aips := table(tabG)
  if(is_fail(aips)) fail

  global a := [=]
  a.time := aips.getcol('TIME')
  a.ant := aips.getcol('ANTENNA1')
  a.gains := aips.getcol('GAIN')
  a.ampgain := abs(a.gains)
  aips.done()

  a.axx := a.ampgain[1,1,,,]
  a.ayy := a.ampgain[2,2,,,]

  mir := open(spaste('< ', mirfilename))
  if(is_fail(mir)) fail

  global m := [=]
  m.time := ['']
  m.axx := []
  m.ayy := []
  m.ant := []
  n := 1
  nant := 6

  while(line := read(mir)){
    cols := split(line)
    m.time[n] := cols[1]
    m.ant[n] := as_integer(cols[2]) + 1
    m.axx[n] := as_double(cols[3])
    m.ayy[n] := as_double(cols[4])
    n +:= 1
  }

  if(len(a.axx) != len(m.axx) || len(a.ayy) != len(m.ayy)){
    print '## Error: Miriad and AIPS++ arrays are not the same length'
    print len(a.axx), len(m.axx), len(a.ayy), len(m.ayy)
    return F
  }

  for(i in 1:nant){
    m.diffxx[i] := 0
    m.diffyy[i] := 0
    m.nxx[i] := 0
    m.nyy[i] := 0
  }

  for(i in 1:len(a.axx)){
    ant := m.ant[i] 
    m.diffxx[ant] +:= abs(m.axx[i] - a.axx[i])
    m.diffyy[ant] +:= abs(m.ayy[i] - a.ayy[i])
    m.nxx[ant] +:= 1
    m.nyy[ant] +:= 1
  }

  print '## Ant   av-abs-diff'
  for(i in 1:nant){
    xxdiff := m.diffxx[i] / m.nxx[i]
    yydiff := m.diffyy[i] / m.nyy[i]

    printf('## XX %d %7.4f\n', i, xxdiff)
    printf('## YY %d %7.4f\n', i, yydiff)

    if(xxdiff > 0.2|| yydiff > 0.2)
      return F
  }
  return T
}


const compare_leakages := function(tabD, mirfilename){
  aips := table(tabD)
  if(is_fail(aips)) fail

  global a := [=]
  a.ant := aips.getcol('ANTENNA1')
  a.gains := aips.getcol('GAIN')
  a.ampgain := abs(a.gains)
  a.phasegain := arg(a.gains)
  aips.done()

  a.ax := a.ampgain[1,2,,,]
  a.ay := a.ampgain[2,1,,,]

# size of old arrays (stable)
#  a.ax := a.ampgain[1,2,,]
#  a.ay := a.ampgain[2,1,,]

  mir := open(spaste('< ', mirfilename))
  if(is_fail(mir)) fail

  global m := [=]
  m.ax := []
  m.ay := []
  n := 1
  while(line := read(mir)){
    cols := split(line)
    m.ax[n] := as_double(cols[2])
    m.ay[n] := as_double(cols[3])
    n +:= 1
  }

  nant := n-1

  print '## Ant  Miriad  AIPS++  |diff|'
  for(i in 1:nant){
    xdiff := abs(m.ax[i]-a.ax[i])
    ydiff := abs(m.ay[i]-a.ay[i])

    printf('## X %d %7.4f %7.4f %8.5f\n', i, m.ax[i], a.ax[i], xdiff)
    printf('## Y %d %7.4f %7.4f %8.5f\n', i, m.ay[i], a.ay[i], ydiff)

    if(xdiff > 0.002 || ydiff > 0.002 || a.ax[i] > 0.05 || a.ay[i] > 0.05)
      return F
  }
  return T
}




