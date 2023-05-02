function mesh = cropMesh(mesh,p1,p2)
  
  fieldNames = fieldnames(mesh);
  if 3!=numel(fieldNames)
    error 'invalid input mesh'
  endif
  
  for k=1:numel(fieldNames)
    u=mesh.(fieldNames{k});
    for m=u
      if abs(p1(k)-m)<2^(-8)
        p1(k) = m;
      endif      
      if abs(p2(k)-m)<2^(-8)
        p2(k) = m;
      endif
    endfor
    
    mesh.(fieldNames{k}) = unique([p1(k) u(u>=min([p1(k) p2(k)]) & u<=max([p1(k) p2(k)])) p2(k)]);      
  endfor
  
endfunction