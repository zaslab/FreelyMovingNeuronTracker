function [] = plot_results()

%%% PLOT_RESULTS Method that plots all the results in a single multi-plot.
%
%   Input:
%       plots - cellArray
%
%   Run:
%       plot_results({'t1',a,'t2', b,'t3', c, 't4',d});


    % ==========    Thresholds           ======
    pixToStage = 4;
    
    % =========================================
    [movie_name,path] = uigetfile('*.mat','Select DB file','MultiSelect','on');
    cd(path);
    
    %load movie DB
    neuron_x = []; neuron_y = []; head_x = []; head_y = []; time_stamps = [];
    head_z = []; fluorescence = []; head_angles = []; len = 0;
    if(iscell(movie_name))
        for i = 1:length(movie_name)
            [neuron_x_t, neuron_y_t, head_x_t, head_y_t, time_stamps_t,...
             head_z_t, head_angles_t, fluorescence_t, len_t] = load_DB_single(path, movie_name{i}, false);
            
            len = len + len_t;
            neuron_x = [neuron_x neuron_x_t];
            neuron_y = [neuron_y neuron_y_t];
            head_x = [head_x head_x_t];
            head_y = [head_y head_y_t];
            time_stamps = [time_stamps time_stamps_t];
            head_z = [head_z head_z_t];
            head_angles = [head_angles head_angles_t];
            fluorescence = [fluorescence fluorescence_t];
        end
        movie_name = movie_name{1};
        sorted = sort(fluorescence);
        base = mean(sorted(1:round(end/5)));
        fluorescence = (fluorescence - base) / base * 100;
    else
        [neuron_x, neuron_y, head_x, head_y, time_stamps, head_z, head_angles, fluorescence, len] = load_DB_single(path, movie_name, true);
    end
     
    
    %%%load attr points
    [file_name, path] = uigetfile(...
        {'*.mat',  'XY file of a attr. movie (*.m)'; ...
        '*.tif','Raw attr. movie (*.tif)'}...
        , 'Select attr movie');
    if(file_name == 0)
        return;
    end
    if(strcmp(file_name(end-2:end), 'mat'))
        load(file_name);
        X = Data.X;
        Y = Data.Y;
    else
        X = getDataFromTif( [path file_name] , 'X');
        Y = getDataFromTif( [path file_name] , 'Y');
    end
    attr_x = X(X ~= 0) + (512/2) * pixToStage;
    attr_y = Y(X ~= 0) - (512/2) * pixToStage;
    attr_radius = (max(attr_x) - min(attr_x) + max (attr_y) - min(attr_y))/4;
    attr_center = [(max(attr_x) + min(attr_x))/2 (max(attr_y) + min(attr_y))/2];
    
    
    %calc updated vectors
    dist_head_attr = zeros(1,len);
    dist_head_attr_center = zeros(1,len);
    speed = zeros(1,len);
    direction_relate_attr = zeros(1,len);
    dir = zeros(1,len);
    in_attr = zeros(1,len);
    %
    for i = 2:len
        D = pdist2([head_x(i), head_y(i)],[attr_x' attr_y']);
        [dist_head_attr(i), closest_attr_point] =  min(D);
        dist_head_attr_center(i) = pdist2([head_x(i), head_y(i)], attr_center);
        movement_vec = [neuron_x(i) - neuron_x(i-1) neuron_y(i) - neuron_y(i-1)];
        speed(i) = norm(movement_vec);
        closest_attr_point = [attr_x(closest_attr_point) attr_y(closest_attr_point)];
        neuron_to_attr = [closest_attr_point(1)-neuron_x(i) closest_attr_point(2)-neuron_y(i)];
        neuron_to_head = [head_x(i)-neuron_x(i) head_y(i)-neuron_y(i)];
        angle_sign = sum(sign(cross([neuron_to_attr 0],[neuron_to_head 0])));   % clockwise is possitive
        direction_relate_attr(i) = acosd(dot(neuron_to_attr,neuron_to_head)/(norm(neuron_to_attr) * norm(neuron_to_head))) * angle_sign;
        dir(i) = acosd(dot(movement_vec,neuron_to_head)/(norm(movement_vec) * norm(neuron_to_head)));
    end
    in_attr = dist_head_attr_center < attr_radius;
    dist_head_attr = dist_head_attr.*(1-in_attr);
	dir_bin = double(dir > 120);
    speed = (-((dir_bin * 2) - 1)) .* speed;
    
    
    %%% Plot things
    plots = {'Fluorescence', ' ', '%Fluorescence', [1 len*8 -50 250], fluorescence(2:end),...
             'Speed - dist(head(i) - head(i-1))', ' ', 'Pixels', [1 len*8 min(speed(2:end))-100 max(speed(2:end))+100], speed(2:end),...
             'Worm Direction', 'Frames (11 fps)', '1 = back', [1 len*8 -1.5 1.5], dir_bin(2:end),...
             'Dist to attr.', ' ', 'Pixels', [1 len*8 min(dist_head_attr(2:end))-100 max(dist_head_attr(2:end))+100], dist_head_attr(2:end),...
             'Angle of head relative to attr', ' ', 'Deg.', [1 len*8 -180 180], direction_relate_attr(2:end),...
             'Head angle', ' ', 'Deg.', [1 len*8 -90 90], head_angles(2:end),...
             'Z height', ' ', 'mm', [1 len*8 min(head_z)-10 max(head_z)+10], head_z(2:end),...
             };
    cyclic = 5;
    num = length(plots) / cyclic;
    
    name = [path movie_name(1:end-4)];
    figure('name', name, 'units', 'normalized', 'outerposition',[0 0 1 1]);
    x_labels  = 9:8:len*8;
    for i = 1:num
        subplot(num,1,i);
        surface([x_labels;x_labels], [plots{cyclic*i};plots{cyclic*i}], [zeros(1,len-1);zeros(1,len-1)],[plots{5};plots{5}],...
                'facecol', 'no',...
                'edgecol', 'interp',...
                'linew',2);
        caxis([-50 100]);
        if(i==1)
            hold on;
            nand_Z = diff(head_z)*0; % creating array of same size
            nand_Z(diff(head_z) == 0) = NaN; % filling all 0 values by NaN - will not be drawn
            nand_dir = dir_bin*0;
            nand_dir(dir_bin == 0) = NaN;
            
            plot(x_labels,nand_dir(2:end), 'LineWidth', 5, 'Color', 'Red');
            plot(x_labels,nand_dir(2:end), 'r*', 'MarkerSize', 6);
            plot(x_labels,nand_Z+200, 'LineWidth', 10, 'Color', 'Black');
            plot(x_labels,nand_Z+200, 'k*', 'MarkerSize', 6);
            hold off;
        end
        title(plots{cyclic*i-4});
        xlabel(plots{cyclic*i-3});
        ylabel(plots{cyclic*i-2});
        axis(plots{cyclic*i-1});
