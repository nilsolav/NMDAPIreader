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
% D(i).sampletime(j).Cruise(k).cruisenr : Cruise number
% D(i).sampletime(j).Cruise(k).shipName : Paltform name
% D(i).sampletime(j).Cruise(k).url      : API url to survey
%
% D(i).sampletime(j).Cruise(k).cruise   : Metainformation for survey
%
% datapath
% D(1).sampletime(1).Cruise(1).cruise.datapath.Text    : Path to data
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
rssURL = 'http://tomcat7.imr.no:8080/apis/nmdapi/cruiseseries/v1';
dom = webread(rssURL, options);
s = dom2struct(dom);
dd='\\ces.imr.no\cruise_data\';

%% Extract survey time series
cs=length(s.list.element);
for i = 1:cs
    D(i).name = s.list.element{i}.result.Text;
    rssURLs = ['http://tomcat7.imr.no:8080/apis/nmdapi/cruiseseries/v1/',D(i).name];
    D(i).url = rssURLs;
end

%% Extract surveys per survey time series
for i = 1:cs
    options = weboptions('ContentType','xmldom');
    doms = webread(D(i).url, options);
    s   = dom2struct(doms);
    for j=1:length(s.CruiseSerie.Samples.Sample)
        D(i).sampletime(j).sampletime = s.CruiseSerie.Samples.Sample{j}.Attributes.sampleTime;
        for k= 1:length(s.CruiseSerie.Samples.Sample{j}.Cruises.Cruise)
            if length(s.CruiseSerie.Samples.Sample{j}.Cruises.Cruise)==1
                try
                    D(i).sampletime(j).Cruise(k).cruisenr = s.CruiseSerie.Samples.Sample{j}.Cruises.Cruise.Attributes.cruisenr;
                catch
                    warning(['missing cruisenr in year ',s.CruiseSerie.Samples.Sample{j}.Attributes.sampleTime,' for cruise ',num2str(k),' in cruise series ',s.CruiseSerie.Attributes.cruiseseriename])
                end
                try
                    D(i).sampletime(j).Cruise(k).shipName = s.CruiseSerie.Samples.Sample{j}.Cruises.Cruise.Attributes.shipName;
                catch
                    warning(['missing ship name in year ',s.CruiseSerie.Samples.Sample{j}.Attributes.sampleTime,' for cruise ',num2str(k),' in cruise series ',s.CruiseSerie.Attributes.cruiseseriename])
                end
            else
                try
                    D(i).sampletime(j).Cruise(k).cruisenr = s.CruiseSerie.Samples.Sample{j}.Cruises.Cruise{k}.Attributes.cruisenr;
                catch
                    warning(['missing cruisenr in year ',s.CruiseSerie.Samples.Sample{j}.Attributes.sampleTime,' for cruise ',num2str(k),' in cruise series ',s.CruiseSerie.Attributes.cruiseseriename])
                end
                try
                    D(i).sampletime(j).Cruise(k).shipName = s.CruiseSerie.Samples.Sample{j}.Cruises.Cruise{k}.Attributes.shipName;
                catch
                    warning(['missing ship name in year ',s.CruiseSerie.Samples.Sample{j}.Attributes.sampleTime,' for cruise ',num2str(k),' in cruise series ',s.CruiseSerie.Attributes.cruiseseriename])
                end
            end
            if isfield(D(i).sampletime(j).Cruise(k),'cruisenr')&&isfield(D(i).sampletime(j).Cruise(k),'shipName')
                findurl = ['http://tomcat7.imr.no:8080/apis/nmdapi/cruise/v1/find?cruisenr=',D(i).sampletime(j).Cruise(k).cruisenr,'&shipname=',D(i).sampletime(j).Cruise(k).shipName];
            elseif isfield(D(i).sampletime(j).Cruise(k),'cruisenr')
                findurl = ['http://tomcat7.imr.no:8080/apis/nmdapi/cruise/v1/find?cruisenr=',D(i).sampletime(j).Cruise(k).cruisenr];
            elseif isfield(D(i).sampletime(j).Cruise(k),'shipName')
                findurl = ['http://tomcat7.imr.no:8080/apis/nmdapi/cruise/v1/find?shipname=',D(i).sampletime(j).Cruise(k).shipName];
            else
                findurl = ['http://tomcat7.imr.no:8080/apis/nmdapi/cruise/v1/find? THIS IS BULLOCKS'];
            end
            try
                dom = webread(findurl, options);
                s2 = dom2struct(dom);
                D(i).sampletime(j).Cruise(k).url = s2.optionList.element.Text;
            catch
                warning([findurl,': Not found'])
                D(i).sampletime(j).Cruise(k).url = 'NaN';
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
            
            if strcmp(D(i).sampletime(j).Cruise(k).url,'NaN')
                % If the cruise url is missing (should not happen...)
                D(i).sampletime(j).Cruise(k).cruise.datapath.Comment = 'CruiseMissingInAPIorFolder';
            else
                % Read the cruise from the API
                options = weboptions('ContentType','xmldom');
                cruisedom = webread(D(i).sampletime(j).Cruise(k).url, options);
                cruise   = dom2struct(cruisedom);
                D(i).sampletime(j).Cruise(k).cruise = cruise.cruise;
                
                % Build the directory path from the cruise structure
                
                % Path to the right year
                ds = fullfile(dd,D(i).sampletime(j).sampletime);
                % Tthe name of the survey
                crn=['S',D(i).sampletime(j).Cruise(k).cruisenr];
                
                % This is a hack to get the directories since I don't have
                % the platform name. I need to traverse the directories to
                % seach for the filename. If not found, I use the survey
                % number only and give an error message.
                hack=false;
                if exist(ds)
                    cr=dir(ds);
                    for n=1:length(cr)
                        if length(cr(n).name)>length(crn) && strcmp(cr(n).name(1:length(crn)),crn)
                            D(i).sampletime(j).Cruise(k).cruise.datapath.Text = fullfile(cr(n).folder,cr(n).name);
                            hack=true;
                        end
                    end
                end
                
                if ~hack
                    D(i).sampletime(j).Cruise(k).cruise.datapath.Text = fullfile(ds,crn);
                    D(i).sampletime(j).Cruise(k).cruise.datapath.Comment = 'surveyNotfoundInFolder';
                else
                    
                    %
                    % Search for raw data
                    %
                    
                    % Search for EK60 files
                    no_raw=-1;
                    dir2=fullfile(D(i).sampletime(j).Cruise(k).cruise.datapath.Text,'ACOUSTIC_DATA\EK60\EK60_RAWDATA');
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
                    dir3 = fullfile(D(i).sampletime(j).Cruise(k).cruise.datapath.Text,'ACOUSTIC_DATA\LSSS\WORK');
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
                    
                    % Add to output structure
                    D(i).sampletime(j).Cruise(k).cruise.datapath.Comment = [tmp,' ',tmp2];
                    D(i).sampletime(j).Cruise(k).cruise.datapath.rawfiles = no_raw;
                    D(i).sampletime(j).Cruise(k).cruise.datapath.snapfiles = no_snap;
                end
            end % End if exist
        end % End cruise
    end % End year
end % End series
end


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