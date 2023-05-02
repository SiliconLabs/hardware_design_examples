% Recursive function which rounds model coordinates by iterating through CSX
% fields and rounding numbers having parent node named 'Primitives' or 'RectilinearGrid'.

function node = roundCSXPositionsRecursive(node, roundN=10, enableWrite=0)
  
  activating_fieldNames = {};
  activating_fieldNames{end+1}='Primitives';
  activating_fieldNames{end+1}='RectilinearGrid';
  activating_fieldNames{end+1}='mesh';
  
  if(isnumeric(node) && enableWrite)
    node = round(node * 2^roundN) * 2^(-roundN); %round value
  elseif(isstruct(node))
    fieldNames = fieldnames(node);
    for k=1:numel(fieldNames)
      if sum(strcmpi(fieldNames{k}, activating_fieldNames))
        enableWrite=1;
      endif
      node.(fieldNames{k})=roundCSXPositionsRecursive(node.(fieldNames{k}), roundN, enableWrite);
    endfor
    
  elseif(iscell(node))
    for k=1:numel(node)
      node{k}=roundCSXPositionsRecursive(node{k}, roundN, enableWrite);
    endfor
  endif 
endfunction