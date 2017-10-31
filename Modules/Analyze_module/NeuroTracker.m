function [mult_factor, last_neuron_point] = NeuroTracker(inputFile, msPerFrame, debugOn, featuresOn, headPoint_opt, multFact_opt)
%
%
% NEUROTRACKER Function that recieves a movie and outputs neuron activity
% level - a graph of neuron fluorescence vs time(secs). The function asks
% to select the bordering frames of the time measurment interval. Then the
% user is asked to mark the neuron by the cursor. After that the analyzing
% takes place until the graph is printed to the screen.
%
% Signature:
%       >> NeuroTracker(inputFile, msPerFrame, debugOn, featuresOn, headPoint_opt, multFact_opt)
%
% Usage Example:
%       >> [] = NeuroTracker('temp2.tif', 33, false, false)
%       >> [] = NeuroTracker('temp2.tif', 33, false, true, [x y])
%
%
%                               **  written by Alexkaz  9.2014     **

    global radius_size plane_position frame_area neuron_rect_area mask_area plot1_area plot2_area start_frame end_frame fastAngleOn file_name PixToStage
    %=========    constants  =================
    radius_size = 30;             %   THRESHOLD - size of the bubble around the neuron
    neuron_sizer = -20;             %   THRESHOLD - mean*neuron_sizer if >0, middle 4 pixels if ==0, grow from mid by 'neuron_sizer' if <neuron_sizer
    bg_eval_start_pixel = 30;     %   The boundaries of the background rectangle evaluation 
    bg_eval_end_pixel = 50;
    update_line_tick = 25;        %   how often the "Finished 23%" line will be printed
    fastAngleOn = false;
    PixToStage=1.6;
    
    intervals = 15;               %   intervals between the skeleton points
    num_of_sceletal_points = 10;           %   amount of points in the skeleton
    forPPT = true;
    
    plane_width_plots = 8;
    plane_height_featuresOn_plots = 9;
    plane_height_featuresOff_plots = 11;
    plane_position = [10 50 1024 940];
    
    frame_area = [1:6 9:14 17:22 25:30 33:38 41:46];
    neuron_rect_area = [7 8 15 16];
    mask_area = [31 32 39 40];
    plot1_area = [57:72];
	plot2_area = [81:88];
    thr = 0;                % constant of skeletonization
    %==========================================

    if nargin == 0      % script run to analyze single movies.
        NeuroTracker(false,true);
        return;
    end
    
    if nargin == 2       % script run to analyze single movies, custumize 'animate' and 'features'
        debugOn = inputFile;
        featuresOn = msPerFrame;
        [inputFile,path] = uigetfile('*.tif','Select a Movie');
        cd(path);
