function [] = tif2mpeg(inputFile, frameRate, brightFactor)
%
% TIF2MPEG Function that transform .gif file with multiple frames into
% MPEG-4 movie with number of the frame printed in the corner.
% The movie can be RGB or Grayscale
%
% Params:
%       inputFile - name of the .tif file.
%       frameRate - frames / sec.
%
% Usage Example:
%       >> tif2mpeg('9.from1to200.realDV.tif', 33)      // GrayScale
%       >> tif2mpeg('animation.6.realDV.tif', 33)      // RGB
%
%                               **  written by alexkaz  9.2014 (and Eyal?)     **

    
    if(nargin == 0)
        [inputFile,path] = uigetfile('*.tif','Select a Movie', 'MultiSelect', 'on');
        cd(path);
        frameRate  = inputdlg('Insert framerate','Framerate',1,{'11'});
        frameRate = str2double(frameRate{1});
    end
    if iscell(inputFile)
        num = length(inputFile);
        brightFactorVec = zeros(1,num);
        for i = 1:num
            [brght, start_frame, endFrame] = playTif(inputFile{i});
            brightFactorVec(i) = brght;
        end

        for i = 1:num
            tif2mpeg(inputFile{i}, frameRate, brightFactorVec(i))
        end
        return;
    end
    info = imfinfo(inputFile);
    endFrame = length(info);
% % %     brightFactor = playTif(inputFile);
    if(strcmp(info(1).PhotometricInterpretation,'BlackIsZero'))
        resize_factor = 1;
        if (nargin ~= 3)    % case when one movie is proccessed by hand
            [brightFactor, start_frame, endFrame] = playTif(inputFile);
        else    % case when one movie is proccessed automatically
            start_frame = 1;
        end
        
    else
        resize_factor = 1;
        brightFactor = 1;
        start_frame = 1;
    end
    num_images = min(numel(info),endFrame);   %   get number of frames
    frame_height = round((info(1).Width)/50);   %   calculate size of font
    
    name = inputFile(1:end-4);
    if(start_frame ~= 1 || endFrame ~= 1000)
        name = [name '.' num2str(start_frame) '-' num2str(endFrame)];
    end
    outputWriter = VideoWriter(name, 'MPEG-4'); % Motion JPEG AVI
    outputWriter.FrameRate = frameRate;
    outputWriter.Quality = 100;
    open(outputWriter);
    
    for k = start_frame:num_images
        frame = imread(inputFile, k,'Info', info);
        
        %   print frame number on the frame
        htxtins = vision.TextInserter(['Frame: ' num2str(k)]);
        htxtins.Color = [255, 255, 255]; % [red, green, blue]
        htxtins.FontSize = frame_height;
        htxtins.Location = [10 10]; % [x y]
% % %         frame2 = im2double(frame);
        frame2 = im2double(imresize(frame*brightFactor, resize_factor));
        %frame2 = (1-(frame2 > 1).*frame2).*(frame2 > 1)+frame2;   % Cut-off high values! max value should be 255, otherwise bring to FORMAT_ERROR
    	J = step(htxtins, frame2);
%         J = step(htxtins, imresize(frame2, 0.5));
        
        % write the changed frame to the movie
        writeVideo(outputWriter, J);
        if(mod(k,25) == 0)
            disp(['|======  .mp4 at frame No.:  ' num2str(k-start_frame+1) '  /  ' num2str(num_images-start_frame+1) '    ' num2str((k-start_frame+1)/(num_images-start_frame+1)*100,2) '%' '   ==========|']);
        end
    end
    close(outputWriter);
end