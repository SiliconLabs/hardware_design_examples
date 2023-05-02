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
BW = f0*0.7; % Simulation bandwidth [Hz]

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
% ^Y
% |  Origo
% |/                      substrate.width                 
% o---->X______________________________________________________   __ substrate.
% | A           <------- ifa.length ------>         ifa.height |\  __ thickness
% | | keepout.   __________________________  _          /      | |
% | | height    |    ___  _________________| _ ifa.tw  A       | |
% | |           |   |   ||                             |       | |
% |_V___________|___|___||_____________________________V_______| |
% | short.tw -> |   |   |\                                     | | substrate.
% |  short.width -> |   | \                                    | |  height
% |          feed.tw -> ||  Excitation                         | |
% |                     |                                      | |
% |<-----feed.pos ----->|                                      | |
% |                                                            | |
% |____________________________________________________________| |
%  \____________________________________________________________\|
%
%

%% Define all model parameters

substrate.width = 50;       % Width of substrate
substrate.height = 50;      % Height of substrate
substrate.thickness = 1.5;  % Thickness of substrate

keepout.height = 8;         % Height of antenna keepout area

ifa.length = 24.7;          % Total length of IFA antenna
ifa.height = 7.5;           % Total height of IFA antenna 
ifa.tw = 1;                 % Width of main (horizontal) IFA trace

short.tw = 3;               % Trace width of (vertical) short circuit stub
short.width = 4.5;          % Inner width of inductive short circuit loop

feed.pos = 20;              % Distance of feed from the (left) edge of dielectric
feed.tw = 1;                % Trace width of feed element

port.height = 0.5;  % Height of simulation lumped port
port.R = 50;        % Resistance of feeding port [Ohm]

substrate.epsR   = 4.4;         % Relative permittivity (dielectric constant) of substrate
substrate.lossTangent = 0.02;   % Loss tangent of substrate
substrate.kappa  = substrate.lossTangent * 2*pi*f0 * EPS0 * substrate.epsR; % Calculate kappa based on loss tangent

%%% Create the model using the defined parameters

%% Create substrate
CSX = AddMaterial( CSX, 'substrate'); % Add substrate material
CSX = SetMaterialProperty( CSX, 'substrate', 'Epsilon',substrate.epsR, 'Kappa', substrate.kappa); % Set substrate material properties

p1 = [0, 0, 0]; % First corner of the substrate (P1) is at the origin [0, 0, 0]
p2  = p1 + [substrate.width, -substrate.height, -substrate.thickness]; % Calculate second corner of substrate (P2)
CSX = AddBox( CSX, 'substrate', 1, p1, p2 );   % Add box defined by P1 & P2 to sim model using 'substrate' material and priority 1

%% Create top and bottom ground planes and vias (simplified to a single metal box)
CSX = AddMetal( CSX, 'groundplane' ); % Add a perfect electric conductor (PEC) metal property for ground

p1 = [0, -keepout.height, 0];
p2  = [substrate.width, -substrate.height, -substrate.thickness];
CSX = AddBox(CSX, 'groundplane', 2, p1, p2); % Add metal box to sim model using priority 2 (higher value means higher priority)

%% Create ifa
CSX = AddMetal( CSX, 'ifa' ); % create separate metal property for IFA antenna
fp = [feed.pos, -keepout.height, 0];   % Calculate feed position to simplifying calculations

% Feed element
p1 = fp + [0, port.height, 0];
p2 = fp + [feed.tw, ifa.height, 0];
CSX = AddBox( CSX, 'ifa', 3,  p1, p2);

% Short circuit stub
p1 = fp + [-short.width, 0, 0];
p2 =  p1 + [-short.tw, ifa.height, 0];
CSX = AddBox( CSX, 'ifa', 3,  p1, p2);

% Horizontal element
p1 = fp + [-(short.width+short.tw), ifa.height, 0];
p2 = p1 + [ifa.length, -ifa.tw, 0];
CSX = AddBox( CSX, 'ifa', 3, p1, p2);

%% Create excitation port
p1 = fp;
p2  = p1 + [feed.tw, port.height, 0];
[CSX port] = AddLumpedPort(CSX, 4 ,1 ,port.R, p1, p2, [0 1 0], true); % See https://openems.de/index.php/Ports.html

%% Define antenne center for more accurate antenna gain calculation
antennaCenter = fp + [feed.tw/2, ifa.height/2, 0];

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
