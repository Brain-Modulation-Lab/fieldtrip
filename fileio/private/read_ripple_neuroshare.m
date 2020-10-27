function [nsout] = read_ripple_neuroshare(filename, varargin)

% READ_RIPPLE_NEUROSHARE reads header information or data from any file format
% supported by Neuroshare. The file can contain event timestamps, spike
% timestamps and waveforms, and continuous (analog) variable data.
% Optimized for files produced by Ripple systems. 
%
% Use as:
%   hdr = read_neuroshare(filename, ...)
%   dat = read_neuroshare(filename, ...)
%
% Optional input arguments should be specified in key-value pairs and may include:
%   'dataformat'    = string
%   'readevent'     = 'yes' or 'no' (default)
%   'readspike'     = 'yes' or 'no' (default)
%   'readanalog'    = 'yes' or 'no' (default)
%   'chanindx'      = list with channel indices to read
%   'begsample      = first sample to read
%   'endsample      = last sample to read
%
% NEUROSHARE: http://www.neuroshare.org is a site created to support the
% collaborative development of open library and data file format
% specifications for neurophysiology and distribute open-source data
% handling software tools for neuroscientists. The particular
% implementation for used in this function was provided by Ripple Neuro 
% https://rippleneuro.com
%
% Note that this is a test version, WINDOWS only

% Developed by Alan Bush based on code by Saskia Haegens
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

% check the availability of the required neuroshare toolbox
ft_hastoolbox('ripple_neuroshare', 1);

% get the optional input arguments
dataformat    = ft_getopt(varargin, 'dataformat');
begsample     = ft_getopt(varargin, 'begsample');
endsample     = ft_getopt(varargin, 'endsample');
chanindx      = ft_getopt(varargin, 'chanindx');
readevent     = ft_getopt(varargin, 'readevent', 'no');
readspike     = ft_getopt(varargin, 'readspike', 'no');
readanalog    = ft_getopt(varargin, 'readanalog', 'no');

% NEUROSHARE LIBRARY %

% open dataset
[feedback fileID] = ns_OpenFile(filename,'single');
if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end

% HEADER %
% retrieve dataset information
[feedback hdr.fileinfo] = ns_GetFileInfo(fileID);
if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end

% retrieve entity information
for i=1:hdr.fileinfo.EntityCount
    [feedback hdr.entityinfo(i)] = ns_GetEntityInfo(fileID, i);
    if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
end

% hdr.entityinfo.EntityType specifies the type of entity data recorded on that
% channel. It can be one of the following:
%   0: Unknown entity
%   1: Event entity
%   2: Analog entity
%   3: Segment entity
%   4: Neural event entity
enttyp = {'unknown'; 'event'; 'analog'; 'segment'; 'neural'};
for i=1:5
  list.(enttyp{i}) = find([hdr.entityinfo.EntityType] == i-1); % gives channel numbers for each entity type
end

% give warning if unkown entities are found
if ~isempty(list.unknown)
  ft_warning(['There are ' num2str(length(list.unknown)) ' unknown entities found, these will be ignored.']);
end

% retrieve event information
for i=1:length(list.event)
  [feedback hdr.eventinfo(i)] = ns_GetEventInfo(fileID, list.event(i));
  if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
end

% retrieve analog information
for i=1:length(list.analog)
  [feedback hdr.analoginfo(i)] = ns_GetAnalogInfo(fileID, list.analog(i));
  if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
end

% retrieve segment information
for i=1:length(list.segment)
  [feedback hdr.seginfo(i)] = ns_GetSegmentInfo(fileID, list.segment(i));
  if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
  [feedback hdr.segsourceinfo(i)] = ns_GetSegmentSourceInfo(fileID, list.segment(i), 1);
  if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
end

% retrieve neural information
for i=1:length(list.neural)
  [feedback hdr.neuralinfo(i)] = ns_GetNeuralInfo(fileID, list.neural(i));
  if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
end

% AB20201027 not sure why this is required
% % required to get actual analog chan numbers
% for i=1:length(list.analog)
%   [feedback analog.contcount(i)] = ns_GetAnalogData(fileID, list.analog(i), 1, hdr.entityinfo(list.analog(i)).ItemCount);
% end


