function calculatePortReflection(simEnv, port, plotFreq, varargin)
% calculatePortReflection(simEnv, port, plotFreq [, varargin] )
%
% Calculate, plot and save port reflection (S11)
%
% input:
%   simEnv:  Project config structure
%   port: port for calculation
%   plotFreq:   array of frequency points where S11 will be evaluated
%
% optional: 'keyword', value
%   'freqMarkers'   frequencies where markers should be added
%   's11dBMarkers'  S11 [dB] values where markers should be placed (defult=[-10])
%   'addNegPeakMarkers'  set to 1 to search negative peaks in S11 (resonance
%                        frequencies) and place markers there (default=1)
%
% example:
%   plotFreq = 2300e6:1e6:2600e6;
%   plotMarkers = [2405e6 2445e6 2485e6];
%   ...
%   calculatePortReflection(simEnv, port, plotFreq, 'freqMarkers', plotMarkers );
%


  freqMarkers = []; % array of frequency markers
  s11dBMarkers = [-10];  % array of S11 [dB] markers
  addNegPeakMarkers = 1; % set to 1 to add markers at S11 negative peaks
  disablePlotting = 0;
  smithParams = []

  for n=1:2:numel(varargin)
      if (strcmpi(varargin{n},'freqMarkers')==1);
          freqMarkers = varargin{n+1};
      elseif (strcmpi(varargin{n},'s11dBMarkers')==1);
          s11dBMarkers = varargin{n+1};
      elseif (strcmpi(varargin{n},'addNegPeakMarkers')==1);
          addNegPeakMarkers = varargin{n+1};
      elseif (strcmpi(varargin{n},'disablePlotting')==1);
          disablePlotting = 1;
      elseif (strcmpi(varargin{n},'smithParams')==1);
          smithParams = varargin{n+1};
      else
          warning('calculatePortReflection',['unknown argument: ' varargin{n}]);
      end
  end


  % Calculate port voltage and current
  port = calcPort(port, simEnv.simPath, plotFreq);

  if ~disablePlotting

  % Get marker points
  markers = getMarkerPoints(port, plotFreq, freqMarkers, s11dBMarkers, addNegPeakMarkers);

  % Plot S11 magnitude [dB]
  plotS11Abs(port, plotFreq, markers, simEnv.sessionName);
  %print([simEnv.simPath filesep 'S11_abs-' simEnv.sessionName '.pdf']);


  %% Smith chart port reflection
  if length(smithParams) > 0
      plotSmith(port, 'fmarkers', [max([min(freqMarkers) plotFreq(1)]), min([max(freqMarkers) plotFreq(end)])], ...
      'inverse', smithParams(1), 'custom_freq', smithParams(2), 'unit_Y', smithParams(3), 'unit_Z', smithParams(4), 'series_resonance', smithParams(5));
  else
      plotRefl(port, 'fmarkers', [max([min(freqMarkers) plotFreq(1)]), min([max(freqMarkers) plotFreq(end)])]);
  endif

    title( 'Reflection coefficient (S_{11})' );
    %print([simEnv.simPath filesep 'S11_Smith-' simEnv.sessionName '.pdf']);

  endif
  saveS1P([simEnv.simPath filesep simEnv.sessionName '.s1p'], port, plotFreq);

endfunction
