function hazard=climada_hazard2octave(hazard)
% climada template
% MODULE:
%   core
% NAME:
%   climada_hazard2octave
% PURPOSE:
%   In case the .mat file whch contains hazard has been saved with option
%   -v7.3, in Octave, hazard.intensity contains sub-fields jc, ir and data
%   There might be a more elegant way, but the present one is an explicit
%   conversion back into a sparse matrix in Octave.
%
%   Call this code whenever you access to hazard.intensity and would like
%   to make sure the code works in Octave for large(r) hazard event sets,
%   too.
%
%   Calling the code in MATLAB has most likely (almost certainly) no effect
%
%   called from climada_EDS_calc
% CALLING SEQUENCE:
%   hazard=climada_hazard2octave(hazard)
% EXAMPLE:
%   hazard=climada_hazard2octave(hazard)
% INPUTS:
%   hazard: a climada hazard event set structure, see e.g.
%       climada_tc_hazard_set
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   hazard: a climada hazard event set structure, with hazard.intensity a
%       sparse array
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150112, initial
%-

if isfield(hazard.intensity,'data')
    fprintf('Note: hazard.intensity saved in MATLAB using ''-v7.3'', converting ...')
    % in such a case, hazard.intensity contains sub-fields jc, ir and data
    % Likely to occurr in Octave. There might be a more elegant way, but
    % the present one is explicit.
    sparse_i=hazard.intensity.data*0; % init
    sparse_j=hazard.intensity.data*0; % init
    for j=1:length(hazard.intensity.jc)-1
        for i=hazard.intensity.jc(j)+1:hazard.intensity.jc(j+1)
            sparse_i(i)=hazard.intensity.ir(i)+1;
            sparse_j(i)=j;
        end
    end
    sparse_data=hazard.intensity.data;
    hazard=rmfield(hazard,'intensity');
    hazard.intensity=sparse(sparse_i,sparse_j,sparse_data,floor(hazard.event_count),length(hazard.lon));
    fprintf(' done\n');
end

end