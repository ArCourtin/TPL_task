function results = stimulus_validation_graphic(subID,TCS,high_temp,low_temp,params)
% TCS: serialport object
%% Unpack params
middle_color=params.screen.middle_color;
background_color=params.screen.background_color;
text_color=params.screen.text_color;
text_size=params.screen.text_size;

rate_str=params.TCS.rate_str;
return_str=params.TCS.return_str;
duration_str=params.TCS.duration_str;
surface_str=params.TCS.surface_str;
eligible_z=params.TCS.eligible_z;
possible_zones=params.TCS.possible_zones;
z_idx=params.TCS.z_idx;
recordTime=params.TCS.recordTime;

n_stim=params.SV.n_stim;
stimulus_duration=params.SV.stimulus_duration;
quality_duration=params.SV.quality_duration;
rating_duration=params.SV.rating_duration;
iti_duration=params.SV.iti_duration;
jitter=params.SV.jitter;

%%
% Make sure the script is running on Psychtoolbox-3:
AssertOpenGL;

%warn if duplicate sub ID
fileName=[pwd,'\data\','TPL_AC_stimulus_validation_expSubj' num2str(subID) '.mat'];
if isfile(fileName)
    resp=input(['the file ' fileName ' already exists. do you want to overwrite it? [Type ok for overwrite]'], 's');
    if ~strcmp(resp,'ok') %abort experiment if overwriting was not confirmed
        disp('experiment aborted')
        return
    end
end

for i=1:n_stim/2
    stims((1:2)+(i-1)*2)=randsample(0:1,2,false);
end
% 
% %Settings for stimulations
writeline(TCS,rate_str); 
writeline(TCS,return_str); 
writeline(TCS,surface_str); 
writeline(TCS,duration_str); 

%Prepare output
colHeaders = {'subID','Trial','Stimulus','Quality','Rating','QualityRT'};
results=NaN * ones(n_stim,length(colHeaders)); %preallocate results matrix

try
    % Set-up key response properties to make it MR compatible
    KbName('UnifyKeyNames');
    keys.Escape = KbName('ESCAPE');
    keys.Space = KbName('space');
    keys.Left = KbName('LeftArrow');
    keys.Right = KbName('RightArrow');
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

    %open an (the only) onscreen Window
    [expWin,rect]=Screen('OpenWindow',screenNumber,background_color);
    Screen('TextSize', expWin, text_size);

    %get the midpoint (mx, my) of this window, x and y
    [mx, my] = RectCenter(rect);

    %get rid of the mouse cursor, we don't have anything to click at anyway
    HideCursor;
    
    [LC,RC,LCc,RCc,fixcross]=prepare_images(1,0,expWin,background_color,middle_color,text_color);
    
    %% First instruction frame
    myText = ['Based on the assement of your sensitivity, we have selected stimulation temperatures for the task.\n\n ' ...
        'During this part of the experiment, we would like to make sure\n' ...
        'that these stimulation temperatures are appropriate.\n\n' ...
        'To do so, we will deliver you a series of stimulations.\n\n ' ...
        'After each stimulus, you will be asked to report whether it caused\n ' ...
        'a burning sensation or not (just like you did during the previous step).\n ' ...
        'Like before, you provide your response by pressing the left or right button.\n\n\n ' ...
        'Press a key 2 times to get to the next explanation frame.'];
    DrawFormattedText(expWin, myText, 'center', 'center',text_color);
    Screen('Flip', expWin);
    KbWait([],2);
    KbWait([],2);

    %% Second instruction frame
    myText = ['You will also be asked to provide a rating of the intensity of the stimulus on a scale ranging from\n' ...
        '"not detected" (if you did not feel the stimulus at all) to "the most intense you can imagine".\n\n' ...
        'By pressing the buttons, you will have to move the cursor to a position\n ' ...
        'that reflects the intensity of the sensation elicited by the stimulus.\n\n ' ...
        'When you have put the cursor in the right position, just leave it there.\n\n ' ...
        'Press a key 2 times to move to the next frame\n ' ...
        'in which you will have the opportunity to test the rating scale.'];
    DrawFormattedText(expWin, myText, 'center', 'center',text_color);
    Screen('Flip', expWin);
    KbWait([],2);
    KbWait([],2);

    %% VAS test frame
    VAS(1,expWin, rect, params,1);

    %start trials loop
    for i=1:n_stim
        disp(sprintf('Trial %i out of %i',i,n_stim));
        %% Inter-trial screen
       
        [VBLTimestamp, iti_onset]=Screen('Flip', expWin);

        %% Stimulation frame
        Screen('DrawTexture', expWin, fixcross, [],[mx-20 my-20 mx+20 my+20]);
        [VBLTimestamp, jitter_onset] = Screen('Flip', expWin,iti_onset+iti_duration(i));
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
   
        flush(TCS);
        stimulus_onset=WaitSecs('UntilTime',jitter_onset+jitter(i));
        writeline(TCS,'L');

         %% Quality of stimulus question
        Screen('DrawTexture', expWin, LC, [], [mx-200,my+50,mx-100,my+150]);
        Screen('DrawTexture', expWin, RC, [], [mx+100,my+50,mx+200,my+150]);
        DrawFormattedText(expWin,'NO', mx-185,my+200);
        DrawFormattedText(expWin,'YES', mx+125,my+200);
        DrawFormattedText(expWin, 'Was the stimulus burning?', 'center', 'center');
        [VBLTimestamp, quality_onset] = Screen('Flip', expWin,stimulus_onset+stimulus_duration);

        %% Quality of stimulus question and response
        t=GetSecs;
        quality=[];
        while (quality_onset+quality_duration)>t
            t=GetSecs;
            [~, ~, keys.KeyCode] = KbCheck;
            if keys.KeyCode(keys.Escape) == 1
                break
            elseif keys.KeyCode(keys.Left) == 1
                quality=0;
                rt_quality=t-quality_onset;          
                t=inf;
            elseif keys.KeyCode(keys.Right) == 1
                quality=1;
                rt_quality=t-quality_onset;          
                t=inf;
            end
        end
        if ~isempty(quality)
            if quality==0
                Screen('DrawTexture', expWin, LCc, [], [mx-200,my+50,mx-100,my+150]);
                Screen('DrawTexture', expWin, RC, [], [mx+100,my+50,mx+200,my+150]);
                DrawFormattedText(expWin,'NO', mx-185,my+200,middle_color);
                DrawFormattedText(expWin,'YES', mx+125,my+200,text_color);
            else
                Screen('DrawTexture', expWin, LC, [], [mx-200,my+50,mx-100,my+150]);
                Screen('DrawTexture', expWin, RCc, [], [mx+100,my+50,mx+200,my+150]);
                DrawFormattedText(expWin,'YES', mx+125,my+200,middle_color);
                DrawFormattedText(expWin,'NO', mx-185,my+200,text_color);
            end        
            DrawFormattedText(expWin, 'Was the stimulus burning?', 'center','center');
        else
            DrawFormattedText(expWin, 'Too slow!', 'center', 'center');
            quality=NaN;
            rt_quality=NaN;  
            quality_onset=quality_onset+.5;
        end                
        Screen('Flip', expWin);
        
        [~, ~, keys.KeyCode] = KbCheck;
        if keys.KeyCode(keys.Escape) == 1
            break
        end

        %% Intensity of perception VAS
        rating_onset=WaitSecs('UntilTime',quality_onset+quality_duration);        
        [rating] = VAS(1,expWin, rect, params,0);

        WaitSecs('UntilTime',rating_onset+rating_duration);

        [~, ~, keys.KeyCode] = KbCheck;
        if keys.KeyCode(keys.Escape) == 1
            break
        end

        %% enter results in matrix
        results(i,:) = [subID, i,stims(i),quality,rating,rt_quality];

        %% End of block screen
        if i==n_stim
            DrawFormattedText(expWin, 'End of the block', 'center', 'center',text_color);
            Screen('Flip', expWin);
            WaitSecs(.5);
        end
    end
    results=array2table(results,'VariableNames',colHeaders);
    %write to excel format
    save(fileName,'results');

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
