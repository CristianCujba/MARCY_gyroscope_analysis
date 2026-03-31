clear all;
clc;
close all;

%% Load data
data = load("sensorlog_angvel_20260330_165739.mat");
table = data.sensorlog_angvel_20260330_165739;
table_angular_velocity = [table.X, table.Y, table.Z];

%% Visualization pre elaboration
figure(1);
plot(table.timestamp, table_angular_velocity);

%% Filtering
% Crop initial data and last data
index = 600; % [10 hz so 600 is first 60 seconds]
start_index = index;
end_index = height(table) - index;

% Create a new trimmed table
table_trimmed = table(start_index:end_index, :);
table_angular_velocity_trimmed = [table_trimmed.X, table_trimmed.Y, table_trimmed.Z];

% Plot the new data
figure(2);
plot(table_trimmed.timestamp, table_angular_velocity_trimmed);

%% Allan variance
Fs = 10; % [Hz], frequency of matlab mobile sampling

[allan_var, tau]  = allanvar(table_angular_velocity_trimmed, 'octave', Fs);

allan_dev = sqrt(allan_var);

%% Plots
figure(3);
h = loglog(tau, allan_dev); 
set(h(1), 'Color', 'r'); set(h(2), 'Color', 'g'); set(h(3), 'Color', 'b');
hold on; grid on;
title('Allan Deviation of Smartphone Gyroscope');
xlabel('\tau (Averaging Time in [s])');
ylabel('\sigma(\tau) (Allan Deviation in [rad/s])');
legend('X-axis', 'Y-axis', 'Z-axis');

%% Angle Random Walk for X-axis
% Calculate the Angle Random Walk (ARW) from Allan deviation using X axis
log_N = interp1(log10(tau), log10(allan_dev), log10(1), 'linear', 'extrap');

% ARW coefficient in [rad/sqrt(s)]
N = 10.^log_N;

% Plot only for X axis
figure(4);
loglog(tau, allan_dev(:, 1), 'r')
hold on; grid on;
line_arw = N(1) ./ sqrt(tau);
loglog(tau, line_arw, '--k', 'LineWidth', 1.5);

%% Bias Instability for X-axis
% We find the minimum value for each axis
[min_allan_dev_x, index_min_x] = min(allan_dev(:, 1));
[min_allan_dev_y, index_min_y] = min(allan_dev(:, 2));
[min_allan_dev_z, index_min_z] = min(allan_dev(:, 3));

% Apply the IEEE constant 0.664
IEEE_constant = 0.664;
B_x = min_allan_dev_x / IEEE_constant;
B_y = min_allan_dev_y / IEEE_constant;
B_z = min_allan_dev_z / IEEE_constant;

% plot
figure(4);
hold on;

% For plotting, we use the raw minimum to show the "floor"
tau_min_x = tau(index_min_x);
line([tau(1) tau(end)], [min_allan_dev_x min_allan_dev_x]);
plot(tau_min_x, min_allan_dev_x, 'ko', 'LineWidth', 2);