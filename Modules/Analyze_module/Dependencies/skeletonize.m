function [skeleton, HeadPoint, angle, thr, round_mask] = skeletonize(frame, intervals, num_of_points, neuronPoint, thr)
% SKELETONIZE method that finds the skeleton, the head and the angle of a head of a worm on a frame.
%      bend_direction = 1 , angle > 0    -     counter-clockwise head turn
%      bend_direction = 0 , angle < 0    -     clockwise head turn
% 
% Usage Example:
%       >> [skeleton, HeadPoint, angle] = skeletonize(frame, 30, 10, 900, [254 316])
%
%                                                   Written by AK 3.2015
	[mask, thr] = createMask(imadjust(frame), neuronPoint);
    

    %%% roundize
    se = ones(3,3);
    round_mask = imdilate(mask,se);


    %%% get boundaries of the worm
    boundaries = bwboundaries(round_mask);
    b = boundaries{1};  % points of contour.

    %%find head & tail, by mean-vector product
    % each point on perimiter finds a single mean vector to each direction of
    % its neighbours. Then a dot-product is found, and the couple with a
    % MAXIMUM value are picked

    [skeleton, HeadPoint] = findSkeletonNhead(b, neuronPoint, intervals, num_of_points);

    % calc the degree of the head
    vec_a = skeleton(:,num_of_points/2)-skeleton(:,num_of_points);
    vec_b = skeleton(:,1)-skeleton(:,num_of_points/2);

    CosTheta = dot(vec_a,vec_b)/(norm(vec_a)*norm(vec_b));
    angle = acos(CosTheta)*180/pi;
    % evaluate left bend or right bend
    sign = cross([vec_a' 0],[vec_b' 0]); % mult of vectors is direction-sensitive.
    bend_direction = sign(3) > 0;
    angle=angle*(bend_direction*2-1);       % bend_direction in {0,1} -> {0,2} -> {-1,1}
end

function [skeleton, head] = findSkeletonNhead(contour_array_full, neuronLocation, skeleton_resolution, num_of_points)
% FINDSKELETONNHEAD recieves a contour of a single worm, and finds the
% head and tail locations. Assumption is that the neuron is closer to the
% head point than to the tail end.
%
% Parameters:
%       contour_array - array of points (each has 2 week neighbours).
%               boundaries = bwboundaries(bw_worm_removedNoise);
%               contour_array = boundaries{1};  % points of contour.
%
%
%                               **   written by Alexkaz 1.2015   **

    contour_array = contour_array_full(1:10:end,:);
    num_of_point = length(contour_array);
    dotProduct_results = zeros(1,num_of_point);
    hopResolution = 5; % THRESHOLD
    
    for i=1:1:num_of_point

        prev = i-hopResolution;
        if (prev <= 0)
            prev = prev+num_of_point;
        end

        next = i+hopResolution;
        if (next > num_of_point)
            next = next-num_of_point;
        end
        vectorA = [contour_array(next,1)-contour_array(i,1) contour_array(next,2)-contour_array(i,2)];
        vectorB = [contour_array(prev,1)-contour_array(i,1) contour_array(prev,2)-contour_array(i,2)];
        dotProduct_results(i) = dot(vectorA , vectorB);
    end

    [~, ind] = sort(dotProduct_results); % get indeces of maximal dot-product (end of the array)
    contour_array_sorted = contour_array(ind,:);
	contour_array_sorted = contour_array_sorted((pdist2(neuronLocation,contour_array_sorted,'euclidean') <80),:);
    try
        head = contour_array_sorted(end,:);
    catch em
        head = contour_array_full(1,:);
    end
    [~,headInd]=ismember(head,contour_array_full,'rows');
    skeleton = findSkeleton(contour_array_full, headInd, skeleton_resolution, num_of_points);
end