% EVENT %
% retrieve events
if strcmp(readevent, 'yes') && ~isempty(list.event)
  ft_error('use NPMK to extract neural events from Ripples .nev files')
%   
%   for i=1:length(list.event)
%       [feedback event.timestamp event.data event.datasize] = ns_GetEventData(fileID, list.event(i), 1:max([hdr.entityinfo(list.event).ItemCount]));
%       if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
%   end
%   
%   % skip empty ones ???
%   event.timestamp(event.datasize==0)=[];
%   event.data(event.datasize==0)=[];
%   event.datasize(event.datasize==0)=[];
% 
%   for c=1:length(list.event)
%     if hdr.entityinfo(list.event(c)).ItemCount~=0
%       for i=1:length(event.timestamp)
%         [feedback, event.sample(i,c)] = ns_GetIndexByTime(fileID, list.event(c), event.timestamp(i,c), 0);
%         if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
%       end
%     end
%   end
elseif strcmp(readevent, 'yes') && isempty(list.event)
  ft_warning('no events were found in the data')
end



% DATA %
% retrieve analog data
if strcmp(readanalog, 'yes') && ~isempty(list.analog)
  % set defaults
  hasdata = [hdr.entityinfo(list.analog).ItemCount]~=0;
  if isempty(chanindx)
    %chanindx = list.analog(analog.contcount~=0);
    chanindx = list.analog(hasdata);
  else % rebuild chanindx such that doesnt contain empty channels
    if length(chanindx)==length(list.analog(hasdata)) && chanindx(1)==1
      chanindx = list.analog(hasdata); % only read nonempty channels
    end
    if length(chanindx)>length(list.analog(hasdata))
      chanindx = list.analog(chanindx & hasdata); % only read nonempty channels
    end
  end
  if isempty(begsample)
    begsample = 1;
  end
  if isempty(endsample)
    itemcount = max([hdr.entityinfo(list.analog).ItemCount]);
  else
    itemcount = endsample - begsample + 1;
  end
  analog.data = nan(itemcount,length(chanindx));
  for i=1:length(chanindx)
    [feedback analog.contcount(i) analog.data(:,i)] = ns_GetAnalogData(fileID, chanindx(i), begsample, itemcount);
    if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
  end
elseif strcmp(readanalog, 'yes') && isempty(list.analog)
  ft_warning('no analog events were found in the data')
end

% SPIKE %
% retrieve segments       [ (sorted) spike waveforms ]
if strcmp(readspike, 'yes') && ~isempty(list.segment)
  ft_error('spikes from ripple files not supported yet')
%   % collect data: all chans (=list.segment) and all waveforms (=hdr.entityinfo.ItemCount)
%   for i=1:length(list.segment)
%       [feedback segment.timestamp(i) segment.data(i) segment.samplecount(i) segment.unitID(i)] = ns_GetSegmentData(fileID, list.segment(i), 1:max([hdr.entityinfo(list.segment).ItemCount]));
%       if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
%   end
elseif strcmp(readspike, 'yes') && isempty(list.segment)
  ft_warning('no spike waveforms were found in the data')
end

% retrieve neural events  [ spike timestamps ]
if strcmp(readspike, 'yes') && ~isempty(list.neural)
  ft_error('neural events from ripple files not supported yet')
%   keyboard % AB 20201027 not debuged for Ripple's version of neuroshare
%   neural.data = nan(length(list.neural), max([hdr.entityinfo(list.neural).ItemCount])); % pre-allocate
%   for chan=1:length(list.neural) % get timestamps
%     [feedback neural.data(chan,1:hdr.entityinfo(list.neural(chan)).ItemCount)] = ns_GetNeuralData(fileID, list.neural(chan), 1, hdr.entityinfo(list.neural(chan)).ItemCount);
%     if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end
%   end
elseif strcmp(readspike, 'yes') && isempty(list.neural)
  ft_warning('no spike timestamps were found in the data')
end

% close dataset
[feedback] = ns_CloseFile(fileID);
if ~strcmp(feedback,'ns_OK'), [feedback err] = ns_GetLastErrorMsg; disp(err), end

% collect the output
nsout = [];
nsout.hdr  = hdr;
nsout.list = list;
try nsout.event  = event;    end
try nsout.analog = analog;   end
try nsout.spikew = segment;  end
try nsout.spiket = neural;   end




