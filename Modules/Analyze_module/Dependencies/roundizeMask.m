function [mask] = roundizeMask(mask, vector_int)

%
% ROUNDIZEMASK That creates a mask more round object. If the _vector_int is
% 0 it only roundize the object, if +1 grows one bit and if -1 removes 1
% bit.
%
% The algorithm: ADD pixel of mask if has at least 5 bright neighbours,
% then REMOVE pixel that has less than 4 neighbours.
%
% Usage Example:
%       >> roundizeMask(mask, -1)
%
%                     

    height = length(mask);
    width = length(mask(1,:));

    mask = doOneOperation(mask, 1, height, width);
    
    if(vector_int > 0)
        mask = doOneOperation(mask, 1, height, width);
    elseif (vector_int < 0)
        mask = doOneOperation(mask, 0, height, width);
    end
    
end

function [mask] = doOneOperation(mask, direct, height, width)
%
% DOONEOPERATION save code repetition
% The direct variable is BINARY - 1 if grow one, 0 if remove one.
%
% Usage Example:
%       >> doOneOperation(mask, direct, height, width)
%
%

    for i=2:1:(height-1)
        for j=2:1:(width-1)
            if (mask(i,j) == (1-direct))
                neighbours = sum(sum(mask(i-1:i+1,j-1:j+1)))-mask(i,j);
                if direct == 1
                    if(neighbours > 4)
                        mask(i,j) = direct;
                    end
                else
                    if(neighbours < 4)
                        mask(i,j) = direct;
                    end
                end
            end
        end
    end
end
