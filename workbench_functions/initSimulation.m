function [simEnv, CSX, FDTD, mesh] = initSimulation(f0, BW, fullPath, saveSession, usePML, varargin)
% initSimulation(f0, BW, fullPath, saveSession, usePML [, varargin])
%
% Initialize simulation


  disp( 'Initialization...' );
  
  NrTs_max = 1e5; %max. number of timesteps
  EndCriteria = 1e-5;
  
  for n=1:2:numel(varargin)
      if (strcmpi(varargin{n},'NrTs_max')==1);
          NrTs_max = varargin{n+1};
          
      elseif (strcmpi(varargin{n},'EndCriteria')==1);
          EndCriteria = varargin{n+1};
          
      else
          warning('calculatePortReflection',['unknown argument: ' varargin{n}]);
      end
  end
  
  pkg load signal;

  
  CSX = InitCSX();
  
  modelName = "model.csx";
  
  FDTD = InitFDTD('NrTS',  NrTs_max, 'EndCriteria', EndCriteria); % max. number of timesteps
  FDTD = SetGaussExcite( FDTD, f0, BW/2 );
  
  BC={};
  if usePML
    BC = {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8'}; % use PML_8 for more accurate results (runs slower)
  else
   BC = {'MUR' 'MUR' 'MUR' 'MUR' 'MUR' 'MUR'}; % use MUR for fast calculation
  endif
  
  % Set boundary conditions
  FDTD = SetBoundaryCond( FDTD, BC );
  
  [workspacePath, fileName, ~] = fileparts(fullPath);
  
  time = clock();
  timeString = sprintf('%04d-%02d-%02d_%02d-%02d-%02.0f',time(1),time(2),time(3),time(4),time(5),time(6));
  sessionName= [fileName "_" timeString];
  
  if 1 == saveSession
    simPath = [workspacePath filesep "sessions" filesep sessionName];
  else
    simPath = [workspacePath filesep "tmp"];
    confirm_recursive_rmdir(0);
    rmdir(simPath,'s');
  endif
  
  mkdir(simPath);
  mkdir([simPath filesep 'models']);
  
  copyfile([workspacePath filesep fileName '.m'],[simPath filesep fileName '.m.bak']);

  mesh={};
  mesh.x=[];
  mesh.y=[];
  mesh.z=[];
  
  % Update simulation environment
  simEnv.modelName = modelName;
  simEnv.workspacePath = workspacePath;
  simEnv.fileName=fileName;
  simEnv.sessionName = sessionName;
  simEnv.simPath = simPath;
  
endfunction