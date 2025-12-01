function [ new_problem ] = scene_generator(problem_params, input_xy)
% This function uses an existing set of target coordinates 'input_xy' 
% and assigns them to the map. It ensures 'n' target points are grouped 
% according to the given parameters.
% INPUTS:
% problem_params: Structure containing the problem parameters (N, Area, etc.)
% input_xy: The already provided coordinates of the target points
%
% OUTPUTS:
% new_problem: Updated problem structure with target points 'T'

% INPUT parameters
new_problem = problem_params;
xy = input_xy;  % Use provided 2D coordinates instead of generating them
n = problem_params.N;
home = problem_params.Home;
r = problem_params.R;
% Ensure that the number of coordinates matches 'n'
if size(xy, 2) ~= n
    disp('The number of input coordinates does not match the specified n!');
    return;
end

% Round the coordinates to 3 decimal places
f = 10.^3;
xy = round(f*xy)/f;

new_problem.T = xy;

% Plotting the map with the input coordinates
figure;
plot(xy(1,:), xy(2,:), 'blue.', home(1,1), home(2,1), '*');
hold on;

% Plot the home location
plot(home(1,1), home(2,1), 'r*', 'MarkerSize', 10);

% Plot circles around the target points if needed
theta = linspace(0, 2*pi);
for i = 1:n
    c_x = r * sin(theta) + xy(1,i);
    c_y = r * cos(theta) + xy(2,i);
    plot(xy(1,i), xy(2,i), 'black+', c_x, c_y, 'r:');
end
hold off;

% Set axis equal and title
axis equal;
title('Map with Input Target Coordinates');

% Save the figure as a PNG image
saveas(gcf, 'map_with_input_coordinates.png');

end