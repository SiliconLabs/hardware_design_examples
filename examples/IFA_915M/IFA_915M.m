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

f0 = 915e6; % center frequency of simulation [Hz]
BW = f0*0.45; % Simulation bandwidth [Hz]

% Boundary condition (simulating open space propagation)
usePML = 0; % set to 1 for more accurate absorbing boundary condition
            % (increases calculation time)

% Mesh configuration

meshConfig.sizeAccuracy = 0.5; % Desired minimum accuracy of model sizes [unit*m] (default is 0.5)
meshConfig.meshRes = 1/20; % minimum mesh resolution compared to min wavelength (default is 1/20)

% Post-processing config
plotFreq = (f0-BW/4):0.1e6:(f0+BW/4); % Frequency values to plot e.g.: {f_start}:{f_step}:{f_stop}
plotMarkers = [902e6 915e6 928e6]; % Marker locations on plots

gainCalcFreq = [915e6]; % Frequency value(s) where the antenna gain will be calculated

% Smith chart configuration
% '1': Plots the admittance circles instead of impedance
inverse = 0;
% Puts a marker on this frequency on the Smith chart
% '0': turn off this feature
custom_frequency = 0;
% '1': Puts a marker on one of the real(Y) = 1 points
% '2': Puts markers on both of these points
unit_Y = 0;
% '1': Puts a marker on one of the real(Z) = 1 points
% '2': Puts markers on both of these points
unit_Z = 0;
% '1': Puts a marker on the resonance point
% '2': Puts a marker on both of the resonance points
series_resonance = 0;

%%%%%%%%%%%%%%%%%%%%%   Application Specific Code End   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Smith_params = [inverse, ...
                custom_frequency, ...
                unit_Y, ...
                unit_Z, ...
                series_resonance];

physical_constants;

if runInitializations
[simEnv, CSX, FDTD, mesh]  = initSimulation(f0, BW, mfilename('fullpath'), saveSession, usePML);
antennaCenter=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%   Application Specific Code Begin  %%%%%%%%%%%%%%%%%%%%%%%
% Model Definition
% TODO:

%% Define all model parameters

short.tw = 1;
short.width = 1.2;

feed.tw = 1;
feed.position = 15;

edge.distance = 2;

gap.width = 3;

IFA.last_trace = 15.6;
IFA.tw = 1;

substrate.height = 25;
substrate.width = 25;
substrate.thickness = 1.5;

port.height = 0.5;  % Height of simulation lumped port
port.R = 50;        % Resistance of feeding port [Ohm]

substrate.epsR   = 4.4;         % Relative permittivity (dielectric constant) of substrate
substrate.lossTangent = 0.02;   % Loss tangent of substrate
substrate.kappa  = substrate.lossTangent * 2*pi*f0 * EPS0 * substrate.epsR; % Calculate kappa based on loss tangent

%%% Create the model using the defined parameters

%% Create substrate
CSX = AddMaterial( CSX, 'substrate'); % Add substrate material
CSX = SetMaterialProperty( CSX, 'substrate', 'Epsilon',substrate.epsR, 'Kappa', substrate.kappa); % Set substrate material properties

%% Add substrate box
p1 = [0, 0, 0]; % First corner of the substrate (P1) is at the origin [0, 0, 0]
p2  = p1 + [substrate.width, -substrate.height, -substrate.thickness]; % Calculate second corner of substrate (P2)
CSX = AddBox( CSX, 'substrate', 1, p1, p2 );   % Add box defined by P1 & P2 to sim model using 'substrate' material and priority 1

%% Create top and bottom ground planes and vias (simplified to a single metal box)
CSX = AddMetal( CSX, 'groundplane' ); % Add a perfect electric conductor (PEC) metal property for ground

gnd_from_edge = gap.width + IFA.tw + edge.distance;

p1 = [gnd_from_edge, -gnd_from_edge, 0];
p2  = [substrate.width-gnd_from_edge, -substrate.height+gnd_from_edge, -substrate.thickness];
CSX = AddBox(CSX, 'groundplane', 2, p1, p2); % Add metal box to sim model using priority 2 (higher value means higher priority)

%% Create ifa
CSX = AddMetal( CSX, 'ifa' ); % create separate metal property for IFA antenna
IFA.height = gap.width + IFA.tw;
fp = [substrate.width-gnd_from_edge, -feed.position, 0];   % Calculate feed position to simplifying calculations

% Feed element
p1 = fp + [port.height, 0, 0];
p2 = fp + [gap.width, feed.tw, 0];
CSX = AddBox(CSX, 'ifa', 3, p1, p2);

%% Stub version
% Short circuit stub
p1 = fp + [0, -short.width-short.tw, 0];
p2 = p1 + [gap.width, short.tw, 0];
CSX = AddBox(CSX, 'ifa', 3, p1, p2);

% 1st IFA trace
p1 = fp + [gap.width, -short.width-short.tw, 0];
%p1 = fp + [gap.width, 0, 0];
p2 = p1 + [IFA.tw, feed.position-edge.distance+short.tw+short.width, 0];
CSX = AddBox(CSX, 'ifa', 3, p1, p2);

##%No stub version
##
##p1 = fp + [gap.width, 0, 0];
##p2 = p1 + [IFA.tw, feed.position-edge.distance, 0];
##CSX = AddBox(CSX, 'ifa', 3, p1, p2);

% 2nd IFA trace
p1 = [edge.distance, -edge.distance, 0];
p2 = [substrate.width - edge.distance - IFA.tw, -edge.distance - IFA.tw, 0];
CSX = AddBox(CSX, 'ifa', 3, p1, p2);

% 3rd IFA trace
p1 = [edge.distance, -edge.distance - IFA.tw, 0];
p2 = [edge.distance + IFA.tw, -substrate.height + edge.distance, 0];
CSX = AddBox(CSX, 'ifa', 3, p1, p2);

% Final IFA trace
p1 = p2;
p2 = [edge.distance + IFA.last_trace, -substrate.height + edge.distance + IFA.tw, 0];
CSX = AddBox(CSX, 'ifa', 3, p1, p2);

%% Create excitation port
p1 = fp;
p2  = p1 + [port.height, feed.tw, 0];
[CSX port] = AddLumpedPort(CSX, 4 ,1 , port.R, p1, p2, [1 0 0], true); % See https://openems.de/index.php/Ports.html

%% Define antenne center for more accurate antenna gain calculation
antennaCenter = [substrate.width/2, -substrate.width/2, -substrate.thickness/2];
% antennaCenter = [0,0,0];

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
  calculatePortReflection(simEnv, port, plotFreq, 'freqMarkers', plotMarkers, 'smithParams', Smith_params );
endif

if calcAntennaGain
  calculateAntennaGain(simEnv, CSX, nf2ff, port, gainCalcFreq, unit, antennaCenter);
endif
