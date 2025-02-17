%% runFAST.m
% This script will run a single FAST simulation with the ROSCO Simulink
% controller.  A more in depth version can be found at https://github.com/dzalkind/matlab-toolbox/tree/master/Simulations

clear;

[this_dir,~,~] = fileparts(mfilename('fullpath'));

% Compile FAST for use with simulink & mex using openfast docs
% fast.FAST_SFuncDir     = '/Users/dzalkind/Tools/openfast-sim/glue-codes/simulink/src';  %%%% NEED FOR SIMULINK
fast.FAST_SFuncDir     = 'C:\Users\emanu\Desktop\Tesi Magistrale\NREL_TEST_SETUP\openfast-2.4.0\openfast-2.4.0\build\bin';
fast.FAST_InputFile    = '5MW_Land_Simulink.fst';   % FAST input file (ext=.fst)
fast.FAST_directory    = 'C:\Users\emanu\Desktop\Tesi Magistrale\NREL_TEST_SETUP\ROSCO-raaw1.3\ROSCO-raaw1.3\Test_Cases\5MW_Land_Simulink';   % Path to fst directory files

% Simulink Parameters
% Model
simu.SimModel           = fullfile(this_dir,'Simulink','ROSCO');

% Script for loading parameters
simu.ParamScript        = fullfile(this_dir,'Utilities','load_ROSCO_params');

%% Simulink Setup

[ControlScriptPath,ControScript] = fileparts(simu.ParamScript);
addpath(ControlScriptPath);
addpath(fast.FAST_SFuncDir);
addpath('Utilities')
 addpath(genpath('C:\Users\emanu\Desktop\Tesi Magistrale\NREL_TEST_SETUP\matlab-toolbox-main\matlab-toolbox-main')); % TODO adapt me
%% Read FAST Files & Load ROSCO Params from DISCON.IN

[Param,Cx] = ReadWrite_FAST(fast);

% Simulation Parameters
simu.TMax   = Param.FP.Val{contains(Param.FP.Label,'TMax')};
simu.dt   = Param.FP.Val{contains(Param.FP.Label,'DT')};
[R,F] = feval(ControScript,Param,simu);

%% Premake OutList for Simulink

OutList = {'Time'};
OutList = [OutList;
    Param.IWP.OutList;
    Param.EDP.OutList;
    Param.ADP.OutList;
    Param.SvDP.OutList;
    ];

for iOut = 2:length(OutList)
    OutList{iOut} = OutList{iOut}(2:end-1); %strip "s
end


%% Exectute FAST

% Using Simulink/S_Func
FAST_InputFileName = [fast.FAST_directory,filesep,fast.FAST_InputFile];
TMax               = simu.TMax;

SimulinkModel = simu.SimModel;

Out         = sim(SimulinkModel, 'StopTime', num2str(simu.TMax));
sigsOut     = get(Out,'sigsOut');   %internal control signals

%% Get OutData

SFuncOutStr = '.SFunc';

% Try text first, then binary
[OutData,OutList] = ReadFASTtext([fast.FAST_directory,filesep,fast.FAST_InputFile(1:end-4),SFuncOutStr,'.out']);
if isempty(OutData)
    [OutData,OutList] = ReadFASTbinary([fast.FAST_directory,filesep,fast.FAST_InputFile(1:end-4),SFuncOutStr,'.outb']);
end

% Dump data to structure
for i = 1:length(OutList)
    simout.(OutList{i}) = OutData(:,i);
end

%% Plot
Pl_FastPlots(simout)