%         msPerFrame  = inputdlg('msPerFrame','msPerFrame',1,{'90'});
%         msPerFrame = str2double(msPerFrame{1});
        msPerFrame = 90;
    end
    
    if nargin < 5       % script run in manual run - check 'start_frame' , 'mult_fact' and '[x y]'
        [mult_factor, start_frame, end_frame] = playTif(inputFile);
        figure;
        frame = imread(inputFile, start_frame);
        imshow(frame*mult_factor);
        [x,y] = getpts;
        if(fastAngleOn)
            hold on;
            plot(x, y, 'g*','MarkerSize',30);
            [x_head,y_head] = getpts;
        end

        close;
    else                % sctipr run in piped manner - no user interaction is activated!
        mult_factor = multFact_opt;
        x = headPoint_opt(1);
        y = headPoint_opt(2);
        start_frame = 1;
        end_frame = 1000;
        frame = imread(inputFile, start_frame);
    end
    
    % Get movie data 
    
    info = imfinfo(inputFile);
    numOfFrames = numel(info);   %   get number of frames
    old_path = cd;
    file_path = which(inputFile);
    [file_path,~,~] = fileparts(file_path);
    cd(file_path);
    disp(['Dumping files to DIR:  ' file_path]);
    file_name = [inputFile(1:end-4) '.mat'];
    disp(['=== Proccessing: ' file_name '   ===']);
    if((start_frame ~= 1) || (end_frame ~= length(info)))
        file_name = [inputFile(1:end-4) '.' num2str(start_frame) '-' num2str(end_frame) '.mat'];
    end
    
    % Acquire neuron area from the user
    
    isGrayScale = strcmp(info(1).ColorType, 'grayscale');
    maxPixelDepth = info(1).MaxSampleValue(1);
    bitDepth = info(1).BitDepth(1);
             % line may be needed for MATLAB R2012b version.
   
    
    % get smaller area that contains the neuron of interest
    try
        rect_pic = getSubPicture(frame, x ,y, radius_size, isGrayScale, bitDepth);
    catch EM
        disp('ERROR - initial [X Y] miss the neuron');
        return;
    end
    [cols,rows] = find(rect_pic == max(max(rect_pic)));   % find maximum spot
 
    x = x-radius_size+rows(1)-1;            %   set the Point to the brightest spot
    y = y-radius_size+cols(1)-1;
    
    rect_pic = getSubPicture(frame, x ,y, radius_size, isGrayScale, bitDepth); % cut area around found neuron
    
    movie_length = end_frame - start_frame + 1;
    pixel_values = zeros(1, movie_length);
    neuron_point = zeros(2, movie_length);
    background_values = zeros(1, movie_length);
    head_angle_values = zeros(1);
    head_point_values = zeros(2, movie_length);
    skeletonValues = cell(1,movie_length);
    ratio_values = zeros(1,5);
    base_level = -1; % the mean of fluorescence of the first 5 frames, for ratio calculations.
    neuron_point(:,1) = [x y];
    background_values(1) = evaluateBackground(frame, bg_eval_start_pixel, bg_eval_end_pixel);
    [pixel_values(1), masked_neuron] = evaluateFluorescence(rect_pic, x ,y, radius_size, background_values(1), neuron_sizer);
    
    %%Creating plot configurations
    figure('name', file_name(1:end-4), 'Position', plane_position);
    set(gcf,'PaperPositionMode','auto');
    plots_height = plane_height_featuresOn_plots;   % Snaller output plane if no features.
    if(featuresOn)
        plots_height = plane_height_featuresOff_plots;
    end

    subplot(plots_height,plane_width_plots,frame_area);     %   A plot with the worm movie
    movie_window = imshow(frame*mult_factor,'Border','tight');

    title('Neuron Tracking', 'FontSize', 16);
    hold on;
    
    subplot(plots_height,plane_width_plots,plot1_area);     %   A plot with the Graph
    plot(ratio_values);
    
    subplot(plots_height,plane_width_plots,neuron_rect_area);
    title(['Area of the neuron: Frame ' 1],'FontSize', 16);
    hold on;
    rect_window = imshow(rect_pic);
    
    subplot(plots_height, plane_width_plots ,mask_area);
    title('Neuron threshold', 'FontSize', 16);
    hold on;
    mask_window = imshow(masked_neuron);
    
    %get skeleton info and draw on the graph
    if(featuresOn)
        if(~fastAngleOn)
            [skeleton, HeadPoint, angle, thr, worm_mask] = skeletonize(frame, intervals, num_of_sceletal_points, [y x], thr);
            head_point_values(:,1) = [HeadPoint(2) HeadPoint(1)];
            skeletonValues{1} = skeleton;
        else
            head_neuron_dist = pdist2([x y], [x_head y_head]);
            x2 = 43 * ((x_head - x) / head_neuron_dist) + radius_size;
            y2 = 43 * ((y_head - y) / head_neuron_dist) + radius_size;
            prev_head = [x2 y2];
            [head, body, angle] = getAngle(rect_pic, prev_head, radius_size);
            prev_head = head;
            head_point_values(:,1) = [x-radius_size+head(1), y-radius_size+head(2)];
            skeletonValues{1} = {'head', head_point_values(:,1), 'body', [x-radius_size+body(1), y-radius_size+body(2)], 'angle', angle};  
        end
        head_angle_values = angle;
        
    end
        
    % creating the aimation file - DEBUG MODE
    if debugOn
        if featuresOn
            anim_file_name = [inputFile(1:end-4) '.Features.animation.tif'];
        else
            anim_file_name = [inputFile(1:end-4) '.animation.tif'];
        end
        disp(['Created animation file:  ' anim_file_name]);
    	print('-dtiff','-r0',anim_file_name);
    end
    
    % create the memory array
    
    mem_array = zeros(2, movie_length);
    mem_array(1,2) = x;
    mem_array(2,2) = y;     %   both first column are same, corner case of first loop
    mem_array(1,1) = x;
    mem_array(2,1) = y;
    
    drawnow;
    % updating loop
    for k = 2:movie_length
        
        % Update neuron to the center
        frame = imread(inputFile, k+start_frame-1,'Info', info);
        
        [x_expected, y_expected] = predictNextPoint(mem_array(1:2 , (k-1):(k))); % get point where the neuron is expected
        try
            rect_pic = getSubPicture(frame, x_expected ,y_expected, radius_size, isGrayScale, bitDepth); % get estimated neuron area
        catch EM
            disp(EM.message);
            printDB(start_frame, inputFile, old_path,info, neuron_point, pixel_values, head_point_values, ratio_values, background_values,head_angle_values, skeletonValues);
            return;
        end
        [cols,rows] = find(rect_pic == max(max(rect_pic))); % cols = y ; rows = x
        
        x = x_expected - radius_size + rows(1) - 1;
        y = y_expected - radius_size + cols(1) - 1;
        
        % updating the mem_array - note that first 2 columns are similar, second is
        % k=1 and so on, so there is a shift of 1 to the right :)
        mem_array(1, k + 1) = x;
    	mem_array(2, k + 1) = y;
        try
            rect_pic = getSubPicture(frame, x ,y, radius_size, isGrayScale, bitDepth); % exact neuron area        
        catch EM
            disp(EM.message);
            printDB(start_frame, inputFile, old_path,info, neuron_point, pixel_values, head_point_values, ratio_values, background_values,head_angle_values, skeletonValues);
            return;
        end
        [cols,rows] = find(rect_pic == max(max(rect_pic)));   % find maximum spot
    
        x = x - radius_size + rows(1) - 1;            %   set the Point to the brightest spot
        y = y - radius_size + cols(1) - 1;
        neuron_point(:, k) = [x y];
    
        % draw the current worm frame
        set(movie_window, 'CData', frame * mult_factor);
        
        if(forPPT)  % print the file name
            title(['Frame No.' num2str(k + start_frame - 1)], 'FontSize', 16);
        else
            title(['File: ' num2str(inputFile(1: end - 4)) '.  Frame No:' num2str(k + start_frame - 1), 'FontSize', 16,'Interpreter','none'], 'FontSize', 16,'Interpreter','none');
        end
        subplot(plots_height, plane_width_plots, frame_area);
        h = plot(x, y, 'yo', 'MarkerSize', 30, 'LineWidth', 4);   % x ~ rows , y ~ cols
                
        % Update the graph
        background_values(k) = evaluateBackground(frame, bg_eval_start_pixel, bg_eval_end_pixel);
        [pixel_values(k), masked_neuron] = evaluateFluorescence(rect_pic, radius_size ,radius_size, radius_size, background_values(k), neuron_sizer);
        if k > 5
            if k==6
                base_level = mean(pixel_values(1:5));
            end
            ratio_values = [ratio_values evaluateRatio(pixel_values(k), base_level)];
        end
        
        updateGraph(plots_height, plane_width_plots, plot1_area, ratio_values, [0, movie_length, -50,250],[50/255, 150/255, 3/255], 'Time (sec)', 'Activity changes in %','Fluorescence of the neuron', numOfFrames, msPerFrame, true);

        
        % Update the Neuron window
        subplot(plots_height, plane_width_plots, neuron_rect_area);
        set(rect_window, 'CData', rect_pic * mult_factor);
        title('Area of the neuron', 'FontSize', 16);
        boundaries = bwboundaries(masked_neuron);
        contour_points = boundaries{1};  % points of contour.
        hc = plot(contour_points(:,2), contour_points(:,1), 'g', 'LineWidth', 0.5);
        %f = plot(rows, cols, 'ro','MarkerSize', 20);
        
        
        
        %get skeleton info and draw on the graph
        if(featuresOn)
            if(~fastAngleOn)
                try
                    size = 100;
                    pic_small = frame(round(y)-size:round(y)+size,round(x)-size:round(x)+size);
