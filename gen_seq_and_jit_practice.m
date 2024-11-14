clear all
satisfied=0;
attempt=0;
while ~satisfied
    attempt=attempt+1
    cues=[];
    stims=[];
    qual_idx=[];
    order=[];    

    %% deterministic practice
    order(1,:)=[zeros(1,4) ones(1,4)];
    order(2,:)=[ones(1,4) zeros(1,4)];
    order(3,:)=[ones(1,2) zeros(1,2) ones(1,2) zeros(1,2)];
        
    idx=randsample(8,8,false)';
    
    cues=[cues order(1,idx)];
    stims=[stims order(2,idx)];
    qual_idx=[qual_idx order(3,idx)];
    
    order=[];
    order(1,:)=[ones(1,1) zeros(1,1)];
    order(2,:)=[ones(1,1) zeros(1,1)];
    order(3,:)=[0 0];
        
    idx=randsample(2,2,false)';
    
    cues=[cues order(1,idx)];
    stims=[stims order(2,idx)];
    qual_idx=[qual_idx order(3,idx)];
    %% probabilistic practice
    order=[];
    
    order(1,:)=[ones(1,5) zeros(1,5)];
    order(2,:)=[ones(1,4) zeros(1,1) ones(1,1) zeros(1,4)];
    order(3,:)=[ones(1,2) zeros(1,3) ones(1,3) zeros(1,2)];
        
    idx=randsample(10,10,false)';
    
    cues=[cues order(1,idx)];
    stims=[stims order(2,idx)];
    qual_idx=[qual_idx order(3,idx)];
    %% trial block
    C=[0 0];
    for i=1:length(C)
        c=C(i);
        order=[];
        n=10;
    
        order(1,:)=[ones(1,n/2) zeros(1,n/2)];
        order(2,:)=[ones(1,n*0.4) zeros(1,n*0.1) ones(1,n*0.1) zeros(1,n*0.4)];
        order(3,:)=[ones(1,n*0.2) zeros(1,n*0.2) ones(1,n*0.1) ones(1,n*0.1) ones(1,n*0.2) zeros(1,n*0.2)];
            
        idx=randsample(n,n,false)';
        
        cues=[cues abs(order(1,idx)-c)];
        stims=[stims order(2,idx)];
        qual_idx=[qual_idx order(3,idx)];
    end
    
    for i=1:length(cues)-4
        cc(i)=(cues(i)==cues(i+1))&&(cues(i+1)==cues(i+2))&&(cues(i+2)==cues(i+3));
        sc(i)=(stims(i)==stims(i+1))&&(stims(i+1)==stims(i+2))&&(stims(i+2)==stims(i+3));
        qc(i)=(qual_idx(i)==qual_idx(i+1))&&(qual_idx(i+1)==qual_idx(i+2))&&(qual_idx(i+2)==qual_idx(i+3));
    end        
    satisfied=(sum(sc)+sum(cc)+sum(qc))==0;
end
%%
close all

subplot(4,1,1)
plot(cues==stims,'.','MarkerSize',5)
hold on
plot([10 10],[0 1],'k--')
plot([20 20],[0 1],'k--')
hold off
title('Contingency')

subplot(4,1,2)
plot(cues,'.')
title('Cues')

subplot(4,1,3)
plot(stims,'.')
title('Stims')

subplot(4,1,4)
plot(qual_idx,'.')
title('Quality report')

%%
jitter=2+4*rand(1,length(cues));
iti_duration=6-jitter;

save('cue_sequence_practice.mat','cues','stims','qual_idx','jitter','iti_duration')