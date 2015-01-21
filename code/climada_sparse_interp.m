function res = climada_sparse_interp(matrix)
% climada event damage hazard probabilistic stochastic damagefunctions
% NAME:
%   climada_sparse_interp
% PURPOSE:
%   helper-function to allow for very efficient execution of the
%   mapping from the hazard-array to the MDD-matrix
%   since the hazard-array is sparse, we cannot directly apply interp1
%   but do this only on the non-zero elements by use of a function handle
%   to the present routine climada_sparse_interp, but before, we pass the other
%   two arguments of interp1 as global variables:
%
%   global interp_x_table
%   global interp_y_table
%   MDD=spfun(@climada_sparse_interp,hazard_arr);
%
%   see climada_EDS_calc about further details (in the code)
%
% CALLING SEQUENCE:
%   res=climada_sparse_interp(matrix)
% EXAMPLE:
%   res=climada_sparse_interp(matrix)
%   see climada_EDS_calc
% INPUTS:
%   matrix: any matrix to be interpolated based upon the relation
%       defined by (interp_x_table,interp_y_table), passed as global variables
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   the interpolated matrix res of same dimensions as matrix
% RESTRICTIONS:
%   none
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091228
%-

global interp_x_table % access first two parameters for interp1
global interp_y_table

res = interp1(interp_x_table,interp_y_table,matrix,'linear','extrap'); % save (nearest not faster)
%%res=interp1(interp_x_table,interp_y_table,matrix,'*linear'); % superfast, but interp_x_table needs to be uniformly spaced
return;