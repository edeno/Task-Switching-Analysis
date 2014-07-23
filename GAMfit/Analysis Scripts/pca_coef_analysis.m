clear all; close all; clc;
cd('C:\Users\edeno\Dropbox\GAM Analysis\Rule Response');
load('neurons.mat');

pfc = logical([neurons.pfc]);
par_est = [neurons.par_est]';
baseline_firing = exp(par_est(1, :))*1000;
par_est = par_est(:, 2:end);

level_names = gam.level_names;
level_names = level_names(2:end);
%%

[coefs_pfc,score_pfc,latent_pfc] = princomp(par_est(pfc, :));
[coefs_acc,score_acc,latent_acc] = princomp(par_est(~pfc, :));


figure;
subplot(2,2,1);

biplot(coefs_pfc(:,1:2), 'scores',score_pfc(:,1:2), 'varlabels',level_names);
set(findobj(gcf,'Type','text'),'FontSize',7) 
title('dlPFC');
box off;

subplot(2,2,2);

biplot(coefs_acc(:,1:2), 'scores',score_acc(:,1:2), 'varlabels',level_names);
set(findobj(gcf,'Type','text'),'FontSize',7) 
title('ACC');
box off;

subplot(2,2,3);

biplot(coefs_pfc(:,2:3), 'scores',score_pfc(:,2:3), 'varlabels',level_names);
set(findobj(gcf,'Type','text'),'FontSize',7) 
title('dlPFC');
box off;

subplot(2,2,4);

biplot(coefs_acc(:,2:3), 'scores',score_acc(:,2:3), 'varlabels',level_names);
set(findobj(gcf,'Type','text'),'FontSize',7) 
title('ACC');
box off;
