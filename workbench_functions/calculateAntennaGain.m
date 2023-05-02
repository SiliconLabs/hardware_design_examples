function res = calculateAntennaGain(simEnv, CSX, nf2ff, port, freq, unit, antennaCenter=[])
  
  logscale=20; % range of gain for 3D pattern, gains lower than Gmax-logscale will be clamped 
  
  % Calculate far field in all direction using 2° resolution
  thetaRange = (0:2:180);
  phiRange = (-180:2:180);

  res = {};
  
  disp( 'Calculating radiated antenna properties...' );
  

  
  % Calculate scale to match half of the model size
  modelEdges = DetectEdges(CSX);
  modelStart = [min(modelEdges.x), min(modelEdges.y), min(modelEdges.z)];
  modelStop  = [max(modelEdges.x), max(modelEdges.y), max(modelEdges.z)];
  
  modelSize = max(modelStop - modelStart);
  scale = modelSize * unit/logscale/2;
  
  % If antenna center point is not defined then use [0 0 0]
  if isempty(antennaCenter)
    antennaCenter = (modelStart+modelStop)/2;
    warning(['Antenna center (antennaCenter) was not defined! Using model center [' num2str(antennaCenter,' %g') '] instead...']);
  endif
  
  antennaCenter = antennaCenter .* unit; % Antenna center must be defined in meters
  %antCenter_str = ['[' num2str(antennaCenter(1)) ', ' num2str(antennaCenter(2)) ', ' num2str(antennaCenter(3)) ']'];
  

  
  nf2ff = CalcNF2FF(nf2ff, simEnv.simPath, freq, thetaRange*pi/180, phiRange*pi/180,'Verbose',1,'Mode',0,'Outfile','3D_Pattern.h5','Center', antennaCenter);
 
  %Iterate through frequencies if multiple frequencies were passed
  for k = 1:numel(nf2ff.freq)
##    figure;
##    plotFF3D(nf2ff,'freq_index',k);
    freq = nf2ff.freq(k);
    
    % Calculate port voltage and current
    port = calcPort(port, simEnv.simPath, freq);
    
    % Calculate port powers
    Pport_mVA = 1000 * 0.5 * port.uf.tot .* conj( port.if.tot ); % (complex) apparent port power
    Pin_dBm = pow2db(abs(real(Pport_mVA))); % antenna input power
    Psource_dBm = pow2db(abs(Pport_mVA)); % available source power

    % Calculate radiated powe
    Prad_dBm = pow2db(nf2ff.Prad(k)*1000);
    
    % Calculate antenna directivity, gain and efficiency (excluding mismatch loss)
    Dmax = nf2ff.Dmax(k);
    Dmax_dBi = pow2db(Dmax);
    nu_dB = Prad_dBm-Pin_dBm;
    nu = db2pow(nu_dB);
    Gmax_dBi = nu_dB + Dmax_dBi;
    
    % Calculate antenna gain including mismatch loss (assuming no matching network)
    G_unmatched_dBi = Prad_dBm-Psource_dBm+Dmax_dBi;
    
    % Display radiated properties
    disp( ['@f = ' num2str(freq/1e6,'%.2f') ' MHz']);
    disp( [' - Antenna gain: G = ' num2str(Gmax_dBi,'%.2f') ' dBi']);
    disp( [' - Antenna directivity: Dmax = ' num2str(Dmax,'%.2f') ' (' num2str(Dmax_dBi,'%.2f') ' dBi)'] );
    disp( [' - Antenna efficiency: nu_rad = ' num2str(nu*100,'%.2f') '% (' num2str(nu_dB,'%.2f') ' dB)'] );
    disp( [' - Total gain (including mismatch loss): Gtot = ' num2str(G_unmatched_dBi,'%.2f') ' dBi']);
    
    resultsDirFullPath=[simEnv.simPath filesep 'Gain_Pattern_' num2str(freq/1e6,'%.0f') 'MHz'];
    mkdir(resultsDirFullPath);
    
    % save radiated properties to file
    save([resultsDirFullPath filesep 'resultData.mat'], 'freq', 'Gmax_dBi', 'G_unmatched_dBi', 'Dmax_dBi', 'nu_dB'); 

    modelFullPath = [simEnv.simPath filesep 'PEC_dump.vtp'];
        
    exportGainToVtk(resultsDirFullPath, modelFullPath, thetaRange, phiRange, nf2ff.E_norm{k}, nf2ff.E_theta{k}, nf2ff.E_phi{k}, Gmax_dBi, scale, logscale);

    res(end+1) = struct("freq",freq,"Dmax_dBi",Dmax_dBi,"nu_dB",nu_dB,"Gmax_dBi",Gmax_dBi,"G_unmatched_dBi",G_unmatched_dBi);

  endfor
endfunction