#############################################################################################################################
## atm2_test.g-- to test the new ATM interface


############################################################################################################################
###
  include "servers.g";
  include "table.g";
  include "quanta.g";
  include "misc.g";
##
  include 'atmosphere.g';
###
### Test Atmosphere() -------------------------------------------------------------------------------------------------
  print "Test of constructor  Atmosphere(altitude,temperature,pressure,maxAltitude,humidity,dTempdH,dP,dPm, h0, atmtype )";
### Make an atmosphere tool 
  #print "Firs test he default value for the constructor first.";
  #test_atm:= atmosphere();
##
  MIDLAT_SUMMER:= 2;
  test_atm:= atmosphere(
    	                altitude    = '2550.m',       # m
    			temperature = '270.32K',      # K
    			pressure    = '73585Pa',      # Pascals
    			maxAltitude = '45000m',       # m
    			humidity    = 20,             # % 
    			dTem_dh     = '-0.0056K/m',   # K/m
    			dP          = '500Pa',        # Pascals
    			dPm         = 1.25,
   	    		h0          = '2000.m',       # m
                        atmtype     = MIDLAT_SUMMER        
             );
### Test getStartupWaterContent() -----------------------------------------------------
  print "Test: getStartupWaterContent()";
  water := test_atm.getStartupWaterContent();
  print spaste('### Guessed water content is:   ', water);
###
### Test getProfile( ... ) -------------------------------------------------------------------------------------------------
  print "Test: void getProfile( ... )";
  
  test_atm.getProfile( thickness=thickness, temperature=temperature, water=water, pressure=pressure, O3=O3, CO=CO, N2O=N2O );
## 
    print spaste( '### thickness = ', thickness );
    print spaste( '### (thickness.value)[1],thickness.unit = ', (thickness.value)[1], thickness.unit );
    print spaste( '### (temperature.value) = ', (temperature.value));
    print spaste( '### temperature = ', temperature );
    print spaste( '### water = ', water );
    print spaste( '### pressure = ', pressure);
    print spaste( '### O3 = ', O3 );
    print spaste( '### CO =', CO );
    print spaste( '### N2O =', N2O );
##
### Test initWindow() ---------------------------------------------------------------------------------------------------------- 
  print "Test of initWindow()";
  print "First test how the default values work:";
  test_atm.initWindow();
##
  print "Now test it with passed in values:";  
  nbands := 2;
  #i := 1;
  for ( i in 1:nbands) {
     (fCenter.value)[i] := 88.e9;  
     (fWidth.value)[i] := 5.e8;  
     (fRes.value)[i] := (fWidth.value)[1]/4.0;   # 4 channels
  }

  fCenter.unit := 'Hz';
  fWidth.unit := 'Hz';
  fRes.unit := 'Hz';
  precWater := water;
  
  test_atm.initWindow(nbands=nbands,
		  fCenter=fCenter,
		  fWidth=fWidth,
		  fRes=fRes );
  print spaste( '### fCenter = ', fCenter);
  print spaste( '### fWidth = ', fWidth );
  print spaste( '### fRes = ', fRes );
###
### Test of getNdata() -----------------------
  print "Test of getNdata()";
  print "First test how its default value works:";
  n:=test_atm.getNdata(iband=1);
  print spaste( '### getNdata() = ', n );
##
  print "Now test it with passed in value:";
  n:=test_atm.getNdata(iband=1);
  print spaste( '### getNdata() = ', n );

### Test of getOpacity() --------------------------------------------------------------------------------------------------
  print "Test getOpacity()";
  test_atm.getOpacity( dryOpacity=dryOpacity, wetOpacity=wetOpacity);
  print spaste('### dryOpacity = ', dryOpacity );
  print spaste('### wetOpacity = ', wetOpacity );
###
### Test of getAbsCoeff()  -------------------------------------------------------------------------------------------------
  print "Test getAbsCoeff()";
  test_atm.getAbsCoeff( kH2OLines=kH2OLines, kH2OCont=kH2OCont, kO2=kO2, kDryCont=kDryCont, kO3=kO3, kCO=kCO, kN2O=kN2O );
  #NMAX_DATOS := 128;
  print spaste('### kH2OLines[1] = ', (kH2OLines.value)[1], kH2OLines.unit );
  #print spaste('### kH2OCont = ', kH2OCont );
  #print spaste('### kO2 = ', kO2 );
  #print spaste('### kDryCont = ', kDryCont );
  #print spaste('### kO3 = ', kO3 );
  #print spaste('### kCO = ', kCO );
  #print spaste('### kfN2O = ', kN2O );
