close all; % close all plots
clc; % clear console
meshConfig = {};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%   Application Specific Code Begin  %%%%%%%%%%%%%%%%%%%%%%%
% Simulation Configuration
% TODO: Configure simulation by modifying the listed variables

% Generic settings
runInitializations = 1;
showModel          = 1;
runSolver          = 1;
calcPortReflection = 1;
calcAntennaGain    = 1;

saveSession = 1; % set to 1 to automatically save model and outputs

unit = 1e-3; % all length in mm

f0 = 2.45e9; % center frequency of simulation [Hz]
BW = 1e9; % Simulation bandwidth [Hz]

% Boundary condition (simulating open space propagation)
usePML = 0; % set to 1 for more accurate absorbing boundary condition
            % (increases calculation time)
            
% Mesh configuration

%meshConfig.sizeAccuracy = 0.5; % Desired minimum accuracy of model sizes [unit*m] (default is 0.5)
%meshConfig.meshRes = 1/20; % minimum mesh resolution compared to min wavelength (default is 1/20)

% Post-processing config
plotFreq = (f0-BW/2):1e6:(f0+BW/2); % Frequency values to plot e.g.: {f_start}:{f_step}:{f_stop}
plotMarkers = [2405e6 2445e6 2485e6]; % Marker locations on plots

gainCalcFreq = [2445e6]; % Frequency value(s) where the antenna gain will be calculated

%%%%%%%%%%%%%%%%%%%%%   Application Specific Code End   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

physical_constants;

if runInitializations
[simEnv, CSX, FDTD, mesh]  = initSimulation(f0, BW, mfilename('fullpath'), saveSession, usePML);
antennaCenter=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%   Application Specific Code Begin  %%%%%%%%%%%%%%%%%%%%%%%
% Model Definition
% TODO: (1) Add model elements by writing to 'CSX'
%       (2) Assign excitation port by defining 'port'.
%           e.g.: [CSX port] = AddLumpedPort(CSX, ...
%       (3) (optional) Define center of radiation ('antennaCenter')
%           for more accurate gain calculation
%       (4) (optional) Add mesh lines manually by adding elements to 'mesh.x',
%           'mesh.y' and 'mesh.z' if needed.
%


%%%%%%%%%%%%%%%%%%%%%   Application Specific Code End   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CSX = generateMesh(CSX, FDTD, unit, mesh, meshConfig);

if calcAntennaGain
  [CSX, nf2ff]=addNF2FFBox(CSX, FDTD);
endif

% Write OpenEMS compatible xml-file
WriteOpenEMS( [simEnv.simPath filesep simEnv.modelName], FDTD, CSX );

endif % runInitializations

if showModel
  % Show the structure
  CSXGeomPlot( [simEnv.simPath filesep simEnv.modelName], ['--export-polydata-vtk=' simEnv.simPath filesep 'models']);
endif

if runSolver;
  RunOpenEMS( simEnv.simPath, simEnv.modelName, '--debug-PEC');  % Run Simulation
endif


if calcPortReflection
  calculatePortReflection(simEnv, port, plotFreq, 'freqMarkers', plotMarkers );
endif

if calcAntennaGain
  calculateAntennaGain(simEnv, CSX, nf2ff, port, gainCalcFreq, unit, antennaCenter);
endif
