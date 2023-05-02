function CSX = generateMesh(CSX, FDTD, unit, mesh, config)
% mesh = generateMesh(CSX, FDTD, unit, mesh, config)
%
% Add airbox to simulation and generate smooth mesh
%
% input:
%   CSX:   CSX-object created by InitCSX()
%   FDTD:  FDTD-object
%   unit
%   mesh:    existing mesh lines
%   config: meshing configurations
%
% required config keys:
%
% optional config keys:
%   
%   'meshRes':   % minimum mesh resolution compared to wavelength (default is 1/20)
%   
%   'sizeAccuracy':   % Desired minimum accuracy of model sizes [unit*m] (default is 0.5)
%
%   'maxAllowedError'  Max allowed error of actual resolution. Must be >0 
%                      (default is 0.01)
%   'STLMeshRes'       Resolution for homogeneous  STL polyhedron mesh (default is 1)
%                      
%   'chamferResolution'  Resolution for chamfered Polygon and LinPoly lines (default is 0.2)
%
%   'Debug'         enable debug mode (default is 1)
%
%   'AddPropertyType'  add a list of additional property types to detect
%                   e.g. 'DumpBox' or {'DumpBox','ProbeBox'}
%   'SetPropertyType'  set the list of property types to detect (override default)
%                   e.g. 'Metal' or {'Metal','ConductingSheet'}
%   'ExcludeProperty'  give a list of property names to exclude from
%                      detection
%   'SetProperty'  give a list of property names to handly exlusively for detection
%


meshRes = 1/20;

if isstruct(config)
  if isfield(config, 'meshRes')
    meshRes=config.meshRes;
  endif
endif
  
  
  if (CSX.ATTRIBUTE.CoordSystem==0)
    coordNames = {'x', 'y', 'z'};
##  elseif (CSX.ATTRIBUTE.CoordSystem==1)
##    coordNames = {'r', 'a', 'z'};  
  else
    error('generateMesh','unsupported coordinate system used');
  endif
  
  for k=1:numel(coordNames)    
    c = coordNames{k};
    if !isfield(mesh, c)
      mesh.(c)=[];
    endif
  endfor 
  
  boundaryDist = 0.25; % [lambda] distance of boundary box compared tom max wavelength (>0.25 is recommended)
  
  physical_constants; % Include physical constants
  
  % Calculate min and max frequency and wavelength in air and dielectric
  fmin=FDTD.Excitation.ATTRIBUTE.f0 - FDTD.Excitation.ATTRIBUTE.fc;
  fmax=FDTD.Excitation.ATTRIBUTE.f0 + FDTD.Excitation.ATTRIBUTE.fc;
  lambda_air_min=c0/fmax/unit;
  lambda_air_max=c0/fmin/unit;


  % round model coordinates to eliminate numerical errors
  CSX = roundCSXPositionsRecursive(CSX);


  % Initial mesh that coincides the edges of primitives
  edges = DetectEdges(CSX, mesh);
  
  meshRes_air_min = meshRes*lambda_air_min;
  airBox_dist = boundaryDist*lambda_air_max;
  
  % add air box around model
  mesh.x=[mesh.x min(edges.x)-airBox_dist max(edges.x)+airBox_dist];
  mesh.y=[mesh.y min(edges.y)-airBox_dist max(edges.y)+airBox_dist];
  mesh.z=[mesh.z min(edges.z)-airBox_dist max(edges.z)+airBox_dist];
  
  mesh = generateSmoothMesh(CSX, meshRes_air_min, mesh, config);

  % Extend mesh on faces for boundary conditions
  mesh = extendMeshForBoundaryConditions(mesh, FDTD);
  
  % Add mesh to CSX
  CSX = DefineRectGrid(CSX, unit, mesh);
endfunction