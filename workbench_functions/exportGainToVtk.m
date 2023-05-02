function exportGainToVtk(resultsDirFullPath, modelFullPath, thetaRange, phiRange, E_norm, E_theta, E_phi, Gmax_dBi, scale, logscale)
    
    filename.gain_norm = 'Gain_norm_dBi.vtk';
    filename.gain_theta = 'Gain_theta_dBi.vtk';
    filename.gain_phi = 'Gain_phi_dBi.vtk';
    [workbench_functions_Path, ~, ~] = fileparts( mfilename('fullpath'));
    filename.paraviewTemplate = [workbench_functions_Path, filesep, 'ParaviewGainView.pvsm.template'];
    
    % Normalize  field values
    Emax = max(E_norm(:));
    E_norm_normalized = abs(E_norm) / Emax;
    E_theta_normalized = abs(E_theta) / Emax;  
    E_phi_normalized = abs(E_phi) / Emax;


    
    % Save 3D gain patterns
    DumpFF2VTK([resultsDirFullPath filesep filename.gain_norm],E_norm_normalized,thetaRange,phiRange, 'scale', scale, 'logscale', -logscale, 'maxgain', Gmax_dBi);
    DumpFF2VTK([resultsDirFullPath filesep filename.gain_theta], E_theta_normalized,thetaRange,phiRange, 'scale', scale, 'logscale', -logscale, 'maxgain', Gmax_dBi);
    DumpFF2VTK([resultsDirFullPath filesep filename.gain_phi],E_phi_normalized,thetaRange,phiRange, 'scale', scale, 'logscale', -logscale, 'maxgain', Gmax_dBi);
    
    %% Write model paths to paraview state template and save
    fid = fopen(filename.paraviewTemplate,'r');
    f=fread(fid,'*char')';
    fclose(fid);    
    
    f = strrep(f,'{full_path_to_model}', modelFullPath);
    f = strrep(f,'{full_path_to_gain_pattern_norm}', [resultsDirFullPath filesep filename.gain_norm]);   
    f = strrep(f,'{full_path_to_gain_pattern_theta}', [resultsDirFullPath filesep filename.gain_theta]);
    f = strrep(f,'{full_path_to_gain_pattern_phi}', [resultsDirFullPath filesep filename.gain_phi]);

    fid = fopen([resultsDirFullPath filesep 'GainViewState.pvsm'],'w');
    fprintf(fid,'%s',f);
    fclose(fid);
    
    disp(['3D gain pattern saved. Load state ' resultsDirFullPath filesep 'GainViewState.pvsm to Paraview to view it.'])

endfunction
