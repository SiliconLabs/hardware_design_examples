function markers=getMarkerPoints(port,plotFreq,freqMarkers,s11dBMarkers,addNegPeakMarkers)

  s11_dB = mag2db(abs(port.uf.ref ./ port.uf.inc)); % s11_dB=20*log10(s11)
  
  markers = [];
  
  % Find markers defined by frequency
  for k=1:length(freqMarkers)
    [~, m]=min(abs(plotFreq-freqMarkers(k)));
    markers = [markers m];
  endfor
  
  % Find markers defined by S11 [dB]
  for k=1:length(s11dBMarkers)
    [~, m] = findpeaks(-abs(s11_dB-s11dBMarkers(k))+max(abs(s11_dB-s11dBMarkers(k))));
    markers = [markers m];
  endfor
  
  % Find neagtive peaks 
  if addNegPeakMarkers
    for k=1:length(s11dBMarkers)
      [~, m] = findpeaks(-1*(s11_dB-max(s11_dB)), "MinPeakDistance", 10e6); % Filter peaks which are at least 10 MHz apart
      markers = [markers m];
    endfor
  endif
  
  markers=unique(markers); %keep only unique values
endfunction