%                     [skeleton, HeadPoint, angle, thr, worm_mask] = skeletonize(frame, intervals, num_of_sceletal_points, [y x], thr);
                    [skeleton_small, HeadPoint_small, angle, thr, worm_mask] = skeletonize(pic_small, intervals, num_of_sceletal_points, [size size], thr);
                    skeleton(1,:) = skeleton_small(1,:)  + y-size;
                    skeleton(2,:) = skeleton_small(2,:)  + x-size;
                    HeadPoint(1)  = HeadPoint_small(1) + y-size;
                    HeadPoint(2)  = HeadPoint_small(2) + x-size;
                catch EM
                    disp(['Error in frame: ' num2str(k + start_frame - 1)]);
                end
                subplot(plots_height,plane_width_plots,frame_area);
                h1 = plot(skeleton(2,:),skeleton(1,:), 'r.','MarkerSize',10);
                h2 = plot(HeadPoint(2),HeadPoint(1), 'g*','MarkerSize',25);
                head_point_values(:,k) = [HeadPoint(2) HeadPoint(1)];
                skeletonValues{k} = skeleton;
                
                subplot(plots_height,plane_width_plots,mask_area);
                h3 = plot(skeleton_small(2,:),skeleton_small(1,:), 'r.','MarkerSize',3);
                h4 = plot(HeadPoint_small(2),HeadPoint_small(1), 'g*','MarkerSize',8);
            else
                [head, body, angle] = getAngle(rect_pic, prev_head, radius_size);
                prev_head = head;
                head = [x-radius_size+head(1), y-radius_size+head(2)];
                body = [x-radius_size+body(1), y-radius_size+body(2)];
                head_point_values(:,k) = head;
                skeletonValues{k} = {'head', head, 'body', body, 'angle', angle};
                subplot(plots_height,plane_width_plots,frame_area);
                h1 = plot(head(1),head(2), 'r*','MarkerSize',10);
                h2 = plot(body(1),body(2), 'g.','MarkerSize',10);
            end
            head_angle_values = [head_angle_values angle];


        end
        
        % Update the Mask window
        subplot(plots_height,plane_width_plots,mask_area);
        if(featuresOn && (~fastAngleOn))
            set(mask_window, 'CData', worm_mask);
        else
            set(mask_window, 'CData', masked_neuron);
        end
        if(featuresOn && (~fastAngleOn))
            tit= 'Worm - thresholded';
        else
            tit= 'Neuron - thresholded';
        end
        title(tit,'FontSize', 16);
        %m = plot(rows, cols, 'ro','MarkerSize', 20);

        if(featuresOn)
            updateGraph(plots_height, plane_width_plots, plot2_area, head_angle_values, [0,movie_length,-90,90],'blue', 'Time (sec)', 'Head deg.','Head degree change (Clockwise = negative)', numOfFrames, msPerFrame, true);
        end
        %plot the head values on the plot
        
        % add created multiplot to the animation
        if debugOn
            print('-dtiff','-r0','temp.tif');
            temp = imread('temp.tif');
            imwrite(temp, anim_file_name, 'WriteMode','append');
        end
        
        drawnow;
        subplot(plots_height, plane_width_plots, frame_area)
        delete(h);	% remove current dot on the worm figure
        delete(hc);
        
        if(featuresOn)
            delete(h1);	% remove current dot on the worm figure
            delete(h2);	% remove current dot on the worm figure
            if(~fastAngleOn)
                delete(h3);	% remove current dot on the worm thresh
                delete(h4);	% remove current dot on the worm thresh
            end
        end
        
        if(mod(k,update_line_tick) == 0)
            disp(['|======  Finished analyzing frame No.:     ' num2str(k) '  /  ' num2str(movie_length) '    ' num2str(k/movie_length*100,2) '%' '   ==========|']);
        end
    end
    last_neuron_point = neuron_point(:,end);
    
    % getting data out of the .tif headers
    
    printDB(inputFile, old_path,info, neuron_point, ...
            pixel_values, head_point_values, ratio_values, ...
            background_values,head_angle_values, skeletonValues);
