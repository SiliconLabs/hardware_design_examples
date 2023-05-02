% add mesh lines on PML faces

function mesh = extendMeshForBoundaryConditions(mesh,FDTD,cellsToAddOnMUR=3)

  cellsToAdd=zeros(1,6);
  fieldNames = fieldnames(FDTD.BoundaryCond.ATTRIBUTE);
  for k=1:numel(fieldNames)
    if 1 == length(pmlLevel=sscanf(FDTD.BoundaryCond.ATTRIBUTE.(fieldNames{k}),'PML_%d'))
      cellsToAdd(k)=pmlLevel;
    elseif strcmp('MUR', FDTD.BoundaryCond.ATTRIBUTE.(fieldNames{k}))
      cellsToAdd(k)=cellsToAddOnMUR;
    endif
  endfor  
  mesh = AddPML( mesh, cellsToAdd);

endfunction