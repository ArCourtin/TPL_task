clear all
satisfied=0;
attempt=0;
while ~satisfied
    attempt=attempt+1
    cues=[];
    stims=[];
    qual_idx=[];
    order=[];    

    %% trial block
    C=[0   0 0 0 0 0 1 0 1 0 1 0 1 1 1 1 1];
    for i=1:length(C)
        rng(i)
        c=C(i);
        order=[];
        n=10;
    
        order(1,:)=[ones(1,n/2) zeros(1,n/2)];
        order(2,:)=[ones(1,n*0.4) zeros(1,n*0.1) ones(1,n*0.1) zeros(1,n*0.4)];
        if mod(i,2)
            order(3,:)=[ones(1,n*0.1) zeros(1,n*0.3) ones(1,n*0.1) ones(1,n*0.1) ones(1,n*0.2) zeros(1,n*0.2)];
        else
            order(3,:)=[ones(1,n*0.2) zeros(1,n*0.2) ones(1,n*0.1) ones(1,n*0.1) ones(1,n*0.1) zeros(1,n*0.3)];
        end
        idx=randsample(n,n,false)';
        
        cues=[cues abs(order(1,idx)-c)];
        stims=[stims order(2,idx)];
        qual_idx=[qual_idx order(3,idx)];
    end
    
    for i=1:length(cues)-4
        sc(i)=(stims(i)==stims(i+1))&&(stims(i+1)==stims(i+2))&&(stims(i+2)==stims(i+3));
        cc(i)=(cues(i)==cues(i+1))&&(cues(i+1)==cues(i+2))&&(cues(i+2)==cues(i+3));
%         qc(i)=(qual_idx(i)==qual_idx(i+1))&&(qual_idx(i+1)==qual_idx(i+2))&&(qual_idx(i+2)==qual_idx(i+3));
    end 
    for i=1:length(cues)-5
        qc(i)=(qual_idx(i)==qual_idx(i+1))&&(qual_idx(i+1)==qual_idx(i+2))&&(qual_idx(i+2)==qual_idx(i+3))&&(qual_idx(i+3)==qual_idx(i+4));%&&(qual_idx(i+4)==qual_idx(i+5));
    end 
    satisfied=(sum(sc)+sum(cc)+sum(qc))==0;
end
%%
close all

subplot(4,1,1)
plot(cues==stims,'.','MarkerSize',5)
hold on
plot([10 10],[0 1],'k--')
hold off
title('Contingency')

subplot(4,1,2)
plot(cues,'.')
title('Cues')

subplot(4,1,3)
plot(stims,'.')
title('Stimuli')

subplot(4,1,4)
plot(qual_idx,'.')
title('Quality Report')
%%
contingencies=stims==cues;
for idx=1:length(cues)-20
    smoothed(idx)=mean(contingencies((10:19)+idx));
end
figure
plot(smoothed)
%%
satisfied=0;
i=0;
while ~satisfied
    i=i+1
    jitter=2+4*rand(1,length(cues));
    iti_duration=6-jitter;
    satisfied=min(iti_duration)>.2;
end
save('cue_sequence_MR.mat','cues','stims','qual_idx','jitter','iti_duration')

