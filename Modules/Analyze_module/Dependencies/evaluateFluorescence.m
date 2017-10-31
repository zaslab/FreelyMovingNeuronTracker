function [value, masked_neuron] = evaluateFluorescence(rect_window, x, y, radius, background, neuron_sizer)
%
% EVALUATEFLUORESCENCE Function that evaluates fluorescence around given
% point. Input is a cropped neuron from a frame of c.elegans.
%
% Usage Example:
%       >> evaluateFluorescence(rect_window, rows ,cols, radius, frame_no) - frame is a single frame,
%       RGB. x and y are No. of column and row.
%
%
%                               **   written by Alexkaz 9.2014   **

%%%% Simplest implementation:	take GREEN value of the exact point
%{
value = rect_window(round(y), round(x), 2);
%}





%%%% Mean implementation:      take mean of an area around brightest pixel

%temp = rect_window(round(y)-1:round(y)+1, round(x)-1:round(x)+1, 2);
%value = mean(temp(:));

%%%% Brightest k pixels in big area:      take mean of k brightest points in given
%%%% rectangle
%{
radius = radius -1;
temp = rect_window(round(y)-radius:round(y)+radius, round(x)-radius:round(x)+radius, 2);
temp2 = sort(temp(:));
value = mean(temp2(end-5:end));
%}

%%%% Brightest k pixels in big area, normalized by background:      take mean of k brightest points in given
%%%% rectangle, MINUS mean of the other pixels
%{
radius = radius -1;
temp = rect_window(round(y)-radius:round(y)+radius, round(x)-radius:round(x)+radius);
temp2 = sort(temp(:));
numberOfPixels = 20;    % THRESHOLD number of pixels that represent the neuron
background = mean(temp2(1:end-numberOfPixels-1));
value = mean(temp2(end-numberOfPixels:end)) - background;
%}
%%%% Mean of the neuron area, normalized by background: the frame is
%%%% thresholded, the biggest object is found and its area is considered to
%%%% be the neuron.

mask = createMask(rect_window, neuron_sizer);
masked_neuron = (mask).*double(rect_window);       % create masked picture (natural pixel values)
%value = median(double(masked_neuron(masked_neuron~=0))) - background;
value = mean(double(masked_neuron(masked_neuron~=0))) - background;% DEBUG mean or median?
%value = background; % DEBUG to check what values the background can get
