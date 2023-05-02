function mesh = generateSmoothMesh(CSX, meshRes_air_min, mesh, config)
% mesh = generateSmoothMesh(CSX, meshRes_air_min, mesh, config)
%
% Create smooth mesh lines based on detected model edges.
% In order to increase accuracy, the algorithm places to close, opposing mesh
% lines instead of one coinciding the actual edge.
%
% input:
%   CSX:   CSX-object created by InitCSX()
%   meshRes_air_min: minimum required resolution in air (eps_r=1)
%   mesh:   existing mesh lines
%   config
%
% optional config keys:
%
%   'sizeAccuracy':   % Desired minimum accuracy of model sizes [unit*m] (default is 0.5)
%
%   'minEdgeAccuracy'  Min resolution of edge mesh lines (relative to distance of 
%                         neighbouring edges) (default is 0.01)
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
% output:
%   mesh: generated mesh
%



% Based on DetectEdges.m by Koen De Vleeschauwer (c) 2012 and Thorsten Liebig (c) 2012, 2013

  supported_properties = {};
  supported_properties{end+1}='Metal';
  supported_properties{end+1}='Material';
  supported_properties{end+1}='Excitation';
  supported_properties{end+1}='LumpedElement';
  supported_properties{end+1}='ConductingSheet';
  
  forcedCoincidingMesh_properties = {};
  forcedCoincidingMesh_properties{end+1}='Excitation';
  forcedCoincidingMesh_properties{end+1}='LumpedElement';


  exclude_list = {};
  prop_list_only = {};


  debug = 1;
  

  sizeAccuracy = 0.5;
  minEdgeAccuracy = 0.01;
  maxAllowedError=0.01;
  STLMeshRes = 1;  
  chamferResolution = 0.2;
  
  if isstruct(config)
    if isfield(config, 'sizeAccuracy')
      sizeAccuracy=config.sizeAccuracy;
    endif
    if isfield(config, 'minEdgeAccuracy')
      minEdgeAccuracy=config.minEdgeAccuracy;
    endif
    if isfield(config, 'maxAllowedError')
      maxAllowedError=config.maxAllowedError;
    endif
    if isfield(config, 'STLMeshRes')
      STLMeshRes=config.STLMeshRes;
    endif
    if isfield(config, 'chamferResolution')
      chamferResolution=config.chamferResolution;
    endif
    if isfield(config, 'Debug')
      Debug=config.Debug;
    endif
    if isfield(config, 'AddPropertyType')
      if iscell(config.AddPropertyType)
          supported_properties(end+1) = config.AddPropertyType;
      elseif ischar(config.AddPropertyType)
          supported_properties{end+1} = config.AddPropertyType;
      else
         error('generateSmoothMesh','unknown property definition');
      end
    endif
    if isfield(config, 'SetPropertyType')
      if iscell(config.SetPropertyType)
          supported_properties(end+1) = config.SetPropertyType;
      elseif ischar(config.SetPropertyType)
          supported_properties{end+1} = config.SetPropertyType;
      else
         error('generateSmoothMesh','unknown property definition');
      end
    endif
    if isfield(config, 'ExcludeProperty')
      exclude_list = config.ExcludeProperty;
    endif
    if isfield(config, 'SetProperty')
      prop_list_only = config.SetProperty;
    endif
  endif
  
  edgeRes = sizeAccuracy/2*3;
  
  origCoordNames = {};  
  if (CSX.ATTRIBUTE.CoordSystem==0)
      origCoordNames = {'x', 'y', 'z'};  
