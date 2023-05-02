function plotS11Abs(port, plotFreq, markers, sessionName)
  
  s11_dB = mag2db(abs(port.uf.ref ./ port.uf.inc));
  Zin = port.uf.tot ./ port.if.tot;
  plotFreq=plotFreq/1e6; % Plot frequency in MHz
  
  plot( plotFreq, s11_dB, 'r-','Linewidth', 2);
  
  hold on;
  
  % Add major and minor grid lines
  grid on;
  grid minor on;
  
  % Add Title labels and legend
  title( 'Reflection coefficient [dB]' );
  xlabel( 'Frequency [MHz]' );
  ylabel( 'Reflection coefficient |S_{11}| [dB]' );

  

  %Add markers
  for k=1:length(markers)
      id=markers(k);
      f=plotFreq(id);
      r=s11_dB(id);
      z=Zin(id);
      plot(f,r,'bo'); % Add marker
      disp(sprintf('%d MHz:  S11 = %.2f dB,  Z = %.2f%+.2fj',f,r,real(z),imag(z))); % Print marker details to console
      text(f,r,sprintf(' - %d MHz\n   Z = %.2f%+.2fj',f,real(z),imag(z)),'color','blue'); % Add marker label
  endfor
  hold off;
  
  if exist('sessionName')
    legend({sessionName},'Interpreter', 'none'); % Add legend if sessionName was provided
  endif
  
endfunction
