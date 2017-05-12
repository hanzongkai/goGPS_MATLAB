function data = funInterp2(x_pred, y_pred, x_obs, y_obs, data_obs, fun)
% SYNTAX:
%   data = funInterp2(x_pred, y_pred, x_obs, y_obs, data_obs, fun)
% DESCRIPTION:
%   generic interpolator using as correlation function fun
%   <default: fun = @(dist) exp(-dist/1e4);>

%--- * --. --- --. .--. ... * ---------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 0.5.1 beta 2
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2017 Mirko Reguzzoni, Eugenio Realini
%  Written by:       Andrea Gatti
%  Contributors:     Andrea Gatti ...
%  A list of all the historical goGPS contributors is in CREDITS.nfo
%--------------------------------------------------------------------------
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
% 01100111 01101111 01000111 01010000 01010011
%--------------------------------------------------------------------------

    narginchk(5, 6);

    if nargin < 6
        % Correlation function
        fun = @(dist) exp(-dist/1e4);
    end

    % Init out data
    data = nan(size(data_obs, 2), numel(x_pred));

    [x_mesh, y_mesh] = meshgrid(x_obs, y_obs);
    d_obs = sqrt(abs(x_mesh - x_mesh').^2 + abs(y_mesh - y_mesh').^2);
    q_fun_obs = fun(d_obs);
    %q_fun_obs = exp(-d_obs/0.4e4);
    [xv, ~, xi] = unique(x_pred);
    [yv, ~, yi] = unique(y_pred);
    x2 = (repmat(x_obs, 1, numel(xv)) - repmat(xv', numel(x_obs), 1)).^2;
    y2 = (repmat(y_obs, 1, numel(yv)) - repmat(yv', numel(y_obs), 1)).^2;
    for i = 1 : numel(x_pred)
        d_pred = sqrt(x2(:,xi(i)) + y2(:,yi(i)));
        c_mat = q_fun_obs * diag(fun(d_pred));
        c_mat = triu(c_mat) + triu(c_mat, 1)';

        trans = sum(c_mat);
        w = sum(trans)\trans;
        data(:, i) = (w * data_obs)';
    end
end