v=PsychtoolboxVersion;
% if strcmp(v(1:6),'3.0.18')
%     disp('Current Psychtoolbox version is 3.0.18')
% else
%     disp('Current Psychtoolbox version is not 3.0.18')
%     disp('Starting the upgrade or downgrade')
%     UpdatePsychtoolbox([],'13009')
% end
% if input('Is the MRI filter enabled? 0=no, 1=yes')~=1
%     beep
%     disp('Enable MRI filter')
%     pause(5)
% end

clc
clear all
close all

session_id=1706;
% session_id=input('Particiant identification number?');

rng(session_id)

addpath("Palamedes\")
addpath("data\")
filename=[pwd,'\data\','TPL_data_acquisition_',num2str(session_id), '.mat'];
load(filename);
COMport='COM4';
filename=[pwd,'\data\','TPL_data_acquisition_',num2str(session_id), '.mat'];

Screen('Preference', 'SkipSyncTests', 1);

TCS=[];

%% initialize TCS
TCS=TCS_initialize(COMport,params);
%% Task
[results_task_MR,TP] = TPL_MR(session_id,TCS,nh_temp,iw_temp,params,1);
save(filename)

cues=results_task_MR.Cue;
stimulus=results_task_MR.Stimulus;
prediction=results_task_MR.Prediction;
quality=results_task_MR.Quality;
rating=results_task_MR.Rating;

figure
plot(stimulus(~isnan(prediction))==prediction(~isnan(prediction)),'.')
title(sprintf('prediction accuracy:%0.2f',mean(stimulus(~isnan(prediction))==prediction(~isnan(prediction)))))

figure
plot(rating(~isnan(rating))) 
title('ratings')

figure 
plot(stimulus(~isnan(quality))==quality(~isnan(quality)),'.')
title(sprintf('quality accuracy:%0.2f',mean(stimulus(~isnan(quality))==quality(~isnan(quality)))))

pa=cues==prediction;
con=stimulus==cues;
for i=1:150
    belief(i)=mean(pa([1:10]+(i-1)),'omitnan');
    window(i)=mean(con([1:10]+(i-1)),'omitnan');
end

figure
hold on
plot(window)
plot(belief)
hold off
title("Smoothed belief trajectory")
legend("true contingencies","predictions")