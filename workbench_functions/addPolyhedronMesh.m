function mesh = addPolyhedronMesh(vertices, mesh, resolution)
  
  axes = {'x' 'y' 'z'};
  for k=1:numel(axes) % Iterate through axes
    mesh_axis = mesh.(axes{k});
    vertices_axis = vertices.(axes{k});
    % Sort vertices in descending order by how frequent they are
    [count,val] = hist(vertices_axis, unique(vertices_axis));
    [~,idx] = sort(-count);
    
    % Ensuring min and max value has highest priority by adding them to the front
    val = [min(val) max(val) val(idx)];
    
    for edge=val
      meshLinesToAdd = [];
      for meshLine = [edge-resolution/2 edge+resolution/2]
        if isempty(mesh_axis) || ( min(abs(mesh_axis-meshLine)) >= resolution )
          meshLinesToAdd(end+1)=meshLine;
        endif
      endfor
      mesh_axis = [mesh_axis meshLinesToAdd];
    endfor
    mesh.(axes{k}) = mesh_axis;    
  endfor
  
  
endfunction
