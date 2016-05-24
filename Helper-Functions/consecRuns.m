function [runSize, start_ind, end_ind] = consecRuns(ind)
aux = [0; ind; 0];
start_ind = find(diff(aux) == 1);
end_ind = find(diff(aux) == -1);
runSize = end_ind - start_ind;
end