function [LCTexture,RCTexture,LCcTexture,RCcTexture,fixcross,Cue1PracticeTexture,Cue0PracticeTexture,Cue1TestTexture,Cue0TestTexture]=prepare_images(key,cueset,expWin,background_color,middle_color,text_color)
    %% Response cues
    if key
        LCLocation = 'LK.png';
    else
        LCLocation = 'LB.png';
    end
    LC = imread(LCLocation)~=0;
    RC=flip(LC,2);
    for i=1:3
        LCb(:,:,i)=double(LC(:,:))*(text_color(i)-background_color(i))+background_color(i);
        RCb(:,:,i)=double(RC(:,:))*(text_color(i)-background_color(i))+background_color(i);
        LCc(:,:,i)=double(LC(:,:))*(middle_color(i)-background_color(i))+background_color(i);
        RCc(:,:,i)=double(RC(:,:))*(middle_color(i)-background_color(i))+background_color(i);
    end
    LCTexture = Screen('MakeTexture', expWin, LCb);
    RCTexture = Screen('MakeTexture', expWin, RCb);
    LCcTexture = Screen('MakeTexture', expWin, LCc);
    RCcTexture = Screen('MakeTexture', expWin, RCc);

    %% Create a fixation cross
    for i=1:3
        FixCr(:,:,i)=ones(50,50)*background_color(i);
        FixCr(20:31,:,i)=text_color(i);
        FixCr(:,20:31,i)=text_color(i);
    end
    fixcross = Screen('MakeTexture',expWin,FixCr);

      
    %% Load practice cue from file
    if cueset~=0
        Cue1Location = 'cue_practice_1.png';
        Cue0Location = 'cue_practice_2.png';
        Cue1 = imread(Cue1Location)/255;
        Cue1=Cue1(2:2:end,2:2:end,:);
        Cue0 = imread(Cue0Location)/255;
        Cue0=Cue0(2:2:end,2:2:end,:);
        for i=1:3
            cue0(:,:,i)=double(Cue0(:,:,i))*(background_color(i)-middle_color(i))+middle_color(i);
            cue1(:,:,i)=double(Cue1(:,:,i))*(background_color(i)-middle_color(i))+middle_color(i);
        end
        Cue1PracticeTexture = Screen('MakeTexture', expWin, cue1);
        Cue0PracticeTexture = Screen('MakeTexture', expWin, cue0);
    
        % Load visual cue from file
        Cue1Location = ['cue' num2str(cueset) '1.png'];
        Cue0Location = ['cue' num2str(cueset) '2.png'];
        Cue1 = imread(Cue1Location)/255;
        Cue1=Cue1(2:2:end,2:2:end,1);
        Cue0 = imread(Cue0Location)/255;
        Cue0=Cue0(2:2:end,2:2:end,1);
        cue0=[];
        cue1=[];
        for i=1:3
            cue0(:,:,i)=double(Cue0(:,:))*(background_color(i)-middle_color(i))+middle_color(i);
            cue1(:,:,i)=double(Cue1(:,:))*(background_color(i)-middle_color(i))+middle_color(i);
        end
        Cue1TestTexture = Screen('MakeTexture', expWin, cue1);
        Cue0TestTexture = Screen('MakeTexture', expWin, cue0);
    end
end