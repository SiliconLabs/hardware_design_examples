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
%                substrate.width
%  _______________________________________________    __ substrate.
% | A                        ifa.l                |\  __    thickness
% | |ifa.e         __________________________     | |
% | |             |    ___  _________________| w2 | |
% | |       ifa.h |   |   ||                      | |
% |_V_____________|___|___||______________________| |
% |                .w1   .wf\                     | |
% |                   |.fp|  \                    | |
% |                       |    feed point         | |
% |                       |                       | | substrate.length
% |<- substrate.width/2 ->|                       | |
% |                                               | |
% |_______________________________________________| |
%  \_______________________________________________\|
%
%

substrate.width  = 30;             % width of substrate
substrate.height = 45;             % length of substrate
substrate.thickness = 1.5;         % thickness of substrate

ifa.h  = 9.5;            % height of the ifa
rad.l  = 15.8;         % length of radiating element
rad.tw = 1;            % trace width of radiating element
short.width = 4.5;      % inner width of short 
short.tw1 = 1;            % trace width of short parallel to radiating element
short.tw2 = 1;            % trace width of short perpendicular to radiatng element
feed.tw = 1;            % trace width of feed element
feed.x = 11.5;             % distance of feed from the left side of the PCB
feed.y = 10.3;           % distance of feed from the top of the PCB


wstk.pos = [42 -9.3 -7]; % the position of the main board top right corner 
                           % relative to the radio board (bottom side) top left corner 
                           % (on the lower side)
wstk.size = [115 60 0];

gnd_connectors.size = [1 1];
gnd_connectors.loc = [
[-substrate.width/2+3 substrate.height/2-15],
[-substrate.width/2+3 -substrate.height/2+4],
[substrate.width/2-4 substrate.height/2-15],
[substrate.width/2-3 -substrate.height/2+4]];

% substrate setup
substrate.epsR   = 4.2;
substrate.tangentLoss = 0.02;
substrate.kappa  = substrate.tangentLoss * 2*pi*f0 * EPS0*substrate.epsR;

%setup feeding
feed.R = 50;     %feed resistance
feed.height = 0.25;


%% create substrate
CSX = AddMaterial( CSX, 'substrate');
CSX = SetMaterialProperty( CSX, 'substrate', 'Epsilon',substrate.epsR, 'Kappa', substrate.kappa);
start = [-substrate.width/2  substrate.height/2-feed.y                    0];
stop  = [ substrate.width/2   substrate.height/2  substrate.thickness];
CSX = AddBox( CSX, 'substrate', 1, start, stop );

%% create ground plane as PEC box
CSX = AddMetal( CSX, 'groundplane' ); % create a perfect electric conductor (PEC)
start = [-substrate.width/2  -substrate.height/2        0];
stop  = [ substrate.width/2   substrate.height/2-feed.y substrate.thickness];
CSX = AddBox(CSX, 'groundplane', 10, start,stop);

%%create wstk
CSX = AddMetal( CSX, 'WSTK' ); % create a perfect electric conductor (PEC)
start = [-substrate.width/2  substrate.height/2        0] + wstk.pos;
stop  = start-wstk.size;
CSX = AddBox(CSX, 'WSTK', 10, start,stop);



%%create connectors
CSX = AddMetal( CSX, 'Connectors' ); % create a perfect electric conductor (PEC)
for k = 1 : length(gnd_connectors.loc)
  start = [gnd_connectors.loc(k,:)-gnd_connectors.size/2 0];
  stop =  [gnd_connectors.loc(k,:)+gnd_connectors.size/2 wstk.pos(3)];
  CSX = AddBox(CSX, 'Connectors', 10, start,stop);
end

%% create ifa
tl = [-substrate.width/2+feed.x,substrate.height/2-feed.y,substrate.thickness];   % translate
CSX = AddMetal( CSX, 'ifa' ); % create a perfect electric conductor (PEC)
start = [-short.width 0 0] + tl;
stop =  start + [-short.tw2 ifa.h 0];
CSX = AddBox( CSX, 'ifa', 10,  start, stop);  % short circuit stub vertical element
start = stop;
stop =  start + [short.tw2+short.width+rad.l -rad.tw 0];
CSX = AddBox( CSX, 'ifa', 10,  start, stop);  % radiating element and short circuit stub horizontal element
start = [0 feed.height 0] + tl;
stop = start + [feed.tw ifa.h-feed.height 0];
CSX = AddBox( CSX, 'ifa', 10, start, stop);   % feed element

%% apply the excitation & resist as a current source
start = [0 0 0] + tl; % to fit the mesh following the Thirds Rule
stop  = start + [feed.tw feed.height 0];
[CSX port] = AddLumpedPort(CSX, 5 ,1 ,feed.R, start, stop, [0 1 0], true);

% Export antenna center point for far-field calculations 
antennaCenter = tl + [feed.tw/2 ifa.h/2 substrate.thickness];

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
