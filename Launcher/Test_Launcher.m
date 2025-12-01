%                        -> 2D TERRA Launcher <-                          %

% This script launchs an execution of TERRA-2D over a random generated
% scenario to solve the Energy Constrained UAV and Charging Station UGV 
% Routing Problem (ECU-CSURP).
% For more information, please refer to the paper:
%   Ropero, F., Mu�oz, P., & R-Moreno, M. D. TERRA: A path planning 
%   algorithm for cooperative UGV�UAV exploration. Engineering Applications 
%   of Artificial Intelligence, 78, 260-272, 2019.

% System Settings
if isunix
    slash='/';
elseif ispc
    slash='\';
end

% Check execution directory
if ~contains(pwd,'TERRA')
    disp('Execution error: You need to be in the "TERRA\" directory')
    return
end

% Configuration of the testing parameters
%  iterations   = n? of executions with different scenarios
%  printResults = LoL
%  saveResults  = xd
%  Vrep         = to launch the V-REP simulation
%  saveDir      = o.O
%  LKHdir       = directory where it is installed the TSP heuristic (LKH). Mandatory bars format 'C:\\Users\\'
format shortg
[c, ~] = clock;
saveDir = ['Results' slash 'Test-' num2str(c(3)) '.' num2str(c(2)) '.' num2str(c(1)) '.' num2str(c(4)) '.' num2str(c(5)) slash];
LKHdir = 'F:\\TERRA-main\\EstimatingHeuristic\\';
cfgParams = struct('iterations',1,'printResults',true,'saveResults',true,'Vrep',false,'saveDir',saveDir,'slash',slash,'fullname','','LKHdir',LKHdir);

%Create directory if saveresults = true
if (cfgParams.saveResults)
    [status, msg, msgID] = mkdir(saveDir);
end

% ECU_CSURP Parameters
%  T    = Target Points of the scenario
%  N    = Number of target points
%  R    = Farthest distance the UAV can travel [m]
%  D    = Number of groups for the random map generator
%  Home = Home location
%  Area = map area
%  Gp   = gravitational point (if null, then no GOA is applied) - Gps = 'GravityCenter','HomeCenter','MedianCenter'
problem_params = struct('T',[],'R',0,'N',52,'D',1,'Home',[0.5;0.5],'Area',10000,'Gp', []);

% UGV's TSP Genetic Algoritm Parameters (Current Used = Id. 2 from TERRA paper)
%  popSize     = size of the population of chromosomes.
%  tournaments = number of chromosomes to select for the tournament selection
%  mutOper     = mutation operator (1 = Flip; 2 = Swap; 3 = Slide)
%  mutRate     = mutation rate from 0.0 to 1.0 (0-100%)
%  crossOper   = crossover operator (1 = OX; 2 = CX; 3 = CBX)
%  eliteP      = elitism selection from 0 to 100%
%ugv_tsp = struct('popSize',430,'tournaments',9,'mutOper',2,'mutRate',0.06,'crossOper',1,'eliteP',2.7);
ugv_tsp = struct('popSize', 430, 'tournaments', 8, ...
                 'mutOper', 2, 'mutRate', 0.03, ...
                 'crossOper', 1, 'eliteP', 4.0);
% UGV Path Planning Parameters
ugv_data = struct('Vugv',0.45, 'ugv_tsp',ugv_tsp); %Mars Curiosity Max Speed in m/s

% UAV Path Planning Parameters
%   Tt   :Total time budget [budget] budget = flight seconds
%   Vuav :UAV's speed [m/s]
%   Tl   :Landing time [s]
%   To   :Taking off time [s]
%   R    :Radius [m]
uav_data = struct('Tt',660,'Vuav',1.0,'Tl',30,'To',30,'R',90);
%problem_params.R = uav_data.Vuav * ((uav_data.Tt - uav_data.To - uav_data.Tl)/2); %m
problem_params.R = uav_data.R;
problem_params.R
%problem_params.R
%uav_data.R = problem_params.R;

%Launch TERRA-2D with timeout (1 hour = 3600 seconds)
timeout_seconds = 3600; % 1 hour timeout
disp(['Starting Test_2D with timeout of ' num2str(timeout_seconds) ' seconds (1 hour)...']);

% Use parallel computing to enable timeout
try
    % Start the function in the background
    future = parfeval(@Test_2D, 1, problem_params, uav_data, ugv_data, cfgParams);
    
    % Monitor execution with timeout
    start_time = tic;
    timeout_reached = false;
    
    while ~strcmp(future.State, 'finished')
        elapsed_time = toc(start_time);
        
        if elapsed_time > timeout_seconds
            % Timeout reached - cancel the task
            cancel(future);
            timeout_reached = true;
            error('Test_2D execution exceeded the timeout limit of %d seconds (1 hour). Execution has been stopped.', timeout_seconds);
        end
        
        % Small pause to avoid busy waiting
        pause(0.1);
    end
    
    % If we get here, the task completed
    if ~timeout_reached
        solution = fetchOutputs(future);
        disp('Test_2D completed successfully within the timeout limit.');
    end
    
catch ME
    if contains(ME.message, 'timeout') || contains(ME.message, 'exceeded')
        rethrow(ME);
    else
        % Other error - try to cancel if still running
        if exist('future', 'var') && ~strcmp(future.State, 'finished')
            cancel(future);
        end
        rethrow(ME);
    end
end


