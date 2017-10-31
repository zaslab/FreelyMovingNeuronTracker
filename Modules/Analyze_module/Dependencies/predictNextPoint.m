function [x, y] = predictNextPoint(mem_array)
%
% PREDICTNEXTPOINT Function that predicts the exact point (x,y) of the neuron,
%                  based on the previous movement of the worm.
%
% Usage Example:
%       >> predictNextPoint(full_mem_array[i:i+4])
%
%
%                               **   written by Alexkaz 10.2014   **

    x = 2*mem_array(1,2) - mem_array(1,1);
    y = 2*mem_array(2,2) - mem_array(2,1);