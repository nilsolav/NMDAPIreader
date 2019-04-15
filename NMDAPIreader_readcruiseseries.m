function D=NMDAPIreader_readcruiseseries
%
% this function returns the cruise time series and cruises from NMD API
%
% Output
%
% Cruise time series
% D(i).name : Name of cruise series
% D(i).url  : API URL to the cruise series
%
% Sample time
% D(1).sampletime(1).sampletime  : The time stamp (usually year)
%
% Cruises
% D(i).sampletime(j).Cruise(k).cruisenr      : Cruise number
% D(i).sampletime(j).Cruise(k).shipName      : Platform name
%
% datapath
% D(1).sampletime(1).Cruise(1).cruise.datapath.path    : Path to data
% D(1).sampletime(1).Cruise(1).cruise.datapath.Comment : Result from
% parsing calisto, with these error messages:
% "CruiseMissingInAPIorFolder" : Can't get the cruise data from the API
% "surveyNotfoundInFolder" : Survey not found in the data structure
% "NoWorkDir"   : Work directory is missing (folder structure not used)
% "NoWorkDir"   : Raw direcotry is missing (folder structure not used)
% "NoSnapFiles" : No snap files in standard location
% "NoRawFiles" : No raw files in standard location
%
% D(1).sampletime(1).Cruise(1).cruise.datapath.rawfiles : Number of raw files in standard location
% D(1).sampletime(1).Cruise(1).cruise.datapath.snapfiles  : Number of snap files in standard location


%% Loop over cruise series
options = weboptions('ContentType','xmldom');
rssURL = 'http://tomcat7.imr.no:8080/apis/nmdapi/reference/v2/dataset/cruiseseries?version=2.0';
dom = webread(rssURL, options);
s = dom2struct(dom);


if isunix
    dd='/data/cruise_data/';
else
    dd='\\ces.imr.no\cruise_data\';
end

%% Extract survey time series

cs=length(s.list.row);
for i = 1:cs
    D(i).name = s.list.row{i}.name.Text;
    for j=1:length(s.list.row{i}.samples.sample)
        D(i).sampletime(j).sampletime = s.list.row{i}.samples.sample{j}.sampleTime.Text;
        for k= 1:length(s.list.row{i}.samples.sample{j}.cruises.cruise)
            if length(s.list.row{i}.samples.sample{j}.cruises.cruise)==1
                try
                    D(i).sampletime(j).Cruise(k).cruisenr = s.list.row{i}.samples.sample{j}.cruises.cruise.cruisenr.Text;
                catch
                    warning(['missing cruisenr in year ',s.list.row{i}.samples.sample{j}.sampleTime.Text,' for cruise ',num2str(k),' in cruise series ',s.list.row{i}.name.Text])
                end
                try
                    D(i).sampletime(j).Cruise(k).shipName = s.list.row{i}.samples.sample{j}.cruises.cruise.shipName.Text;
                catch
                    warning(['missing ship name in year ',s.list.row{i}.samples.sample{j}.sampleTime.Text,' for cruise ',num2str(k),' in cruise series ',s.list.row{i}.name.Text])
                end
            else
                try
                    D(i).sampletime(j).Cruise(k).cruisenr = s.list.row{i}.samples.sample{j}.cruises.cruise{k}.cruisenr.Text;
                catch
                    warning(['missing cruisenr in year ',s.list.row{i}.samples.sample{j}.sampleTime.Text,' for cruise ',num2str(k),' in cruise series ',s.list.row{i}.name.Text])
                end
                try
                    D(i).sampletime(j).Cruise(k).shipName = s.list.row{i}.samples.sample{j}.cruises.cruise{k}.shipName.Text;
                catch
                    warning(['missing ship name in year ',s.list.row{i}.samples.sample{j}.sampleTime.Text,' for cruise ',num2str(k),' in cruise series ',s.list.row{i}.name.Text])
                end
            end
            
            % Find the platform code to build data url for the cruise
            p = fullfile(dd,D(i).sampletime(j).sampletime,['S',D(i).sampletime(j).Cruise(k).cruisenr,'*']);
            dds = ls(p);
            if size(dds,1)~=1
                D(i).sampletime(j).Cruise(k).datapath.path = 'NaN';
            else
                D(i).sampletime(j).Cruise(k).datapath.path = fullfile(dd,D(i).sampletime(j).sampletime,dds);
            end
        end
    end
