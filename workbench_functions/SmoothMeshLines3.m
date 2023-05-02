function lines = SmoothMeshLines3( lines, max_res, ratio, varargin)
% lines = SmoothMeshLines3( lines, max_res [, ratio, varargin] )
%
% Create smooth mesh lines.
%
% input:
%   lines:   1xn vector of (fixed) mesh lines
%   max_res: target maximum distance between any two lines (e.g. lambda/10)
%   ratio:   target max ratio (optional) default: 1.5
%
% optional variable arguments ('key', value)
%   CheckMesh:          Do a final mesh check (default is true)
%   allowed_max_ratio:  allow only a given max. grading ratio
%                           (default --> ratio*1.001)
%   allowed_max_res:  allow only a given max. resolution
%                           (default --> max_res*1.001)
% output:
%   lines:   1xn vector of (smoothed) mesh lines
%
% example:
%   % create a x-mesh with lines at 0, 50 and 200 and a desired mesh
%   resolution of 5 and ratio of 1.5
%   mesh.x = SmoothMeshLines3([0 50 200], 5, 1.5);
%




if (numel(lines)<2)
    return
end

if (nargin<3)
    ratio = 1.5;
end

check_mesh = true;
allowed_max_ratio = ratio*1.001;
allowed_max_res = max_res*1.001;

for vn=1:2:numel(varargin)
    if (strcmpi(varargin{vn},'CheckMesh'))
        check_mesh = varargin{vn+1};
    end
    if (strcmpi(varargin{vn},'allowed_allowed_max_ratio'))
        allowed_max_ratio = varargin{vn+1};
    end
    if (strcmpi(varargin{vn},'allowed_max_res'))
        allowed_max_res = varargin{vn+1};
    end
end

if numel(lines)==2
  dist = abs(lines(2) - lines(1));
  if dist>allowed_max_res
    constLines = floor(dist/max_res);
    if(constLines*max_res != dist)
      constLines++;
    endif
    constDist=dist/constLines;
    lines=unique(sort([lines min(lines)+(1:(constLines-1))*constDist]));
  endif
  return;
end


while(1)

  lines = unique(sort(lines));
  dist = diff(lines);

% Display ratios and plot progress for debug
##  rat=dist(1:end-1)./dist(2:end);
##  rat(rat<1)=1./rat(rat<1)
##  plot(lines, ones(1,numel(lines)), 'x');



   % Error function highest for smallest invalid mesh pair
  function error = errorFun(dist, neighbourDist, allowed_max_ratio, allowed_max_res)
     if neighbourDist / dist > allowed_max_ratio
       error = 1/(dist+neighbourDist);
     elseif neighbourDist > allowed_max_res
       error = 0;
     else
       error = -1;
     endif;
  endfunction


  maxErrorIds=[1,2];
  maxErrorVal = errorFun(dist(maxErrorIds(1)),dist(maxErrorIds(2)),allowed_max_ratio,allowed_max_res);
  for k=1:numel(dist)
    if k>1 && errorFun(dist(k),dist(k-1),allowed_max_ratio,allowed_max_res) > maxErrorVal
      maxErrorIds = [k,k-1];
      maxErrorVal = errorFun(dist(maxErrorIds(1)),dist(maxErrorIds(2)),allowed_max_ratio,allowed_max_res);
    endif
    if k<numel(dist) && errorFun(dist(k),dist(k+1),allowed_max_ratio,allowed_max_res) > maxErrorVal
      maxErrorIds = [k,k+1];
      maxErrorVal = errorFun(dist(maxErrorIds(1)),dist(maxErrorIds(2)),allowed_max_ratio,allowed_max_res);
    endif
  endfor

  if -1 == maxErrorVal
    % No invalid mesh line is found
    break;
  end

  % |      a            |                b                     |     c
  % | (=maxErrorIds(1)) |           (=maxErrorIds(2))          |
  % | not modified      |  mesh line(s) will be inserted here  |
  %
  %     dist(a) <= dist(b)
  % AND dist(a) <= dist(c)
  %

  a = maxErrorIds(1);
  b = maxErrorIds(2);
  c = maxErrorIds(1) + 2 * (maxErrorIds(2) - maxErrorIds(1));

  a_min = min([dist(a) max_res])/ratio;
  a_max = min([dist(a)*ratio max_res]);

  b_min = min([dist(b) max_res]) * ratio / (1 + ratio);
  b_max = dist(b) - b_min;

  if c>=1 && c<=numel(dist)
    c_min = dist(b) - min([dist(c)*ratio max_res]);
    c_max = dist(b) - min([dist(c) max_res])/ratio;
  else
    c_min = dist(b) - max_res;
    c_max = dist(b) - 0;
  endif


  linesToAdd=[];

  low = max([0 a_min b_min c_min]);
  high = min([dist(b) a_max b_max c_max]);
  if low <= high
    % Easy solution, one additional mesh line is enough
    linesToAdd=min([high dist(b)/2]);

  elseif a_max < c_min
    % more than one mesh line has to be added at the center segment
    % calculate number of required lines by increasing the mesh distances from both sides according to ratio and max_res

    a_ext=0;
    c_ext=dist(b);

    a_ext_lastDist = dist(a);

    % if c is at edge, extend a only
    c_ext_lastDist = max_res;
    if c>=1 && c<=numel(dist)
      c_ext_lastDist = dist(c);
    endif

    % calculate maximum ranges where geometric increase is needed
    a_geomLines = c_geomLines = 0;
    while a_ext < c_ext && (a_ext_lastDist*ratio < max_res || c_ext_lastDist*ratio < max_res)
      if a_ext_lastDist < c_ext_lastDist
        a_ext_lastDist = a_ext_lastDist*ratio;
        a_ext += a_ext_lastDist;
        a_geomLines++;
      else
        c_ext_lastDist = c_ext_lastDist*ratio;
        c_ext -= c_ext_lastDist;
        c_geomLines++;
      endif
    endwhile


    % Refine ratios and const distance as needed
    a_rat=c_rat=ratio;
    constLines=0;
    constDist = max_res;


    constLines = floor((c_ext-a_ext)/constDist);
    if(constLines<0)
      constLines = 0;
    elseif(constLines*constDist != dist(b))
      constLines++;
    endif

    scale = dist(b)/(a_ext + (dist(b)-c_ext) + constLines*constDist);

    % Remove some lines to eliminiate duplicate lines
    if constLines == 0 && c_geomLines == 0
      a_geomLines--;
    endif
    if c_geomLines == 0
      constLines--;
    endif
    c_geomLines--;

    lastpos=0;
    for k=1:a_geomLines
      lastpos += scale * dist(a)*(a_rat^k);
      linesToAdd=[linesToAdd lastpos];
    endfor

    for k=1:constLines
      lastpos += scale * constDist;
      linesToAdd=[linesToAdd lastpos];
    endfor

    lastpos=dist(b);
    for k=1:c_geomLines
      lastpos -= scale * dist(c) * (c_rat^k);
      linesToAdd=[linesToAdd lastpos];
    endfor

   else
    % Unable to meet all requirements, add one line which meets a (and b if possible) with max resulting new mesh distances
    low = max([0 a_min b_min]);
    high = min([dist(b) a_max b_max]);
    if low <= high
      linesToAdd=min([high dist(b)/2]);
    else
      linesToAdd=min([a_max dist(b)/2]);
    endif


  endif

  if b > a
    lines = [lines lines(a+1)+linesToAdd];
  else
    lines = [lines lines(a)-linesToAdd];
  endif


endwhile

if check_mesh
    CheckMesh(lines,0,allowed_max_res,allowed_max_ratio);
end

endfunction
