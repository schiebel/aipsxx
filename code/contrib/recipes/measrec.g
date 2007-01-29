#
#RECIPE: Coordinate conversions in aips++ measures
#
#CATEGORY: General
#
#GOALS: Express and convert among coordinate systems
#
#USING: measures tool, quanta tool, misc tool
#
#RESULTS: listings of initial converted coordinates
#
#ASSUME: 
#
#SYNOPSIS:
# Via the measures tool, aips++ provides a very powerful mechanism for
# expressing and converting among coordinate systems.  Time, position,
# direction, frequency, and other coordinate reference frames are
# supported.  This example determines the azimuth and elevation of
# a celestial object at a location on earth at a specific time.
#

#SCRIPTNAME: measrec.g

#SCRIPT:

include 'measures.g'                     # initialize measures (dm) tool
include 'misc.g'                         # initialize misc (dms) tool


print 'Epoch measures:';
print '***************';
misctim:=dm.epoch(rf='utc',              # get an epoch at some date/time
                  v0='2002/01/05/12:35:00');
dms.listfields(rec=misctim);             # report as record

tim:=dm.epoch(rf='utc',                  # Get epoch (now!) and report neatly
              v0='today');
print 'Time = ',dq.time(v=dm.getvalue(v=tim),
                        form='ymd'),
                dm.getref(tim);


print ' ';
print 'Direction (toward the sky) measures:';
print '***********************************';
miscdir:=dm.direction(rf='J2000',        # A misc direction on the sky
                      v0='18h30m15.0s',
                      v1='-30d14m23.0s');
dms.listfields(rec=miscdir);             # report as record

srcdir:=dm.source(name='0234+285')       # retrieve cataloged direction to the
                                         #  quasar '0234+285' and report neatly
print '0234+285: ref=',dm.getref(v=srcdir);
print '          RA =',dq.angle(v=dm.getvalue(v=srcdir)[1],
                                form='time');
print '          Dec=',dq.angle(v=dm.getvalue(v=srcdir)[2],
                                form='dig2');

srcdir:=dm.measure(v=srcdir,             # convert to Galactic Coords and
                   rf='GALAC');          #  report neatly
print '0234+285: ref =',dm.getref(v=srcdir);
print '          Long=',dq.angle(v=dm.getvalue(v=srcdir)[1]);
print '          Lat =',dq.angle(v=dm.getvalue(v=srcdir)[2],
                                form='dig2');


print ' ';
print 'Position (on the earth) measures:';
print '*********************************';
miscpos:=dm.position(rf='WGS84',         # A misc WGS84 (geodetic) position
                     v0='70deg',         #  at 70deg longitude
                     v1='40deg',         #     40deg latitude
                     v2='100m');         #     100m above geoid
dms.listfields(rec=miscpos);             # report as record

vlapos:=dm.observatory(name='VLA');      # retrieve cataloged VLA center
                                         #  position (ITRF) 
vlapos:=dm.measure(v=vlapos,             # convert to WGS84 (geodetic)
                   rf='WGS84');

print 'VLA: ref =',dm.getref(v=vlapos);  # report position neatly
print '     Long=',dq.angle(v=dm.getvalue(v=vlapos)[1]);
print '     Lat =',dq.angle(v=dm.getvalue(v=vlapos)[2],
                            form='dig2');
print '     Alt =',dq.form.len(v=dm.getvalue(v=vlapos)[3]);



dm.doframe(v=vlapos);                    # set frame position to that of VLA
dm.doframe(v=tim);                       # set frame time to right now

AZEL:=dm.measure(v=srcdir,               # convert source direction to
                 rf='AZEL');             #  AZEL at time/position of frame
dms.listfields(rec=AZEL);                # report as record

AZ:=dq.convert(v=dm.getvalue(v=AZEL)[1], # extract AZ and convert to deg
               out='deg'); 
EL:=dq.convert(v=dm.getvalue(v=AZEL)[2], # extract EL and convert to deg
               out='deg'); 

dq.setformat(t='unit',                   # make deg default units for
             v='deg');                   #  formatting output of angles

print 'AZ =', dq.form.unit(v=AZ);        # neatly report AZ and EL
print 'EL =', dq.form.unit(v=EL);



#OUTPUT:
# 
# Epoch measures:
# ***************
#   type = epoch
#   refer = UTC
#   m0
#     value = 52279.5243
#     unit = d
# Time =  2002/01/25/23:31:51.386 UTC
#  
# Direction (toward the sky) measures:
# ***********************************
#   type = direction
#   refer = J2000
#   m1
#     value = -0.527782718
#     unit = rad
#   m0
#     unit = rad
#     value = -1.4388058
# 0234+285: ref= J2000
#           RA = 02:37:52.405
#           Dec= +28.48.08.984
# 0234+285: ref = GALACTIC
#           Long= +149.27.57.443
#           Lat = -28.31.41.738
#  
# Position (on the earth) measures:
# *********************************
#   type = position
#   refer = WGS84
#   m2
#     value = 100
#     unit = m
#   m1
#     unit = rad
#     value = 0.698131701
#   m0
#     unit = rad
#     value = 1.22173048
# VLA: ref = WGS84
#      Long= -107.37.06.001
#      Lat = +34.04.43.728
#      Alt = 2114.89023 m
#   type = direction
#   refer = AZEL
#   m1
#     value = 1.13028076
#     unit = rad
#   m0
#     unit = rad
#     value = 1.63461364
# AZ = 93.6564626 deg
# EL = 64.7603171 deg

#SUBMITTER: George Moellenbrock
#SUBMITAFFL: NRAO-Socorro
#SUBMITDATE: 2002-Jan-25
