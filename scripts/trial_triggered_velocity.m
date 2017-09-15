function trial_triggered_velocity(source)

% Step 1: Load data
% source = 'm756_20170915.csv';

trials = find_trials(source, 4, 6); % Note: Ch4 is Trial, Ch6 is US
num_trials = size(trials,1);

counter = count_enc_position(source, 0, 1); % EncA and EncB are Ch0 and Ch1, respectively

% Step 2: Parse encoder position into a raster
t_offsets = -2:0.1:6; % Time relative to trial start [s]
num_points = length(t_offsets);

T = zeros(num_trials, num_points);
P = zeros(num_trials, num_points);
for k = 1:num_trials
    T(k,:) = trials(k,1) + t_offsets; % Absolute time
    P(k,:) = interp1(counter(:,1), counter(:,2), T(k,:), 'linear');
end

% Step 2b (optional): Inspect quality of interpolation
figure;
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

% Step 3: Compute the velocity
dt = t_offsets(2) - t_offsets(1);
cpr = 500; % Encoder counts per rotation
V = gradient(P/cpr, dt); % [rotations/sec]

% Step 4: Plot the result
figure;
subplot(3,1,1);
shadedErrorBar(t_offsets, mean(V,1), std(V,0,1)/sqrt(num_trials));
xlim([t_offsets(1) t_offsets(end)]);
xlabel('Time relative to CS (s)');
ylabel('Running velocity (rotations per second)');
grid on;
legend('Shaded area indicates s.e.m.', 'Location', 'NorthWest');
title(strrep(source, '_', '\_'));

subplot(3,1,[2 3]);
imagesc(V,'XData',t_offsets,'YData',1:num_trials);
corr_width = 0.5;
for k = 1:num_trials
    if trials(k,2)
        corr_color = 'g'; % No US applied
    else
        corr_color = 'r'; % US applied
    end
    rectangle('Position', [t_offsets(end) k-0.5 corr_width 1], 'FaceColor', corr_color);
end
xlim([t_offsets(1) t_offsets(end)+corr_width]);
xlabel('Time relative to CS (s)');
% set(gca,'YTick',1:num_trials);
grid on;
ylabel('Trial');
colorbar;