end

function [db_full, db_reduced] = prepareDB(info, neuron_point, raw_data, ...
                                            head_point_values, ratio_data, ...
                                            background_values,head_angle_values, skeletonValues)
    global start_frame end_frame PixToStage
    % Create reducing array
    stage_x = [info.XPosition];
%     stage_x = stage_x(start_frame:end_frame);
    reduction_arr = stage_x ~= 0;
    stage_x_reduced = stage_x(reduction_arr);
    
    stage_y = [info.YPosition];
%     stage_y = stage_y(start_frame:end_frame);
    % Reduce all arrays
    stage_y_reduced = stage_y(reduction_arr);
    time_stamps = str2double({info.DateTime});
%     time_stamps = time_stamps(start_frame:end_frame);
    time_stamps_reduced = time_stamps(reduction_arr);  % sub array of 'Time', with timestamps correspomding to the x_trace
    stage_z = str2double({info.HostComputer});
%     stage_z = stage_z(start_frame:end_frame);
    stage_z_reduced = stage_z(reduction_arr);
    ratio_fluo_reduced = ratio_data(reduction_arr);
    raw_fluo_reduced = raw_data(reduction_arr);
    skeletonValues_reduced = skeletonValues(reduction_arr);
    head_point_reduced = head_point_values(:,reduction_arr);
    neuron_point_reduced = neuron_point(:,reduction_arr);
    head_angle_reduced = head_angle_values(reduction_arr);
    
    % create special arrays
    neuron_x_t = neuron_point_reduced(1, :);
    neuron_y_t = -neuron_point_reduced(2, :);    % MINUS sign is for consistency between axis dierctions of the stage and the image pixels
    neuron_x = stage_x_reduced + PixToStage * neuron_x_t;
    neuron_y = stage_y_reduced + PixToStage * neuron_y_t;
    
    head_x_t = head_point_reduced(1, :);
    head_y_t = -head_point_reduced(2, :);
    head_x = stage_x_reduced + PixToStage * head_x_t;
    head_y = stage_y_reduced + PixToStage * head_y_t;
    
    % Save the DB
    db_full = struct('raw_data',raw_data,...
                    'ratio_data', ratio_data, ...
                    'background_values', background_values, ...
                    'skeletonValues', {skeletonValues}, ...
                    'head_angle_values', head_angle_values, ...
                    'head_point_values', head_point_values,...
                    'neuron_point', neuron_point, ...
                    'stage_x', stage_x, ...
                    'stage_y', stage_y, ...
                    'stage_z', stage_z, ...
                    'time_stamps', time_stamps);
                
   db_reduced = struct('stage_x_reduced', stage_x_reduced, ...
                    'stage_y_reduced', stage_y_reduced, ...
                    'stage_z_reduced', stage_z_reduced, ...
                    'ratio_fluo_reduced', ratio_fluo_reduced, ...
                    'raw_fluo_reduced', raw_fluo_reduced, ...
                    'neuron_point_reduced', [neuron_x; neuron_y], ...
                    'time_stamps_reduced', time_stamps_reduced,...
                    'skeletonValues_reduced', {skeletonValues_reduced},...
                    'head_point_reduced', [head_x; head_y],...
                    'head_angle_values', head_angle_reduced);
end

function printDB(inputFile, old_path,info, neuron_point, raw_data, head_point_values, ratio_data, background_values,head_angle_values, skeletonValues)
    global start_frame end_frame file_name
   	
    info = info(start_frame:end_frame);
    [db_full, db_reduced] = prepareDB(info, neuron_point, raw_data, head_point_values, ratio_data, background_values,head_angle_values, skeletonValues);
    save(file_name, 'db_full', 'db_reduced');
    disp(['Created DB file:  ' file_name]);
    cd(old_path);
end