end


%% Extract cruises and links to calisto

for i = 1:length(D)
    % for each cruise series
    disp([D(i).name])
    for j=1:length(D(i).sampletime)
        %        disp(['  ',D(i).sampletime(j).sampletime])
        for k=1:length(D(i).sampletime(j).Cruise)
            %            disp(['    ',D(i).sampletime(j).Cruise(k).cruisenr,D(i).sampletime(j).Cruise(k).shipName])
            if strcmp(D(i).sampletime(j).Cruise(k).datapath.path,'NaN')
                % If the cruise url is missing (should not happen...)
                D(i).sampletime(j).Cruise(k).cruise.datapath.Comment = 'CruiseMissingInAPIorFolder';
            else
                
                % Search for EK60 files
                no_raw=-1;
                dir2=fullfile(D(i).sampletime(j).Cruise(k).datapath.path,'ACOUSTIC_DATA/EK60/EK60_RAWDATA');
                if exist(dir2)
                    no_raw=length(dir(fullfile(dir2,'*.raw')));
                    if no_raw==0
                        tmp='NoRawFiles';
                    else
                        tmp='';
                    end
                else
                    tmp='NoRawDir';
                end
                
                % Search for snap files
                no_snap = -1;
                dir3 = fullfile(D(i).sampletime(j).Cruise(k).datapath.path,'ACOUSTIC_DATA/LSSS/WORK');
                if exist(dir3)
                    no_snap=length(dir(fullfile(dir3,'*.snap')));
                    if no_snap==0
                        tmp2='NoSnapFiles';
                    else
                        tmp2='';
                    end
                else
                    tmp2='NoWorkDir';
                end
                
                % Search for lsss files
                no_lsss = -1;
                dir4 = fullfile(D(i).sampletime(j).Cruise(k).datapath.path,'ACOUSTIC_DATA\LSSS\LSSS_FILES');
                if exist(dir4)
                    no_lsss=length(dir(fullfile(dir4,'*.lsss')));
                    if no_lsss==0
                        tmp3='NoLSSSFile';
                    else
                        tmp3='';
                    end
                else
                    tmp3='NoLSSSDir';
                end
                % Add to output structure
                D(i).sampletime(j).Cruise(k).cruise.datapath.Comment = [tmp,' ',tmp2,' ',tmp3];
                D(i).sampletime(j).Cruise(k).cruise.datapath.rawfiles = no_raw;
                D(i).sampletime(j).Cruise(k).cruise.datapath.snapfiles = no_snap;
                D(i).sampletime(j).Cruise(k).cruise.datapath.lsssfile = no_lsss;
            end % End if exist
        end % End cruise k
    end % End year j
end % End series i
end % End function



function [ s ] = dom2struct(dom)
%Convert DOM into a MATLAB structure
% [ s ] = xml2struct(dom)
%
% A file containing:
% <XMLname attrib1="Some value">
%   <Element>Some text</Element>
%   <DifferentElement attrib2="2">Some more text</Element>
%   <DifferentElement attrib3="2" attrib4="1">Even more text</DifferentElement>
% </XMLname>
%
% Will produce:
% s.XMLname.Attributes.attrib1 = "Some value";
% s.XMLname.Element.Text = "Some text";
% s.XMLname.DifferentElement{1}.Attributes.attrib2 = "2";
% s.XMLname.DifferentElement{1}.Text = "Some more text";
% s.XMLname.DifferentElement{2}.Attributes.attrib3 = "2";
% s.XMLname.DifferentElement{2}.Attributes.attrib4 = "1";
% s.XMLname.DifferentElement{2}.Text = "Even more text";
%
% Please note that the following characters are substituted
% '-' by '_dash_', ':' by '_colon_' and '.' by '_dot_'
%
% Written by W. Falkena, ASTI, TUDelft, 21-08-2010
% Attribute parsing speed increased by 40% by A. Wanner, 14-6-2011
% Added CDATA support by I. Smirnov, 20-3-2012
%
% Modified by X. Mo, University of Wisconsin, 12-5-2012
% Modified by NO Handegard, IMR, 17-3-2017


