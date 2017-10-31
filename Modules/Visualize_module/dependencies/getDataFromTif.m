function [ arr ] = getDataFromTif( name , param)
%GETDATAFROMTIF Gets data from multi-tiff as array.
%   Valid param:
%       All
%
%       X
%       Y
%       Z
%       EM
%       Exp
%       Time
%
%   Run Example:
%       >>  getDataFromTif( 'GUI_created.tif' , 'All')
%
%
%                   *   *   Created by AlexKaz 6.2015   *   *
   
    if (nargin == 0)
        param = 'All';
        [name,~] = uigetfile('*.tif','Select a Movie');
    end
    if(strcmp(name,'Save'))
        old_dir = cd();
        [name, dir] = uigetfile('*.tif','Select a Movie');
        cd(dir);
        disp(['=========    Processing file:' name '    ==========']);
        X = getDataFromTif( name , 'X');
        Y = getDataFromTif( name , 'Y');
        Data = struct('X',X,'Y',Y);
        new_name = [name(1:end-4) '_XY_data'];
        save(new_name, 'Data');
        disp(['=====    New file created. Name: ' new_name '.mat   =============']);
        cd(old_dir)
        return;
    end
    if(strcmp(param,'All'))
        figure;
        subplot(3,2,1:4);
        X = getDataFromTif( name , 'X');
        Y = getDataFromTif( name , 'Y');
        Time = getDataFromTif( name , 'Time');
        Z = getDataFromTif( name , 'Z');
        Y_trace = Y(X ~= 0);
        X_trace = X(X ~= 0);
        Time_trace = Time(X ~= 0);  % sub array of 'Time', with timestamps correspomding to the x_trace
        scatter(Y_trace, X_trace, 100, Time_trace, 'filled');
        axis([-300,114000,-300,76000]);
        title('Movement XY - Colored over time');
        subplot(3,2,[5 6]);
        plot(Z);
        title('Z');
        
        arr = struct('X',X,'Y',Y,'X_trace',X_trace,'Y_trace',Y_trace,'Z',Z,'Time',Time, 'Time_trace', Time_trace);
        return;
    end

    inf = imfinfo(name);
    arr_length = numel(inf);
    arr = zeros(1,arr_length);
    defined_names = struct('X','XPosition',...
                            'Time', 'DateTime'	,...	
                            'Y', 'YPosition',...
                            'Z', 'HostComputer' ,... 
                            'EM', 'YResolution'	,...
                            'Exp', 'XResolution');
    
    real_param = defined_names.(param);
    if(strcmp(real_param,'DateTime') || strcmp(real_param,'HostComputer'))
        arr = str2double({inf.(real_param)});
    else
        arr = [inf.(real_param)];
    end
end

