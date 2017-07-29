clear all;

%% Step 1: Load data
source = '2017_06_15_p495_m487_activeAvoidance14.csv';

trial_start_times = find_edges(source, 4); % TRIAL is Ch4
num_trials = length(trial_start_times);

counter = count_enc_position(source, 0, 1); % EncA and EncB are Ch0 and Ch1, respectively

%% Step 2: Parse encoder position into a raster
t_offsets = -2:0.1:6; % Time relative to trial start [s]
num_points = length(t_offsets);

T = zeros(num_trials, num_points);
P = zeros(num_trials, num_points);
for k = 1:num_trials
    T(k,:) = trial_start_times(k) + t_offsets; % Absolute time
    P(k,:) = interp1(counter(:,1), counter(:,2), T(k,:), 'linear');
end

%% Step 2b (optional): Inspect quality of interpolation
close all;

plot(counter(:,1), counter(:,2), 'o');
xlim([0 counter(end,1)]);
xlabel('Time [s]');
ylabel('Encoder counter (500 CPR)');
title(strrep(source, '_', '\_'));
grid on;
hold on;
for k = 1:num_trials
    plot(T(k,:), P(k,:), 'r', 'LineWidth', 2);
    text(T(k,1), P(k,1), num2str(k),...
         'Color', 'r', 'VerticalAlignment', 'top');
end

%% Step 3: Compute the velocity
dt = t_offsets(2) - t_offsets(1);
cpr = 500; % Encoder counts per rotation
V = gradient(P/cpr, dt); % [rotations/sec]

%% Step 4: Plot the result
close all;
shadedErrorBar(t_offsets, mean(V,1), std(V,0,1)/sqrt(num_trials));
xlim([t_offsets(1) t_offsets(end)]);
xlabel('Time relative to trial start (s)');
ylabel('Encoder velocity (rotations per second)');
grid on;
title(strrep(source, '_', '\_'));
legend('Shaded area indicates s.e.m.', 'Location', 'NorthWest');