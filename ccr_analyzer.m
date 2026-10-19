function result = ccr_analyzer(csvFile, outputRoot, showPlots)
% CCR_ANALYZER GPS, speed and lateral-g analyzer. Base MATLAB R2020a+.
% ccr_analyzer() runs a clearly labeled synthetic demo.
% ccr_analyzer('my_run.csv') imports the documented canonical CSV format.
if nargin < 1, csvFile = ''; end
if nargin < 2 || isempty(outputRoot), outputRoot = fullfile(pwd,'results'); end
if nargin < 3, showPlots = true; end
if isempty(csvFile)
    data = ccr_generate_demo();
    source = 'Generated synthetic demo';
else
    if ~isfile(csvFile), error('CCR:File','CSV file not found: %s',csvFile); end
    opts = detectImportOptions(csvFile,'Delimiter',',');
    required = {'time_s','speed_kmh','latitude_deg','longitude_deg','lateral_g','is_synthetic'};
    if ~all(ismember(required,opts.VariableNames))
        error('CCR:Columns','Required headers: %s. See README for units.',strjoin(required,', '));
    end
    opts = setvartype(opts,required,'double');
    data = readtable(csvFile,opts);
    source = char(csvFile);
end
data = ccr_validate(data);
metrics = ccr_metrics(data);
if data.is_synthetic(1) == 1
    label = 'SYNTHETIC DEMO - NOT CAR MEASUREMENTS';
else
    label = 'IMPORTED DATA - USER DECLARED NON-SYNTHETIC';
end
% Each execution gets a new directory; previous results are preserved.
if ~isfolder(outputRoot), mkdir(outputRoot); end
out = tempname(outputRoot); mkdir(out);
writetable(data,fullfile(out,'processed_telemetry.csv'));
writetable(metrics,fullfile(out,'metrics.csv'));
fid = fopen(fullfile(out,'run_info.txt'),'w');
if fid < 0, error('CCR:Export','Cannot create run_info.txt'); end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\nSource: %s\nCreated: %s\n',label,source,datestr(now,31));
fprintf(fid,'Units: seconds, km/h, WGS84 degrees, lateral acceleration in g.\n');
fprintf(fid,'Lateral g is supplied, not calculated from GPS. No smoothing applied.\n');
clear cleanup
fig = ccr_plot(data,label,showPlots);
print(fig,fullfile(out,'dashboard.png'),'-dpng','-r150');
savefig(fig,fullfile(out,'dashboard.fig'));
if ~showPlots, close(fig); end
result = struct('data',data,'metrics',metrics,'outputDirectory',out);
fprintf('\n%s\n',label); disp(metrics);
fprintf('Results saved in: %s\n',out);
end
