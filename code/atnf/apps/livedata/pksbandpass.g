#-----------------------------------------------------------------------------
# pksbandpass.g: Controller for Parkes multibeam bandpass calibration.
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2006
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: pksbandpass.g,v 19.25 2006/06/23 05:03:10 mcalabre Exp $
#-----------------------------------------------------------------------------
# -------------------------------------------------------------------- <USAGE>
# Handler and optional GUI for Parkes multibeam bandpass calibration.
#
# Arguments:
#    config            string   'DEFAULTS', 'GENERAL', 'CONTINUUM', 'GASS',
#                               'HIPASS', 'HVC', 'METHANOL', 'ZOA', 'MOPRA',
#                               or 'AUDS'.
#    client_dir        string   Directory containing client executable.  May
#                               be blank to use PATH.
#    nbeams            int      Number of beams present in data.
#    nifs              int      Number of IFs present in data; maximum two,
#                               each with the same number of channels and
#                               polarizations.
#    npols             int      Number of polarizations in input data.
#    nchans            int      Number of spectral channels in input data.
#    smoothing         string   Smoothing function, 'TUKEY', 'HANNING' or
#                               'NONE'.
#    prescale_mode     string   Method of prescaling spectra before averaging,
#                               'NONE', 'MEAN', or 'MEDIAN'.
#    method            string   Bandpass correction method
#                                   COMPACT: Scanned - compact source,
#                                  EXTENDED: Scanned - extended source, load
#                                            the whole scan before correcting,
#                                        MX: MX mode,
#                                      SCMX: Scanned MX mode,
#                                    FREQSW: Frequency-switched mode,
#                                REFERENCED: Scanned, referenced data (Mopra).
#    estimator         string   Statistical estimator used for averaging the
#                               spectra, 'MEDIAN', 'MEAN', 'RFIMED',
#                               'POLYFIT', 'MEDMED', 'MINMED', or 'NONE'.
#
#                               Mask broadening parameters:
#    chan_growmin      double   Grow each region in the channel mask by one on
#                               each side if it contains this many elements...
#    chan_growadd      double   ... and by a further one on each side for
#                               every additional number of elements.
#    time_growmin      double   And likewise for the time mask.
#    time_growadd      double
#
#                               RFIMED parameters:
#    rfi_clip          double   Set the clipping threshhold to this multiple
#                               of the typical bandpass RMS.
#    rfi_iter          int      Number of clipping iterations.
#    rfi_minint        int      Minimum number of integrations that must
#                               remain after clipping to accept the bandpass
#                               calibration for a channel.
#    rfi_lev           double   Reject the bandpass calibration for a
#                               channel if the RMS exceeds this multiple of
#                               the typical bandpass RMS.
#    rfi_sflag         double   If more than this fraction of integrations
#                               in a channel was clipped then flag them.
#
#                               POLYFIT parameters:
#    polydegree        int      Degree of the robust polynomial fit.
#    polydev           double   Discard points outside the specified number of
#                               "median deviations" for the robust polynomial
#                               fit.  The median deviation is computed as the
#                               median of the absolute deviation from the
#                               median.  Thus, discarding one median deviation
#                               will discard half of the data points remaining
#                               at each iteration.  Note that this is done
#                               cumulatively over iterations.
#    polyiter          int      Number of iterations of the robust polynomial
#                               fit.
#
#    statratio         boolean  Statistic of ratios (recommended) or ratio of
#                               statistics (HIPASS/ZOA).
#    bp_recalc         int      The period, in cycles, at which the bandpass
#                               is recalculated.
#    nprecycles        int      Number of cycles to store and search for valid
#    npostcycles       int      bandpass spectra for COMPACT source bandpass
#                               correction.
#    maxcycles         int      Maximum number of integrations in a scan for
#                               the EXTENDED, MX, SCMX, and FREQSW bandpass
#                               correction methods.
#    boxsize           int      Box size, in integrations, for the MEDIAN and
#                               MEAN estimators for EXTENDED source bandpass
#                               correction.  Also used to split scans with the
#                               RFIMED estimator.
#    boxreject         boolean  If true, reject integrations in the box with
#                               the lowest sum(Tsys(i)/spectrum(i)), else
#                               accept only those in the box with the highest.
#    nboxes            int      Number of subdivisions of the scan for the
#                               MEDMED and MINMED estimators.
#    margin            int      Sub-scan margin to use for SCMX bandpass
#                               correction.  Set to zero to use adjacent sub-
#                               scans.
#    xbeam             boolean  Do cross-beam Tsys correction (for continuum
#                               sources).
#    fit_order         int      Method of post-bandpass residual spectral
#                               baseline removal:
#                                 -1 for no post-bandpass fit,
#                                  0 for constant offset (i.e. median),
#                                 >0 for robust (adaptive) polynomial fit;
#                                    Note that this is the polynomial degree
#                                    (highest power), not the order (number of
#                                    coefficients = degree + 1).
#                      string   can also be specified as 'NONE'.
#    l1norm            boolean  Use L1 norm for linear fit rather than
#                               adaptive.
#    continuum         boolean  Preserve the linear component of the baseline
#                               fit (continuum flux).
#    chan_mask         int[10]  Up to five pairs of channel ranges may be
#                               defined to exclude line emission or the
#                               bandpass edges from the baseline fit.  The
#                               first channel must not exceed the second;
#                               unwanted ranges should be set to zero.
#    doppler_frame     string   Shift spectra to this Doppler reference frame,
#                               'TOPOCENT', 'GEOCENTR', 'LSRK', 'LSRD',
#                               'BARYCENT', 'GALACTOC', 'LOCALGRP',
#                               'CMBDIPOL'.
#    rescale_axis      boolean  The Doppler shift may be applied in either of
#                               two ways:
#                                 T: predominantly by scaling the frequency
#                                    axis parameters but also by shifting the
#                                    spectrum (via FFT) by a fraction of a
#                                    channel so that the new reference
#                                    frequency is an integer multiple of the
#                                    original channel spacing.  This method is
#                                    more accurate and satisfies gridzilla's
#                                    requirements, for which it must be used
#                                    if Doppler tracking was enabled when the
#                                    observations were made, or
#                                 F: by shifting the spectrum (via an FFT)
#                                    without changing the frequency axis
#                                    parameters (the HIPASS/ZOA method).
#
#                               Data selection / validity checking:
#    fast              boolean  Check min/max time/position for the central
#                               beam only, for speed (COMPACT method only)?
#    check_field       boolean  Check field names for each spectra?
#    check_time        boolean  Check time?
#    tmin              int      Minimum time separation, seconds (COMPACT
#                               method only).
#    tmax              int      Maximum time separation, seconds (COMPACT
#                               method only).
#    tjump             int      Maximum time jump, seconds.
#    check_position    boolean  Check position?
#    dmin              int      Minimum position separation, arcmin (COMPACT
#                               method only).
#    dmax              int      Maximum position separation, arcmin (COMPACT
#                               method only).
#    djump             int      Maximum position jump, arcmin.
#
# Received events:
#    correct(record)     Correct the supplied data.
#    flush()             Flush the event handler.
#    hidegui()           Make the GUI invisible.
#    init(record)        Initialize the bandpass calibration client.
#                        Parameter values may optionally be specified.
#    lock()              Disable parameter entry.
#    printparms()        Print parameters for the bandpass calibration client.
#    printvalid()        Print parameter validation rules.
#    setconfig(string)   Set configuration to 'DEFAULTS', 'GENERAL',
#                        'CONTINUUM', 'GASS', 'HIPASS', 'HVC', 'METHANOL',
#                        'ZOA', 'MOPRA', or 'AUDS'.
#    setparm(record)     Set parameter values for the bandpass calibration
#                        client.
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    terminate()         Close down.
#    unlock()            Enable parameter entry.
#
# Sent events:
#    corrected_data(record)
#                        Batch of corrected data.
#    done()              Agent has terminated.
#    flushed_data(record)
#                        Batch of corrected data flushed from the buffer.
#    finished()          Processing has finished, all data has been flushed
#                        from the buffer.
#    guiready()          GUI construction complete.
#    log(record)         Log message.
#    need_more_data()    Request for more data from the reader.
#
# -------------------------------------------------------------------- <USAGE>
# ------------------------------------------------------------------ <COMPACT>
# COMPACT - compact source bandpass calibration method
#
# In general terms, bandpass calibration is done independently for each beam,
# IF and polarization on a channel-by-channel basis by establishing a baseline
# in the time domain (spatio-temporal domain for scanned observations).  The
# aim is to correct for the relative gain of each spectral channel and to
# subtract the response to a blank field, leaving only the contribution from
# cosmic emission, whether line or continuum.
#
# Compact source bandpass calibration is the original method developed for the
# HIPASS and ZOA surveys.  The telescope is assumed to scan sufficiently far
# and sufficiently quickly across the sky that sources of interest occupy only
# a small fraction of the scan length.  HIPASS/ZOA scans consisted of 100 x 5s
# integrations with a scan rate of 1 degree per minute (5' per integration) in
# declination and an external galaxy typically only spans a few integrations.
#
# Calibration is done in the time domain (i.e. for each separate spectral
# channel) by loading the data into a circular buffer.  The buffer length is
# controlled by the number of "Precycles" and "Postcycles" (default 24 each),
# which are used to form the reference spectrum, plus one for the target
# spectrum which of course is not used in determining the reference spectrum.
# Minimum and maximum times and positions may also be specified in the lower
# panel to exclude integrations that are too close to, or too distant from the
# target spectrum, whether temporally or spatially
#
# One advantage of the COMPACT source method over other methods that load the
# entire scan (e.g. EXTENDED) is that it can accomodate scans of any length
# using a fixed, usually smaller amount of memory.  During real-time operation
# there is also less of a delay before processed data becomes visible on the
# monitor because fewer integrations need to be buffered (as determined by the
# number of Postcycles).  The main drawback is that the data is processed non-
# uniformly; because of end-effects, data within Postcycles of the start of
# the scan, and within Precycles of the end, have a reduced baseline for the
# calibration in the time domain.
#
# Three statistical estimators are available to determine the reference
# spectrum:
#
#   MEDIAN: HIPASS/ZOA used this for RFI rejection (robust statistics) and to
#     reduce baseline contamination caused by real sources, so-called bandpass
#     sidelobes.
#
#   MEAN: In the absence of significant RFI the mean value is a more efficient
#     estimator in the statistical sense, though it is much more sensitive to
#     bad data.
#
#   POLYFIT: Robust polynomial fitting in the time domain is an iterative
#     process whereby a polynomial of a specified degree is fit to the data
#     and points outside a specified number of median deviations are excluded
#     from the next iteration.  This is repeated the specified number of
#     times.
#
# Each of these statistical estimators can be applied as the "Statistic of
# Ratios", i.e. factor(i) = median(Tsys(i)/spectrum(i)), or the "Ratio of
# Statistics", i.e. factor(i) = median(Tsys(i))/median(spectrum(i)), where i
# is the integration number.  The former is expected to be more statistically
# (and computationally) efficient, but the latter was used for HIPASS/ZOA and
# so is kept as a heritage estimator.
#
# Since recomputing the reference spectrum for each target integration may be
# computationally expensive, an option is provided to "Recalculate" it less
# often (default 4).
#
# Having multiple simultaneous beams provides an opportunity to detect and
# correct for RFI that increases Tsys simultaneously in each beam.  The excess
# for each beam and polarization (up to 26 spectra at Parkes) is computed as
# the mean value of the spectrum divided by the time-average Tsys (using the
# chosen statistical estimator).  The median value of these excesses should be
# zero unless RFI drove Tsys up simultaneously in each beam and polarization.
# The "Cross-beam" correction removes a constant value from each spectrum
# equal to the median excess times the time-average Tsys.  It is therefore of
# interest only in measuring the continuum.
#
# The two operations performed after bandpass calibration are firstly to
# remove bandpass curvature in the spectral domain, and secondly to perform
# Doppler frame conversion.  The degree of the polynomial used for the
# spectral baseline correction may need to be chosen with reference to the
# particular data being processed.  However, the constant term is always
# determined (whether subtracted or not), it and the first degree term
# effectively measure the continuum contribution and spectral index, so at
# least a first degree fit must be done if spectral index mapping in gridzilla
# is contemplated.  If "Preserve continuum" is selected these terms will be
# added back to the spectra so that the continuum may be assessed in the
# monitor display, particularly using the "Show sum spectrum" option.  Whether
# or not "Preserve continuum" is selected the spectral baseline fit, and the
# baseline polynomial actually removed, are recorded in the output SDFITS
# file.
#
# In correcting the spectral baseline it may help to specify channel ranges to
# exclude, particularly if there are any very strong or wide emission or
# absorption lines since these may lead the robust polynomial fit astray.  Up
# to five pairs of channels may be specified.
#
# Doppler correction should always be done using "Rescale frequency axis", the
# alternative is only preserved for heritage HIPASS/ZOA data reduction.  In
# the first, the Doppler shift is done predominantly by scaling the frequency
# axis parameters (reference frequency and channel spacing) but also by
# shifting the spectrum (via FFT) by a fraction of a channel so that the new
# reference frequency is an integer multiple of the original channel spacing.
# This method is more accurate and satisfies gridzilla's requirements, for
# which it *must* be used if Doppler tracking was enabled in TCS when the
# observations were made.  The HIPASS/ZOA method simply shifts the spectrum
# (via an FFT) without changing the frequency axis parameters.
# ------------------------------------------------------------------ <COMPACT>
# ----------------------------------------------------------------- <EXTENDED>
# EXTENDED - extended source bandpass calibration method
#
# Extended source bandpass calibration was originally developed for the High
# Velocity Cloud (HVC) survey in which HIPASS survey data was reprocessed to
# search for small though notably extended HI clouds with anomalous velocity
# in the vicinity of the galaxy.  The method differs from COMPACT source
# bandpass calibration in that
#
#   a) The whole scan is loaded into memory and used to determine the bandpass
#      calibration for each channel.  Thus only one parameter "Max cycles" is
#      provided to determine the size of the (non-cyclic) buffer, and this
#      must be set large enough to contain the whole scan.  (In fact, a
#      similar effect can be obtained with the COMPACT method by setting
#      "Precycles" and "Postcycles" to the scan length, though this uses twice
#      as much memory.)
#
#   b) A varied set of statistical estimators are available that aim to
#      exclude consecutive integrations that may contain extended source
#      emission from the baseline determination.
#
# In other respects, pre- and post-bandpass calibration, the EXTENDED method
# is similar to the COMPACT source method, q.v.  The main difference is thus
# the additional statistical estimators which are applied on a channel-by-
# channel basis:
#
#   MEDIAN/MEAN: These two estimators have an associated "Box size" which (if
#     non-zero) specifies the width of a sliding window used to compute a
#     running mean of Tsys(i)/spectrum(i), where i is the integration number.
#     There are then two possibilities:
#
#     a) The integrations for which the running mean is lowest are rejected on
#        the assumption that these correspond to the source, the remaining
#        integrations then define the baseline.  The box size should therefore
#        be chosen to match the expected extent, in integrations, of the
#        source of interest.
#
#     b) The integrations for which the running mean is highest are accepted
#        and the remainder rejected.  This is appropriate when the scan mostly
#        consists of emission.  The box size should be chosen to match the
#        expected extent, in integrations, of the baseline that appears
#        between the emission.
#
#     The calibration factor is determined as the median or mean value of the
#     factors that were not rejected.  A robust linear fit to Tsys over
#     integration number is then subtracted.
#
#   POLYFIT: Robust polynomial fitting in the time domain as for the COMPACT
#     method.
#
#   MEDMED: The scan is divided rigidly into the specified number of sub-scans
#     and median(Tsys(i)/spectrum(i)) computed for each.  The minimum of these
#     values is discarded and the calibration factor determined as the median
#     of those remaining.  Because of the inflexible way that the scan is sub-
#     divided this method is likely to be inferior to the MEDIAN with a well
#     chosen box size.
#
#   MINMED: The scan is divided into the specified number of sub-scans and
#     median(Tsys(i)) and median(spectrum(i)) computed for each.  The
#     calibration factor is then computed as the minimum of the Tsys medians
#     divided by the minimum of the spectral channel medians.  Note that this
#     estimator is statistically biassed as well as inefficient and is only
#     preserved as a heritage estimator for the HVC survey.
#
#   RFIMED: A clipped median estimator with flagging that takes account of
#     strong radar signals such as those that affect Arecibo ALFA/AUDS data
#     for which it was developed.  RFI in this data is sufficiently strong and
#     persistent that use of robust statistics (median estimation) alone is
#     not sufficient to deal with it.  Thus the main aim is to identify and
#     flag strong RFI and so compute a reliable calibration factor for each
#     spectral channel - if this can't be done the whole channel is flagged.
#     Flagging of sporadic RFI (radar flashes) is a secondary issue, since
#     this can be dealt with later, e.g. via simple clipping in gridzilla.
#     Since the radar is typically strong enough to affect Tsys, it is also
#     recomputed with the bad channels masked-out.
#
#     The only parameters for this estimator that may be defined from the GUI
#     are the channel mask-broadening parameters for the radar lines as
#     described for the FREQSW method, q.v.  In early ALFA/AUDS observations
#     multiple scans (usually five) were written to a single output FITS file;
#     the "Box size" parameter is provided solely as a means of splitting
#     these apart and should be set to the number of integrations in a scan
#     (typically 100) with "Max cycles" set large enough (typically 500) to
#     hold the whole file.
#
#   NONE: Skips bandpass calibration, but pre- and post-bandpass calibration
#     operations are still performed.
# ----------------------------------------------------------------- <EXTENDED>
# ----------------------------------------------------------------------- <MX>
# MX - beam-multiplexed bandpass calibration method
#
# In multiplexed (MX) observing mode each beam of the Multibeam system tracks
# a source in turn.  A scan therefore consists of a number of subscans (up to
# 13 for Parkes), with the on-source subscan for a particular beam being
# calibrated by the off-source subscans before and after it (except the first
# and last which only have a following or preceding subscan).  The buffer size
# must be set large enough to contain three whole subscans plus one
# integration.  If set smaller than this integrations from the first subscan
# will be overwritten by the latest subscan in the cyclic buffer.  livedata
# will issue copious warnings to this effect.
#
# In other respects, pre- and post-bandpass calibration, the MX method is
# similar to the COMPACT source method, q.v.
#
# The bandpass client itself detects MX mode data via the OBSTYPE card (set to
# "MX") in the RPFITS header, selecting MX in the GUI simply tailors it to
# show the relevant processing parameters.
# ----------------------------------------------------------------------- <MX>
# --------------------------------------------------------------------- <SCMX>
# SCMX - scanned, beam-multiplexed bandpass calibration method
#
# Scanned-MX mode is similar to ordinary MX mode (q.v.) in which a source is
# tracked by each beam in turn, except that now the telescope scans through
# the source of interest.  This admits the possibility of forming the bandpass
# calibration from a number of integrations at the start and end of the scan
# as specified by the "Margin" parameter.  If set to zero the calibration is
# formed from the previous and/or following subscans as in MX mode.
#
# In other respects, pre- and post-bandpass calibration, the SCMX method is
# similar to the COMPACT source method, q.v.
#
# SCMX is a specialised observing mode developed specifically for Parkes
# project P424 to measure the beamshape and the continuum and bandpass ripple
# response of each beam in the Multibeam system.  Certain technical problems
# relating to the RPFITS format require source coordinates to be hard-coded in
# the bandpass client for particular source names.  Use with caution!
# --------------------------------------------------------------------- <SCMX>
# ------------------------------------------------------------------- <FREQSW>
# FREQSW - frequency-switched bandpass calibration
#
# This bandpass calibration method is uniquely associated with the "QUOTIENT"
# estimator and can only, and must only be used for frequency-switched
# observations.  The bandpass client itself detects such data, selecting
# FREQSW in the GUI simply tailors it to show the relevant processing
# parameters.
#
# There are two separate algorithms.  Setting "Max cycles" to 2 causes
# livedata to use a simple pair-wise algorithm; each member of the frequency-
# switched pair is divided by the other.  A robust polynomial baseline fit is
# then done: one iteration of a fourth-degree (quartic) to remove broadscale
# features, followed by three iterations of an eighth-degree polynomial.
#
# Setting "Max cycles" greater than 2 signals use of the scan-wise algorithm.
# In this case "Max cycles" defines the buffer size which must be large enough
# to hold the whole scan.  The following procedure is applied separately for
# each beam, IF, and polarization.
#
# The whole scan is buffered in a 2-D array, freq vs time.  If there is an odd
# number of integrations the last is thrown away.
#
# 1) For each pair of frequency-switched spectra form the two quotient spectra
#    by dividing each by the other, e.g. (S0,S1) is replaced with (S0/S1,
#    S1/S0).  Note that these are reciprocals of one another and that zero-
#    relative indexing is used, i.e. the spectra are counted from 0 as
#    0,1,2,...
#
# 2) Now determine the time-average quotient value (avquot) of each channel.
#    for the first of each pair of quotient spectra.  This is done in two
#    passes which differ only in the method of rejecting line emission (and
#    RFI, etc.).
#
#    First pass:
#    a) Determine the median value of every other quotient spectrum starting
#       with the first, i.e. 0,2,4,..., corresponding to S0/S1, S2/S3,
#       S4/S5,...
#    b) Determine the median of these medians - this gives the "median-of-
#       quotients", the zeroth approximation to the time-average quotient
#       value of each channel.
#    c) For the first of each pair of quotient spectra, determine the median
#       of the absolute difference between it and the median-of-quotients.
#    d) Determine the median of these medians - this gives the "median-
#       quotient-deviation".
#
#       At this point we have two numbers, the "median-of-quotients" and the
#       "median-quotient-deviation", which will be used to identify line
#       emission or absorption in selecting data to form the time-average
#       quotient value for each channel.
#
#    f) Now looking at each channel as a function of time, accept the first of
#       each pair of quotient spectra for statistical purposes if its absolute
#       deviation from the median-of-quotients is less than a discriminant
#       which is set to x3 times the median-quotient-deviation.
#    g) Broaden the time mask (see below).  By default the broadening is ~50%
#       i.e. four consecutive rejected integrations become six.
#    h) If not more than 90% of integrations are rejected, form the time-
#       average quotient value, avquot(i), for the channel as the median of
#       those remaining.  Otherwise, reject the channel for statistical
#       purposes.
#
#       At this point each channel either has a first approximation,
#       avquot(i), to its time-average quotient value or has been rejected for
#       statistical purposes.
#
#    i) Now broaden the mask of rejected channels.  By default
#       the broadening is ~150%, i.e. four consecutive rejected channels
#       become ten.
#    j) Using the channel rejection mask, do a robust polynomial fit of
#       degree 15 to avquot(i) to give avquot'(i).
#
#       At this point we have a refined value of the time-average quotient
#       value, avquot'(i), for each channel.
#
#    Second pass:
#    k) Repeat steps (c) to (j) of the first pass with the median-of-quotients
#       replaced with avquot'(i) and the discriminant reduced to x2 times the
#       median-quotient-deviation at step (f).  The final estimate of the
#       time-average quotient value, avquot"(i) is formed at the equivalent of
#       step (j).
#
#       At this point we have the time-average quotient value of each channel,
#       avquot"(i), free from the affects of line emission and RFI.
#
# 3) Now compute medTsys0 and medTsys1, the median values of Tsys for the
#    first and second of the frequency-switched pairs and apply the
#    calibration factor, avquot"(i), determined in step (2):
#
#       spec0(i) = Norm(S0(i)/S1(i) / avquot"(i)) * Tsys0 - medTsys0
#       spec1(i) = Norm(S1(i)/S0(i) * avquot"(i)) * Tsys1 - medTsys1
#
#    Where Norm() indicates normalization of the spectrum to a mean value of
#    unity.
#
# 4) Apply post-bandpass baseline removal, Doppler correction, etc. as
#    specified in the GUI and described for the COMPACT source method, q.v.
#
# It may be helpful, particularly in the first iteration, if a channel mask is
# set manually to exclude known strong lines.  Note that this component of the
# mask is applied between steps (i) and (j) and therefore is not subject to
# mask-broadening.
#
# Mask-broadening
# ---------------
# Masks constructed by means of a simple discriminant only account for the
# central part of an emission line or RFI.  Mask-broadening, which takes two
# parameters growMin and growAdd, helps to remove the wings: each region of
# consecutive False values in the mask is extended by one on each side if it
# is at least growMin elements wide, and by a further one on each side for
# every additional growAdd elements.  The default values for time mask-
# broadening are 2 and 4, and for channel mask-broadening, 1 and 1.5 - much
# more aggressive because the wings are generally wider.  These values were
# determined from test data.
# ------------------------------------------------------------------- <FREQSW>
# --------------------------------------------------------------- <REFERENCED>
# REFERENCED - signal/reference bandpass calibration method
#
# Referenced bandpass calibration uses reference integrations inserted
# periodically in the observing pattern and relies on the ATNF convention of
# identifying these by appending "_R" to the source name.  Such observations
# are typically only done at Mopra for on-the-fly mapping of molecular clouds.
# These start with a reference observation well away from the mapping region,
# then a scan back and forth in right ascension (or declination) and then
# another reference integration, and so on.
#
# When REFERENCED method is selected the bandpass client checks that the data
# is in fact referenced via the OBSTYPE card (set to "RF") in the RPFITS
# header, and returns an error if not.
#
# There are no user-definable parameters for this bandpass calibration method,
# only the MEAN estimator is provided.  Note that the bandpass calibration is
# determined only from the mean of the reference integrations in the set
# immediately *preceding* the signal integrations - there is effectively no
# buffering of the data.
#
# In other respects, pre- and post-bandpass calibration, the REFERENCED method
# is similar to the COMPACT source method, q.v.
# --------------------------------------------------------------- <REFERENCED>
#-----------------------------------------------------------------------------

