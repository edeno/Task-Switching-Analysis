function [args] = struct2args(structure)

args = [fieldnames(structure), struct2cell(structure)]';
args = args(:);

end