function PM = thresholding_graphic_psi(subID,TCS,params)
% TCS: serialport object

%% Unpack parameters
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

marginalize = params.psi.marginalize;
stimRange = params.psi.stimRange;
priorAlphaRange = params.psi.priorAlphaRange;
priorBetaRange = params.psi.priorBetaRange;
priorLambdaRange = params.psi.priorLambdaRange;
priorGammaRange= params.psi.priorGammaRange;
PF=params.psi.PF;
n_stim=params.psi.n_stim;
jitter=params.psi.jitter;
iti_duration=params.psi.iti_duration;
stimulus_duration=params.psi.stimulus_duration;
quality_duration=params.psi.quality_duration;


%Initialize PM structure (use of single() cuts down on memory lo
PM= PAL_AMPM_setupPM('priorAlphaRange',single(priorAlphaRange),...
    'priorBetaRange',single(priorBetaRange),'priorGammaRange',single(priorGammaRange),...
    'priorLambdaRange',single(priorLambdaRange), 'numtrials',n_stim, 'PF' , PF,...
    'stimRange',single(stimRange),'marginalize',marginalize);

% Make sure the script is running on Psychtoolbox-3:
AssertOpenGL;

%warn if duplicate sub ID
fileName=[pwd,'\data\','TPL_AC_thresholding_expSubj' num2str(subID) '.mat'];

if isfile(fileName)
    resp=input(['the file ' fileName ' already exists. do you want to overwrite it? [Type ok for overwrite]'], 's');
    if ~strcmp(resp,'ok') %abort experiment if overwriting was not confirmed
        disp('experiment aborted')
        return
    end
end

% Settings for stimulations
writeline(TCS,rate_str); 
writeline(TCS,return_str); 
writeline(TCS,surface_str); 
writeline(TCS,duration_str); 

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

    %% Display instruction screen
    myText = ['We will start by assessing your sensitivity to temperature.\n\n\n ' ...
        'To do so, we will stimulate your skin with different temperatures.\n\n\n' ...
        'When ready to start, press a key 2 times (slowly)'];

    DrawFormattedText(expWin, myText, 'center', 'center',text_color);
    Screen('Flip', expWin);
    KbWait([],2);
    KbWait([],2);

    myText = ['After each stimulus, you will be asked to report whether\n the sensation caused by the stimulus was burning or not.\n\n ' ...
        'What is meant by burning here is not that your skin is actually being burnt but rather that\n ' ...
        'the sensation transitions from something that is quite hot but comfortable/neutral\n ' ...
        'to something that becomes unpleasant/burning/pricking/aching/painful (describing sensations is hard).\n\n\n ' ...
        'To answer the question, you just have to click on the left or right button.\n\n\n ' ...
        'When ready to start, press a key 2 times (slowly)'];

    DrawFormattedText(expWin, myText, 'center', 'center',text_color);
    Screen('DrawTexture', expWin, LC, [], [mx-200,my+250,mx-100,my+350]);
    Screen('DrawTexture', expWin, RC, [], [mx+100,my+250,mx+200,my+350]);
    DrawFormattedText(expWin,'NO', mx-185,my+400,text_color);
    DrawFormattedText(expWin,'YES', mx+125,my+400,text_color);
    Screen('Flip', expWin);
    KbWait([],2);
    KbWait([],2);

    for i=1:n_stim+10
        disp(sprintf('Trial %i out of %i',i,n_stim+10));
        %% Inter-trial screen
        iti_onset = Screen('Flip', expWin);

        %% Stimulation screen
        Screen('DrawTexture', expWin, fixcross, [],[mx-20 my-20 mx+20 my+20]);
        jitter_onset = Screen('Flip', expWin,iti_onset+iti_duration(i));
        
        if i==1
            target_temp=45;
        elseif i<11
            if isnan(quality)
                target_temp=target_temp;
            elseif quality==1
                target_temp=target_temp-1;
            else
                target_temp=target_temp+2;
            end
        else
            target_temp=PM.xCurrent;
        end

        wt_str=sprintf('C%i%03i',0,round((35+3*(target_temp-35)/4)*10));
        writeline(TCS,wt_str);
        z_idx=randsample(eligible_z(z_idx,:),1);
        zones=possible_zones(z_idx,:);
        ht_str=sprintf('C%i%03i',zones(1),round(target_temp*10));
        writeline(TCS,ht_str);
        ht_str=sprintf('C%i%03i',zones(2),round(target_temp*10));
        writeline(TCS,ht_str);
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
        WaitSecs('UntilTime',quality_onset+quality_duration);

        %% Saving results
        if i>10
        PM = PAL_AMPM_updatePM(PM,quality);
        end
        PM.rt(i)=rt_quality;
        
        save(fileName,'PM')

        %% End of block screen
        if i==n_stim+10
            DrawFormattedText(expWin, 'End of the block', 'center', 'center',text_color);
            Screen('Flip', expWin);
            WaitSecs(.5);
        end
    end

    %clean up before exitd
    ShowCursor;
    sca;
    ListenChar(0);
    %return to olddebuglevel
    Screen('Preference', 'VisualDebuglevel', olddebuglevel);

catch
    % This section is executed only in case an error happens in the
    % experiment code implemented between try and catch...
    ShowCursor;
    sca; 
    ListenChar(0);
    Screen('Preference', 'VisualDebuglevel', olddebuglevel);
    %output the error message
    psychrethrow(psychlasterror);
end