###
### Test of getAbsCoeffDer() ------------------------------------------------------------------------------------------------
  print "Test of getAbsCoeffDer()";
  test_atm.getAbsCoeffDer( kH2OLinesDer=kH2OLinesDer, kH2OContDer=kH2OContDer, kO2Der=kO2Der, kDryContDer=kDryContDer,
                              kO3Der=kO3Der, kCODer=kCODer, kN2ODer=kN2ODer );
  print spaste( ' ### kH2OLinesDer[1] =  ', kH2OLinesDer.value[1], kH2OLinesDer.unit );
  #print spaste( ' ### kH2OContDer = ', kH2OContDer );
  #print spaste( ' ### kO2Der = ', kO2Der );
  #print spaste( ' ### kDryContDer =', kDryContDer );
  #print spaste( ' ### kO3Der = ', kO3Der );
  #print spaste( ' ### kCODer = ', kCODer );
  #print spaste( ' ### kN2ODer = ', kN2ODer );
###
### Test of getPhaseFactor () -----------------------------------------------------------------------------------------------
  print "Test of getPhaseFactor()";
  test_atm.getPhaseFactor( dispPhase=dispPhase, nonDispPhase=nonDispPhase ); 
  print spaste( ' ### dispPhase = ' , dispPhase );
  print spaste( ' ### nonDispPhase = ', nonDispPhase );
###
### Test of computeSkyBrightness() ---------------------------------------------------------------------------------------------
  print "Test of computeSkyBrightness()";
  print "First test how its default values work:";
  test_atm.computeSkyBrightness();
##
  print "Now test it with passed in values:";
  airMass := 1.51;
  tbgr    := '2.73K';
  precWater := '4.05e-3m';
  test_atm.computeSkyBrightness(airMass, tbgr, precWater);
  print spaste( '### Temperature of cosmic background = ', tbgr );
  print spaste( '### Value of temperature = ', tbgr );
  print spaste( '### Precipitable water content = ', precWater );
###
### Test of getSkyBrightness() ---------------------------------------------------  
  print "Test of getSkyBrightness()";
  print "First test how its default value works:";
  tBand := test_atm.getSkyBrightness();
  print spaste("SkyBrightness for Blackbody = ",tBand );
##
  print "Now test it with passed in value:";
  BLACKBODY := 1;
  tBand := test_atm.getSkyBrightness(iopt=BLACKBODY);
  print spaste("SkyBrightness for Blackbody = ",tBand );
  RAYLEIGH_JEANS := 2;
  tBand := test_atm.getSkyBrightness(iopt=RAYLEIGH_JEANS);
  print spaste("SkyBrightness(K) for Rayleigh Jeans = ",tBand );
###
### Test of setSkyCoupling() -----------------------------------------------------
  print "Test of setSkyCoupling()";
  print "First test how its default value works:";
  test_atm.setSkyCoupling();
  sc_out := test_atm.getSkyCoupling();
  print spaste( 'SkyCoupling = ', sc_out );
##
  print "Now test it with passed in value:";
  sc_in := 1.0;
  test_atm.setSkyCoupling( c=sc_in );
###
### Test of getSkyCoupling -------------------------------------------------------
  print "Test of getSkyCoupling()";
  sc_out := test_atm.getSkyCoupling();
  print spaste( 'SkyCoupling = ', sc_out );
###
###==========================================================================
  print " Test spectral routines ";
###==========================================================================

### Test of getOpacitySpec() --------------------------------------------------------
  print "Test getOpacitySpec()";
  test_atm.getOpacitySpec( dryOpacitySpec=dryOS, wetOpacitySpec=wetOS );
  
     print spaste( '### dryOpacitySpec = ', dryOS );
     print spaste( '### wetOpacitySpec = ', wetOS );
###
### Test of getSkyBrightnessSpec() ------------------------------------------------------
  print "Test of getSkyBrightnessSpec()";
  print "First test how its default value works:";
  tBandSpec := test_atm.getSkyBrightnessSpec();
  print spaste("SkyBrightnessSpec for Blackbody = ",tBandSpec );
##
  print "Now test it with passed in value:";
  tBandSpec := test_atm.getSkyBrightnessSpec(iopt=BLACKBODY);
  print "For Blackbody:";
       print spaste(' ### SkyBrightnessSpec = ', tBandSpec);

  tBandSpec := test_atm.getSkyBrightnessSpec(iopt=RAYLEIGH_JEANS);
  print "For Rayleigh Jeans: ";
       print spaste(' ### SkyBrightnessSpec = ', tBandSpec );

## end of test code
