function params=generate_param_structure()
    %% Rendering
    params.screen.middle_color=[60 60 160];
    params.screen.background_color =[15 15 40];
    params.screen.text_color=[200 200 240];
    params.screen.text_size=35;
    
    %% TCS
    params.TCS.rate_str='V00400';
    params.TCS.duration_str='D003000';
    params.TCS.return_str='R00400';
    params.TCS.surface_str='S11111';
    params.TCS.bl_str='N350';
    params.TCS.eligible_z=[3,4;4,4;1,1;1,2];
    params.TCS.possible_zones=[1 2;2 3;3 4;4 5];
    params.TCS.z_idx=1;
    params.TCS.recordTime=4;
    
    %% VAS
    params.VAS.aborttime = 4;
    params.VAS.scalePosition = 0.6;
    params.VAS.scaleLength   = 0.6;
    params.VAS.lineLength    = 10;
    params.VAS.width         = 3;
    params.VAS.mouseButton   = 1;
    params.VAS.anchors= {'Not detected','The most intense'};
    params.VAS.question= 'How intense was the stimulus?';
    params.VAS.stepSize= 2;
    
    %% Thresholding
    params.psi.marginalize = [];
    params.psi.stimRange = 39:0.5:50;
    params.psi.priorAlphaRange = 40:0.5:50;
    params.psi.priorBetaRange =  -.4:.05:1;
    params.psi.priorLambdaRange = .01;
    params.psi.priorGammaRange= .05;
    params.psi.PF= @PAL_CumulativeNormal;
    params.psi.n_stim= 30;
    params.psi.iti_duration = 3 + 2 * rand(1,params.psi.n_stim+10);
    params.psi.jitter= 5 - params.psi.iti_duration;
    params.psi.stimulus_duration = 4;
    params.psi.quality_duration = 4;
    
    %% Stimulus validation
    params.SV.n_stim= 12;
    params.SV.stimulus_duration= params.psi.stimulus_duration;
    params.SV.quality_duration= 2;
    params.SV.rating_duration= params.VAS.aborttime;
    params.SV.iti_duration= 2 + 2 * rand(1,params.SV.n_stim+10);
    params.SV.jitter= 4 - params.SV.iti_duration;
    
    %% Learning task
    params.TPL.prediction_duration = 3;
    params.TPL.stimulus_duration= params.psi.stimulus_duration;
    params.TPL.quality_duration= params.SV.quality_duration;
    params.TPL.rating_duration= params.VAS.aborttime;

    %% MR
    params.MR.TR= 1.305;
    params.MR.dummies= 4;

end