function [head, body, angle] = getAngle(rect_frame, prev_head, radius)

    frame = rect_frame;
    
    % get cercular indexes
    [xx,yy] = ndgrid(-radius:radius, -radius:radius);
    mask = uint8((xx.^2 + yy.^2) < (radius^2 - 500));
    b = bwboundaries(mask);
    b = b{1};
    b = b(1:1:end, :);
    b = [b(:,2) b(:,1)];

    % get 
    len = length(b);
    means = zeros(1, len);
    rect_size = 4;
    for i = 1 : len;
        area = frame(b(i,2)-rect_size:b(i,2)+rect_size, b(i,1)-rect_size:b(i,1)+rect_size);
        means(i) = mean(mean(area));
    end

    % show results
%     imshow(frame*15);
%     hold on;
%     scatter(b(:, 2), b(:, 1), 'g.', 'LineWidth', 2);
%     figure;plot(means);
    [~, I] = sort(means);
   	head = b(I(end), :);
    
    % zero first peak
    means2 = means;
    z_reg_size = 30;
    i = I(end);
    if(i < z_reg_size+1)
        means2(1:i+z_reg_size) = 0;
        means2(end-z_reg_size+i:end) = 0;
    elseif(i > (253-z_reg_size))
        means2(i-z_reg_size:end) = 0;
        means2(1:z_reg_size-(end-i)) = 0;
    else
        means2(i-z_reg_size:i+z_reg_size) = 0;
    end
    [~, I2] = sort(means2);
    body = b(I2(end), :);
    
    % swap head and tail
    if(pdist2(head, prev_head) > pdist2(body, prev_head))
        temp = head;
        head = body;
        body = temp;
    end
    
    %get degree
    len = length(rect_frame)/2;
    neuron = [len;len];
    vec_a = head' - neuron;
    vec_b = neuron - body';

    CosTheta = dot(vec_a,vec_b)/(norm(vec_a)*norm(vec_b));
    if(abs(CosTheta - 1) < exp(1)^-10)
        angle = 0;
        return;
    end
    angle = acos(CosTheta)*180/pi;
    % evaluate left bend or right bend
    sign = cross([vec_a' 0],[vec_b' 0]); % mult of vectors is direction-sensitive.
    bend_direction = sign(3) > 0;
    angle=angle*(bend_direction*2-1);       % bend_direction in {0,1} -> {0,2} -> {-1,1}

    % find closest


%     point = []
%     head_neuron_dist = pdist2([x y], [x_h y_h]);
%     x2 = 43*(dx/head_neauron_dist)+radius;
%     y2 = 43*(dy/head_neauron_dist)+radius;
%     dists = pdist2(b,[y2 x2]);
%     [m, i] = min(dists);
%     point = b(i,:);
end