[~, hostname] = system('hostname');

switch strtrim(hostname)
    case 'cns-ws18'
        setenv('MAIN_DIR', 'C:\Users\edeno\Task Switching Analysis\');
    case 'millerlab'
        setenv('MAIN_DIR', '/data/home/edeno/Task Switching Analysis/');
    case 'Erics-MacBook-Air.local'
        setenv('MAIN_DIR', '/Users/edeno/Documents/Task Switching Analysis/');
    otherwise
        setenv('MAIN_DIR', pwd);
end