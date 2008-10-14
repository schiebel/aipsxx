include 'simulator.g';

    mysim := simulatorfromms("sim+ALMA+SD/sim+ALMA+SD.ms");
    mysim.setoptions(ftmachine="both", gridfunction="pb");
    mysim.setvp(dovp=T, vptable="sim+ALMA+SD/sim+ALMA+SD.vp", usedefaultvp=F);
    mysim.predict("sim+ALMA+SD/sim+ALMA+SD.model");
    mysim.done();
