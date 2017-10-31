function [mask_roundized] = createMask(rect_window, neuron_sizer)
% CREATEMASK creates mask of the neuron. It find the optimal threshold
% value.
% Params:
%       frame - the frame with the worm

    radius = ceil(length(rect_window)/2);
    if(neuron_sizer > 0)
        BW = rect_window > (mean(rect_window(:))*neuron_sizer); % THREASHOLD - find all bright pixels.
        [L, num] = bwlabel(BW, 8); % find unconnected components on the photo
        % count_pixels_per_obj = sum(bsxfun(@eq,L(:),1:num));
        % [~,ind] = max(count_pixels_per_obj);    % find the index of the neuron (biggest object) in L

        ind = L(radius , radius);
        % se = ones(3,3);

        mask = double(L==ind);
        mask_roundized = roundizeMask(mask, -1);      % THREASHOLD - second parameter.
        % h1 = figure;
        % subplot(1,2,1);
        % imshow(mask,'InitialMagnification','fit');
        % title('mask');
        % 
        % subplot(1,2,2);
        % imshow(mask_roundized,'InitialMagnification','fit');
        % title('mask_roundized');
        %mask = 1-imdilate(1-mask,se);       % reduce the neuron area by a pixel
        % if(false)
        % end
        % close(h1);
    elseif(neuron_sizer == 0)
        mask_roundized = double(rect_window*0);
        mask_roundized(radius,radius)= 1;
        mask_roundized(radius+1,radius)= 1;
        mask_roundized(radius,radius+1)= 1;
        mask_roundized(radius+1,radius+1)= 1;
    else
        body = floodBody(rect_window, ceil(length(rect_window(:))/2), -neuron_sizer);
        mask_roundized = double(rect_window*0);
        mask_roundized(body) = 1;
        if ((-neuron_sizer) > 30)
            mask_roundized = roundizeMask(mask_roundized, -1);
        end
    end
end

function [body] = floodBody(pic, body, n)
% GETNEIGHBORS returns neighbors of the 'body' as list. Uses linear
% indices.
    len = length(pic);
    for n=1:n
        max_value = 0;
        max_ind = 0;
        for i=1:length(body)
            body_ind = body(i);
            for j=1:9
                new_ind = body_ind + (mod(j-1,3)-1)*len - (j <= 3)-(j <= 6)+1;
                if((sum(body == new_ind) == 0) && (new_ind > 0) && (new_ind <= length(pic(:))))
                    if(pic(new_ind) > max_value)
                        max_value = pic(new_ind);
                        max_ind = new_ind;
                    end
                end
            end
        end
        body = [body max_ind];
    end
end