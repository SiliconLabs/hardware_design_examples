function [CSX, nf2ff]=addNF2FFBox(CSX, FDTD, MURdist=3)

  fieldNames = fieldnames(FDTD.BoundaryCond.ATTRIBUTE);
  for k=1:numel(fieldNames)
    separation=0;
    if 1 == length(pmlLevel=sscanf(FDTD.BoundaryCond.ATTRIBUTE.(fieldNames{k}),'PML_%d'))
      separation=pmlLevel;
    elseif strcmp('MUR', FDTD.BoundaryCond.ATTRIBUTE.(fieldNames{k}))
      separation=MURdist;
    endif
    
    switch fieldNames{k}
      case 'xmin'
        start(1)=CSX.RectilinearGrid.XLines(1+separation);
      case 'xmax'
        stop(1)=CSX.RectilinearGrid.XLines(end-separation);
      case 'ymin'
        start(2)=CSX.RectilinearGrid.YLines(1+separation);
      case 'ymax'
        stop(2)=CSX.RectilinearGrid.YLines(end-separation);
      case 'zmin'
        start(3)=CSX.RectilinearGrid.ZLines(1+separation);
      case 'zmax'
        stop(3)=CSX.RectilinearGrid.ZLines(end-separation);
    endswitch
      
  endfor 
  
  [CSX, nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', start, stop); 
endfunction