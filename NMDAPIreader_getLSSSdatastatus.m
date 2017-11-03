function [filecount,files]=NMDAPIreader_getLSSSdatastatus(directory,par)
%
% counts LSSS and raw files in the cruise directory
%
% Input:
% directory    : the path to the cruise folder
% par.raw_dir  : Relative path to raw data 'ACOUSTIC_DATA\EK60\EK60_RAWDATA';
% par.snap_dir : Relative path to snap files 'ACOUSTIC_DATA\LSSS\WORK';
% par.work_dir : Relative path to work files 'ACOUSTIC_DATA\LSSS\WORK';
%
% Output
% filecount(1) : Number of raw files in par.raw_dir location 
% filecount(2) : Number of snap files in par.snap_dir location
% filecount(3) : Number of work files in par.work_dir location
% filecount(4) : Number of raw files in non standard location
% filecount(5) : Number of snap files in non standard location
% filecount(6) : Number of work files in non standard location
%
% files(1) : List of raw files 
% files(2) : List of snap files 
% files(3) : List of work files 
%

if nargin==1
    par.raw_dir=[];
    par.snap_dir=[];
    par.work_dir =[];
end


filecount = zeros([1 4]);
% Does the standard directory structure exist and are there any files?
e1 = exist(fullfile(directory,par.raw_dir));
if e1==7
    % Standard directory does exist
    d1 = rdir(fullfile(directory,par.raw_dir,'/*.raw'));
    filecount(1) = length(d1);
end

e2 = exist(fullfile(directory,par.snap_dir));
if e2==7
    % Standard directory does exist
    d2 = rdir(fullfile(directory,par.snap_dir,'/*.snap'));
    filecount(2) = length(d2);
end

e3 = exist(fullfile(directory,par.work_dir));
if e3==7
    % Standard directory does exist
    d3 = rdir(fullfile(directory,par.work_dir,'/*.work'));
    filecount(3) = length(d3);
end

% Are there any snap, work or raw files in the directory that is not in the standard structure? If yes, where and how many?
d4 = rdir(fullfile(directory,'/**/*.raw'));
filecount(4) = length(d4) - filecount(1);

d5 = rdir(fullfile(directory,'/**/*.snap'));
filecount(5) = length(d5) - filecount(2);

d6 = rdir(fullfile(directory,'/**/*.work'));
filecount(6) = length(d6) - filecount(3);

files.raw  =  d4;
files.snap = d5;
files.work = d6;
