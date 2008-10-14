# This pulsar, 1929+10, doesn't have much dispersion at 1400 MHz
# so you won't see much difference between the raw and dedispersed profiles.
# The effect on a much weaker but more dispersed pulsar, 1823-13, in
# tbl := table('t17') is much more obvious.

tbl       := table('t17')
chosen_rcvr := 2
data      := tbl.getcol('DATA')
rcvr      := tbl.getcol('RECEIVER_ID') + 1
num_rcvrs := max(rcvr)
subscan   := tbl.getcol('SUBSCAN')
data      := data[,(rcvr == chosen_rcvr & subscan == 1)]

utcstart  := tbl.getcol('UTCSTART')[1] * 86400. / 6.28318531
mjd       := tbl.getcol('UTDATE')[1]
phasetime := tbl.getcol('PHASETIM')[1]
freqres   := tbl.getcol('FREQRES')[1]
ctrfreq   := tbl.getcol('OBSFREQ')[chosen_rcvr]
dispmeas  := tbl.getcol('PSRDM')[1]
rfsideb   := tbl.getcol('RFSIDE')[1]
ifsideb   := tbl.getcol('IFSIDE')[chosen_rcvr]

for (ch in 1:data::shape[1]) {
    avg := sum(data[ch,]) / data::shape[2]
    data[ch,] /:= avg
}

dd.array(data)

fftserv := fftserver()
dm_coef := 0.0041494 * dispmeas
one_over_cf_sq := 1.0e18 / ctrfreq^2
freq_step := freqres
if (rfsideb != ifsideb) freq_step := - freq_step
for (ch in 1:data::shape[1]) {
    ch_offset := as_double(ch - (data::shape[1] / 2) - 1)
    freq := ctrfreq + (freq_step * ch_offset)
    time_shift := dm_coef * ( 1.0e18 / (freq^2) - one_over_cf_sq)
    bin_shift := -time_shift / phasetime
    data[ch,] := fftserv.shift(data[ch,], bin_shift);
}

profile := array(0.0, data::shape[2])
for (bin in 1:data::shape[2]) {
    profile[bin] := sum(data[,bin]) / data::shape[1]
}
dp.ploty(profile, style_='lines')

include 'ptemplates.g'

template := template_1929[chosen_rcvr,[65:128,1:64]]
dp.ploty(template, style_='lines')
cc := fftserv.crosscorr(profile - 1.0, template)
dp.ploty(cc, style_='lines')
# solve for x offset of a y-axis parabola through the three points near
# the peak correlation value.
nch := length(cc)
peak_ch := order(cc)[nch]
if ((ch := peak_ch - 1) < 1) ch := nch
y1 := cc[ch]
y2 := cc[peak_ch]
y3 := cc[(peak_ch % nch) + 1]
k := (y3 + y1 - 2.0 * y2) / 2.0
x0 := (y1 - y3) / (4.0 * k) + peak_ch - 1.0
toa := utcstart + x0 * phasetime
if (toa >= 86400.0) {
    toa -:= 86400.0;
    mjd +:= 1;
}
print 'TOA: MJD', mjd, 'UTC', toa, 'seconds'