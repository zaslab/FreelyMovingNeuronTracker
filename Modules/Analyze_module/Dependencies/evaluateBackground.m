function [value,gdDownPer10pxls] = evaluateBackground(frame, startBox, endBox)
% EVALUATEBACKGROUND evaluates the background value.
% Params:
%       frame - the frame with the worm
%
% Output:
%       gdDownPer10pxls - coefficient of the gradient for the gradient, from
%       up to down.given

dim = size(frame);
width = dim(2);
height = dim(1);
hieghtBetweenUandD = height-(endBox+startBox);
ULcorner = frame(startBox:endBox ,  startBox:endBox);
%Ucorner = frame(20:40 ,  width/2-20:width/2+20);
URcorner = frame(startBox:endBox , width-endBox:width-startBox);
Lcenter = frame(height/2-20:height/2+20 , 20:40);
%Rcenter = frame(height/2-20:height/2+20 , width-40:width-20);
%center = frame(height/2-20:height/2+20 , width/2-20:width/2+20);
DLcorner = frame(height-endBox:height-startBox , startBox:endBox);
%Dcorner = frame(height-40:height-20 , width/2-20:width/2+20);
DRcorner = frame(height-endBox:height-startBox , width-endBox:width-startBox);


%values = [mean(mean(ULcorner)) mean(mean(Ucorner)) mean(mean(URcorner)) mean(mean(Lcenter)) mean(mean(center))  mean(mean(Rcenter)) mean(mean(DLcorner)) mean(mean(Dcorner)) mean(mean(DRcorner))];
values = [mean(mean(ULcorner)) mean(mean(URcorner)) mean(mean(DLcorner)) mean(mean(DRcorner))];
[~,maximum] = max(values);
%value = mean(values(1:end ~= maximum));
value = mean(mean(Lcenter));
gdDownPer10pxls = (mean(mean(DLcorner)) - mean(mean(ULcorner)))/hieghtBetweenUandD;