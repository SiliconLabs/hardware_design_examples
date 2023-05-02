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
BW = 500e6; % Simulation bandwidth [Hz]

% Boundary condition (simulating open space propagation)
usePML = 0; % set to 1 for more accurate absorbing boundary condition
            % (increases calculation time)
            
% Mesh configuration

%meshConfig.sizeAccuracy = 0.5; % Desired minimum accuracy of model sizes [unit*m] (default is 0.5)
%meshConfig.meshRes = 1/20; % minimum mesh resolution compared to min wavelength (default is 1/20)
meshConfig.STLMeshRes = 0.5;

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
% |/                                       
% o---->X __________________________________________________________________
% |                                                                         |\
% |        ___________       ___________       ___________________________  |
% |       |   _____   |     |   _____   |     |   _____    _______        | | |
% |       |  |     |  |     |  |     |  |     |  |     |  |       |       | | |
% |       |  |     |  |     |  |     |  |     |  |     |  |       |       | | |
% |       |__|     |  |     |  |     |  |     |  |     |  |       |       | | |
% |                |  |_____|  |     |  |_____|  |     |  |       |       | | |
% |                |___________|     |___________|     |  |       |       | | |
% |                                                    |  |       |       | | |
% |  __________________________________________________####_______|       | | |
% | |                                                                     | | |
% | |                                               Excitation            | | |
% | |                                                                     | | |
% | |                                                                     | | |
% | |                                                                     | | |
% | |                                                                     | | |
% | |                                                                     | | |
% | |                                                                     | | |
% | |_____________________________________________________________________| | |
%  \_________________________________________________________________________\|
%

substrate.width  = 25.75;             % width of substrate
substrate.height = 61.725;             % length of substrate
substrate.thickness = 1.5;   % thickness of substrate
substrate.position = [0 0 0]; % reference is top left corner ot top layer
substrate.epsR   = 4.3;
substrate.tangentLoss = 0.02;
substrate.kappa  = substrate.tangentLoss * 2*pi*f0 * EPS0 * substrate.epsR;
substrate.mountingHolePosition = [substrate.width-2 -7.225 0];
substrate.cells = 4; % Number of mesh lines to add 

antKeepout.width = 22.22;
antKeepout.height = 5.7;

gndPour.edgeDist = 0.38;

antenna.traceThickness = 0.5;
antenna.indL.height = 4.7;
antenna.indL.width = 3.55;
antenna.meander.l=[2.17 3 2.17 3 2.17 3 2.17 3 2.17 1.5];

%setup feeding
feed.R = 50;     %feed resistance
feed.height = 0.5;

enclosure.epsR = 2.8; % Typical value for ABS
enclosure.tangentLoss = 0.015; % Typical value for ABS
enclosure.kappa  = enclosure.tangentLoss * 2*pi*f0 * EPS0 * enclosure.epsR;
enclosure.top.transformations = {'Rotate_X', -pi/2,'Translate','-2.375,-68.72,11.3'};
enclosure.bottom.transformations = {'Rotate_X', pi/2,'Translate','-2.375,-68.72+75.3,11.3-26.4'};

battery.radius=10.5/2;
battery.length=44.5;
battery.a.position= [substrate.width/2-battery.radius -10.77-1.65 -9];
battery.b.position= battery.a.position + [2*battery.radius 0 0];

%% Add 2xAAA batteries
CSX = AddMetal( CSX, 'batteries' ); % create a perfect electric conductor (PEC)
start = battery.a.position;
stop = start + [0 -battery.length 0];
CSX = AddCylinder(CSX, 'batteries', 0, start, stop, battery.radius);

start = battery.b.position;
stop = start + [0 -battery.length 0];
CSX = AddCylinder(CSX, 'batteries', 0, start, stop, battery.radius);


stop  = [21 start(2) -12];
start = [4.5 -8.5 (start(3)+10.5/2)];
CSX = AddBox(CSX, 'batteries', 0, start,stop);


% Add plastic enclosure
CSX = AddMaterial(CSX,'enclosure_top');
CSX = AddMaterial(CSX,'enclosure_bottom');


