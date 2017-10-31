function [] = checkCommunication(config)
%%% CHECKCOMMUNICATION checks communication of the MATLAB and the hardware of
%   the microscope. If no config file is given as a parameter, the demo
%   config will be loaded.
%   
%   Known configuration files:
%       'C:\Program Files\Micro-Manager-1.4\MMConfig_demo.cfg'
%       'C:\Program Files\Micro-Manager-1.4\PriorXY_PVCam.cfg'
%       'C:\Program Files\Micro-Manager-1.4\Cam_IX83_StageXY.cfg'
%
%                                    **  written by Alexkaz  4.2015     **


import mmcorej.*;
mmc = CMMCore;
if(nargin < 1)  
    config = 'C:\Program Files\Micro-Manager-1.4\MMConfig_demo.cfg';
end
mmc.loadSystemConfiguration (config);

% check camera - take an image
mmc.snapImage();
img = mmc.getImage();
width = mmc.getImageWidth();
height = mmc.getImageHeight();
pixelType = 'uint16';
img = typecast(img, pixelType);
img = reshape(img, [width, height]);
img = transpose(img);
imtool(img);

% check stage - move 10000 in X and Y
a = mmc.getYPosition('XYStage');
b = mmc.getXPosition('XYStage');

mmc.setRelativeXYPosition('XYStage', -10000,-10000);
mmc.waitForDevice('XYStage');

aa = mmc.getYPosition('XYStage');
bb = mmc.getXPosition('XYStage');

% check Z stage - take an image
mmc.setRelativePosition(mmc.getFocusDevice(), 1000);


disp(['|==========      Stage moved ' num2str(aa-a) ' Y pixels and ' num2str(bb-b) ' X pixels!!!    =======|']);
disp('|=======  done!   =========|');
mmc.unloadAllDevices();
disp('|===============================================|');