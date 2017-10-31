%% MATLAB's javaclasspath for Micro-Manager java classes 1
% Run this script before first using MATLAB and Micro-Manager together.
% This script will locate all of the |*.jar| files within the Micro-Manager
% directory tree and save their locations to a text file. The text file is
% saved to the MATLAB |prefdir| directory. The contents of this file can be
% appended to a text file named |javaclasspath.txt|. From then on, every
% time MATLAB starts the files located in this text file will be added to
% the MATLAB's static JAVA path.
%
% Verify the MATLAB java path using the command |javaclasspath|.
%
% Verify Micro-Manager is responding using the commands |import mmcorej.*;
% mmc=CMMCore|.
%% Inputs
% * |path2MM|, the root directory of the Micro-Manager software
%% Outputs
% NONE


function [] = MMsetup_javaclasspath(path2MM)
%%
fileList = getAllFiles(path2MM);
fileListJarBool = regexp(fileList,'.jar$','end');
fileListJarBool = cellfun(@isempty,fileListJarBool);
fileListJar = fileList(~fileListJarBool);
fid = fopen(fullfile(cd(),'MMjavaclasspath.txt'),'w');
cellfun(@(x) fprintf(fid,'%s\r\n',x), fileListJar);
fclose(fid);

%% nested directory listing ala gnovice from stackoverflow
% inputs and outputs are self-explanatory
function fileList = getAllFiles(dirName)
dirData = dir(dirName);      %# Get the data for the current directory
dirIndex = [dirData.isdir];  %# Find the index for directories
fileList = {dirData(~dirIndex).name}';  %'# Get a list of the files
if ~isempty(fileList)
    fileList = cellfun(@(x) fullfile(dirName,x),fileList,'UniformOutput',false);
end
subDirs = {dirData(dirIndex).name};  %# Get a list of the subdirectories
validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories

%#   that are not '.' or '..'
for iDir = find(validIndex)                  %# Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
    fileList = vertcat(fileList, getAllFiles(nextDir));  %# Recursively call getAllFiles
end