CSX = SetMaterialProperty( CSX, 'enclosure_top', 'Epsilon', enclosure.epsR, 'Mue', 1, 'kappa', enclosure.kappa  );
CSX = SetMaterialProperty( CSX, 'enclosure_bottom', 'Epsilon', enclosure.epsR, 'Mue', 1, 'kappa', enclosure.kappa  );
CSX = ImportSTL(CSX, 'enclosure_top', 1, strrep([simEnv.workspacePath filesep 'Enclosure Front Rev B_STL Binary.STL'],'\','\\'), 'Transform', enclosure.top.transformations);
CSX = ImportSTL(CSX, 'enclosure_bottom', 1, strrep([simEnv.workspacePath filesep 'Enclosure Back Rev D_STL Binary.STL'],'\','\\'), 'Transform', enclosure.bottom.transformations);


%% create substrate
CSX = AddMaterial( CSX, 'substrate');
CSX = SetMaterialProperty( CSX, 'substrate', 'Epsilon',substrate.epsR, 'Kappa', substrate.kappa);
start = substrate.position;
stop  = start + [substrate.width -substrate.height -substrate.thickness];
CSX = AddBox( CSX, 'substrate', 2, start, stop );

%% model top and bottom gnd pours (and stitching vias) as solid metal box
CSX = AddMetal( CSX, 'gnd' ); % create a perfect electric conductor (PEC)
start = substrate.position + [gndPour.edgeDist  -antKeepout.height        0];
stop  = substrate.position + [(substrate.width-gndPour.edgeDist) (-substrate.height+gndPour.edgeDist) -substrate.thickness];
CSX = AddBox(CSX, 'gnd', 3, start,stop);


% connection point for wire betweeen the pcb and batteries
wire(:,1)= substrate.position + [(substrate.width-gndPour.edgeDist) (-substrate.height+gndPour.edgeDist) 0];
wire(:,2)= battery.b.position +[battery.radius, -battery.length, 0];
CSX = AddMetal(CSX,'wire'); %create PEC with propName 'metal'
CSX = AddCurve(CSX,'wire',3, wire);

%% Add gnd bridge next to antenna separately
start = substrate.position + [antKeepout.width  (-antKeepout.height+antenna.indL.height+antenna.traceThickness)        0];
stop  = substrate.position + [(substrate.width-gndPour.edgeDist) -antKeepout.height -substrate.thickness];
CSX = AddBox(CSX, 'gnd', 3, start,stop);

%% Define excitaton source
start = substrate.position + [(antKeepout.width-antenna.indL.width)  -antKeepout.height        0];
stop  = start + [-antenna.traceThickness feed.height 0];
[CSX port] = AddLumpedPort(CSX, 255 ,1 ,feed.R, start, stop, [0 1 0], true);

%% Add meandered ifa feed element
CSX = AddMetal( CSX, 'meanderedIFA' ); % create a perfect electric conductor (PEC)
start = stop;
stop  = start + [antenna.traceThickness (antenna.indL.height+antenna.traceThickness-feed.height) 0];
CSX = AddBox(CSX, 'meanderedIFA', 4, start,stop);


%% Add meandered ifa inductive load element
start = stop;
stop  = start + [antenna.indL.width -antenna.traceThickness 0];
CSX = AddBox(CSX, 'meanderedIFA', 4, start,stop);

%% Add meandering
stop = substrate.position + [(antKeepout.width-antenna.indL.width) (-antKeepout.height+antenna.indL.height+antenna.traceThickness) 0];

for k=[1:length(antenna.meander.l)] %iterate through meander definition array
  l=antenna.meander.l(k);
  switch mod(k,4)
      case 1 % Top (closer to pcb edge) horizontal elements
          start = stop + [-antenna.traceThickness 0 0];
          stop  = start + [-l -antenna.traceThickness 0];
      case 2 % Vertical elements (odd)
          start = stop;
          stop  = start + [antenna.traceThickness -l 0];
      case 3 % Bottom horizontal elements
          start = stop + [-antenna.traceThickness 0 0];
          stop  = start + [-l antenna.traceThickness 0];
      case 0 % Vertical elements (even)
          start = stop;
          stop  = start + [antenna.traceThickness l 0];
  endswitch
  CSX = AddBox(CSX, 'meanderedIFA', 4, start,stop);
end

antennaCenter = substrate.position + [antKeepout.width -antKeepout.height 0] / 2;

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
