function [frame_data, pos] = parse_aa_saleae(source)
% Parse active avoidance data from its Saleae CSV log.
%
% Outputs:
% - frame_data: [num_frames x 5] table where,
%   -> frame_data(k,1): Trial index associated with the k-th frame
%   -> frame_data(k,2): Absolute time at the beginning of the k-th frame
%   -> frame_data(k,3): 1 if CS was active at the k-th frame, 0 otherwise
%   -> frame_data(k,4): 1 if US was active at the k-th frame, 0 otherwise
%   -> frame_data(k,5): Interpolated position (units of encoder "counts" 
%           at the beginning of the k-th frame
%
% - pos: Exact position of the encoder.
%
% Note: Also works on baseline (non-trial) data. However, in this case the
% trial-idx will be set to 0, and CS / US are also set to 0.

% Saleae channels
encA_ch = 0;
encB_ch = 1;

scope_en_ch = 3;
frame_clock_ch = 7;
cs_ch = 5;
us_ch = 6;

% Load data
%------------------------------------------------------------
fprintf('Loading Saleae data into memory... '); tic;
data = csvread(source, 1, 0); % Omit first line, assumed to be column headings
times = data(:,1);
num_rows = length(times);
t = toc; fprintf('Done in %.1f seconds!\n', t);

% Parse encoder position at full resolution
%------------------------------------------------------------
fprintf('Parsing encoder data... '); tic;

encA = data(:,2+encA_ch);
encB = data(:,2+encB_ch);

pos = zeros(num_rows, 2); % Preallocate output
idx = 0;
curr_pos = 0;
for k = 2:num_rows
    if (~encA(k-1) && encA(k)) % Rising edge on encA
        if ~encB(k)
            curr_pos = curr_pos + 1;
        else
            curr_pos = curr_pos - 1;
        end
        idx = idx + 1;
        pos(idx,:) = [times(k) curr_pos];
    end
end
pos = pos(1:idx,:);

t = toc; fprintf('Done in %.1f seconds!\n', t);

% Parse frame data
%------------------------------------------------------------
fprintf('Parsing frame data... '); tic;

scope_en = data(:,2+scope_en_ch);
frame_clock = data(:,2+frame_clock_ch);
cs_trace = data(:,2+cs_ch);
us_trace = data(:,2+us_ch);

% Preallocate output. Format: [Trial-idx Time CS US]
frame_data = zeros(num_rows,4);
frame_idx = 0;
trial_idx = 0;

for k = 2:length(times)
    if (~scope_en(k-1) && scope_en(k)) %% Rising edge on scope_enable
        trial_idx = trial_idx + 1;
    end
    
    if (~frame_clock(k-1) && frame_clock(k)) %% Rising edge on frame clock
        frame_idx = frame_idx + 1;
        frame_data(frame_idx,:) = [trial_idx times(k) cs_trace(k) us_trace(k)];
    end
end

frame_data = frame_data(1:frame_idx,:);

% Interpolated position at start of each frame
frame_times = frame_data(:,2);
pos_interp = interp1(pos(:,1), pos(:,2), frame_times);
frame_data = [frame_data pos_interp];

t = toc; fprintf('Done in %.1f seconds!\n', t);