pragma include once

include 'pkslib.g'

const pksbandpass := subsequence(config         = 'GENERAL',
                                 client_dir     = '',
                                 nbeams         = 13,
                                 nifs           = 1,
                                 npols          = 2,
                                 nchans         = 1024,
                                 smoothing      = 'TUKEY',
                                 prescale_mode  = 'NONE',
                                 method         = 'COMPACT',
                                 estimator      = 'MEDIAN',
                                 chan_growmin   = 1.0,
                                 chan_growadd   = 1.5,
                                 time_growmin   = 2.0,
                                 time_growadd   = 4.0,
                                 rfi_clip       = 3.0,
                                 rfi_iter       = 5,
                                 rfi_minint     = 5,
                                 rfi_lev        = 2.0,
                                 rfi_sflag      = 0.75,
                                 polydegree     = 2,
                                 polydev        = 2.0,
                                 polyiter       = 3,
                                 statratio      = T,
                                 bp_recalc      = 4,
                                 nprecycles     = 24,
                                 npostcycles    = 24,
                                 maxcycles      = 250,
                                 boxsize        = 20,
                                 boxreject      = T,
                                 nboxes         = 5,
                                 margin         = 0,
                                 xbeam          = T,
                                 fit_order      = 0,
                                 l1norm         = F,
                                 continuum      = F,
                                 chan_mask      = [0,0,0,0,0,0,0,0,0,0],
                                 doppler_frame  = 'BARYCENT',
                                 rescale_axis   = T,
                                 fast           = T,
                                 check_field    = T,
                                 check_time     = T,
                                 tmin           = 0,
                                 tmax           = 300,
                                 tjump          = 20,
                                 check_position = T,
                                 dmin           = 15,
                                 dmax           = 300,
                                 djump          = 10) : [reflect=T]
{
  # Our identity.
  self.name := 'bandpass'

  for (j in system.path.include) {
    self.file := spaste(j, '/pksbandpass.g')
    if (len(stat(self.file))) break
  }

  # Parameter values.
  parms := [=]

  # Parameter value checking.
  pchek := [
    config         = [string  = [default = 'GENERAL',
                                 valid   = "DEFAULTS GENERAL CONTINUUM GASS \
                                            HIPASS HVC METHANOL ZOA MOPRA \
                                            AUDS"]],
    client_dir     = [string  = [default = '']],
    nbeams         = [integer = [default = 13,
                                 minimum = 1,
                                 maximum = 13]],
    nifs           = [integer = [default = 1,
                                 minimum = 1,
                                 maximum = 2]],
    npols          = [integer = [default = 2,
                                 minimum = 1,
                                 maximum = 2]],
    nchans         = [integer = [default = 1024,
                                 minimum = 1,
                                 maximum = 256*1024]],
    smoothing      = [string  = [default = 'TUKEY',
                                 valid   = "TUKEY HANNING NONE"]],
    prescale_mode  = [string  = [default = 'NONE',
                                 valid   = "NONE MEAN MEDIAN"]],
    method         = [string  = [default = 'COMPACT',
                                 valid   = "COMPACT EXTENDED MX SCMX \
                                            FREQSW REFERENCED"]],
    estimator      = [string  = [default = 'MEDIAN',
                                 valid   = "MEDIAN MEAN RFIMED POLYFIT \
                                            MEDMED MINMED QUOTIENT NONE"]],
    chan_growmin   = [double  = [default = 1.0,
                                 minimum = 0.0]],
    chan_growadd   = [double  = [default = 1.5,
                                 minimum = 0.0]],
    time_growmin   = [double  = [default = 2.0,
                                 minimum = 0.0]],
    time_growadd   = [double  = [default = 4.0,
                                 minimum = 0.0]],
    rfi_clip       = [double  = [default = 3.0,
                                 minimum = 1.0]],
    rfi_iter       = [integer = [default = 5,
                                 minimum = 0,
                                 maximum = 100]],
    rfi_minint     = [integer = [default = 5,
                                 minimum = 1]],
    rfi_lev        = [double  = [default = 2.0,
                                 minimum = 1.0]],
    rfi_sflag      = [double  = [default = 0.75,
                                 minimum = 0.0,
                                 maximum = 1.0]],
    polydegree     = [integer = [default = 2,
                                 minimum = 0,
                                 maximum = 6]],
    polydev        = [double  = [default = 2.0,
                                 minimum = 1.0,
                                 maximum = 3.0]],
    polyiter       = [integer = [default = 3,
                                 minimum = 1,
                                 maximum = 6]],
    statratio      = [boolean = [default = T]],
    bp_recalc      = [integer = [default = 4,   minimum = 1]],
    nprecycles     = [integer = [default = 24,  minimum = 1]],
    npostcycles    = [integer = [default = 24,  minimum = 1]],
    maxcycles      = [integer = [default = 250, minimum = 1]],
    boxsize        = [integer = [default = 20,  minimum = 0]],
    boxreject      = [boolean = [default = T]],
    nboxes         = [integer = [default = 5,   minimum = 1]],
    margin         = [integer = [default = 0,   minimum = 0]],
    xbeam          = [boolean = [default = T]],
    fit_order      = [integer = [default = 0,
                                 minumum = -1,
                                 maximum = 15],
                      string  = [valid   = 'NONE']],
    l1norm         = [boolean = [default = F]],
    continuum      = [boolean = [default = F]],
    chan_mask      = [integer = [default = [0,0,0,0,0,0,0,0,0,0],
                                 minimum = 0]],
    doppler_frame  = [string  = [default = 'BARYCENT',
                                 valid   = "TOPOCENT GEOCENTR LSRK LSRD \
                                            BARYCENT GALACTOC LOCALGRP  \
                                            CMBDIPOL"]],
    rescale_axis   = [boolean = [default = T]],
    fast           = [boolean = [default = T]],
    check_field    = [boolean = [default = T]],
    check_time     = [boolean = [default = T]],
    tmin           = [integer = [default = 0,   minimum = 0]],
    tmax           = [integer = [default = 300, minimum = 1]],
    tjump          = [integer = [default = 20,  minimum = 1]],
    check_position = [boolean = [default = T]],
    dmin           = [integer = [default = 15,  minimum = 1]],
    dmax           = [integer = [default = 300, minimum = 1]],
    djump          = [integer = [default = 10,  minimum = 1]]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    print spaste(self.file, ': internal inconsistency - pchek field names.')
  }

  # Version information maintained by RCS.
  wrk := [=]
  wrk.RCSid    := "$Revision: 19.25 $$Date: 2006/06/23 05:03:10 $"
  wrk.version  := spaste(wrk.RCSid[2], ', ', wrk.RCSid[4])
  wrk.lastexit := './livedata.lastexit/pksbandpass.lastexit'

  # Work variables.
  wrk.locked := F

  # GUI widgets.
  gui := [f1 = F]

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local helpmsg, readgui, set := [=], sethelp, setparm, showgui

  #------------------------------------------------------------------ helpmsg

  # Write a widget help message.

  const helpmsg := function(msg='')
  {
    if (is_agent(gui.helpmsg)) gui.helpmsg->text(msg)
  }

  #------------------------------------------------------------------- readgui

  # Read values from entry boxes.
  const readgui := function()
  {
    wider parms

    if (is_agent(gui.f1)) {
      for (j in 1:10) chan_mask[j] := gui.chan_mask.en[j]->get()

      setparm([chan_growmin = gui.chan_growmin.en->get(),
               chan_growadd = gui.chan_growadd.en->get(),
               time_growmin = gui.time_growmin.en->get(),
               time_growadd = gui.time_growadd.en->get(),
               bp_recalc    = gui.bp_recalc.en->get(),
               nprecycles   = gui.nprecycles.en->get(),
               npostcycles  = gui.npostcycles.en->get(),
               maxcycles    = gui.maxcycles.en->get(),
               boxsize      = gui.boxsize.en->get(),
               nboxes       = gui.nboxes.en->get(),
               margin       = gui.margin.en->get(),
               chan_mask    = chan_mask,
               tmin         = gui.tmin.en->get(),
               tmax         = gui.tmax.en->get(),
               tjump        = gui.tjump.en->get(),
               dmin         = gui.dmin.en->get(),
               dmax         = gui.dmax.en->get(),
               djump        = gui.djump.en->get()])
    }
  }

  #------------------------------------------------------------------ sethelp

  # Set up the help message for a widget.

  const sethelp := function(ref widget, msg='')
  {
    if (!gui.dohelp) return

    widget.helpmsg := msg

    widget->bind('<Enter>', 'Enter')
    widget->bind('<Leave>', 'Leave')

    whenever
      widget->Enter do
        helpmsg(widget.helpmsg)

    whenever
      widget->Leave do
        helpmsg('')
  }

  #------------------------------------------------------------------- setparm

  # setparm() updates parameter values, also updating any associated widget(s)
  # using showparm() if the GUI is active.
  #
  # Given:
  #    value      record   Each field name, item, identifies the parameter as
  #
  #                           parms[item]
  #
  #                        The field values are the new parameter settings.

  const setparm := function(value)
  {
    wider parms

    # Do parameter validation.
    value := validate(pchek, parms, value)

    if (len(parms) == 0) {
      # Initialize parms.
      parms := value
    }

    for (item in field_names(value)) {
      if (has_field(set, item)) {
        # Invoke specialized update procedure.
        set[item](value[item])

      } else {
        # Update the parameter value.
        parms[item] := value[item]
      }

      rec := [=]
      rec[item] := parms[item]
      showparm(gui, rec)
    }
  }

  #---------------------------------------------------------------- set.config

  # Set predefined parameter sets.

  const set.config := function(value)
  {
    wider parms, wrk

    old_config := parms.config
    parms.config := value

    if (parms.config == 'DEFAULTS') {
      for (parm in field_names(pchek)) {
        args[parm] := pchek[parm][1].default
      }
      setparm(args)

    } else if (parms.config == 'CONTINUUM') {
      # Select continuum processing options.
      self->unlock()
      if (parms.method == 'FREQSW') setparm([method = 'COMPACT'])
      setparm([statratio      = T,
               xbeam          = T,
               continuum      = T,
               chan_mask      = [0,0,0,0,0,0,0,0,0,0],
               rescale_axis   = T])

    } else if (parms.config == 'GASS') {
      # GASS processing options are not enforced.
      self->unlock()
      setparm([smoothing      = 'NONE',
               prescale_mode  = 'NONE',
               method         = 'FREQSW',
               chan_growmin   = 1.0,
               chan_growadd   = 1.5,
               time_growmin   = 2.0,
               time_growadd   = 4.0,
               maxcycles      = 250,
               fit_order      = 0,
               continuum      = F,
               chan_mask      = [590,660,1390,1460,0,0,0,0,0,0],
               doppler_frame  = 'LSRK',
               rescale_axis   = T,
               check_field    = T,
               check_time     = T,
               tjump          = 20,
               check_position = T,
               djump          = 10])

    } else if (any(parms.config == "HIPASS ZOA")) {
      # Enforce HIPASS/ZOA processing restrictions.
      self->lock()
      setparm([smoothing      = 'TUKEY',
               prescale_mode  = 'NONE',
               method         = 'COMPACT',
               estimator      = 'MEDIAN',
               statratio      = F,
               bp_recalc      = 4,
               nprecycles     = 24,
               npostcycles    = 24,
               xbeam          = F,
               fit_order      = 1,
               continuum      = F,
               chan_mask      = [0,0,0,0,0,0,0,0,0,0],
               doppler_frame  = 'BARYCENT',
               rescale_axis   = F,
               fast           = T,
               check_field    = T,
               check_time     = T,
               tmin           = 0,
               tmax           = 300,
               tjump          = 20,
               check_position = T,
               dmin           = 15,
               dmax           = 300,
               djump          = 10])

    } else if (parms.config == 'HVC') {
      # Enforce High Velocity Cloud processing restrictions.
      self->lock()
      setparm([smoothing      = 'HANNING',
               prescale_mode  = 'NONE',
               method         = 'EXTENDED',
               estimator      = 'MEDIAN',
               statratio      = T,
               maxcycles      = 110,
               boxsize        = 20,
               boxreject      = F,
               nboxes         = 5,
               xbeam          = F,
               fit_order      = 1,
               continuum      = F,
               chan_mask      = [0,0,0,0,0,0,0,0,0,0],
               doppler_frame  = 'LSRK',
               rescale_axis   = T,
               check_field    = F,
               check_time     = F,
               tjump          = 20,
               check_position = F,
               djump          = 10])

    } else if (parms.config == 'METHANOL') {
      # METHANOL processing options are not enforced.
      self->unlock()
      setparm([smoothing      = 'NONE',
               prescale_mode  = 'NONE',
               method         = 'EXTENDED',
               estimator      = 'MEDIAN',
               statratio      = T,
               maxcycles      = 250,
               boxsize        = 20,
               boxreject      = T,
               xbeam          = F,
               fit_order      = 1,
               continuum      = F,
               chan_mask      = [1,50,0,0,0,0,0,0,2000,2048],
               doppler_frame  = 'LSRK',
               rescale_axis   = T,
               check_field    = F,
               check_time     = F,
               tjump          = 20,
               check_position = F,
               djump          = 10])

    } else if (parms.config == 'MOPRA') {
      # MOPRA processing options are not enforced.
      self->unlock()
      setparm([smoothing      = 'NONE',
               prescale_mode  = 'NONE',
               method         = 'REFERENCED',
               estimator      = 'MEAN',
               statratio      = T,
               xbeam          = F,
               fit_order      = 1,
               continuum      = F,
               chan_mask      = [1,100,0,0,0,0,0,0,925,1024],
               doppler_frame  = 'LSRK',
               rescale_axis   = T,
               check_field    = F,
               check_time     = F,
               check_position = F])

    } else if (parms.config == 'AUDS') {
      # AUDS processing options are not enforced.
      self->unlock()
      setparm([smoothing      = 'HANNING',
               prescale_mode  = 'NONE',
               method         = 'EXTENDED',
               estimator      = 'RFIMED',
               chan_growmin   = 7.0,
               chan_growadd   = 10.0,
               rfi_clip       = 3.0,
               rfi_iter       = 5,
               rfi_minint     = 5,
               rfi_lev        = 2.0,
               rfi_sflag      = 1.0,
               statratio      = T,
               maxcycles      = 120,
               boxsize        = 100,
               xbeam          = F,
               fit_order      = 1,
               continuum      = F,
               chan_mask      = [0,0,0,0,0,0,0,0,0,0],
               doppler_frame  = 'BARYCENT',
               rescale_axis   = T,
               check_field    = T,
               check_time     = T,
               tjump          = 3,
               check_position = T,
               djump          = 4])

    } else {
      # General mode.
      self->unlock()

      # Reset these on changing from HIPASS/ZOA mode.
      if (any(old_config == "HIPASS ZOA")) {
        setparm([statratio    = T,
                 rescale_axis = T])
      }
    }
  }

  #------------------------------------------------------------- set.continuum

  # Preserve continuum flux in the baseline fit?

  const set.continuum := function(value)
  {
    wider parms

    if (parms.config == 'CONTINUUM') {
      parms.continuum := T
    } else if (parms.method == 'FREQSW') {
      parms.continuum := F
    } else {
      parms.continuum := value
    }

    if (parms.continuum) {
      if (parms.fit_order == 0) {
        setparm([fit_order = -1])
      }
    }
  }

  #------------------------------------------------------------- set.estimator

  # Set statistical estimator.

  const set.estimator := function(value)
  {
    wider parms

    if (parms.method == 'FREQSW') {
      value := 'QUOTIENT'
    } else if (parms.method == 'REFERENCED') {
      value := 'MEAN'
    } else if (value == 'QUOTIENT') {
      value := 'MEDIAN'
    } else if (parms.method != 'EXTENDED') {
      if (!any(value == "MEDIAN MEAN POLYFIT")) {
        # Must have one or other of these estimators.
        value := 'MEDIAN'
      }
    }
    parms.estimator := value

    if (parms.method == 'EXTENDED') {
      setparm([statratio = parms.estimator != 'MINMED'])
    } else if (parms.method == 'REFERENCED') {
      setparm([statratio = T])
    } else if (parms.method == 'SCMX' && parms.estimator == 'POLYFIT') {
      setparm([statratio = T])
    }
  }

  #------------------------------------------------------------- set.fit_order

  # Set baseline fit.

  const set.fit_order := function(value)
  {
    wider parms

    if (is_integer(value)) {
       parms.fit_order := value
    } else {
       parms.fit_order := -1
    }
  }

  #------------------------------------------------------------- set.maxcycles

  # Set buffer size.

  const set.maxcycles := function(value)
  {
    wider parms

    parms.maxcycles := value

    if (parms.estimator == 'QUOTIENT') setparm([estimator = parms.estimator])
  }

  #---------------------------------------------------------------- set.method

  # Set bandpass correction method.

  const set.method := function(value)
  {
    wider parms

    parms.method := value

    if (parms.method == 'FREQSW') {
      setparm([continuum = F])
    } else {
      setparm([continuum = parms.continuum])
    }

    # Enforce restrictions on the type of estimator.
    setparm([estimator = parms.estimator])
  }

  #--------------------------------------------------------- set.prescale_mode

  # Set statistical estimator used for prescaling.

  const set.prescale_mode := function(value)
  {
    wider parms

    parms.prescale_mode := value

    if (!any(parms.prescale_mode == "MEAN MEDIAN")) {
      parms.prescale_mode := 'NONE'
    }
  }

  #------------------------------------------------------------- set.statratio

  # Statistic of ratio or otherwise.

  const set.statratio := function(value)
  {
    wider parms

    if (any(parms.estimator == "MEDMED REFERENCED")) {
      parms.statratio := T
    } else if (parms.estimator == 'MINMED') {
      parms.statratio := F
    } else {
      parms.statratio := value
    }
  }

  #------------------------------------------------------------------- showgui

  # Build a graphical user interface for the bandpass calibration client.
  # If the parent frame is not specified a separate window will be created.

  const showgui := function(parent=F)
  {
    wider gui

    if (is_agent(gui.f1)) {
      # Show the GUI and bring it to the top of the window stack.
      gui.f1->map()
      if (gui.f1.top) gui.f1->raise()
      return
    }

    # Check whether DISPLAY is defined.
    if (!has_field(environ, 'DISPLAY')) {
       print 'DISPLAY environment variable is not set, can\'t construct GUI!'
       return
    }

    # Parent window.
    tk_hold()
    if (is_agent(parent)) {
      gui.f1 := parent
      gui.f1->side('top')
      gui.f1->expand('both')
      gui.f1->map()
      gui.f1.top := F

    } else {
      # Create a top-level frame.
      gui.f1 := frame(title='Parkes multibeam bandpass calibration',
                      expand='none')

      if (is_fail(gui.f1)) {
        print '\n\nWindow creation failed - check that the DISPLAY',
              'environment variable is set\nsensibly and that you have done',
              '\'xhost +\' as necessary.\n'
        gui.f1 := F
        return
      }

      gui.f1.top := T
    }

    gui.helpmsg := F
    if (is_record(parent) && has_field(parent, 'helpmsg')) {
      gui.helpmsg := parent.helpmsg
    }
    gui.dohelp := is_agent(gui.helpmsg) || gui.helpmsg

    #=========================================================================
    gui.f11  := frame(gui.f1, relief='ridge', borderwidth=4, expand='both')

    # Upper panel: configuration.
    gui.f111  := frame(gui.f11, relief='ridge')
    gui.f1111 := frame(gui.f111, borderwidth=0, expand='none')
    gui.f11110 := frame(gui.f1111, width=400, height=0, borderwidth=0)

    gui.title.ex := button(gui.f1111, 'BANDPASS CALIBRATION', relief='flat',
                           borderwidth=0, foreground='#0000a0')
    sethelp(gui.title.ex, spaste('Control panel (v', wrk.version,
      ') for the bandpass calibration client; PRESS FOR USAGE!'))

    whenever
      gui.title.ex->press do
        explain(self.file, 'USAGE')

    gui.f11111 := frame(gui.f1111, side='left', borderwidth=0)
    gui.config.la := label(gui.f11111, 'Configuration: ',
                           foreground='#b03060')
    gui.config.sv := label(gui.f11111, '', width=0, fill='x')
    sethelp(gui.config.sv, 'Current processing configuration.')

    #=========================================================================
    # Second panel: pre-bandpass option.
    gui.f112  := frame(gui.f11, relief='ridge')
    gui.f1121 := frame(gui.f112, borderwidth=0, expand='none')
    gui.f11210 := frame(gui.f1121, width=400, height=0, borderwidth=0)

    gui.f11211 := frame(gui.f1121, side='left', borderwidth=0)
    gui.parameters.la := label(gui.f11211, 'Pre-bandpass calibration options',
                               foreground='#b03060')
    sethelp(gui.parameters.la, 'Operations to be applied in preparation for \
      bandpass calibration.')

    # Smoothing --------------------------------------------------------------
    gui.f11212  := frame(gui.f1121, side='left', borderwidth=0)
    gui.f112121 := frame(gui.f11212, side='left', borderwidth=0,
                         expand='none')

    gui.smoothing.la := label(gui.f112121, 'Spectral smoothing')
    gui.smoothing.bn := button(gui.f112121, type='menu', width=7,
                                relief='groove')
    sethelp(gui.smoothing.bn, 'Smoothing applied in the spectral domain \
      prior to spectral pre-scaling and bandpass calibration.')

    gui.smoothing_1.bn := button(gui.smoothing.bn, 'TUKEY 25%', value='TUKEY')
    gui.smoothing_2.bn := button(gui.smoothing.bn, 'HANNING', value='HANNING')
    gui.smoothing_3.bn := button(gui.smoothing.bn, 'NONE', value='NONE')

    whenever
      gui.smoothing_1.bn->press,
      gui.smoothing_2.bn->press,
      gui.smoothing_3.bn->press do
        setparm([smoothing = $value])

    # Spacer.
    gui.f112122 := frame(gui.f11212, width=0, height=0, borderwidth=0,
                         expand='x')

    # Prescale mode ----------------------------------------------------------
    gui.f112123 := frame(gui.f11212, side='left', borderwidth=0,
                         expand='none')

    gui.prescale_mode.la := label(gui.f112123, 'Spectral pre-scaling')
    gui.prescale_mode.bn := button(gui.f112123, type='menu', width=6,
                                   relief='groove')
    sethelp(gui.prescale_mode.bn, 'Scaling applied before bandpass \
      calibration; each spectrum is divided by its median or mean value.')

    gui.prescale_mode_1.bn := button(gui.prescale_mode.bn, 'NONE',
                                     value='NONE')
    gui.prescale_mode_2.bn := button(gui.prescale_mode.bn, 'MEAN',
                                     value='MEAN')
    gui.prescale_mode_3.bn := button(gui.prescale_mode.bn, 'MEDIAN',
                                     value='MEDIAN')

    whenever
      gui.prescale_mode_1.bn->press,
      gui.prescale_mode_2.bn->press,
      gui.prescale_mode_3.bn->press do
        setparm([prescale_mode = $value])

    #=========================================================================
    # Third panel: parameter setting.
    gui.f113  := frame(gui.f11, relief='ridge')
    gui.f1131 := frame(gui.f113, borderwidth=0, expand='none')
    gui.f11310 := frame(gui.f1131, width=400, height=0, borderwidth=0)

    gui.f11311 := frame(gui.f1131, side='left', borderwidth=0)
    gui.parameters.la := label(gui.f11311, 'Bandpass calibration parameters',
                               foreground='#b03060')
    sethelp(gui.parameters.la, 'Parameters for the bandpass calibration \
      (not used for frequency-switched observations).')

    # Bandpass correction method ---------------------------------------------
    gui.f11312  := frame(gui.f1131, side='left', borderwidth=0)
    gui.f113121 := frame(gui.f11312, borderwidth=0, expand='none')

    gui.f1131211 := frame(gui.f113121, side='right', borderwidth=0)
    gui.method.bn := button(gui.f1131211, type='menu', width=11,
                            relief='groove')
    sethelp(gui.method.bn, 'Bandpass correction method.')

    gui.method_1.bn := button(gui.method.bn, 'Scanned, COMPACT source',
                              value='COMPACT')
    gui.method_2.bn := button(gui.method.bn, 'Scanned, EXTENDED source',
                              value='EXTENDED')
    gui.method_3.bn := button(gui.method.bn, 'Beam switching (MX) mode',
                              value='MX')
    gui.method_4.bn := button(gui.method.bn, 'Scanned MX mode',
                              value='SCMX')
    gui.method_5.bn := button(gui.method.bn, 'Frequency-switched',
                              value='FREQSW')
    gui.method_6.bn := button(gui.method.bn, 'Referenced (Ref-Sig-Ref-...)',
                              value='REFERENCED')

    whenever
      gui.method_1.bn->press,
      gui.method_2.bn->press,
      gui.method_3.bn->press,
      gui.method_4.bn->press,
      gui.method_5.bn->press,
      gui.method_6.bn->press do {
        setparm([method = $value])
        explain(self.file, parms.method, raise=F)
      }

    gui.method.ex := button(gui.f1131211, 'Method', relief='flat',
                            borderwidth=0, foreground='#0000a0')
    sethelp(gui.method.ex, 'PRESS FOR EXPLANATION!')

    whenever
      gui.method.ex->press do
        explain(self.file, parms.method)

    # Bandpass estimator -----------------------------------------------------
    gui.f1131212 := frame(gui.f113121, side='right', borderwidth=0)
    gui.estimator.bn := button(gui.f1131212, type='menu', width=11,
                               relief='groove')
    sethelp(gui.estimator.bn, 'Time domain statistic used for each channel \
      in bandpass correction.')

    gui.estimator_1.bn := button(gui.estimator.bn, 'MEDIAN',  value='MEDIAN')
    gui.estimator_2.bn := button(gui.estimator.bn, 'MEAN',    value='MEAN')
    gui.estimator_3.bn := button(gui.estimator.bn,
                                 'RFIMED (median with RFI flagging)',
                                 value='RFIMED')
    gui.estimator_4.bn := button(gui.estimator.bn,
                                'POLYFIT (robust polynomial)',
                                 value='POLYFIT')
    gui.estimator_5.bn := button(gui.estimator.bn,
                                'MEDMED (median of medians)', value='MEDMED')
    gui.estimator_6.bn := button(gui.estimator.bn,
                                'MINMED (minimum of medians)',
                                 value='MINMED')
    gui.estimator_7.bn := button(gui.estimator.bn,
                                'NONE (skip it)', value='NONE')

    whenever
      gui.estimator_1.bn->press,
      gui.estimator_2.bn->press,
      gui.estimator_3.bn->press,
      gui.estimator_4.bn->press,
      gui.estimator_5.bn->press,
      gui.estimator_6.bn->press,
      gui.estimator_7.bn->press do
        setparm([estimator = $value])

    gui.estimator.la := label(gui.f1131212, 'Estimator')

    # Compute statistic of ratios? -------------------------------------------
    gui.f1131213 := frame(gui.f113121, side='right', borderwidth=0)
    gui.statratio.bn := button(gui.f1131213, type='menu', relief='groove',
                               width=20, fill='x')
    sethelp(gui.statratio.bn, 'STATISTIC OF RATIOS (e.g. mean(Tsys_i/\
      chan_i), recommended) or RATIO OF STATISTICS \
      (e.g. mean(Tsys_i)/mean(chan_i)).')

    gui.statratio_1.bn := button(gui.statratio.bn, 'STATISTIC OF RATIOS',
                                 value=T)
    gui.statratio_2.bn := button(gui.statratio.bn, 'RATIO OF STATISTICS',
                                 value=F)

    whenever
      gui.statratio_1.bn->press,
      gui.statratio_2.bn->press do
        setparm([statratio = $value])

    # Recalculation interval -------------------------------------------------
    gui.f113122  := frame(gui.f11312, borderwidth=0)

    gui.f1131221 := frame(gui.f113122, borderwidth=0, expand='y')
    gui.f1131221->unmap()

    gui.f11312211 := frame(gui.f1131221, side='right', borderwidth=0)
    gui.bp_recalc.en := entry(gui.f11312211, justify='right', width=3,
                              relief='sunken')
    sethelp(gui.bp_recalc.en, 'Recalculate the bandpass estimate after this \
      many integrations.')

    whenever
      gui.bp_recalc.en->return do
        setparm([bp_recalc = $value])

    gui.bp_recalc.la := label(gui.f11312211, 'Recalculate')

    # Number of precycles ----------------------------------------------------
    gui.f11312212 := frame(gui.f1131221, side='right', borderwidth=0)

    gui.nprecycles.en := entry(gui.f11312212, justify='right', width=3,
                               relief='sunken')
    sethelp(gui.nprecycles.en, 'Number of integrations BEFORE the one being \
      calibrated to use for bandpass correction.')

    whenever
      gui.nprecycles.en->return do
        setparm([nprecycles = $value])

    gui.nprecycles.la := label(gui.f11312212, 'Precycles')

    # Number of postcycles ---------------------------------------------------
    gui.f11312213 := frame(gui.f1131221, side='right', borderwidth=0)

    gui.npostcycles.en := entry(gui.f11312213, justify='right', width=3,
                                relief='sunken')
    sethelp(gui.npostcycles.en, 'Number of integrations AFTER the one being \
      calibrated to use for bandpass correction.')

    whenever
      gui.npostcycles.en->return do
        setparm([npostcycles = $value])

    gui.npostcycles.la := label(gui.f11312213, 'Postcycles')

    # Buffer size ------------------------------------------------------------
    gui.f1131222 := frame(gui.f113122, borderwidth=0, expand='y')
    gui.f1131222->unmap()

    # Maximum number of cycles -----------------------------------------------
    gui.f11312221 := frame(gui.f1131222, side='right', borderwidth=0,
                           expand='x')
    gui.maxcycles.en := entry(gui.f11312221, justify='right', width=4,
                              fill='none', relief='sunken')
    sethelp(gui.maxcycles.en, 'Maximum number of cycles expected per scan \
      (only used to set buffer size).')

    whenever
      gui.maxcycles.en->return do
        setparm([maxcycles = $value])

    gui.maxcycles.la := label(gui.f11312221, '  Max cycles')

    # Box size ---------------------------------------------------------------
    gui.f11312222 := frame(gui.f1131222, side='right', borderwidth=0,
                           expand='x')
    gui.boxsize.en := entry(gui.f11312222, justify='right', width=4,
                            fill='none', relief='sunken')
    sethelp(gui.boxsize.en, 'Box size for the "MEDIAN" and "MEAN" \
      estimators, set to zero to disable.  Also used by "RFIMED" to split \
      scans.')

    whenever
      gui.boxsize.en->return do
        setparm([boxsize = $value])

    gui.boxsize.la := label(gui.f11312222, 'Box size')

    # Box reject/accept ------------------------------------------------------
    gui.f11312223 := frame(gui.f1131222, side='right', borderwidth=0,
                           expand='x')

    gui.boxreject.bn := button(gui.f11312223, 'Reject box', type='check',
                               width=10)

    sethelp(gui.boxreject.bn, 'Reject integrations in the box with lowest \
      sum(Tsys(i)/spectrum(i)), else accept only those with the highest.')

    whenever
      gui.boxreject.bn->press do
        setparm([boxreject = gui.boxreject.bn->state()])

    # Number of boxes --------------------------------------------------------
    gui.f11312224 := frame(gui.f1131222, side='right', borderwidth=0,
                           expand='x')
    gui.nboxes.en := entry(gui.f11312224, justify='right', width=4,
                           fill='none', relief='sunken')
    sethelp(gui.nboxes.en, 'Number of divisions of the scan for the "MEDMED" \
      and "MINMED" estimators.')

    whenever
      gui.nboxes.en->return do
        setparm([nboxes = $value])

    gui.nboxes.la := label(gui.f11312224, 'No. of boxes')

    # SCMX margin ------------------------------------------------------------
    gui.f11312225 := frame(gui.f1131222, side='right', borderwidth=0,
                           expand='x')
    gui.margin.en := entry(gui.f11312225, justify='right', width=4,
                           fill='none', relief='sunken')
    sethelp(gui.margin.en, 'Sub-scan margin for "SCMX" bandpass correction.')

    whenever
      gui.margin.en->return do
        setparm([margin = $value])

    gui.margin.la := label(gui.f11312225, 'Margin')

    # Channel mask broadening ------------------------------------------------
    gui.f11312226 := frame(gui.f1131222, side='left', borderwidth=0,
                           expand='x')

    gui.chan_grow.la := label(gui.f11312226, 'Chan mask', anchor='e',
                              fill='x')

    gui.chan_growmin.en := entry(gui.f11312226, justify='right', width=3,
                                 relief='sunken', fill='none')
    sethelp(gui.chan_growmin.en, 'Grow each region in the channel mask by \
      one on each side if it contains this many elements.')

    whenever
      gui.chan_growmin.en->return do
        setparm([chan_growmin = $value])


    gui.chan_growadd.en := entry(gui.f11312226, justify='right', width=3,
                                 relief='sunken', fill='none')
    sethelp(gui.chan_growadd.en, 'Grow each region in the channel mask by \
      a further one on each side for every additional number of elements.')

    whenever
      gui.chan_growadd.en->return do
        setparm([chan_growadd = $value])

    # Time mask broadening ------------------------------------------------
    gui.f11312227 := frame(gui.f1131222, side='left', borderwidth=0,
                           expand='x')

    gui.time_grow.la := label(gui.f11312227, 'Time mask', anchor='e',
                              fill='x')

    gui.time_growmin.en := entry(gui.f11312227, justify='right', width=3,
                                 relief='sunken', fill='none')
    sethelp(gui.time_growmin.en, 'Grow each region in the time mask by \
      one on each side if it contains this many elements.')

    whenever
      gui.time_growmin.en->return do
        setparm([time_growmin = $value])


    gui.time_growadd.en := entry(gui.f11312227, justify='right', width=3,
                                 relief='sunken', fill='none')
    sethelp(gui.time_growadd.en, 'Grow each region in the time mask by \
      a further one on each side for every additional number of elements.')

    whenever
      gui.time_growadd.en->return do
        setparm([time_growadd = $value])

    # Cross-beam correction --------------------------------------------------
    gui.f113123 := frame(gui.f11312, borderwidth=0, expand='y')

    gui.f1131231 := frame(gui.f113123, borderwidth=0)
    gui.xbeam.bn := button(gui.f1131231, 'Cross-beam', type='check', width=10,
                           pady=2)
    sethelp(gui.xbeam.bn, 'Remove RFI-induced excess Tsys appearing \
      simultaneously in each beam?  (For continuum sources.)')

    whenever
      gui.xbeam.bn->press do
        setparm([xbeam = gui.xbeam.bn->state()])

    # PolyFit parameters -----------------------------------------------------
    gui.f1131232 := frame(gui.f113123, borderwidth=0)
    gui.f1131232->unmap()

    gui.polyparm.la := label(gui.f1131232, 'Deg   Dev   Iter')

    gui.f11312321 := frame(gui.f1131232, side='left', borderwidth=0,
                           expand='x')
    gui.polydegree.bn := button(gui.f11312321, type='menu', relief='groove',
                                width=1, fill='x')
    sethelp(gui.polydegree.bn, 'Degree of the robust polynomial fit.')

    gui.polydegree_0.bn := button(gui.polydegree.bn, '0', value=0)
    gui.polydegree_1.bn := button(gui.polydegree.bn, '1', value=1)
    gui.polydegree_2.bn := button(gui.polydegree.bn, '2', value=2)
    gui.polydegree_3.bn := button(gui.polydegree.bn, '3', value=3)
    gui.polydegree_4.bn := button(gui.polydegree.bn, '4', value=4)
    gui.polydegree_5.bn := button(gui.polydegree.bn, '5', value=5)
    gui.polydegree_6.bn := button(gui.polydegree.bn, '6', value=6)

    whenever
      gui.polydegree_0.bn->press,
      gui.polydegree_1.bn->press,
      gui.polydegree_2.bn->press,
      gui.polydegree_3.bn->press,
      gui.polydegree_4.bn->press,
      gui.polydegree_5.bn->press,
      gui.polydegree_6.bn->press do
        setparm([polydegree = $value])


    gui.polydev.bn := button(gui.f11312321, type='menu', relief='groove',
                             width=2, fill='x')
    gui.polydev.bn.format := '%3.1f'
    sethelp(gui.polydev.bn, 'Discard points outside the specified number of \
      median deviations for the robust polynomial fit.')

    gui.polydev_1.bn := button(gui.polydev.bn, '1.0', value=1.0)
    gui.polydev_2.bn := button(gui.polydev.bn, '1.5', value=1.5)
    gui.polydev_3.bn := button(gui.polydev.bn, '2.0', value=2.0)
    gui.polydev_4.bn := button(gui.polydev.bn, '2.5', value=2.5)
    gui.polydev_5.bn := button(gui.polydev.bn, '3.0', value=3.0)

    whenever
      gui.polydev_1.bn->press,
      gui.polydev_2.bn->press,
      gui.polydev_3.bn->press,
      gui.polydev_4.bn->press,
      gui.polydev_5.bn->press do
        setparm([polydev = $value])

    gui.polyiter.bn := button(gui.f11312321, type='menu', relief='groove',
                              width=1, fill='x')
    sethelp(gui.polyiter.bn, 'Number of iterations of the robust polynomial \
      fit.')

    gui.polyiter_1.bn := button(gui.polyiter.bn, '1', value=1)
    gui.polyiter_2.bn := button(gui.polyiter.bn, '2', value=2)
    gui.polyiter_3.bn := button(gui.polyiter.bn, '3', value=3)
    gui.polyiter_4.bn := button(gui.polyiter.bn, '4', value=4)
    gui.polyiter_5.bn := button(gui.polyiter.bn, '5', value=5)
    gui.polyiter_6.bn := button(gui.polyiter.bn, '6', value=6)

    whenever
      gui.polyiter_1.bn->press,
      gui.polyiter_2.bn->press,
      gui.polyiter_3.bn->press,
      gui.polyiter_4.bn->press,
      gui.polyiter_5.bn->press,
      gui.polyiter_6.bn->press do
        setparm([polyiter = $value])

    #=========================================================================
    # Fourth panel: post-bandpass options.
    gui.f114  := frame(gui.f11, relief='ridge')
    gui.f1141 := frame(gui.f114, borderwidth=0, expand='none')
    gui.f11410 := frame(gui.f1141, width=400, height=0, borderwidth=0)

    gui.f11411 := frame(gui.f1141, side='left', borderwidth=0)
    gui.parameters.la := label(gui.f11411, 'Post-bandpass calibration options',
                               foreground='#b03060')
    sethelp(gui.parameters.la, 'Operations to be applied after bandpass \
      calibration.')

    # Fit order --------------------------------------------------------------
    gui.f11412  := frame(gui.f1141, side='left', borderwidth=0, expand='x')

    gui.fit_order.la := label(gui.f11412, 'Spectral baseline fit')
    sethelp(gui.fit_order.la, 'Residual spectral baseline removal after \
      bandpass calibration.')
    gui.fit_order.bn := button(gui.f11412, type='menu', width=6,
                               relief='groove', fill='x')
    sethelp(gui.fit_order.bn, 'Degree of the robust polynomial (or other \
      method) used for residual spectral baseline removal.')

    gui.fit_order_N.bn := button(gui.fit_order.bn,
                          '-: No post-bandpass baseline removal', value=-1)
    gui.fit_order_0.bn := button(gui.fit_order.bn,
                          '0: Baseline median value', value=0)
    gui.fit_order_l.bn := button(gui.fit_order.bn,
                          '1: Robust (L1 norm)  linear fit', value=1)
    gui.robust.bn      := button(gui.fit_order.bn,
                          'Robust (adaptive) polynomial fits', type='menu')
    gui.fit_order_1.bn := button(gui.robust.bn,
                          '  1: linear', value=1)
    gui.fit_order_2.bn := button(gui.robust.bn,
                          '  2: quadratic',
                          value=2)
    gui.fit_order_3.bn := button(gui.robust.bn,
                          '  3: cubic',
                          value=3)
    gui.fit_order_4.bn := button(gui.robust.bn,
                          '  4: 4th degree',
                          value=4)
    gui.fit_order_5.bn := button(gui.robust.bn,
                          '  5: 5th degree',
                          value=5)
    gui.fit_order_6.bn := button(gui.robust.bn,
                          '  6: 6th degree',
                          value=6)
    gui.fit_order_7.bn := button(gui.robust.bn,
                          '  7: 7th degree',
                          value=7)
    gui.fit_order_8.bn := button(gui.robust.bn,
                          '  8: 8th degree',
                          value=8)
    gui.fit_order_9.bn := button(gui.robust.bn,
                          '  9: 9th degree',
                          value=9)
    gui.fit_order_10.bn := button(gui.robust.bn,
                          '10: 10th degree',
                          value=10)
    gui.fit_order_11.bn := button(gui.robust.bn,
                          '11: 11th degree',
                          value=11)
    gui.fit_order_12.bn := button(gui.robust.bn,
                          '12: 12th degree',
                          value=12)
    gui.fit_order_13.bn := button(gui.robust.bn,
                          '13: 13th degree',
                          value=13)
    gui.fit_order_14.bn := button(gui.robust.bn,
                          '14: 14th degree',
                          value=14)
    gui.fit_order_15.bn := button(gui.robust.bn,
                          '15: 15th degree',
                          value=15)

    whenever
      gui.fit_order_N.bn->press,
      gui.fit_order_0.bn->press,
      gui.fit_order_1.bn->press,
      gui.fit_order_2.bn->press,
      gui.fit_order_3.bn->press,
      gui.fit_order_4.bn->press,
      gui.fit_order_5.bn->press,
      gui.fit_order_6.bn->press,
      gui.fit_order_7.bn->press,
      gui.fit_order_8.bn->press,
      gui.fit_order_9.bn->press,
      gui.fit_order_10.bn->press,
      gui.fit_order_11.bn->press,
      gui.fit_order_12.bn->press,
      gui.fit_order_13.bn->press,
      gui.fit_order_14.bn->press,
      gui.fit_order_15.bn->press do
        setparm([l1norm = F, fit_order = $value])

    whenever
      gui.fit_order_l.bn->press do
        setparm([l1norm = T, fit_order = $value])

    gui.f114121 := frame(gui.f11412, width=5, height=0, expand='none')

    # Preserve continuum flux? -----------------------------------------------
    gui.continuum.bn := button(gui.f11412, 'Preserve continuum',
                               type='check', anchor='w', width=22, padx=10)

    sethelp(gui.continuum.bn, 'Preserve the linear component of the baseline \
      fit (continuum flux) for higher order fits?')

    whenever
      gui.continuum.bn->press do
        setparm([continuum = gui.continuum.bn->state()])

    # Line exclusion mask ----------------------------------------------------
    gui.f11413  := frame(gui.f1141, side='left', borderwidth=0)

    gui.mask.la := label(gui.f11413, 'Mask')
    sethelp(gui.mask.la, 'Define up to five pairs of channel ranges to \
      exclude from the baseline fit (set unwanted ranges to zero).')

    f := '-adobe-courier-medium-r-*-*-11'
    gui.chan_mask.en := [=]
    for (j in 1:13) gui.chan_mask.en[j] := F

    gui.f114131 := frame(gui.f11413, side='left', relief='ridge',
                         expand='none')
    gui.chan_mask.en[1] := entry(gui.f114131, font=f, justify='right',
                                 width=4)
    sethelp(gui.chan_mask.en[1], 'First channel of first range to exclude.')
    gui.chan_mask.en[2] := entry(gui.f114131, font=f, justify='right',
                                 width=4)
    sethelp(gui.chan_mask.en[2], 'Last channel of first range to exclude.')

    gui.f114132 := frame(gui.f11413, width=0, height=0, borderwidth=0)
    gui.f114133 := frame(gui.f11413, side='left', relief='ridge',
                        expand='none')
    gui.chan_mask.en[3] := entry(gui.f114133, font=f, justify='right',
                                 width=4)
    sethelp(gui.chan_mask.en[3], 'First channel of second range to exclude.')
    gui.chan_mask.en[4] := entry(gui.f114133, font=f, justify='right',
                                 width=4)
    sethelp(gui.chan_mask.en[4], 'Last channel of second range to exclude.')

    gui.f114134 := frame(gui.f11413, width=0, height=0, borderwidth=0)
    gui.f114135 := frame(gui.f11413, side='left', relief='ridge',
                         expand='none')
    gui.chan_mask.en[5] := entry(gui.f114135, font=f, justify='right',
                                 width=4)
    sethelp(gui.chan_mask.en[5], 'First channel of third range to exclude.')
    gui.chan_mask.en[6] := entry(gui.f114135, font=f, justify='right',
                                 width=4)
    sethelp(gui.chan_mask.en[6], 'Last channel of third range to exclude.')

    gui.f114136 := frame(gui.f11413, width=0, height=0, borderwidth=0)
    gui.f114137 := frame(gui.f11413, side='left', relief='ridge',
                         expand='none')
    gui.chan_mask.en[7] := entry(gui.f114137, font=f, justify='right',
                                 width=4)
    sethelp(gui.chan_mask.en[7], 'First channel of fourth range to exclude.')
    gui.chan_mask.en[8] := entry(gui.f114137, font=f, justify='right',
                                 width=4)
    sethelp(gui.chan_mask.en[8], 'Last channel of fourth range to exclude.')

    gui.f114138 := frame(gui.f11413, width=0, height=0, borderwidth=0)
    gui.f114139 := frame(gui.f11413, side='left', relief='ridge',
                         expand='none')
    gui.chan_mask.en[9]  := entry(gui.f114139, font=f, justify='right',
                                  width=4)
    sethelp(gui.chan_mask.en[9], 'First channel of fifth range to exclude.')
    gui.chan_mask.en[10] := entry(gui.f114139, font=f, justify='right',
                                  width=4)
    sethelp(gui.chan_mask.en[10], 'Last channel of fifth range to exclude.')

    whenever
      gui.chan_mask.en[1]->return,
      gui.chan_mask.en[2]->return,
      gui.chan_mask.en[3]->return,
      gui.chan_mask.en[4]->return,
      gui.chan_mask.en[5]->return,
      gui.chan_mask.en[6]->return,
      gui.chan_mask.en[7]->return,
      gui.chan_mask.en[8]->return,
      gui.chan_mask.en[9]->return,
      gui.chan_mask.en[10]->return do {
        for (j in 1:10) chan_mask[j] := gui.chan_mask.en[j]->get()
        setparm([chan_mask = chan_mask])
      }

    # Doppler reference frame ------------------------------------------------
    gui.f114141 := frame(gui.f1141, width=0, height=3, borderwidth=0)
    gui.f114142 := frame(gui.f1141, width=0, height=1, borderwidth=0,
                         background='white')
    gui.f114143 := frame(gui.f1141, width=0, height=2, borderwidth=0)


    gui.f11415  := frame(gui.f1141, side='left', borderwidth=0, expand='x')

    gui.doppler_frame.la := label(gui.f11415, 'Doppler frame')
    sethelp(gui.doppler_frame.la, 'Doppler correction applied after bandpass \
      calibration.')
    gui.doppler_frame.bn := button(gui.f11415, type='menu', width=10,
                                   relief='groove', fill='x')
    sethelp(gui.doppler_frame.bn, 'Required Doppler reference frame.')

    gui.doppler_frame_1.bn := button(gui.doppler_frame.bn, 'Topocentric',
                                     value='TOPOCENT')
    gui.doppler_frame_2.bn := button(gui.doppler_frame.bn, 'Geocentric',
                                     value='GEOCENTR')
    gui.doppler_frame_3.bn := button(gui.doppler_frame.bn, 'Barycentric',
                                     value='BARYCENT')
    gui.doppler_frame_4.bn := button(gui.doppler_frame.bn, 'LSR (kinematic)',
                                     value='LSRK')
    gui.doppler_frame_5.bn := button(gui.doppler_frame.bn, 'LSR (dynamic)',
                                     value='LSRD')
    gui.doppler_frame_6.bn := button(gui.doppler_frame.bn, 'Galactocentric',
                                     value='GALACTOC')
    gui.doppler_frame_7.bn := button(gui.doppler_frame.bn, 'Local Group',
                                     value='LOCALGRP')
    gui.doppler_frame_8.bn := button(gui.doppler_frame.bn, 'CMB Dipole',
                                     value='CMBDIPOL')

    whenever
      gui.doppler_frame_1.bn->press,
      gui.doppler_frame_2.bn->press,
      gui.doppler_frame_3.bn->press,
      gui.doppler_frame_4.bn->press,
      gui.doppler_frame_5.bn->press,
      gui.doppler_frame_6.bn->press,
      gui.doppler_frame_7.bn->press,
      gui.doppler_frame_8.bn->press do
        setparm([doppler_frame = $value])

    gui.f114151 := frame(gui.f11415, width=5, height=0, expand='none')

    # Rescale axis -----------------------------------------------------------
    gui.rescale_axis.bn := button(gui.f11415, 'Rescale frequency axis',
                                  type='check', anchor='w', width=22, padx=10)
    sethelp(gui.rescale_axis.bn, 'Doppler shift mainly by rescaling the \
      frequency axis (recommended), else only shift the spectrum (HIPASS/ZOA \
      method).')

    whenever
      gui.rescale_axis.bn->press do
        setparm([rescale_axis = gui.rescale_axis.bn->state()])

    #=========================================================================
    # Fifth panel: validity checking.
    gui.f115  := frame(gui.f11, relief='ridge')
    gui.f1151 := frame(gui.f115, borderwidth=0, expand='none')
    gui.f11510 := frame(gui.f1151, width=400, height=0, borderwidth=0)

    gui.f11511  := frame(gui.f1151,  side='left', borderwidth=0, expand='x')
    gui.f115111 := frame(gui.f11511, borderwidth=0, expand='y')

    gui.validity.la := label(gui.f115111, 'Validity checking', anchor='nw',
                             foreground='#b03060', fill='x')
    sethelp(gui.validity.la, 'Selection criteria for bandpass correction.')

    # Spacer.
    gui.f1151111 := frame(gui.f115111, width=0, height=9, borderwidth=0,
                          expand='none')

    # Check field name? ------------------------------------------------------
    gui.check_field.bn := button(gui.f115111, 'Check field name ',
                                 type='check', relief='raised', width=15,
                                 pady=1)
    sethelp(gui.check_field.bn, 'Check that the field name hasn\'t changed \
      between successive integrations?')

    whenever
      gui.check_field.bn->press do
        setparm([check_field = gui.check_field.bn->state()])

    # Check central beam only? -----------------------------------------------
    gui.f1151112 := frame(gui.f115111, borderwidth=0, expand='none')
    gui.fast.bn := button(gui.f1151112, 'Central beam only', type='check',
                          relief='raised', width=15, pady=1)
    sethelp(gui.fast.bn, 'Speed processing by checking the central beam \
      only?')

    whenever
      gui.fast.bn->press do
        setparm([fast = gui.fast.bn->state()])

    # Horizontal spacer and vertical strut.
    gui.f115112 := frame(gui.f11511, width=10, height=75, borderwidth=0)

    gui.f115113   := frame(gui.f11511, side='left', borderwidth=0)
    gui.f1151131  := frame(gui.f115113, borderwidth=0, expand='y')
    gui.f1151132  := frame(gui.f115113, side='left', borderwidth=0)
    gui.f11511321 := frame(gui.f1151132, borderwidth=0, expand='y')
    gui.f11511322 := frame(gui.f1151132, borderwidth=0, expand='y')
    gui.f1151133  := frame(gui.f115113,  borderwidth=0, expand='y')
    gui.f1151134  := frame(gui.f115113,  borderwidth=0, expand='both')

    gui.f11511311 := frame(gui.f1151131, width=0, height=0, borderwidth=0)

    gui.f115113211 := frame(gui.f11511321, width=0, height=8, borderwidth=0)
    gui.min.la     := label(gui.f11511321, 'min',  pady=0)
    gui.f115113221 := frame(gui.f11511322, width=0, height=8, borderwidth=0)
    gui.max.la     := label(gui.f11511322, 'max',  pady=0)
    gui.f11511331  := frame(gui.f1151133, width=0, height=8, borderwidth=0)
    gui.jump.la    := label(gui.f1151133, 'jump', pady=0)

    gui.f11511341 := frame(gui.f1151134, width=0, height=0, borderwidth=0)

    # Check time? ------------------------------------------------------------
    gui.check_time.bn := button(gui.f1151131, 'Time', anchor='w',
                                type='check', width=6, pady=1)
    sethelp(gui.check_time.bn, 'Do time checks for each integration?')

    whenever
      gui.check_time.bn->press do
        setparm([check_time = gui.check_time.bn->state()])

    # Minimum time -----------------------------------------------------------
    gui.tmin.en := entry(gui.f11511321, justify='right', width=4,
                         relief='sunken')
    sethelp(gui.tmin.en, 'Minimum allowable time separation between the \
      integration being calibrated and those used for bandpass correction.')

    whenever
      gui.tmin.en->return do
        setparm([tmin = $value])

    # Maximum time -----------------------------------------------------------
    gui.tmax.en := entry(gui.f11511322, justify='right', width=4,
                         relief='sunken')
    sethelp(gui.tmax.en, 'Maximum allowable time separation between the \
      integration being calibrated and those used for bandpass correction.')

    whenever
      gui.tmax.en->return do
        setparm([tmax = $value])

    # Time jump --------------------------------------------------------------
    gui.tjump.en := entry(gui.f1151133, justify='right', width=4,
                          relief='sunken')
    sethelp(gui.tjump.en, 'Maximum allowable time jump between integrations.')

    whenever
      gui.tjump.en->return do
        setparm([tjump = $value])

    gui.tunits.la := label(gui.f1151134, 'second', fill='x')

    # Check position? --------------------------------------------------------
    gui.check_position.bn := button(gui.f1151131, 'Position', anchor='w',
                                    type='check', width=6, pady=1)
    sethelp(gui.check_position.bn, 'Do position checks for each integration?')

    whenever
      gui.check_position.bn->press do
        setparm([check_position = gui.check_position.bn->state()])

    # Minimum offset ---------------------------------------------------------
    gui.dmin.en := entry(gui.f11511321, justify='right', width=4,
                         relief='sunken')
    sethelp(gui.dmin.en, 'Minimum allowable position offset between the \
      integration being calibrated and those used for bandpass correction.')

    whenever
      gui.dmin.en->return do
        setparm([dmin = $value])

    # Maximum offset ---------------------------------------------------------
    gui.dmax.en := entry(gui.f11511322, justify='right', width=4,
                         relief='sunken')
    sethelp(gui.dmax.en, 'Maximum allowable position offset between the \
      integration being calibrated and those used for bandpass correction.')

    whenever
      gui.dmax.en->return do
        setparm([dmax = $value])

    # Position jump  ---------------------------------------------------------
    gui.djump.en := entry(gui.f1151133, justify='right', width=4,
                          relief='sunken')
    sethelp(gui.djump.en, 'Maximum allowable position jump between \
      integrations.')

    whenever
      gui.djump.en->return do
        setparm([djump = $value])

    gui.dunits.la := label(gui.f1151134, 'arcmin', fill='x')

    #=========================================================================
    # Widget help messages.
    if (gui.dohelp) {
      if (!is_agent(gui.helpmsg)) {
        gui.f1131 := frame(gui.f11, relief='ridge')
        gui.helpmsg := label(gui.f1131, '', font='courier', width=1, fill='x',
                             borderwidth=0)
        sethelp(gui.helpmsg, 'Widget help messages.')
      }
    }


    # Lock parameter entry?  (Must precede showparm.)
    if (wrk.locked) gui.f1->disable()

    # Initialize widgets.
    showparm(gui, parms)

    tk_release()

    self->guiready()
  }

  #--------------------------------------------------- gui.check_position.show

  # Check position?

  const gui.check_position.show := function()
  {
    gui.check_position.bn->state(parms.check_position)

    if (parms.check_position) {
      gui.dmin.en->disabled(F)
      gui.dmax.en->disabled(F)
      gui.djump.en->disabled(F)
      gui.dmin.en->foreground('#000000')
      gui.dmax.en->foreground('#000000')
      gui.djump.en->foreground('#000000')
      gui.dunits.la->foreground('#000000')
    } else {
      gui.dmin.en->disabled(T)
      gui.dmax.en->disabled(T)
      gui.djump.en->disabled(T)
      gui.dmin.en->foreground('#a3a3a3')
      gui.dmax.en->foreground('#a3a3a3')
      gui.djump.en->foreground('#a3a3a3')
      gui.dunits.la->foreground('#a3a3a3')
    }
  }

  #------------------------------------------------------- gui.check_time.show

  # Check time?

  const gui.check_time.show := function()
  {
    gui.check_time.bn->state(parms.check_time)

    if (parms.check_time) {
      gui.tmin.en->disabled(F)
      gui.tmax.en->disabled(F)
      gui.tjump.en->disabled(F)
      gui.tmin.en->foreground('#000000')
      gui.tmax.en->foreground('#000000')
      gui.tjump.en->foreground('#000000')
      gui.tunits.la->foreground('#000000')
    } else {
      gui.tmin.en->disabled(T)
      gui.tmax.en->disabled(T)
      gui.tjump.en->disabled(T)
      gui.tmin.en->foreground('#a3a3a3')
      gui.tmax.en->foreground('#a3a3a3')
      gui.tjump.en->foreground('#a3a3a3')
      gui.tunits.la->foreground('#a3a3a3')
    }
  }

  #----------------------------------------------------------- gui.config.show

  # Show parameter set.

  const gui.config.show := function()
  {
    gui.config.sv->text(parms.config)

    if (wrk.locked) gui.f1->enable()

    if (parms.config == 'CONTINUUM') {
      gui.method_5.bn->disabled(T)
      gui.continuum.bn->disabled(T)
    } else {
      gui.method_5.bn->disabled(F)
      gui.continuum.bn->disabled(F)
    }

    if (wrk.locked) gui.f1->disable()
  }

  #-------------------------------------------------------- gui.continuum.show

  # Preserve continuum flux in the baseline fit?

  const gui.continuum.show := function()
  {
    gui.continuum.bn->state(parms.continuum)

    gui.fit_order_0.bn->disabled(parms.continuum)
  }

  #-------------------------------------------------------- gui.estimator.show

  # Show statistical estimator.

  const gui.estimator.show := function()
  {
    tk_hold()

    gui.f11312222->unmap()
    gui.f11312223->unmap()
    gui.f11312224->unmap()
    gui.f11312225->unmap()
    gui.f11312226->unmap()
    gui.f11312227->unmap()
    gui.f1131232->unmap()

    lockstat := F
    if (any(parms.estimator == "MEDIAN MEAN RFIMED")) {
      if (parms.method == 'EXTENDED') {
        lockstat := T
        gui.f11312222->map()
        gui.f11312223->map()

      } else if (parms.method == 'SCMX') {
        gui.f11312225->map()
      }

      if (parms.estimator == 'RFIMED') gui.f11312226->map()

    } else if (parms.estimator == 'POLYFIT') {
      lockstat := any(parms.method == "EXTENDED SCMX MX")

      if (parms.method == 'SCMX') gui.f11312225->map()

      gui.f1131232->map()

    } else if (parms.estimator == 'QUOTIENT') {
      if (parms.maxcycles > 2) {
        gui.f11312226->map()
        gui.f11312227->map()
      }

    } else {
      lockstat := T
      if (parms.estimator != 'NONE') gui.f11312224->map()
    }

    if (wrk.locked) gui.f1->enable()
    gui.statratio.bn->disabled(lockstat)
    if (wrk.locked) gui.f1->disable()

    gui.estimator.bn->text(parms.estimator)
    tk_release()
  }

  #-------------------------------------------------------- gui.fit_order.show

  # Show baseline fit.

  const gui.fit_order.show := function()
  {
    if (parms.fit_order == -1) {
      gui.fit_order.bn->text('NONE')
    } else if (parms.fit_order == 1 && parms.l1norm) {
      gui.fit_order.bn->text(paste(parms.fit_order, '(L1)'))
    } else {
      gui.fit_order.bn->text(as_string(parms.fit_order))
    }
  }

  #----------------------------------------------------------- gui.l1norm.show

  # Show whether a linear fit uses L1 norm or not.

  const gui.l1norm.show := function()
  {
    if (parms.fit_order == 1) {
      if (parms.l1norm) {
        gui.fit_order.bn->text(paste(parms.fit_order, '(L1)'))
      } else {
        gui.fit_order.bn->text(as_string(parms.fit_order))
      }
    }
  }

  #----------------------------------------------------------- gui.method.show

  # Show bandpass correction method.

  const gui.method.show := function()
  {
    tk_hold()

    gui.f1131213->map()
    gui.f1131221->unmap()
    gui.f1131222->unmap()
    gui.f113123->map()
    gui.f1151112->unmap()
    gui.f11511321->unmap()
    gui.f11511322->unmap()

    gui.estimator_1.bn->disabled(F)
    gui.estimator_2.bn->disabled(F)
    gui.estimator_3.bn->disabled(T)
    gui.estimator_4.bn->disabled(F)
    gui.estimator_5.bn->disabled(T)
    gui.estimator_6.bn->disabled(T)
    gui.estimator_7.bn->disabled(T)

    gui.statratio_2.bn->disabled(F)
    gui.continuum.bn->disabled(F)

    if (parms.method == 'COMPACT') {
      gui.f1131221->map()
      gui.f1151112->map()
      gui.f11511321->map()
      gui.f11511322->map()

    } else if (parms.method == 'EXTENDED') {
      gui.f1131222->map()

      gui.estimator_3.bn->disabled(F)
      gui.estimator_5.bn->disabled(F)
      gui.estimator_6.bn->disabled(F)
      gui.estimator_7.bn->disabled(F)

    } else if (parms.method == 'MX') {
      gui.f1131222->map()

    } else if (parms.method == 'SCMX') {
      gui.f1131222->map()

    } else if (parms.method == 'FREQSW') {
      gui.f1131213->unmap()
      gui.f1131222->map()
      gui.f113123->unmap()

      gui.estimator_1.bn->disabled(T)
      gui.estimator_2.bn->disabled(T)
      gui.estimator_4.bn->disabled(T)

      gui.continuum.bn->disabled(T)

    } else if (parms.method == 'REFERENCED') {
      gui.estimator_1.bn->disabled(T)
      gui.estimator_4.bn->disabled(T)

      gui.statratio_2.bn->disabled(T)
    }

    gui.method.bn->text(parms.method)

    tk_release()
  }


  #-------------------------------------------------------- gui.statratio.show

  # Show statratio.

  const gui.statratio.show := function()
  {
    if (parms.statratio) {
      gui.statratio.bn->text('STATISTIC OF RATIOS')
    } else {
      gui.statratio.bn->text('RATIO OF STATISTICS')
    }
  }

  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  # Set parameter values.
  whenever
    self->setparm do
      if (!wrk.locked) setparm($value)

  # Predefined parameter set.
  whenever
    self->setconfig do
      setparm([config = $value])

  # Show parameter values.
  whenever
    self->printparms do {
      readgui()
      print ''
      printrecord(parms)
    }

  # Show parameter validation rules.
  whenever
    self->printvalid do {
      print ''
      printrecord(pchek, 'valid')
    }

  # Disable parameter entry.
  whenever
    self->lock do {
      if (!wrk.locked) {
        wrk.locked := T
        if (is_agent(gui.f1)) gui.f1->disable()
      }
    }

  # Enable parameter entry.
  whenever
    self->unlock do {
      if (wrk.locked &&
          any(parms.config == "GENERAL CONTINUUM GASS METHANOL MOPRA AUDS")) {
        wrk.locked := F
        if (is_agent(gui.f1)) gui.f1->enable()
      }
    }

  # Initialize the bandpass calibrator client.
  whenever
    self->init do {
      setparm($value)
      readgui()
      wrk.client->init(parms)
    }

  # Correct data.
  whenever
    self->correct do
      wrk.client->correct($value)

  # Flush data.
  whenever
    self->flush do
      wrk.client->flush(1)

  # Create or expose the GUI.
  whenever
    self->showgui do
      showgui($value)

  # Hide the GUI.
  whenever
    self->hidegui do
      if (is_agent(gui.f1)) gui.f1->unmap()

  # Close down.
  whenever
    self->terminate do {
      readgui()
      store(parms, wrk.lastexit)

      deactivate whenever_stmts(wrk.client).stmt

      deactivate wrk.whenevers
      self->done()
      gui  := F
      wrk  := F
      self := F
    }

  wrk.whenevers := whenever_stmts(self).stmt

  #---------------------------------------------------------------------------
  # Initialize.
  #---------------------------------------------------------------------------

  # Set parameters.
  args := [config         = 'GENERAL',
           client_dir     = client_dir,
           nbeams         = nbeams,
           nifs           = nifs,
           npols          = npols,
           nchans         = nchans,
           smoothing      = smoothing,
           prescale_mode  = prescale_mode,
           method         = method,
           estimator      = estimator,
           chan_growmin   = chan_growmin,
           chan_growadd   = chan_growadd,
           time_growmin   = time_growmin,
           time_growadd   = time_growadd,
           rfi_clip       = rfi_clip,
           rfi_iter       = rfi_iter,
           rfi_minint     = rfi_minint,
           rfi_lev        = rfi_lev,
           rfi_sflag      = rfi_sflag,
           polydegree     = polydegree,
           polydev        = polydev,
           polyiter       = polyiter,
           statratio      = statratio,
           bp_recalc      = bp_recalc,
           nprecycles     = nprecycles,
           npostcycles    = npostcycles,
           maxcycles      = maxcycles,
           boxsize        = boxsize,
           boxreject      = boxreject,
           nboxes         = nboxes,
           margin         = margin,
           xbeam          = xbeam,
           fit_order      = fit_order,
           l1norm         = l1norm,
           continuum      = continuum,
           chan_mask      = chan_mask,
           doppler_frame  = doppler_frame,
           rescale_axis   = rescale_axis,
           fast           = fast,
           check_field    = check_field,
           check_time     = check_time,
           tmin           = tmin,
           tmax           = tmax,
           tjump          = tjump,
           check_position = check_position,
           dmin           = dmin,
           dmax           = dmax,
           djump          = djump]

  if (!streq(field_names(args), field_names(pchek))) {
    print spaste(self.file, ': internal inconsistency - args field names.')
  }

  # Recover last exit state.
  if (len(stat(wrk.lastexit))) {
    last := read_value(wrk.lastexit)

    j := 0
    for (parm in field_names(pchek)) {
      j +:= 1

      # Don't override any non-defaulting arguments.
      if (has_field(args, parm) && has_field(last, parm)) {
        if (missing()[j]) {
          # Parameters not to recover:
          if (parm == 'client_dir') continue

          args[parm] := last[parm]

        } else {
          # Reset the default value for this parameter.
          pchek[parm][1].default := args[parm]
        }
      }
    }
  }

  setparm(args)

  # Apply parameter restrictions.
  if (config != 'GENERAL') setparm([config = config])

  #----------------------------------------------------------- bandpass client

  if (parms.client_dir == '') {
    wrk.client := client('pksbandpass')
  } else {
    wrk.client := client(spaste(parms.client_dir, '/pksbandpass'))
  }
  wrk.client.name := 'pksbandpass'

  # Forward events through.
  whenever
    wrk.client->* do
      self->[$name]($value)
}
