function [results_table,TP_table] = TPL_MR(subID,TCS,high_temp,low_temp,params,start_block)
% Thermal pain learning task contrasting innocuous warm and noxious heat
stimulate=1;
MR=1;

%% Unpack params
middle_color=params.screen.middle_color;
background_color=params.screen.background_color;
text_color=params.screen.text_color;
text_size=params.screen.text_size-5;

rate_str=params.TCS.rate_str;
return_str=params.TCS.return_str;
duration_str=params.TCS.duration_str;
surface_str=params.TCS.surface_str;
eligible_z=params.TCS.eligible_z;
possible_zones=params.TCS.possible_zones;
z_idx=params.TCS.z_idx;
recordTime=params.TCS.recordTime;

prediction_duration=params.TPL.prediction_duration;
stimulus_duration=params.TPL.stimulus_duration;
quality_duration=params.TPL.quality_duration;
rating_duration=params.TPL.rating_duration;

TR=params.MR.TR;
dummies=params.MR.dummies;

idx_block(:,1)=[1 11 51 91 131];
idx_block(:,2)=[10 50 90 130 170];
%% 
% Make sure the script is running on Psychtoolbox-3:
AssertOpenGL;

%warn if duplicate sub ID
fileName=[pwd,'\data\','TPL_MR_expSubj' num2str(subID) '.mat'];
if isfile(fileName)
    resp=input(['the file ' fileName ' already exists. do you want to overwrite it? [Type ok for overwrite]'], 's');
    if ~strcmp(resp,'ok') %abort experiment if overwriting was not confirmed
        disp('experiment aborted')
        return
    end
end

if stimulate
    %Settings for stimulations
    writeline(TCS,rate_str); 
    writeline(TCS,return_str); 
    writeline(TCS,surface_str); 
    writeline(TCS,duration_str); 
end

% Recover cue and stimulus sequence
load("cue_sequence_MR.mat")

%Prepare output
colHeaders = {'subID','Trial','Cue','Stimulus','TargetTemperature','Prediction','Quality',...
    'Rating','PredictionRT','QualityRT','ITIOnset','PredictionOnset','JitterOnset','StimulusOnset','QualityOnset','RatingOnset'};
if start_block>1
    load(fileName)
else
    results=NaN * ones(length(cues),length(colHeaders));
    TP=[]; %temp recording
    TriggerMR=[];
end
results_table=array2table(results,'VariableNames',colHeaders);
results_table.subID(1:end)=subID;
results_table.Trial(1:10)=0;
results_table.Trial(11:end)=1:160;
results_table.Cue=cues';
results_table.Stimulus=stims';
results_table.TargetTemperature(stims==0)=low_temp;
results_table.TargetTemperature(stims==1)=high_temp;



try
    % Set-up key response properties to make it MR compatible
    KbName('UnifyKeyNames');
    keys.Escape = KbName('ESCAPE');
    keys.Space = KbName('space');
    keys.Trigger = KbName('5%');
    keys.Left = KbName('3#');
    keys.Right = KbName('4$');
    keys.KeyCode = zeros(1,256);

    %disable output of keypresses to Matlab
    ListenChar(2);

    %Set higher DebugLevel, so that you don't get all kinds of messages flashed
    %at you each time you start the experiment:
    olddebuglevel=Screen('Preference', 'VisualDebuglevel', 3);

    %Choosing the display
    screens=Screen('Screens');
    if length(screens)>1
        screenNumber=1;
    else
        screenNumber=screens;
    end
   
    %open the onscreen Window
    [expWin,rect]=Screen('OpenWindow',screenNumber,background_color);
    Screen('TextSize', expWin, text_size);

    %get the midpoint (mx, my) of this window, x and y
    [mx, my] = RectCenter(rect);

    [LC,RC,LCc,RCc,fixcross,Cue1P,Cue0P,Cue1T,Cue0T]=prepare_images(0,1,expWin,background_color,middle_color,text_color);
    Cue1=Cue1T;
    Cue0=Cue0T;

    %get rid of the mouse cursor
    HideCursor;

    for j=start_block:length(idx_block)
        if j>1
            Cue1=Cue1T;
            Cue0=Cue0T;
        else
            Cue1=Cue1P;
            Cue0=Cue0P;
        end

        if j==1 %Display instruction screens practice block
            myText = ['We will start with a practice block, so that you can get used to performing the task in the scanner.\n\n' ...
                'The task is exactly the same as before.\n' ...
                'Your job is to learn the associations between the symbols and thermal stimuli.\n\n\n'... 
                'One symbol signals high intensity stimuli, leading to burning sensations.\n' ...
                'The other symbol signals low intensity stimuli, leading to non-burning warm sensations.\n ' ...
                'The two symbol have opposite meaning.\n' ...
                'So, if you know the association for one, you also know the association for the other.\n\n\n' ...
                'Remember, every once in while, the association will change.\n\n\n ' ...
                'Click 2 times to get to the next explanation frame.'];
            DrawFormattedText(expWin, myText, 'center', 'center',text_color,[],[],[],1.5);
            Screen('Flip', expWin);
            KbWait([],2);
            KbWait([],2);  

            myText = ['First, a symbol will appear on the screen and\n' ...
                'you will then be asked to make a prediction (using a button click)\n' ...
                'about whether the next stimulus is going to be burning or not.\n\n\n ' ...
                'Then, a stimulus will be delivered to your skin.\n\n\n ' ...
                'In half of the trials, you will then be asked to report \n' ...
                'whether it was burning or not (using a button click)\n ' ...
                'and to provide a rating of the stimulus intensity using a rating scale.\n' ...
                'To input your rating, press on the left or right buttons until the cursor reaches the right level.\n' ...
                'Your rating will be recorded at the end of the trial duration, no need to confirm your choice.\n\n\n ' ...
                'When ready, click 2 times to start the training block.'];
            DrawFormattedText(expWin, myText, 'center', 'center',text_color,[],[],[],1.5);
            Screen('Flip', expWin);
            KbWait([],2);
            KbWait([],2);
        elseif j==2
            DrawFormattedText(expWin, ['You are now ready to start the experiment.\n\n\n ' ...
                'For this part, we will use different symbols.\n ' ...
                'They are displayed at the bottom of the screen.\n\n\n ' ...
                'Take some time to get familiar with them as you will have to be able to distinguish them.'], ...
                'center', my-200,text_color,[],[],[],1.5);
            Screen('DrawTexture', expWin, Cue0, [], [mx-400,my+150,mx-100,my+450]);
            Screen('DrawTexture', expWin, Cue1, [], [mx+100,my+150,mx+400,my+450]);
            Screen('Flip', expWin);
            clc
            disp('Ready to start, press space when MR is ready to proceed')
            while keys.KeyCode(keys.Space) == 0
                [~, ~, keys.KeyCode] = KbCheck;
                WaitSecs(10^-3);
            end
        end

        clc
        disp(sprintf('Block %i out of %i',j,length(idx_block)))
        close
        figure('position',[0,250,600,500])

        %% Wait for MR trigger
        if j>1 && MR==1
            DrawFormattedText(expWin,'The experiment will resume soon', 'center',  'center',text_color);
            Screen('Flip', expWin);
            
            disp('Waiting for MR trigger')
            while keys.KeyCode(keys.Trigger) == 0
                [~, ~, keys.KeyCode] = KbCheck;
                WaitSecs(10^-3);
            end
            
            TriggerMR(j-1) = GetSecs;

            disp(['Trigger received. Waiting for ', num2str(dummies), ' dummy volumes.']);
            WaitSecs(TR*dummies);
        end

        for i=idx_block(j,1):idx_block(j,2)
            disp(sprintf('\nTrial %i',i))

            %% Display filler frame
            [VBLTimestamp, previous_onset]=Screen('Flip', expWin);
            [~, ~, keys.KeyCode] = KbCheck;
            if keys.KeyCode(keys.Escape) == 1
                break
            end
            results_table.ITIOnset(i)=previous_onset;
            
            %% Display cue and prediction question
            if cues(i)
                Screen('DrawTexture', expWin, Cue1, [], [mx-150,my-300,mx+150,my]);
            else
                Screen('DrawTexture', expWin, Cue0, [], [mx-150,my-300,mx+150,my]); 
            end
            Screen('DrawTexture', expWin, LC, [], [mx-220,my+110,mx-100,my+270]);
            Screen('DrawTexture', expWin, RC, [], [mx+100,my+110,mx+220,my+270]);
            DrawFormattedText(expWin,'NO', mx-190,my+320);
            DrawFormattedText(expWin,'YES', mx+140,my+320);
            DrawFormattedText(expWin, 'Will the next stimulus be burning?', 'center',my+70);
            [VBLTimestamp, previous_onset] = Screen('Flip', expWin,previous_onset+iti_duration(i));
            results_table.PredictionOnset(i)=previous_onset;
            [~, ~, keys.KeyCode] = KbCheck;
            if keys.KeyCode(keys.Escape) == 1
                break
            end
            disp(sprintf('Cue: %i',cues(i)))

            %% Display cue, prediction question and response or time-out message
            t=GetSecs;
            prediction=[];
            WaitSecs(.1);
            while (previous_onset+prediction_duration)>t
                t=GetSecs;
                [~, ~, keys.KeyCode] = KbCheck;
                if keys.KeyCode(keys.Escape) == 1
                    break
                elseif keys.KeyCode(keys.Left) == 1
                    prediction=0;
                    results_table.Prediction(i)=prediction;          
                    results_table.PredictionRT(i)=t-previous_onset;          
                    t=inf;
                elseif keys.KeyCode(keys.Right) == 1
                    prediction=1;
                    results_table.Prediction(i)=prediction;          
                    results_table.PredictionRT(i)=t-previous_onset;          
                    t=inf;
                end
            end
            if ~isempty(prediction)
                if cues(i)
                    Screen('DrawTexture', expWin, Cue1, [], [mx-150,my-300,mx+150,my]);
                else
                    Screen('DrawTexture', expWin, Cue0, [], [mx-150,my-300,mx+150,my]); 
                end
                if prediction==0
                    Screen('DrawTexture', expWin, LCc, [], [mx-220,my+110,mx-100,my+270]);
                    Screen('DrawTexture', expWin, RC, [], [mx+100,my+110,mx+220,my+270]);        
                    DrawFormattedText(expWin,'NO',mx-190,my+320,middle_color);
                    DrawFormattedText(expWin,'YES', mx+140,my+320,text_color);
                else
                    Screen('DrawTexture', expWin, LC, [], [mx-220,my+110,mx-100,my+270]);
                    Screen('DrawTexture', expWin, RCc, [], [mx+100,my+110,mx+220,my+270]);
                    DrawFormattedText(expWin,'YES', mx+140,my+320,middle_color);
                    DrawFormattedText(expWin,'NO', mx-190,my+320,text_color);
                end        
                DrawFormattedText(expWin, 'Will the next stimulus be burning?', 'center',my+70);
            else
                DrawFormattedText(expWin, 'Too slow!', 'center', 'center');
                results_table.Prediction(i)=NaN;          
                results_table.PredictionRT(i)=NaN;          
                previous_onset=previous_onset+.5;
            end                
            disp(sprintf('Prediction: %i',prediction))
            Screen('Flip', expWin);

            [~, ~, keys.KeyCode] = KbCheck;
            if keys.KeyCode(keys.Escape) == 1
                break
            end
    
            %% Stimulation frame
            disp(sprintf('Stimulus: %i',stims(i)))
            Screen('DrawTexture', expWin, fixcross, [],[mx-20 my-20 mx+20 my+20]);
            [VBLTimestamp, previous_onset] = Screen('Flip', expWin,previous_onset+prediction_duration);
            results_table.JitterOnset(i)=previous_onset;          

            if stimulate
                %Set stimulator
                if stims(i)
                    target_temp=high_temp;
                else
                    target_temp=low_temp;
                end   
                
                wt_str=sprintf('C%i%03i',0,round((35+3*(target_temp-35)/4)*10));
                writeline(TCS,wt_str);
                z_idx=randsample(eligible_z(z_idx,:),1);
                zones=possible_zones(z_idx,:);
                ht_str=sprintf('C%i%03i',zones(1),round(target_temp*10));
                writeline(TCS,ht_str);
                ht_str=sprintf('C%i%03i',zones(2),round(target_temp*10));
                writeline(TCS,ht_str);
                %Prepare temperature recording
                tp=nan(1000,6);
                timepoint=1;        
                flush(TCS);
                time_sampled=0;
            end
            previous_onset=WaitSecs('UntilTime',previous_onset+jitter(i));
            results_table.StimulusOnset(i)=previous_onset;          
            if stimulate
                tic;
                writeline(TCS,'L');
                while toc < recordTime
                    if (toc-time_sampled)>=0.01
                        time_sampled = toc';
                        writeline(TCS,'E');
                        data=read(TCS, 24, 'char');     
                        if size( data, 2 ) > 23
                            neutral = str2num( data(2:4) );
                            temperatures( 1 ) = str2num( data(5:8) ) / 10;
                            temperatures( 2 ) = str2num( data(9:12) ) / 10;
                            temperatures( 3 ) = str2num( data(13:16) ) / 10;
                            temperatures( 4 ) = str2num( data(17:20) ) / 10;
                            temperatures( 5 ) = str2num( data(21:24) ) / 10;
                            tp(timepoint,1) = time_sampled;
                            tp(timepoint,2:6) = temperatures;            
                            timepoint = timepoint + 1; % update counter
                        else
                        end
                    end
                end
                tp=tp(~isnan(tp(:,1)),:);
                plot(tp(:,1),tp(:,2:6));
                ylim([30,50])
                title(sprintf('Block %i of %i, stimulus %i of %i',j,5,i,length(cues)))
                
                TP(size(TP,1)+1:size(TP,1)+size(tp,1),:)=[ones(size(tp,1),1)*i tp];
            end
            [~, ~, keys.KeyCode] = KbCheck;
            if keys.KeyCode(keys.Escape) == 1
                break
            end
        
            if qual_idx(i)
                %% Quality of stimulus question
                Screen('DrawTexture', expWin, LC, [], [mx-220,my+110,mx-100,my+270]);
                Screen('DrawTexture', expWin, RC, [], [mx+100,my+110,mx+220,my+270]);
                DrawFormattedText(expWin,'NO', mx-190,my+320);
                DrawFormattedText(expWin,'YES', mx+140,my+320);
                DrawFormattedText(expWin, 'Was the stimulus burning?', 'center', 'center');
                [VBLTimestamp, previous_onset] = Screen('Flip', expWin,previous_onset+stimulus_duration);
                results_table.QualityOnset(i)=previous_onset;          
                [~, ~, keys.KeyCode] = KbCheck;
                if keys.KeyCode(keys.Escape) == 1
                    break
                end
        
                %% Quality of stimulus question and response
                t=GetSecs;
                quality=[];
                WaitSecs(.1);
                while (previous_onset+quality_duration)>t
                    WaitSecs(.001);
                    t=GetSecs;
                    [~, ~, keys.KeyCode] = KbCheck;
                    if keys.KeyCode(keys.Escape) == 1
                        break
                    elseif keys.KeyCode(keys.Left) == 1
                        quality=0;
                        results_table.Quality(i)=quality;          
                        results_table.QualityRT(i)=t-previous_onset;          
                        t=inf;
                    elseif keys.KeyCode(keys.Right) == 1
                        quality=1;
                        results_table.Quality(i)=quality;          
                        results_table.QualityRT(i)=t-previous_onset;          
                        t=inf;
                    end
                end
                if ~isempty(quality)
                    if quality==0
                        Screen('DrawTexture', expWin, LCc, [], [mx-220,my+110,mx-100,my+270]);
                        Screen('DrawTexture', expWin, RC, [], [mx+100,my+110,mx+220,my+270]);        
                        DrawFormattedText(expWin,'NO',mx-190,my+320,middle_color);
                        DrawFormattedText(expWin,'YES', mx+140,my+320,text_color);
                    else
                        Screen('DrawTexture', expWin, LC, [], [mx-220,my+110,mx-100,my+270]);
                        Screen('DrawTexture', expWin, RCc, [], [mx+100,my+110,mx+220,my+270]);
                        DrawFormattedText(expWin,'YES', mx+140,my+320,middle_color);
                        DrawFormattedText(expWin,'NO', mx-190,my+320,text_color);
                    end        
                    DrawFormattedText(expWin, 'Was the stimulus burning?', 'center','center');
                else
                    DrawFormattedText(expWin, 'Too slow!', 'center', 'center');
                    results_table.Quality(i)=NaN;          
                    results_table.QualityRT(i)=NaN;          
                    previous_onset=previous_onset+.5;
                end                
                Screen('Flip', expWin);
                disp(sprintf('Reported quality: %i',quality))
                [~, ~, keys.KeyCode] = KbCheck;
                if keys.KeyCode(keys.Escape) == 1
                    break
                end
        
                %% Intensity of perception VAS
                previous_onset=WaitSecs('UntilTime',previous_onset+quality_duration);    
                [rating] = VAS(0,expWin, rect, params,0);
                results_table.Rating(i)=rating;          
                results_table.RatingOnset(i)=previous_onset;          

                disp(sprintf('Intensity rating: %i',round(rating)))
            else
                results_table.QualityOnset(i)=NaN;          
                results_table.Quality(i)=NaN;          
                results_table.QualityRT(i)=NaN;          
                results_table.RatingOnset(i)=NaN;          
                results_table.Rating(i)=NaN;          
            end
            [~, ~, keys.KeyCode] = KbCheck;
            if keys.KeyCode(keys.Escape) == 1
                break
            end
    
            %% show between trial prompt and wait for button press
            if i==length(cues)
                DrawFormattedText(expWin, 'End of the experiment', 'center', 'center');
                Screen('Flip', expWin);
                WaitSecs(.5);
            elseif i==20
                DrawFormattedText(expWin, 'End of the training block', 'center', 'center');
                Screen('Flip', expWin);
                WaitSecs(.5);
            end
        end
    
        if ~isempty(TP)
            TP_table=array2table(TP,'VariableNames',{'trial','time','z1','z2','z3','z4','z5'});
            save(fileName,'results','TP','TriggerMR',"results_table","TP_table");
        else
            save(fileName,'results','TP','TriggerMR',"results_table");
        end
        
        [~, ~, keys.KeyCode] = KbCheck;
        if keys.KeyCode(keys.Escape) == 1
           break
        end

        %% Display break screen
            if j<5 && j>1
                previous_onset=tic;
                DrawFormattedText(expWin,sprintf(['You already did %i%% of the stimuli.\n\n ' ...
                    'Remember the association for when we resume.'],round(100*(i-10)/(length(cues)-10))), 'center',  'center',text_color);
                Screen('Flip', expWin);
                clc
                disp('Ready to start, press space when MR is ready to proceed')
                while keys.KeyCode(keys.Space) == 0
                    [~, ~, keys.KeyCode] = KbCheck;
                    WaitSecs(10^-3);
                end
            end
    end 

    %clean up before exit
    ShowCursor;
    sca; %or sca;
    ListenChar(0);
    %return to olddebuglevel
    Screen('Preference', 'VisualDebuglevel', olddebuglevel);

catch
    % This section is executed only in case an error happens in the
    % experiment code implemented between try and catch...
    ShowCursor;
    sca; %or sca
    ListenChar(0);
    Screen('Preference', 'VisualDebuglevel', olddebuglevel);
    %output the error message
    psychrethrow(psychlasterror);
end