%         set(gca,'XTick',1:8:length(plots{cyclic*i})*8);
        grid on;
    end
    
    %%% save new DB
    post_proc_DB = struct('Fluorescence', fluorescence(2:end), 'Speed', speed(2:end),...
                          'Angle_to_attr', direction_relate_attr(2:end),...
                          'Dist_to_attr', dist_head_attr(2:end), 'Z_height', head_z(2:end),...
                          'Head_angle', head_angles(2:end), 'head_position',[head_x(2:end); head_y(2:end)],...
                          'neuron_position',[neuron_x(2:end); neuron_y(2:end)], 'Direction', dir(2:end));
    save([movie_name(1:end-4) '_post_proc_DB.mat'], 'post_proc_DB');
    

end

function [neuron_x, neuron_y, head_x, head_y, time_stamps, head_z,...
          head_angles, fluorescence, len] = load_DB_single(path, movie_name,isSingle)
    s = load([path movie_name]);
    db_reduced = s.db_reduced;
% %     PixToStage=1.6015625;
%     PixToStage = 1;
      len = length(db_reduced.time_stamps_reduced);
%     neuron_x_t = db_reduced.neuron_point_reduced(1,:);
%     neuron_y_t = -db_reduced.neuron_point_reduced(2,:);    % MINUS sign is for consistency between axis dierctions of the stage and the image pixels
%     neuron_x = db_reduced.stage_x_reduced + PixToStage*neuron_x_t;
%     neuron_y = db_reduced.stage_y_reduced + PixToStage*neuron_y_t;
%     
%     head_x_t = db_reduced.head_point_reduced(1,:);
%     head_y_t = -db_reduced.head_point_reduced(2,:);
%     head_x = db_reduced.stage_x_reduced + PixToStage*head_x_t;
%     head_y = db_reduced.stage_y_reduced + PixToStage*head_y_t;
    neuron_x = db_reduced.neuron_point_reduced(1,:);
    neuron_y = db_reduced.neuron_point_reduced(2,:);
    head_x = db_reduced.head_point_reduced(1,:);
    head_y = db_reduced.head_point_reduced(2,:);
    time_stamps = db_reduced.time_stamps_reduced;
    head_z  = db_reduced.stage_z_reduced;
    head_angles = db_reduced.head_angle_values;
    fluorescence = db_reduced.ratio_fluo_reduced;
    if(~isSingle)
        fluorescence = db_reduced.raw_fluo_reduced;
    end
    
end


function [dir_arr] = calc_dir(head, neuron)
    len = length(head);
    dir_arr_a = zeros(1,len-1);
    dir_arr_b = zeros(1,len-1);

    for i=3:len
        dir_arr_a(i) = (pdist2(neuron(:,i-1)', head(:,i)'));
        dir_arr_a(i) = (pdist2(neuron(:,i-2)', head(:,i)'));
    end
    
    dir_arr = (dir_arr_b(2:end) + dir_arr_a)/2;
end
