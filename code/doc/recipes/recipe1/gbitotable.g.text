
tablefromascii('ss433table','1909+048', 'gbihdr')
ss433 := table('ss433table')
ss433.getkeywords()
mjd := ss433.getcol('MJD')
Ss := ss433.getcol('SS') 
Sx := ss433.getcol('SX') 
plot := pgplotter()
xmin := min(mjd)
xmax := max(mjd)
ymin := 0
ymax := max(Ss)*1.05
plot.env(xmin,xmax,ymin,ymax,0,1)
plot.sci(red)
plot.line(mjd,Ss)
plot.sci(blue)
plot.line(mjd,Sx)