##  elseif (CSX.ATTRIBUTE.CoordSystem==1)
##      origCoordNames = {'r', 'a', 'z'};  
  else
      error('CSXCAD:generateSmoothMesh','unknown or unsupported coordinate system used');
  end


  for k=1:numel(origCoordNames)    
    c = origCoordNames{k};
    if !isfield(mesh, c)
      mesh.(c)=[];
    endif
  endfor 

  refineRegions = {};
  refineRegions.X = [];
  refineRegions.Y = [];
  refineRegions.Z = [];

  edges = {};
  edges.X = [min(mesh.(origCoordNames{1})) max(mesh.(origCoordNames{1}))];
  edges.Y = [min(mesh.(origCoordNames{2})) max(mesh.(origCoordNames{2}))];
  edges.Z = [min(mesh.(origCoordNames{3})) max(mesh.(origCoordNames{3}))];

  if (~isstruct(CSX))
      error('expected a CSX structure');
  end

  CoordSystem = CSX.ATTRIBUTE.CoordSystem;
  physical_constants;
  
  if (isfield(CSX, 'Properties'))
      prop_fn = fieldnames(CSX.Properties);
      for p = 1:numel(prop_fn)
          if (sum(strcmpi(prop_fn{p}, supported_properties))==0)
              continue;
          end
          %isMetal = sum(strcmpi(prop_fn{p},{'Metal','ConductingSheet'}));

          
          property_group = CSX.Properties.(prop_fn{p});
          for m = 1:numel(property_group)
              property=property_group{m};
              if ~isfield(property, 'Primitives')
                  continue;
              end
              if (sum(strcmpi(property.ATTRIBUTE.Name,exclude_list)))
                  continue;
              end
              if (~isempty(prop_list_only) && (sum(strcmpi(property.ATTRIBUTE.Name,prop_list_only))==0))
                  continue;
              end
              
              epsR = 1;
              if ( strcmp('Material', prop_fn{p})
                && isfield(property,'Property')
                && isfield(property.Property.ATTRIBUTE,'Epsilon')
                )
                epsR = property.Property.ATTRIBUTE.Epsilon;
              endif
              
              resWlLimit = meshRes_air_min/sqrt(epsR);
              
              primitives = property.Primitives;
              prim_fn = fieldnames(primitives);
              for n_prim = 1:numel(prim_fn)
                  if (strcmp(prim_fn{n_prim}, 'Box'))
                      for b = 1:length(primitives.Box)
                          box = primitives.Box{b};
                          
                          coordNames = {'X', 'Y', 'Z'};  
                          for k=1:numel(coordNames)
                            c = coordNames{k};
                            v1 = box.P1.ATTRIBUTE.(c);
                            v2 = box.P2.ATTRIBUTE.(c);
                            if (v1==v2)
                              edges.(c) = [edges.(c) v1];
                            else
                              edges.(c) = [edges.(c) v1 v2];
                              if epsR ~= 1
                                refineRegions.(c)(end+1,:) = [resWlLimit v1 v2];
                              endif
                              
                            endif                            
                          endfor
                      endfor
                  elseif (strcmp(prim_fn{n_prim}, 'LinPoly') || strcmp(prim_fn{n_prim}, 'Polygon'))
                      for l = 1:length(primitives.(prim_fn{n_prim}))
                          poly = primitives.(prim_fn{n_prim}){l};
                          dir = poly.ATTRIBUTE.NormDir + 1;
                          dirU = mod(poly.ATTRIBUTE.NormDir+1,3) + 1;
                          dirV = mod(poly.ATTRIBUTE.NormDir+2,3) + 1;
                          lin_length = 0;
                          if (strcmp(prim_fn{n_prim}, 'LinPoly'))
                              lin_length = poly.ATTRIBUTE.Length;
                          end

                          edges_U = [];
                          edges_V = [];
                          if (isfield(poly, 'Vertex'))
                              prev_u = poly.Vertex{end}.ATTRIBUTE.X1;
                              prev_v = poly.Vertex{end}.ATTRIBUTE.X2;
                              for vtx = 1:length(poly.Vertex)
                                  vertex_attribute = poly.Vertex{vtx}.ATTRIBUTE;
                                  u = vertex_attribute.X1;
                                  v = vertex_attribute.X2;
                                  edges_U = [edges_U, u];
                                  edges_V = [edges_V, v];
                                  
                                  % Add refine region if line is not parallel
                                  if prev_u ~= u && prev_v ~= v
                                    refineRegions.(coordNames{dirU})(end+1,:) = [chamferResolution, min([u, prev_u]), max([u, prev_u])];
                                    refineRegions.(coordNames{dirV})(end+1,:) = [chamferResolution, min([v, prev_v]), max([v, prev_v])];
                                  endif
                                  prev_u = u;
                                  prev_v = v;
                              end
                          end
                          
                          if ~isempty(edges_U) && ~isempty(edges_V)
                            coordNames = {'X', 'Y', 'Z'};
                            edges.(coordNames{dir}) = [edges.(coordNames{dir}), poly.ATTRIBUTE.Elevation, (poly.ATTRIBUTE.Elevation+lin_length)];
                            edges.(coordNames{dirU}) = [edges.(coordNames{dirU}), edges_U];
                            edges.(coordNames{dirV}) = [edges.(coordNames{dirV}), edges_V];
                            
                            if epsR ~= 1
                              refineRegions.(coordNames{dir})(end+1,:) = [resWlLimit, poly.ATTRIBUTE.Elevation, (poly.ATTRIBUTE.Elevation+lin_length)];
                              
                              if min(edges_U) ~= max(edges_U)
                                refineRegions.(coordNames{dirU})(end+1,:) = [resWlLimit, min(edges_U), max(edges_U)];
                              endif
                              
                              if min(edges_V) ~= max(edges_V)
                                refineRegions.(coordNames{dirV})(end+1,:) = [resWlLimit, min(edges_V), max(edges_V)];
                              endif
                              
                            endif
                          endif
                      endfor
                  elseif (strcmp(prim_fn{n_prim}, 'Curve'))
                      for l = 1:length(primitives.(prim_fn{n_prim}))
                          curve = primitives.(prim_fn{n_prim}){l};
                          if (isfield(curve, 'Vertex'))
                              for v = 1:length(curve.Vertex)
                                  vertex = curve.Vertex{v};
                                  coordNames = {'X', 'Y', 'Z'};  
                                  for k=1:numel(coordNames)
                                    c = coordNames{k};
                                    v1 = vertex.ATTRIBUTE.(c);
                                    edges.(c) = [edges.(c) v1];
                                  endfor
                              end
                          end
                      end
                  elseif (strcmp(prim_fn{n_prim}, 'Cylinder'))
                      for c = 1:length(primitives.Cylinder)
                          cylinder = primitives.Cylinder{c};
                          r = cylinder.ATTRIBUTE.Radius;
                          x1 = cylinder.P1.ATTRIBUTE.X;
                          y1 = cylinder.P1.ATTRIBUTE.Y;
                          z1 = cylinder.P1.ATTRIBUTE.Z;
                          x2 = cylinder.P2.ATTRIBUTE.X;
                          y2 = cylinder.P2.ATTRIBUTE.Y;
                          z2 = cylinder.P2.ATTRIBUTE.Z;
                          start=stop=[];
                          if ((x1 == x2) && (y1 == y2) && (z1 ~= z2))
                            % cylinder parallel with z axis
                            start = [x1 - r, y1 - r, z1];
                            stop  = [x2 + r, y2 + r, z2];
                          elseif ((x1 == x2) && (y1 ~= y2) && (z1 == z2))
                            % cylinder parallel with y axis
                            start = [x1 - r, y1, z1 - r];
                            stop  = [x2 + r, y2, z2 + r];
                          elseif ((x1 ~= x2) && (y1 == y2) && (z1 == z2))
                            % cylinder parallel with x axis
                            start = [x1, y1 - r, z1 - r];
                            stop  = [x2, y2 + r, z2 + r];
                          elseif (debug > 0)
                            warning('generateSmoothMesh',['unsupported primitive of type: "' prim_fn{n_prim} '" found, skipping refineRegions']);
                          end
                          if ~isempty(start) && ~isempty(stop)
                            coordNames = {'X', 'Y', 'Z'};  
                            for k=1:numel(coordNames)
                              c = coordNames{k};
                              v1 = start(k);
                              v2 = stop(k);
                              edges.(c) = [edges.(c) v1 v2];
                              if epsR ~= 1
                                refineRegions.(c)(end+1,:) = [resWlLimit v1 v2];
                              endif                          
                            endfor
                          endif
                          
                      end
                  else
                      if (debug>0)
                          warning('generateSmoothMeshs',['unsupported primitive of type: "' prim_fn{n_prim} '" found, skipping refineRegions']);
                      end
                  end
              end
          end
      end
  end
  
  % Iterate through coordinate components
  coordNames = {'X', 'Y', 'Z'};  
  for k=1:numel(coordNames)    
    c = coordNames{k};
    edges.(c) = unique(sort(edges.(c)));
    m = sort(unique([mesh.(origCoordNames{k}) edges.(c)])); % Add edges to mesh

    for l=2:numel(edges.(c))-1
      
      d_opt_l = getOptMeshDist(edges.(c), m, l, -1, edgeRes, maxAllowedError);
      d_opt_h = getOptMeshDist(edges.(c), m, l, +1, edgeRes, maxAllowedError);
      newMeshLines = [];
      if ~isempty(d_opt_l)
        newMeshLines = [newMeshLines edges.(c)(l) - d_opt_l];
      endif
 
      if ~isempty(d_opt_h)
        newMeshLines = [newMeshLines edges.(c)(l) + d_opt_h];
      endif
      
      if ~isempty(newMeshLines)
        m = sort(unique([m newMeshLines])); % Add coincidingLines to mesh 
      endif
    endfor
    
    mesh.(origCoordNames{k}) = m; % Add coincidingLines to mesh
  endfor
  
  % Add  mesh lines for polyhedron (STL) files
  for property = [CSX.Properties.Material CSX.Properties.Metal]
    for k=1:numel(property) % iterate through different materials/metals
      
      % Check whether there are  polyhedrons for this metal/material
      if( isfield(property{k},'Primitives')
          && isfield(property{k}.Primitives,'PolyhedronReader') )
        for l=1:numel(property{k}.Primitives.PolyhedronReader)
          % Get a list of vertices for the transformed polyhedron
          vertices = getPolyhedronVertices(property{k}.Primitives.PolyhedronReader{l});
          
          % Add mesh lines for the most frequent edges complying the max resolution
          mesh = addPolyhedronMesh(vertices, mesh, STLMeshRes);
        endfor
      endif
    endfor
  endfor
    
  % Refine mesh according to eps_r in specific regions
  for k=1:numel(coordNames)        
    m = sort(unique(mesh.(origCoordNames{k})));
    
    regions = refineRegions.(coordNames{k});
    regions = sortrows(regions,1);
    for l = 1:size(regions,1)
      start = min(regions(l,2:3));
      stop = max(regions(l,2:3));
      maxRes_loc = regions(l,1);
      
