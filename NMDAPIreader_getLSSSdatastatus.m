function datastatus=NMDAPIreader_getLSSSdatastatus(directory,par)
%
% counts LSSS and raw files in Calisto
%
% Input:
% directory : the path to the cruise folder
% par.dir_raw  : Relative path to raw data 'ACOUSTIC_DATA\EK60\EK60_RAWDATA';
% par.dir_snap : Relative path to work files 'ACOUSTIC_DATA\LSSS\WORK';
% par.dir_work : Relative path to work files 'ACOUSTIC_DATA\LSSS\WORK';
%
% Output
% filecount.rawfilecount : Number of raw files
% filecount.snapfilecount : 

% Combine the different files
pairedfiles=LSSSreader_pairfiles(par);

filecount = zeros([1 4]);
% Does the standard directory structure exist and are there any files?
e1 = exist(fullfile(directory,par.dir_raw));
if e1==7
    % Standard directory does exist
    d1 = rdir(fullfile(directory,par.dir_raw,'\*.raw'));
    filecount(1) = length(d1);
end

e2 = exist(fullfile(directory,par.dir_snap));
if e2==7
    % Standard directory does exist
    d2 = rdir(fullfile(directory,par.dir_snap,'\*.snap'));
    filecount(2) = length(d2);
end

e3 = exist(fullfile(directory,par.dir_work));
if e3==7
    % Standard directory does exist
    d3 = rdir(fullfile(directory,par.dir_work,'\*.work'));
    filecount(3) = length(d3);
end

% Are there any snap, work or raw files in the directory that is not in the standard structure? If yes, where and how many?
d4 = rdir(fullfile(directory,'\**\*.raw'));
filecount(4) = length(d4) - filecount(1);

d5 = rdir(fullfile(directory,'\**\*.snap'));
filecount(5) = length(d5) - filecount(2);

d6 = rdir(fullfile(directory,'\**\*.work'));
filecount(6) = length(d6) - filecount(3);


datastatus.filecount=filecount;
datastatus.pairedfiles = pairedfiles;