function [skeleton_array] = findSkeleton(contour_array, headIndex, points_distance, num_of_points)
% FINDSKELETON recieves a contour of a single worm and the location of a
% neuron, and returns the 5 points of cetral spine, when point 1 is the
% head tip and point 5 is the start of the gut.
%
% Problems: a-symetric evaluation of the skeleton, one side of the worm is
% always leading. The skeleton may get inconsistant if turning in different
% directions.
%
%                               **   written by Alexkaz 3.2015   **

    skeleton_array = zeros(2,5);
    skeleton_array(:,1) = contour_array(headIndex,:)';
    side_A = zeros(2,num_of_points);
    side_B = zeros(2,num_of_points);
    num_points = length(contour_array);
    contour_array = repmat(contour_array,2,1); % trick for cycling index (instead of modulo math on index values)

    lastPoint = 0;
    for i=1:1:num_of_points
        side_A(:,i) = contour_array(headIndex+i*points_distance,:)';
        % create first vector - Meshiq to the first point
        vector_A = [contour_array(headIndex+i*points_distance-10,1)-contour_array(headIndex+i*points_distance+10,1) contour_array(headIndex+i*points_distance-10,2)-contour_array(headIndex+i*points_distance+10,2)];
        degreeToPoints = zeros(1,2*points_distance);
        for j=1:1:2*points_distance;
            vector_B = [contour_array(num_points + headIndex-lastPoint-j,1)-side_A(1,i) contour_array(num_points + headIndex-lastPoint-j,2)-side_A(2,i)];
            degreeToPoints(j) = abs(dot(vector_A, vector_B));
        end
        [~, ind] = min(degreeToPoints);
        lastPoint = lastPoint + ind;
        % create first vector - Meunah to the first point
        side_B(:,i) = contour_array(num_points + headIndex - lastPoint,:)';
    end

    % creating the middle points of the skeleton
    for i=1:1:num_of_points
        skeleton_array(:,i+1) = [mean([side_A(1,i) side_B(1,i)]);mean([side_A(2,i) side_B(2,i)])];
    end

end

function [mask, thr] = createMask(frame, neuronPoint)

    frame_smoothed = im2double(wiener2(frame,[3 3]))*65535;
    thr_start = median(frame_smoothed(:));
    CC_labels = bwlabel(frame_smoothed > thr_start);
    prev_mask_neuron = (CC_labels == CC_labels(round(neuronPoint(1)), round(neuronPoint(2))));
    sum_start = sum(prev_mask_neuron(:));
    res = 7;
    limit = 9000;
    prev_sum = sum_start;
    
    thr = thr_start - 50;
    flag = 1;       % decrease pixel number, set 'thr' higher
    if(sum_start < limit)
        flag = -1;      % encrease pixel number
    end
    for i = 1:1:30
        thr = thr + flag * res * i;
        CC_labels = bwlabel(frame_smoothed > thr);
        mask_neuron = (CC_labels == CC_labels(round(neuronPoint(1)), round(neuronPoint(2))));
        summed = sum(mask_neuron(:));
        if(flag*summed < flag*limit)
            if(( (flag == 1) &&(summed < limit - 5000)) || ( (flag == -1) &&(summed > limit + 10000)))
                mask_neuron = prev_mask_neuron;
            end
            break;
        end
        prev_sum = summed;
        prev_mask_neuron = mask_neuron;
    end
    mask = imdilate(mask_neuron,ones(3));
%     disp(['i = ' num2str(i)]);
end

function [mask_neuron] = findSingleCC(frame, neuronPoint, res, shift, doSmooth)
    if(doSmooth)
        frame = im2double(wiener2(frame,[3 3]))*65535;
    end
    thr = median(double(frame(:)));
    figure;
    for i=1:1:12
        
        dt = i*res;
        if(i == 12)
            dt = thr;
        end
        CC_labels = bwlabel(frame > thr - shift + dt);
        mask_neuron = (CC_labels == CC_labels(round(neuronPoint(1)), round(neuronPoint(2))));
        subplot(3,4,i);
        imshow(mask_neuron);
        summed = sum(mask_neuron(:));
        title(['mean-' num2str(res) '+' num2str(shift) '  Sum: ' num2str(summed ) '   ==   ' num2str(summed / length(frame) / length(frame) * 100) '%']);        
    end
end