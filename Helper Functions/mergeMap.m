function [mergedMap] = mergeMap(maps)

allKeys  = cellfun(@keys, maps, 'UniformOutput', false);
allKeys = unique([allKeys{:}]);
allValues0 = cellfun(@values, maps, 'UniformOutput', false);
allValues0 = cat(1, allValues0{:});
for k = 1:size(allValues0, 2),
    allValues{k} = cat(1, allValues0{:,k});
end

mergedMap = containers.Map(allKeys, allValues);

end