function [badFolders, numFiles] = FileNumCheck(data_dir)

cd(data_dir);
folder_list = dir(data_dir);
bad_ind = ~cellfun(@isempty, regexp({folder_list.name}, '(\.)', 'match'));
folder_list(bad_ind) = [];

for cur_folder = 1:length(folder_list),
    cd(folder_list(cur_folder).name);
    files(cur_folder).name = folder_list(cur_folder).name;
    files(cur_folder).numFiles = length(dir('*.mat'));
    cd(data_dir);
end

badFolders_ind = [files.numFiles] < 52;
badFolders = {files(badFolders_ind).name};
numFiles = [files(badFolders_ind).numFiles];

end