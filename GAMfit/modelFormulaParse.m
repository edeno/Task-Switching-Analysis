function [model] = modelFormulaParse(model_str)

% Expand shortcuts to create terms
addTerms = strtrim(regexp(model_str, '+', 'split'));

% Figure out if there's smoothing
parsedTerms = strtrim(regexp(addTerms, ',', 'split'));
isSmooth_add = cellfun(@(x) ~isempty(regexp(x{1}, 's\(.*', 'match')), parsedTerms, 'UniformOutput', false);
isSmooth_add = [isSmooth_add{:}];

% Strip any smooth function syntax
parsedTerms = cellfun(@(x) regexprep(x, '(s\()|(\))|(,.*)', ''), parsedTerms, 'UniformOutput', false);

addTerms = cellfun(@(x) x{1}, parsedTerms, 'UniformOutput', false);

hasSmoothParams = cellfun(@(x) length(x) > 1, parsedTerms, 'UniformOutput', false);
hasSmoothParams = [hasSmoothParams{:}];

parsedTerms = cellfun(@(x) x(2:end), parsedTerms, 'UniformOutput', false);

smoothParams_opt = [];
smoothingTerm = [];

% Parse for interactions within additive terms
isInteraction = cellfun(@(x) ~isempty(strfind(x, '*')), addTerms);

modelTerms = [];
modelOrder = [];
isSmooth = [];

for add_ind = 1:length(addTerms),
    
    if isInteraction(add_ind)
        % Deal with * shorthand notation for interactions
        interTerms = strtrim(regexp(addTerms{add_ind}, '*', 'split'));
        numInterTerms = length(interTerms);
        combs = [];
        for comb_ind = 1:numInterTerms,
            str_ind = nchoosek(1:numInterTerms, comb_ind);
            combs = [combs; num2cell(str_ind, 2)];
        end
        
        interTerms = cellfun(@(x) interTerms(x), combs, 'UniformOutput', false);
        order = cellfun(@(x) length(x), interTerms, 'UniformOutput', false);
        order = [order{:}]';
        for order_ind = 1:length(order),
            if order(order_ind) > 1
                new_term = cell(1, 2*order(order_ind)-1);
                new_term(1:2:end) = interTerms{order_ind};
                new_term(2:2:end) = {':'};
                new_term = {strcat(new_term{:})};
                interTerms(order_ind) = {new_term};
            end
        end
        
        modelTerms = [modelTerms; cellfun(@(x) x{:}, interTerms, 'UniformOutput', false)];
        modelOrder = [modelOrder; order];
        isSmooth = [isSmooth; isSmooth_add(add_ind)*ones(size(interTerms))];
        
        if hasSmoothParams(add_ind),
            parsedTerms_add = parsedTerms{add_ind};
            parsedTerms_add = strtrim(regexp(parsedTerms_add, '=', 'split'));
            numSmoothParams_add = cellfun(@(x) length(x), parsedTerms_add, 'UniformOutput', false);
            numSmoothParams_add = [numSmoothParams_add{:}];
            
            smoothParams_opt_add = {parsedTerms_add{numSmoothParams_add > 1}};
            if ~isempty(smoothParams_opt_add)
                if mod(length([smoothParams_opt_add{:}]), 2) ~= 0,
                    error(['Error: smoothing term ', addTerms{add_ind}, 'is parameterized incorrectly']);
                end
                for add_opts_ind = 1:length(smoothParams_opt_add),
                    smoothParams_opt_add{add_opts_ind}{2} = str2num(smoothParams_opt_add{add_opts_ind}{2}); %#ok<ST2NM>
                end
                smoothParams_opt_add = [smoothParams_opt_add{:}];
            end
            if any(numSmoothParams_add == 1),
                smoothingTerm = [smoothingTerm; repmat(parsedTerms_add{numSmoothParams_add == 1}, size(interTerms))];
            else
                smoothingTerm = [smoothingTerm; cell(size(interTerms))];
            end
            
            if any(numSmoothParams_add > 1),
                smoothParams_opt = [smoothParams_opt; repmat({smoothParams_opt_add}, size(interTerms))];
            else
                smoothParams_opt = [smoothParams_opt; cell(size(interTerms))];
            end
        else
            smoothParams_opt = [smoothParams_opt; cell(size(interTerms))];
            smoothingTerm = [smoothingTerm; cell(size(interTerms))];
        end
    else
        modelTerms = [modelTerms; addTerms(add_ind)];
        modelOrder = [modelOrder; length(strfind(addTerms{add_ind}, ':'))+1];
        isSmooth = [isSmooth; isSmooth_add(add_ind)];
        
        if hasSmoothParams(add_ind),
            parsedTerms_add = strtrim(regexp(parsedTerms{add_ind}, '=', 'split'));
            numSmoothParams_add = cellfun(@(x) length(x), parsedTerms_add, 'UniformOutput', false);
            numSmoothParams_add = [numSmoothParams_add{:}];
            
            smoothParams_opt_add = {parsedTerms_add{numSmoothParams_add > 1}};
            if ~isempty(smoothParams_opt_add)
                if mod(length([smoothParams_opt_add{:}]), 2) ~= 0,
                    error(['Error: smoothing term ', addTerms{add_ind}, 'is parameterized incorrectly']);
                end
                for add_opts_ind = 1:length(smoothParams_opt_add),
                    smoothParams_opt_add{add_opts_ind}{2} = str2num(smoothParams_opt_add{add_opts_ind}{2}); %#ok<ST2NM>
                end
                smoothParams_opt_add = [smoothParams_opt_add{:}];
            end
            
            if any(numSmoothParams_add == 1),
                smoothingTerm = [smoothingTerm; parsedTerms_add{numSmoothParams_add == 1}];
            else
                if isSmooth_add(add_ind),
                    smoothingTerm = [smoothingTerm; addTerms(add_ind)];
                else
                    smoothingTerm = [smoothingTerm; {[]}];
                end
            end
            
            if any(numSmoothParams_add > 1)
                smoothParams_opt = [smoothParams_opt; {smoothParams_opt_add}];
            else
                smoothParams_opt = [smoothParams_opt; {[]}];
            end
        else
            smoothParams_opt = [smoothParams_opt; {[]}];
            if isSmooth_add(add_ind),
                smoothingTerm = [smoothingTerm; addTerms(add_ind)];
            else
                smoothingTerm = [smoothingTerm; {[]}];
            end
            
        end
    end
end

% Make sure isSmooth is a logical
isSmooth = logical(isSmooth);

% Reorder terms by order
[~, sort_ind] = sort(modelOrder);
modelTerms = modelTerms(sort_ind);
isSmooth = isSmooth(sort_ind);
smoothParams_opt = smoothParams_opt(sort_ind, :);
smoothingTerm = smoothingTerm(sort_ind);
try % 'stable' is only works for matlab 2012a and beyond
    [model.terms, unique_ind] = unique(modelTerms, 'stable');
catch
    [~, unique_ind] = unique(modelTerms);
    model.terms = modelTerms(sort(unique_ind));
end
model.isSmooth = isSmooth(unique_ind);
model.smoothParams_opt = smoothParams_opt(unique_ind, :);
model.smoothingTerm = smoothingTerm(unique_ind);
model.isInteraction = cellfun(@(x) ~isempty(x), strfind(model.terms, ':'));

end