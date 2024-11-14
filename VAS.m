function [position] = VAS(key,screenPointer, rect, params,familiarization)
%Adapted by A.S.C. from the slideScale function written by Joern Alexander Quent

text_color=params.screen.text_color;
middle_color=params.screen.middle_color;

aborttime=params.VAS.aborttime;
scalePosition=params.VAS.scalePosition;
scaleLength=params.VAS.scaleLength;
lineLength=params.VAS.lineLength;
width=params.VAS.width;
anchors=params.VAS.anchors;
question=params.VAS.question;
stepSize=params.VAS.stepSize;

if familiarization
    aborttime=6;
end

KbName('UnifyKeyNames');
keys.Escape = KbName('ESCAPE');

if key==1
    keys.Left = KbName('LeftArrow');
    keys.Right = KbName('RightArrow');
else
    keys.Left = KbName('3#');
    keys.Right = KbName('4$');
end
keys.KeyCode = zeros(1,256);

%% Coordinates of scale lines and text bounds
x = rect(3)*(scaleLength-(1-scaleLength))/4*(rand-.5)+rect(3)/2;

% SetMouse(round(x), round(rect(4)*scalePosition), screenPointer, 1);
leftTick   = [rect(3)*(1-scaleLength) rect(4)*scalePosition - lineLength rect(3)*(1-scaleLength) rect(4)*scalePosition  + lineLength];
rightTick  = [rect(3)*scaleLength rect(4)*scalePosition - lineLength rect(3)*scaleLength rect(4)*scalePosition  + lineLength];
horzLine   = [rect(3)*scaleLength rect(4)*scalePosition rect(3)*(1-scaleLength) rect(4)*scalePosition];
textBounds = [Screen('TextBounds', screenPointer, sprintf(anchors{1})); Screen('TextBounds', screenPointer, sprintf(anchors{2}))];

% Calculate the range of the scale, which will be need to calculate the
% position
scaleRange        = round(rect(3)*(1-scaleLength)):round(rect(3)*scaleLength); % Calculates the range of the scale

%% Loop for scale loop
t0= GetSecs;
secs=GetSecs;
prev=10;
while secs - t0 < aborttime 
    [~, ~, keys.KeyCode] = KbCheck;
    if keys.KeyCode(keys.Left) == 1 && prev==0
        prev=0;
        x = x - 2*stepSize; % Goes stepSize pixel to the left
    elseif keys.KeyCode(keys.Left) == 1 && prev~=0
        prev=0;
        x = x - stepSize; % Goes stepSize pixel to the left
    elseif keys.KeyCode(keys.Right) == 1 && prev==1
        prev=1;
        x = x + 2*stepSize; % Goes stepSize pixel to the right
    elseif keys.KeyCode(keys.Right) == 1 && prev~=1
        prev=1;
        x = x + stepSize; % Goes stepSize pixel to the right
    end

    % Stop at upper and lower bound
    if x > rect(3)*scaleLength
        x = rect(3)*scaleLength;
    elseif x < rect(3)*(1-scaleLength)
        x = rect(3)*(1-scaleLength);
    end
      
    % Drawing the question as text
    DrawFormattedText(screenPointer, question, 'center', rect(4)*(scalePosition - 0.16)); 
    
    % Drawing the anchors of the scale as text
    DrawFormattedText(screenPointer, anchors{1}, leftTick(1, 1) - textBounds(1, 3)-20,  rect(4)*scalePosition+10, [],[],[],[],[],[],[]); % Left point
    DrawFormattedText(screenPointer, anchors{2}, rightTick(1, 1) +20,  rect(4)*scalePosition+10, [],[],[],[],[],[],[]); % Right point
    
    
    % Drawing the scale
    Screen('DrawLine', screenPointer, text_color, leftTick(1), leftTick(2), leftTick(3), leftTick(4), width);     % Left tick
    Screen('DrawLine', screenPointer, text_color, rightTick(1), rightTick(2), rightTick(3), rightTick(4), width); % Right tick
    Screen('DrawLine', screenPointer, text_color, horzLine(1), horzLine(2), horzLine(3), horzLine(4), width);     % Horizontal line
    
    % The slider
    Screen('DrawLine', screenPointer, text_color, x, rect(4)*scalePosition - lineLength, x, rect(4)*scalePosition  + lineLength, 2*width);
    
    % Caculates position
    position = round((x)-min(scaleRange));                       % Calculates the deviation from 0. 
    position = (position/(max(scaleRange)-min(scaleRange)))*100; % Converts the value to percentage
    
    % Flip screen
    Screen('Flip', screenPointer);
    
    % Check if answer has been given
    secs = GetSecs;
end                                          
end
