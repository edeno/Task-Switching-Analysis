function [data, time, eye_pos, opts] = ExtractTimePeriod_Cortex(cells, trials, varargin)

% data = ExtractTimePeriod_Cortex(cells, trials, /options/)
%
% Extracts a period of time from the spiking data passed in for each trial.
%
% Returns a matrix or a cell array of extracted data.  A matrix is used if the time taken is
% consistent, and is size (N x T x D) where N is the number of trials, T is the length of time,
% and D is the number of spike channels.  Missing values are filled in with NaNs.
%
% A cell array is returned if the chunk of time desired is not consistent between trials.  In this
% case it returns an N x 1 cell array with each cell containing a T_N x D array.
%
% Key-Value pairs are used to specify the details of extracting a chunk of time. Default is to
% return the entire dataset.

%% Set options
inParser = inputParser;

inParser.addRequired('cells');
inParser.addRequired('trials');
inParser.addOptional('StartEncode', []);
inParser.addOptional('EndEncode', []);
inParser.addOptional('StartOffset', []);
inParser.addOptional('EndOffset', []);
inParser.addOptional('WindowSize', []);
inParser.addOptional('WindowStep', []);
inParser.addOptional('ValidWindow', []);
inParser.addOptional('SmoothParam', []);
inParser.addOptional('SmoothType', []);
inParser.addOptional('TimeIndex', []);
inParser.addOptional('TimeResample', []);
inParser.addOptional('TrialErrorsAllowed', []);

inParser.parse(cells, trials, varargin{:});

% Add parameters to input structure after validation
opts = inParser.Results;

% If only a start encode is passed then it will be used for both start and end
if ~isempty(opts.StartEncode) && isempty(opts.EndEncode),
    opts.EndEncode = opts.StartEncode;
end

% Log Time Extracted
opts.TimeExtracted = datestr(now);
%% Initialize constants
num_neurons = length(cells);
num_trials = length(trials);

%% Loop through trials, find start/end time for each trial
trial_time = nan(num_trials, 2);
for cur_trial = 1:num_trials,
    %Starting point for this trial
    if isempty(opts.StartEncode),
        start_ind = 1;
    else
        start_enc_ind = find(ismember(trials(cur_trial).Encodes,  [opts.StartEncode{:}]));
        if isempty(start_enc_ind),
            start_ind = NaN;
        else
            start_ind = trials(cur_trial).EncodeTimes(start_enc_ind(1));
        end
    end
    
    %Ending point
    if isempty(opts.EndEncode),
        end_ind = round((trials(cur_trial).EndTime - trials(cur_trial).StartTime)*1000 + 1);
    else
        end_enc_ind = find(ismember(trials(cur_trial).Encodes, [opts.EndEncode{:}]));
        if isempty(end_enc_ind),
            end_ind = NaN;
        else
            end_ind = trials(cur_trial).EncodeTimes(end_enc_ind(end));
        end
    end
    
    trial_time(cur_trial, :) = [start_ind end_ind];
end %trial loop

%Add in any specified offsets
if ~isempty(opts.StartOffset),
    trial_time(:, 1) = trial_time(:, 1) + opts.StartOffset;
    if opts.ValidWindow && ~isempty(opts.WindowSize) && ~isempty(opts.WindowStep),
        trial_time(:, 1) = trial_time(:, 1) - opts.WindowSize + 1; %extend backwards so we have valid data into past
    end
end
if ~isempty(opts.EndOffset),
    trial_time(:, 2) = trial_time(:, 2) + opts.EndOffset;
end
trial_time(:, 3) = trial_time(:, 2) - trial_time(:, 1) + 1;

%% What trials exist for each neuron?
data_exists = false(num_neurons, num_trials);
for neuron_ind = 1:num_neurons,
    data_exists(neuron_ind, cells(neuron_ind).Trials) = 1;
end
neuron_trial_ind = cumsum(data_exists, 2);

