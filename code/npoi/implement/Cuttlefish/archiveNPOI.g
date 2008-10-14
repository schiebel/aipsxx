
# ------------------------------------------------------------------------------

# archiveNPOI

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains glish functions for obtaining statistics about NPOI *.cha
# HDS files.

# glish functions:
# ----------------
# archiveNPOI.

# Modification history:
# ---------------------
# 1999 Oct 13 - Nicholas Elias, USNO/NPOI
#               File created with glish function archiveNPOI( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'cuttlefish.g' ) {
  fail '%% archiveNPOI: Cannot include cuttlefish.g ...';
}

# ------------------------------------------------------------------------------

# archiveNPOI

# Description:
# ------------
# This glish functions defines the glish class for obtaining statistics about
# NPOI *.cha HDS files.

# Inputs:
# -------
# host           - The host name (default = '').
# forcenewserver - The 'force new server' flag (default = F).

# Outputs:
# --------
# The member functions, returned via the glish function value.

# Modification history:
# ---------------------
# 1999 Oct 13 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const archiveNPOI := function( host = '', forcenewserver = F ) {

  # Initialize variables
  
  const dirCha := '/dorado/data0/cha';

  private := [=];
  public := [=];
  
  
  ##### Define the private.* functions #####
  
  
  # Return all years on disk
  
  const private.years := function( ) {
    wider dirCha;
    return( as_string( shell( spaste( 'cd ', dirCha, '; ls -d 1*' ) ) ) );
  }
  
  
  # Check the year(s)
  
  const private.checkYears := function( years ) {
    wider private;
    years := as_string( years );
    yearsAll := private.years();
    for ( y1 in 1:length( years ) ) {
      for ( y2 in 1:(length( yearsAll ) + 1) ) {
        if ( y2 > length( yearsAll ) ) {
          fail 'archiveNPOI: Invalid year ...';
        }
        if ( years[y1] == yearsAll[y2] ) return( T );
      }
    }
  }
  
  
  # Get the date from the *.cha HDS file name
  
  const private.getDate := function( fileCha ) {
    if ( length( fileCha ) > 1 ) {
      fail 'archiveNPOI: More than *.cha HDS file specified ...';
    }
    if ( !is_string( fileCha ) ) {
      fail 'archiveNPOI: Invalid *.cha HDS file ...';
    }
    if ( length( field_names( stat( fileCha ) ) ) == 0 ) {
      fail 'archiveNPOI: Invalid *.cha HDS file ...';
    }
    date := split( fileCha ~ s/\.cha//, '/' );
    return( date[length( date )] );
  }
  
  
  # Get the *.cha HDS file name from the date
  
  const private.getCha := function( date ) {
    if ( date !~ m/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ ) {
      fail 'archiveNPOI: Invalid date format ...';
    }
    fileCha := spaste( dirCha, '/', split( date, '-' )[1], '/', date, '.cha' );
    if ( length( field_names( stat( fileCha ) ) ) == 0 ) {
      fail 'archiveNPOI: Invalid date ...';
    }
    return( fileCha );
  }
  
  
  # Get all the *.cha HDS file names for a year
  
  const private.filesCha := function( year ) {
    wider dirCha;
    if ( length( year ) > 1 ) {
      fail 'archiveNPOI: More than one year specified ...';
    }
    if ( is_fail( private.checkYears( year ) ) ) {
      fail;
    }
    return( as_string( shell( spaste( 'ls ',dirCha, '/', year, '/*.cha' ) ) ) );
  }
  
  
  # Get the data from a *.cha HDS file
  
  const private.getData := function( fileCha ) {
    data := [=];
    hds := hdsopen( fileCha );
    hds.goto( 'DataSet.ScanData' );
    data.starID := hds.obtain( 'StarID' );
    data.scanID := hds.obtain( 'ScanID' );
    data.scanTime := hds.obtain( 'ScanTime' );
    hds.done();
    return( data );
  }
  
  
  ##### Define the public.* member functions #####
  
  
  # Delete object
  
  const public.done := function( ) {
    private := F;
    val public := F;
    return;
  }
  
  
  # Get the summary for a list of dates and stars
  
  const public.dateSummary := function( dates, starsID = '' ) {
    wider private;
    summary := [=];
    if ( !is_string( dates ) ) {
      fail 'archiveNPOI: Invalid date(s) ...';
    }
    dates := split( dates, ' ' );
    starsID := to_upper( split( as_string( starsID ), ' ' ) );
    if ( length( starsID ) == 0 ) {
      starsID := '';
    }
    for ( d in 1:length( dates ) ) {
      if ( is_fail( fileCha := private.getCha( dates[d] ) ) ) {
        fail;
      }
      data := private.getData( fileCha );
      for ( s1 in 1:length( starsID ) ) {
        for ( s2 in 1:length( data.starID ) ) {
          if ( starsID[s1] == data.starID[s2] || starsID == '' ) {
            if ( !has_field( summary, dates[d] ) ) {
              summary[dates[d]] := [=];
            }
            if ( !has_field( summary[dates[d]], data.starID[s2] ) ) {
              summary[dates[d]][data.starID[s2]] := [=];
              summary[dates[d]][data.starID[s2]].numScan := 1;
              summary[dates[d]][data.starID[s2]].scanTime[1] :=
                  data.scanTime[s2];
              summary[dates[d]][data.starID[s2]].scanNumber[1] := s2;
              summary[dates[d]][data.starID[s2]].scanID[1] := data.scanID[s2];
            } else {
              summary[dates[d]][data.starID[s2]].numScan +:= 1;
              numScan := summary[dates[d]][data.starID[s2]].numScan;
              summary[dates[d]][data.starID[s2]].scanTime[numScan] :=
                  data.scanTime[s2];
              summary[dates[d]][data.starID[s2]].scanNumber[numScan] := s2;
              summary[dates[d]][data.starID[s2]].scanID[numScan] :=
                  data.scanID[s2];
            }
          }
        }
      }
    }
    return( summary );
  }
    
  
  # Get the summary for a list of years and stars

  const public.yearSummary := function( years, starsID = '' ) {
    wider private;
    summary := [=];
    years := split( as_string( years ), ' ' );
    if ( is_fail( private.checkYears( years ) ) ) {
      fail;
    }
    starsID := to_upper( split( as_string( starsID ), ' ' ) );
    if ( length( starsID ) == 0 ) {
      starsID := '';
    }
    for ( y in 1:length( years ) ) {
      filesCha := private.filesCha( years[y] );
      for ( f in 1:length( filesCha ) ) {
        date := private.getDate( filesCha[f] );
        data := private.getData( filesCha[f] )
        for ( s1 in 1:length( starsID ) ) {
          for ( s2 in 1:length( data.starID ) ) {
            if ( starsID[s1] == data.starID[s2] || starsID == '' ) {
              if ( !has_field( summary, years[y] ) ) {
                summary[years[y]] := [=];
              }
              if ( !has_field( summary[years[y]], data.starID[s2] ) ) {
                summary[years[y]][data.starID[s2]] := [=];
                summary[years[y]][data.starID[s2]].numScan := 1;
                summary[years[y]][data.starID[s2]].date[1] := date;
                summary[years[y]][data.starID[s2]].scanTime[1] :=
                    data.scanTime[s2];
                summary[years[y]][data.starID[s2]].scanNumber[1] := s2
                summary[years[y]][data.starID[s2]].scanID[1] := data.scanID[s2];
              } else {
                summary[years[y]][data.starID[s2]].numScan +:= 1;
                numScan := summary[years[y]][data.starID[s2]].numScan;
                summary[years[y]][data.starID[s2]].date[numScan] := date;
                summary[years[y]][data.starID[s2]].scanTime[numScan] :=
                    data.scanTime[s2];
                summary[years[y]][data.starID[s2]].scanNumber[numScan] := s2
                summary[years[y]][data.starID[s2]].scanID[numScan] :=
                    data.scanID[s2];
              }
            }
          }
        }
      }
    }
    return( summary );
  }
       
  
  # Get the summary for a list of stars

  const public.totalSummary := function( starsID = '' ) {
    wider private;
    summary := [=];
    starsID := to_upper( split( as_string( starsID ), ' ' ) );
    if ( length( starsID ) == 0 ) {
      starsID := '';
    }
    years := private.years();
    for ( y in 1:length( years ) ) {
      filesCha := private.filesCha( years[y] );
      for ( f in 1:length( filesCha ) ) {
        date := private.getDate( filesCha[f] );
        data := private.getData( filesCha[f] )
        for ( s1 in 1:length( starsID ) ) {
          for ( s2 in 1:length( data.starID ) ) {
            if ( starsID[s1] == data.starID[s2] || starsID == '' ) {
              if ( !has_field( summary, data.starID[s2] ) ) {
                summary[data.starID[s2]] := [=];
                summary[data.starID[s2]].numScan := 1;
                summary[data.starID[s2]].date[1] := date;
                summary[data.starID[s2]].scanTime[1] := data.scanTime[s2];
                summary[data.starID[s2]].scanNumber[1] := s2;
                summary[data.starID[s2]].scanID[1] := data.scanID[s2];
              } else {
                summary[data.starID[s2]].numScan +:= 1;
                numScan := summary[data.starID[s2]].numScan;
                summary[data.starID[s2]].date[numScan] := date;
                summary[data.starID[s2]].scanTime[numScan] := data.scanTime[s2];
                summary[data.starID[s2]].scanNumber[numScan] := s2;
                summary[data.starID[s2]].scanID[numScan] := data.scanID[s2];
              }
            }
          }
        }
      }
    }
    return( summary );
  }
  
  
  # Create the GUI
  
  const public.gui := function( ) {
  }
  
  
  # Return the reference to the public.* member functions
  
  return( ref public );
  
}