%parse xDoc into a MATLAB structure
s = parseChildNodes(dom);

end

% ----- Subfunction parseChildNodes -----
function [children,ptext,textflag] = parseChildNodes(theNode)
% Recurse over node children.
children = struct;
ptext = struct; textflag = 'Text';
if hasChildNodes(theNode)
    childNodes = getChildNodes(theNode);
    numChildNodes = getLength(childNodes);
    
    for count = 1:numChildNodes
        theChild = item(childNodes,count-1);
        [text,name,attr,childs,textflag] = getNodeData(theChild);
        
        if (~strcmp(name,'#text') && ~strcmp(name,'#comment') && ~strcmp(name,'#cdata_dash_section'))
            %XML allows the same elements to be defined multiple times,
            %put each in a different cell
            if (isfield(children,name))
                if (~iscell(children.(name)))
                    %put existsing element into cell format
                    children.(name) = {children.(name)};
                end
                index = length(children.(name))+1;
                %add new element
                children.(name){index} = childs;
                if(~isempty(fieldnames(text)))
                    children.(name){index} = text;
                end
                if(~isempty(attr))
                    children.(name){index}.('Attributes') = attr;
                end
            else
                %add previously unknown (new) element to the structure
                children.(name) = childs;
                if(~isempty(text) && ~isempty(fieldnames(text)))
                    children.(name) = text;
                end
                if(~isempty(attr))
                    children.(name).('Attributes') = attr;
                end
            end
        else
            ptextflag = 'Text';
            if (strcmp(name, '#cdata_dash_section'))
                ptextflag = 'CDATA';
            elseif (strcmp(name, '#comment'))
                ptextflag = 'Comment';
            end
            
            %this is the text in an element (i.e., the parentNode)
            if (~isempty(regexprep(text.(textflag),'[\s]*','')))
                if (~isfield(ptext,ptextflag) || isempty(ptext.(ptextflag)))
                    ptext.(ptextflag) = text.(textflag);
                else
                    %what to do when element data is as follows:
                    %<element>Text <!--Comment--> More text</element>
                    
                    %put the text in different cells:
                    % if (~iscell(ptext)) ptext = {ptext}; end
                    % ptext{length(ptext)+1} = text;
                    
                    %just append the text
                    ptext.(ptextflag) = [ptext.(ptextflag) text.(textflag)];
                end
            end
        end
        
    end
end
end

% ----- Subfunction getNodeData -----
function [text,name,attr,childs,textflag] = getNodeData(theNode)
% Create structure of node info.

%make sure name is allowed as structure name
name = toCharArray(getNodeName(theNode))';
name = strrep(name, '-', '_dash_');
name = strrep(name, ':', '_colon_');
name = strrep(name, '.', '_dot_');

attr = parseAttributes(theNode);
if (isempty(fieldnames(attr)))
    attr = [];
end

%parse child nodes
[childs,text,textflag] = parseChildNodes(theNode);

if (isempty(fieldnames(childs)) && isempty(fieldnames(text)))
    %get the data of any childless nodes
    % faster than if any(strcmp(methods(theNode), 'getData'))
    % no need to try-catch (?)
    % faster than text = char(getData(theNode));
    text.(textflag) = toCharArray(getTextContent(theNode))';
end

end

% ----- Subfunction parseAttributes -----
function attributes = parseAttributes(theNode)
% Create attributes structure.

attributes = struct;
if hasAttributes(theNode)
    theAttributes = getAttributes(theNode);
    numAttributes = getLength(theAttributes);
    
    for count = 1:numAttributes
        %attrib = item(theAttributes,count-1);
        %attr_name = regexprep(char(getName(attrib)),'[-:.]','_');
        %attributes.(attr_name) = char(getValue(attrib));
        
        %Suggestion of Adrian Wanner
        str = toCharArray(toString(item(theAttributes,count-1)))';
        k = strfind(str,'=');
        attr_name = str(1:(k(1)-1));
        attr_name = strrep(attr_name, '-', '_dash_');
        attr_name = strrep(attr_name, ':', '_colon_');
        attr_name = strrep(attr_name, '.', '_dot_');
        attributes.(attr_name) = str((k(1)+2):(end-1));
    end
end
end