%% Do we need to remove any trials because they don't fit the desired errors?
if ~isempty(opts.TrialErrorsAllowed),
    [resp_error{1:num_trials}] = deal(trials.ResponseError);
    error_okay = ismember(cell2mat(resp_error), opts.TrialErrorsAllowed);
    %Pull out bad trials from the variables created so far
    trial_time = trial_time(error_okay, :);
    neuron_trial_ind = neuron_trial_ind(:, error_okay);
    data_exists = data_exists(:, error_okay);
    num_trials = sum(error_okay);
end

data = cell(num_trials, 1);
time = cell(num_trials, 1);
eye_pos = cell(num_trials, 1);

%% Loop through trials, for each trial extract data from neurons
for cur_trial = 1:num_trials,
    
    %Is this a bad trial?
    if any(isnan(trial_time(cur_trial, :))),
        %Skip, leaving it blank or filled with NaNs if consistent timelength
        continue;
    end
    
    %Initialize this trial's data matrix
    trial_data = nan(trial_time(cur_trial, 3), num_neurons);
    
    
    %Init the time vector
    cur_trial_time = [0:trial_time(cur_trial, 3)-1];
    if ~isempty(opts.StartOffset),
        cur_trial_time = cur_trial_time + opts.StartOffset;
    end
    
    
    %Extract data from each neuron
    for neuron_ind = 1:num_neurons,
        %If this neuron wasn't recorded for this trial, skip it, keeping all NaNs
        if ~data_exists(neuron_ind, cur_trial),
            continue;
        end
        
        %Copy data from our structure
        cur_data = cells(neuron_ind).Spikes{neuron_trial_ind(neuron_ind, cur_trial)};
        
        %If data was empty on this trial, that means there were no spikes from this neuron in this
        %trial (even though it was cut for this trial), so set it to all zeros.
        if isempty(cur_data),
            trial_data(:, neuron_ind) = 0;
            continue;
        end
        
        %Need to make sure we stay bounded by the data
        neuron_start_ind = trial_time(cur_trial, 1); neuron_end_ind = trial_time(cur_trial, 2);
        data_start_ind = 1; data_end_ind = trial_time(cur_trial, 3);
        
        %Are we over-reaching our bounds?
        if neuron_start_ind < 1,
            data_start_ind = data_start_ind + (1 - neuron_start_ind);
            neuron_start_ind = 1;
        end
        if neuron_end_ind > length(cur_data),
            data_end_ind = data_end_ind + (length(cur_data) - neuron_end_ind);
            neuron_end_ind = length(cur_data);
        end
        
        %Extract data
        temp_trial_data = nan(trial_time(cur_trial, 3), 1);
        
        try
            temp_trial_data(data_start_ind:data_end_ind) = cur_data(neuron_start_ind:neuron_end_ind);
        catch
            data_start_ind
            data_end_ind
            neuron_start_ind
            neuron_end_ind
            length(cur_data)
            trial_time(cur_trial, :)
            error(lasterr);
        end
        trial_data(:, neuron_ind) = temp_trial_data;
    end %neuron loop
    
    
    %Smooth data
    if ~isempty(opts.SmoothType),
        switch lower(opts.SmoothType),
            case {'moving', 'lowess', 'loess', 'sgolay', 'rlowess', 'rloess'}
                %Use smooth function in matlab
                for i = 1:num_neurons,
                    trial_data(:, i) = smooth(trial_data(:, i), opts.SmoothParam, opts.SmoothType);
                end
                cur_trial_time = smooth(cur_trial_time, opts.SmoothParam, opts.SmoothType);
            case {'boxcar'},
                trial_data = convn(trial_data, ones(opts.SmoothParam, 1)./opts.SmoothParam, 'same');
                %cur_trial_time = convn(cur_trial_time, ones(opts.SmoothParam, 1)./opts.SmoothParam, 'same');
            case {'gaussian', 'normpdf'},
                if length(opts.SmoothParam) >= 3,
                    conv_filt = normpdf([opts.SmoothParam(2):opts.SmoothParam(3)], 0, opts.SmoothParam(1));
                elseif length(opts.SmoothParam) >= 2,
                    conv_filt = normpdf([-opts.SmoothParam(2):opts.SmoothParam(2)], 0, opts.SmoothParam(1));
                else
                    conv_filt = normpdf([(-5*opts.SmoothParam(1)):(5*opts.SmoothParam(1))], 0, opts.SmoothParam(1)); %smooth param(1) = std dev, mean = 0; %height =0.4
                end
                conv_filt = conv_filt(:)./sum(conv_filt(:));
                trial_data = convn(trial_data, conv_filt, 'same');
                %cur_trial_time = convn(cur_trial_time, conv_filt, 'same');
            case {'opt_gaussian'},
                
                [time_points, num_elect] = size(trial_data);
                
                temp = nan(time_points, num_elect);
                parfor i = 1:num_elect,
                    optW = sskernel(trial_data(:,i));
                    conv_filt = ksdensity(trial_data(:,i),'width',optW);
                    temp(:,i) = conv(trial_data(:,i), conv_filt, 'same');
                    
                end
                
                trial_data = temp;
                clear temp
            otherwise
                error('Smoothing type specified not implemented.');
        end
    end %smoothing
    
    
    %Window data or re-sample
    if ~isempty(opts.WindowSize) && ~isempty(opts.WindowStep),
        
        %Window data using a convolution
        if opts.ValidWindow,
            trial_data = convn(trial_data, fir1(8, 1/opts.WindowStep), 'same');
            window_ind = opts.WindowSize + [0:opts.WindowStep:(trial_time(cur_trial, 3) - opts.WindowSize)];
        else
            trial_data = convn(trial_data, ones(opts.WindowSize, 1)./opts.WindowSize, 'same');
            window_ind = [1:opts.WindowStep:trial_time(cur_trial, 3)];
        end
        trial_data = trial_data(window_ind, :);
        
        %Resample data
    elseif ~isempty(opts.TimeResample),
        %opts.TimeResample(1) = 1
        %opts.TimeResample(2) = step size
        %opts.TimeResample(3) = window size
        trial_data = resample(trial_data, opts.TimeResample(1), opts.TimeResample(2));
        cur_trial_time = downsample(cur_trial_time, opts.TimeResample(2));
    elseif ~isempty(opts.TimeIndex),
        %Take specific time points
        trial_data = trial_data(opts.TimeIndex, :);
        cur_trial_time = cur_trial_time(opts.TimeIndex);
    end
    
    temp_cur_eye_pos = nan(trial_time(cur_trial, 3), 3);
    %Extract eye position data
    cur_eye_pos = trials(cur_trial).EyeData;
    
    %Need to make sure we stay bounded by the data
    neuron_start_ind = trial_time(cur_trial, 1); neuron_end_ind = trial_time(cur_trial, 2);
    eye_start_ind = 1; eye_end_ind = trial_time(cur_trial, 3);
    
    %Are we over-reaching our bounds?
    if neuron_start_ind < 1,
        eye_start_ind = eye_start_ind + (1 - neuron_start_ind);
        neuron_start_ind = 1;
    end
    if neuron_end_ind > length(cur_eye_pos),
        eye_end_ind = eye_end_ind + (length(cur_eye_pos) - neuron_end_ind);
        neuron_end_ind = length(cur_eye_pos);
    end
    
    temp_cur_eye_pos(eye_start_ind:eye_end_ind, :) = cur_eye_pos(neuron_start_ind:neuron_end_ind, :);
    
    %Save to overall data structure
    
    data{cur_trial} = trial_data;
    time{cur_trial} = cur_trial_time;
    eye_pos{cur_trial} = temp_cur_eye_pos;
end %trial loop
