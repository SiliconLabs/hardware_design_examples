
function saveS1P(fileName, port, plotFreq)

s11 = port.uf.ref ./ port.uf.inc;

file_id = fopen(fileName, 'w');
fprintf(file_id,'# Hz S RI R 50\n');

for k = 1:numel(plotFreq)
  fprintf(file_id,'%i\t%E\t%E\n', plotFreq(k),real(s11(k)),imag(s11(k)));
endfor

fclose(file_id);

endfunction