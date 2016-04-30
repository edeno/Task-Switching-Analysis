clear variables
main_dir = getWorkingDir();
load(sprintf('%s/paramSet.mat', main_dir), 'sessionNames')
numSessions = length(sessionNames);
neuronInfo = containers.Map();

for session_ind = 1:numSessions,
    fprintf('\nProcessing file %s...\n', sessionNames{session_ind});
    
    session_file = sprintf('%s/Raw Data/%s.sdt', main_dir, sessionNames{session_ind});
    
    fprintf('\tLoading data...\n');
    load('-mat', session_file, 'cells', 'trials');
    for i = 1:length(cells),
        neuronStruct = [];
        neuronStruct.name = sprintf('%s-%d-%d', sessionNames{session_ind}, cells(i).WireNumber, cells(i).UnitNumber);
        fprintf('\t... %s\n', neuronStruct.name);
        neuronStruct.wireNumber = cells(i).WireNumber;
        neuronStruct.unitNumber = cells(i).UnitNumber;
        neuronStruct.sessionName = sessionNames{session_ind};
        neuronStruct.subject = upper(regexprep(sessionNames{session_ind}, '\d+', ''));
        
        %% Find which areas correspond to PFC
        % isa5 is a special case
        if strcmp(sessionNames{session_ind}, 'isa5'),
            if neuronStruct.wireNumber <= 16,
                neuronStruct.brainArea = 'dlPFC';
            else
                neuronStruct.brainArea = 'ACC';
            end
        else
            if neuronStruct.wireNumber <= 8
                neuronStruct.brainArea = 'dlPFC';
            else
                neuronStruct.brainArea = 'ACC';
            end         
        end 
        neuronInfo(neuronStruct.name) = neuronStruct;
    end
end

save(sprintf('%s/paramSet.mat', main_dir), 'neuronInfo', '-append');