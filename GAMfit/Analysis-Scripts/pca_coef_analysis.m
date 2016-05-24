clear all; close all; clc;
drop_path = getappdata(0, 'drop_path');
cd([drop_path, '/GAM Analysis/Rule Response']);
load('neurons.mat');

%% Latent structure of the parameters
pfc = logical([neurons.pfc]);
par_est = exp([neurons.par_est])';
baseline_firing = exp(par_est(:,1))*1000;
good_ind = baseline_firing > 0.5;
par_est = par_est(good_ind, 2:end);
pfc = pfc(good_ind);

level_names = gam.level_names;
level_names = level_names(2:end);

numComponents = 3;
if numComponents > 2,
    plot_inds = numSubplots(numComponents);
else
    plot_inds = numSubplots(1);
end
area_name = {'ACC', 'dlPFC'};

for area_ind = 0:1,
    
    % Compute PCA
    [coefs,score,latent, ~, explained] = pca(par_est(pfc == area_ind, :),'NumComponents', 10);
    
    figure;
    plot_counter = 1;
    % Plot component bi-plots
    for comp1 = 1:numComponents,
        for comp2 = comp1+1:numComponents,
            subplot(plot_inds(1),plot_inds(2),plot_counter);
            biplot(coefs(:,[comp1, comp2]), 'scores',score(:,[comp1, comp2]), 'varlabels',level_names);
            set(findobj(gcf,'Type','text'),'FontSize',10)
            box off; grid off;
            xlabel(sprintf('Component %d', comp1));
            ylabel(sprintf('Component %d', comp2));
            plot_counter = plot_counter + 1;
        end
    end
    
    suptitle(area_name{area_ind+1});
    
    figure;
    pareto(explained);
    xlabel('Principal Component');
    ylabel('Variance Explained (%)');
    title(area_name{area_ind+1});
    box off;
end

%% Latent Structure of the neurons
clear all;
drop_path = getappdata(0, 'drop_path');
cd([drop_path, '/GAM Analysis/Rule Response']);
load('neurons.mat');

pfc = logical([neurons.pfc]);
par_est = [neurons.par_est];
baseline_firing = exp(par_est(1,:))*1000;
good_ind = baseline_firing > 0.5;
par_est = exp(par_est(2:end, good_ind));
pfc = pfc(good_ind);

numComponents = 3;
plot_inds = numSubplots(numComponents);
area_name = {'ACC', 'dlPFC'};

% Compute PCA
[coefs,score,latent, ~, explained] = pca(par_est, 'NumComponents', 10);

figure;
plot_counter = 1;
% Plot component bi-plots
for comp1 = 1:numComponents,
    for comp2 = comp1+1:numComponents,
        
        subplot(plot_inds(1),plot_inds(2),plot_counter);
        biplot_groups(coefs(:,[comp1, comp2]), 'scores',score(:,[comp1, comp2]), 'groups', pfc, 'MarkerSize', 20);
        set(findobj(gcf,'Type','text'),'FontSize',10)
        box off; grid off;
        xlabel(sprintf('Component %d', comp1));
        ylabel(sprintf('Component %d', comp2));
        plot_counter = plot_counter + 1;
    end
end

figure;
pareto(explained);
xlabel('Principal Component');
ylabel('Variance Explained (%)');
box off;