##      m=mesh.(meshNames{k});
##      for n=m
##        if abs(regions(l,2)-m)<2^(-8)
##          regions(l,2) = m;
##        endif      
##        if abs(regions(l,3)-m)<2^(-8)
##          regions(l,3) = m;
##        endif
##      endfor
      m_loc_ids = find(m>=start & m<=stop);
      l_id=m_loc_ids(1);      
      while l_id>=2 && ( m(l_id)-m(l_id-1)<= maxRes_loc )
        l_id--;
      endwhile
      
      h_id=m_loc_ids(end);      
      while h_id<=length(m)-1 && ( m(h_id+1)-m(h_id)<= maxRes_loc )
        h_id++;
      endwhile

      m_loc = SmoothMeshLines3(m(l_id:h_id), maxRes_loc);
      
      m = sort(unique([m m_loc]));        
    endfor
    
    m = SmoothMeshLines3(m, meshRes_air_min);

    mesh.(origCoordNames{k}) = sort(unique(m)); % Add coincidingLines to mesh
  endfor
endfunction


function d_opt = getOptMeshDist(edges, mesh, pos, dir, edgeRes, maxAllowedError)

  %Calculate actual neighbouring mesh line distances
  % (a possible mesh line at the edge is only included for d_act_mesh_opposite calculation) 
  d_act_mesh = [];
  
  if dir > 0
    mesh_h = mesh>edges(pos); % list of greater mesh lines
    if any(mesh_h)
      d_act_mesh = mesh(mesh_h)(1) - edges(pos);
    endif
  else
    mesh_l = mesh<edges(pos); % list of lower mesh lines
    if any(mesh_l)
      d_act_mesh = edges(pos) - mesh(mesh_l)(end);
    endif
  endif
  
  d_act_edge = abs(edges(pos)-edges(pos+dir));
  
  if ( ~isempty(d_act_mesh)
##    && d_act_mesh < d_act_edge
    && d_act_mesh < edgeRes*(1+maxAllowedError) )
    d_opt=[];
  else
    if d_act_edge <= 2* edgeRes
      d_opt = min([d_act_edge, d_act_mesh])/2;
    else
      d_opt = min([edgeRes, d_act_edge/3, d_act_mesh/2]);
    endif
  endif  
endfunction


##function res = CoordSystemisValid(refineRegions, csx_prim, CoordSystem, debug)
##  if isfield(csx_prim.ATTRIBUTE,'CoordSystem')
##      if (csx_prim.ATTRIBUTE.CoordSystem~=CoordSystem)
##          if (debug>0)
##              warning('generateSmoothMesh','different coordinate systems not supported, skipping refineRegions');
##          end
##          return
##      end
##  end
##endfunction
##
##function [start stop] = processTransforms(csx_prim, start, stop, debug)
##  
##  if (isfield(csx_prim, 'Transformation'))
##
##      transformation = csx_prim.Transformation;
##      trans_fn = fieldnames(transformation);
##
##      for t=1:numel(trans_fn)
##          if (strcmp(trans_fn{t}, 'Translate'))
##              start = start + transformation.Translate.ATTRIBUTE.Argument;
##              stop = stop + transformation.Translate.ATTRIBUTE.Argument;
##          else
##              if (debug>0)
##                  warning('generateSmoothMesh','unsupported transformation found in primitive, skipping refineRegions');
##              end
##              return
##          end
##      end
##
##  end
##
##endfunction