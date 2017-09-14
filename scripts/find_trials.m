function trials = find_trials(saleae_file, trial_ch, us_ch)

data = csvread(saleae_file, 1, 0); % Omit first line, assumed to be column headings
times = data(:,1);
trial_trace = data(:,2+trial_ch);
us_trace = data(:,2+us_ch);

% Preallocate output. Format: [Trial-start-time, Trial-correctness]
trials = zeros(length(times),2);
num_edges = 0;

prev_val = trial_trace(1);
for k = 2:length(times)
    val = trial_trace(k);
    
    if (~prev_val && val) % Rising edge on trial trace, indicating START
        trial_start_k = k;
    end
    
    if (prev_val && ~val) % Falling edge, indicating END
        trial_end_k = k;
        
        % Determine if the US was applied at any point during the trial
        us_trace_trial = us_trace(trial_start_k:trial_end_k);
        trial_correct = ~any(us_trace_trial);
        
        % Tabulate trial data
        num_edges = num_edges + 1;
        trials(num_edges,:) = [times(trial_start_k) trial_correct];
    end
    
    prev_val = val;
end

trials = trials(1:num_edges,:);