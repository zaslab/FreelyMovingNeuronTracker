function [subPic] = getSubPicture(frame, y_center ,x_center, radius, isGS, bits)
%
% GETSUBPICTURE Function that crops an area out of the frame, around given
% point, with a given radius (or length, if rectangle).
%
% Usage Example:
%       >> getSubPicture(frame, x_center ,y_center, radius, isGS)
%
%                               **   written by Alexkaz 9.2014   **

    %%%% Rectangle:     crop square with (radius+1) side, while the point
    %%%%                is in the middle
    
    %subPic = imcrop(frame,[x_center-radius/2 y_center-radius/2 radius radius]); % cut area around point
    
    
    
    %%%% Circle:        crop circle around the given point, and returns
    %%%%                rectangle that is white except the circled inner
    %%%%                area.
    
    imageSize = size(frame);
    imageSize = imageSize(1:2);

    [xx,yy] = ndgrid((1:imageSize(1))-x_center,(1:imageSize(2))-y_center);
    if bits == 8
        mask = uint8((xx.^2 + yy.^2)<radius^2);
        temp = uint8(zeros(imageSize));
    else
        mask = uint16((xx.^2 + yy.^2)<radius^2);
        temp = uint16(zeros(imageSize));
    end
    
    if not(isGS)
        temp = frame(:,:,2).*mask;
    else
        temp = frame.*mask;
    end
    subPic = temp(round(x_center - radius):round(x_center + radius), (round(y_center - radius)):round(round(y_center) + radius));