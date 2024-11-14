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

COMport='COM3';
baseline_temp=32;       %degree C
rng(session_id)

filename=[pwd,'\data\','TPL_data_acquisition_',num2str(session_id), '.mat'];
Screen('Preference', 'SkipSyncTests', 1);
addpath("Palamedes\")
addpath("data\")

params=generate_param_structure();

%% initialize TCS
TCS=TCS_initialize(COMport,params);

%% Thresholding
PM = thresholding_graphic_psi(session_id,TCS,params);
save(filename)
%%
if 2/10^PM.slope(end)>1
    nh_temp=PM.threshold(end)+2/10^PM.slope(end);
    iw_temp=PM.threshold(end)-2/10^PM.slope(end);
else
    nh_temp=PM.threshold(end)+1;
    iw_temp=PM.threshold(end)-1;
end

if nh_temp>49
    nh_temp=49;
    if (nh_temp-iw_temp)<2
        iw_temp=47;
    end
end

x=1:PM.numTrials;
figure('Color','w')
subplot(1,3,1)
hold on
plot(x,PM.threshold,'color',[230,159,0]/255,'LineWidth',1)
plot(x,PM.x(1:(end-1)),'o','color',[230,159,0]/255)
plot(x(PM.response==1),PM.x(PM.response==1),'*','color',[230,159,0]/255)
plot(x,PM.threshold+2*PM.seThreshold,':','color',[230,159,0]/255,'LineWidth',1)
plot(x,PM.threshold-2*PM.seThreshold,':','color',[230,159,0]/255,'LineWidth',1)
hold off
ylabel("Temperature (°C)")
xlabel("Trial")
title("Stimuli and \mu posterior ")
subplot(1,3,2)
hold on
plot(x,1./10.^PM.slope,'color',[230,159,0]/255,'LineWidth',1)
plot(x,1./10.^(PM.slope+2*PM.seSlope),':','color',[230,159,0]/255,'LineWidth',1)
plot(x,1./10.^(PM.slope-2*PM.seSlope),':','color',[230,159,0]/255,'LineWidth',1)
hold off
title("\sigma posterior")
ylabel("Temperature (°C)")
xlabel("Trial")
subplot(1,3,3)
hold on
plot(PM.stimRange(1):.1:PM.stimRange(end),normcdf(PM.stimRange(1):.1:PM.stimRange(end),PM.threshold(end),1/10^PM.slope(end)),'LineWidth',1)
plot(iw_temp*ones(2,1),[0 1],'k:','LineWidth',1)
plot(nh_temp*ones(2,1),[0 1],'k:','LineWidth',1)
hold off
xlim([min(PM.stimRange) max(PM.stimRange)])
title("PF and selected stimulus intensties")
xlabel("Temperature (°C)")
ylabel("Probability")

%% Stimulus check
results_stimulus_validation = stimulus_validation_graphic(session_id,TCS,nh_temp,iw_temp,params);
save(filename)
%%
d=results_stimulus_validation(results_stimulus_validation.Stimulus==0,:);
p=results_stimulus_validation(results_stimulus_validation.Stimulus==1,:);
figure('Color','w')
hold on
plot(d.Rating/100,'Color',[213,94,0]/255)
plot(p.Rating/100,'Color',[230,159,0]/255)
plot(d.Quality,'o','Color',[213,94,0]/255)
plot(p.Quality,'*','Color',[230,159,0]/255) 
hold off
ylim([0  1])
title('Stimulus validation')

%% Task
[results_task_practice,TP_table_practice] = TPL_practice(session_id,TCS,nh_temp,iw_temp,params,1);
save(filename)
stimulus=results_task_practice.Stimulus;
prediction=results_task_practice.Prediction;
quality=results_task_practice.Quality;

figure
plot(stimulus(~isnan(prediction))==prediction(~isnan(prediction)),'.')
title(sprintf('prediction accuracy:%0.2f',mean(stimulus(~isnan(prediction))==prediction(~isnan(prediction)))))

figure 
plot(stimulus(~isnan(quality))==quality(~isnan(quality)),'.')
title(sprintf('quality accuracy:%0.2f',mean(stimulus(~isnan(quality))==quality(~isnan(quality)))))
