function [SP3_time, SP3_coor, SP3_clck] = load_SP3(filename_SP3, time, week, wait_dlg)

% SYNTAX:
%   [SP3_time, SP3_coor, SP3_clck] = load_SP3(filename_SP3, time, week, wait_dlg);
%
% INPUT:
%   filename_SP3 = SP3 file
%   time     = time window (GPS time)
%   week     = GPS week
%   wait_dlg = optional handler to waitbar figure
%
% OUTPUT:
%   SP3_time = precise ephemeris timestamps (GPS time)
%   SP3_coor = satellite coordinates  [m]
%   SP3_clck = satellite clock errors [s]
%
% DESCRIPTION:
%   SP3 (precise ephemeris) file parser.
%   NOTE: at the moment the parser reads only time, coordinates and clock;
%         it does not take into account all the other flags and parameters
%         available according to the SP3c format specified in the document
%         http://www.ngs.noaa.gov/orbits/sp3c.txt

%----------------------------------------------------------------------------------------------
%                           goGPS v0.3.1 beta
%
% Copyright (C) 2009-2012 Mirko Reguzzoni, Eugenio Realini
%----------------------------------------------------------------------------------------------
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%----------------------------------------------------------------------------------------------

%degree of interpolation polynomial (Lagrange)
n = 10;

%number of seconds in a quarter of an hour
quarter_sec = 900;

if (nargin > 3)
    waitbar(0.5,wait_dlg,'Reading SP3 (precise ephemeris) file...')
end

%extract containing folder
if (isunix)
    slash = '/';
else
    slash = '\';
end
pos = strfind(filename_SP3, slash);
filename_SP3 = filename_SP3(1:pos(end)+3);

%define time window
time_start = time(1);
time_end   = time(end);
week_start = week(1);
week_end   = week(end);

%day-of-week
dow_start = floor(time_start / 86400);
dow_end   = floor(time_end / 86400);

%add a buffer before and after
if ((time_start-dow_start*86400) < n/2*quarter_sec)
    if (dow_start == 0)
        week_start = week_start - 1;
        dow_start = 6;
    else
        dow_start = dow_start - 1;
    end
else
end

if (time_end-dow_end*86400 > 86400-n/2*quarter_sec)
    if (dow_end == 6)
        week_end = week_end + 1;
        dow_end = 0;
    else
        dow_end = dow_end + 1;
    end
else
end

week_dow  = [];
week_curr = week_start;
dow_curr  = dow_start;
while (week_curr <= week_end)
    while ((week_curr < week_end & dow_curr <= 6) | (week_curr == week_end & dow_curr <= dow_end))
        week_dow = [week_dow; week_curr dow_curr];
        dow_curr = dow_curr + 1;
    end
    week_curr = week_curr + 1;
    dow_curr = 0;
end

nEpochs = 96*size(week_dow,1);
SP3_time = zeros(nEpochs,1);
SP3_coor = zeros(3,32,nEpochs);
SP3_clck = zeros(32,nEpochs);

k = 0;

for p = 1 : size(week_dow,1)
    
    %open SP3 file
    f_sp3 = fopen([filename_SP3 num2str(week_dow(p,1)) num2str(week_dow(p,2)) '.sp3'],'r');
    
    %skip the SP3 header (first 22 lines)
    for i = 1 : 22
        fgetl(f_sp3);
    end

    while (~feof(f_sp3))
        
        %get the next line
        lin = fgetl(f_sp3);
        
        if (strcmp(lin(1),'*'))
            
            k = k + 1;
            
            %read the epoch header
            %example 1: "*  1994 12 17  0  0  0.00000000"
            data = textscan(lin(2:31),'%f%f%f%f%f%f');
            year = data{1};
            month = data{2};
            day = data{3};
            hour = data{4};
            minute = data{5};
            second = data{6};
            %computation of the corresponding julian day
            jd = julday(year, month, day, 0);
            %computation of the GPS time in weeks and seconds of week
            [week, sec_of_week] = gps_time(jd); %#ok<ASGLU>
            SP3_time(k,1) = sec_of_week + hour*3600+minute*60+second;
            
        elseif (strcmp(lin(1),'P'))
            %read position and clock
            %example 1: "P  1  16258.524750  -3529.015750 -20611.427050    -62.540600"
            %example 2: "PG01   8953.350886  12240.218129 -21918.986611 999999.999999"
            %example 3: "PG02 -13550.970765 -16758.347434 -15825.576525    274.198680  7  8  8 138"
            if (strcmp(lin(2),'G') | strcmp(lin(2),' '))
                PRN = sscanf(lin(3:4),'%f');
                X   = sscanf(lin(5:18),'%f');
                Y   = sscanf(lin(19:32),'%f');
                Z   = sscanf(lin(33:46),'%f');
                clk = sscanf(lin(47:60),'%f');
                
                SP3_coor(1,PRN,k) = X*1e3;
                SP3_coor(2,PRN,k) = Y*1e3;
                SP3_coor(3,PRN,k) = Z*1e3;
                
                SP3_clck(PRN,k) = clk/1e6; %NOTE: clk >= 999999 stands for bad or absent clock values
            end
        end
    end
    
    %close SP3 file
    fclose(f_sp3);
    
end

%remove empty slots
SP3_time(k+1:nEpochs) = [];
SP3_coor(:,:,k+1:nEpochs) = [];
SP3_clck(:,k+1:nEpochs) = [];

if (nargin > 3)
    waitbar(1,wait_dlg)
end