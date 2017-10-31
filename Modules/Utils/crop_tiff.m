function crop_tiff()
    %
    % CROP_TIFF Function that recieves a movie and bounds, and outputs a cropped movie.
    % The created movie include all internal headers, for each of the
    % frames.
    % Usage Example:
    %       >> crop_tiff()
    %
    %
    %                               **   written by Alexkaz 8.2016   **
    
    
    [inputFile, pwd] = uigetfile('*.tif','Select a Movie');
    old_path = cd();
    cd(pwd);
    o = imfinfo(inputFile);
    num_frames = length(o);

    answer = inputdlg({'Start frame:', 'End frame:'},...
                       'Bordering frames selection', 1,...
                       {'1', num2str(num_frames)});

    start = str2num(answer{1});
    stop = str2num(answer{2});
    t = Tiff([inputFile(1:end-4) '_' num2str(start) '-' num2str(stop) '.tif'],'w');

    t.setTag('XResolution', o(1).XResolution);
    t.setTag('YResolution', o(1).YResolution);
    t.setTag('Software', o(1).Software);
    t.setTag('Artist', o(1).Artist);

    for i = start : stop
        if(i ~= start)
             writeDirectory(t);  % create new DIR inside the multi-tiff file
        end
        t.setTag('ImageLength', 512.00);
        t.setTag('ImageWidth', 512.00);
        t.setTag('Photometric', Tiff.Photometric.MinIsBlack);
        t.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky)
        t.setTag('BitsPerSample', 16);
        tagStruct.DateTime = o(i).DateTime;  
        tagStruct.XPosition = o(i).XPosition;             
        tagStruct.YPosition = o(i).YPosition;             
        tagStruct.HostComputer = o(i).HostComputer;
        setTag(t, tagStruct)

        t.write(imread(inputFile, i, 'Info', o));
        if(~mod(i, round((stop-start)/10)))
            disp(['=========    Finished ' num2str(round(((i-start)/(stop-start)*100))) '%    ========='])
        end
    end

    t.close();
    cd(old_path);
    disp('========    Cropping finished    ========');
end