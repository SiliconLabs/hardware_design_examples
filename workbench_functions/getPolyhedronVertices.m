function vertices = getPolyhedronVertices(pReader)
  vertices.x=vertices.y=vertices.z=[];
  % Only STL polyhedrons are supported
  if !strcmp(pReader.ATTRIBUTE.FileType,'STL')
    warning 'Only STL files are supported'
    return;
  endif  
  
  [v, ~, ~] = stlread(pReader.ATTRIBUTE.FileName);
  
  if isfield(pReader,'Transformation')
    tNames = fieldnames(pReader.Transformation);
    for k=1:numel(tNames)
      arg=pReader.Transformation.(tNames{k}).ATTRIBUTE.Argument;
      switch tNames{k}
      case 'Scale'
        v = arg.*v;
      case 'Rotate_X'
        arg = -arg;
        R=[1       0         0;
           0 cos(arg) -sin(arg);
           0 sin(arg)  cos(arg)];
        v = v*R;
      case 'Rotate_Y'
        arg = -arg;
        R=[cos(arg)  0 sin(arg);
           0         1        0;
           -sin(arg) 0 cos(arg)];
        v = v*R;
      case 'Rotate_Z'
        arg = -arg;
        R=[cos(arg) -sin(arg) 0;
           sin(arg)  cos(arg) 0;
                  0         0 1];
        v = v*R;
      case 'Translate'
        t=str2num(arg);
        v += t;
      endswitch
    endfor
  endif
  
  vertices.x=v(:,1);
  vertices.y=v(:,2);
  vertices.z=v(:,3);
  
endfunction

