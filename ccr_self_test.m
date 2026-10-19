function ccr_self_test()
% Base-MATLAB acceptance tests: demo, CSV round trip, export and bad inputs.
data = ccr_validate(ccr_generate_demo());
assert(height(data)==1201);
m = ccr_metrics(data);
assert(abs(m.value(strcmp(m.metric,'duration'))-120)<1e-9);
assert(abs(m.value(strcmp(m.metric,'speed_integrated_distance'))-1200)<1e-7);
assert(abs(max(data.speed_kmh)-46.8)<1e-9);
assert(abs(max(data.lateral_g)-169/(45*9.80665))<1e-9);
root = tempname; mkdir(root); cleanup = onCleanup(@() rmdir(root,'s'));
csv = fullfile(root,'demo.csv'); writetable(data,csv);
r = ccr_analyzer(csv,root,false);
assert(max(abs(r.data.speed_kmh-data.speed_kmh))<1e-8);
assert(isfile(fullfile(r.outputDirectory,'dashboard.png')));
assert(isfile(fullfile(r.outputDirectory,'dashboard.fig')));
assert(isfile(fullfile(r.outputDirectory,'metrics.csv')));
assert(isfile(fullfile(r.outputDirectory,'run_info.txt')));
bad = data; bad.time_s(2)=bad.time_s(1); expectError(bad,'CCR:Time');
bad = data; bad.speed_kmh(2)=-1; expectError(bad,'CCR:Speed');
bad = data; bad.lateral_g(2)=NaN; expectError(bad,'CCR:Numeric');
bad = data; bad.latitude_deg(2)=91; expectError(bad,'CCR:GPS');
bad = data; bad.lateral_g(2)=6; expectError(bad,'CCR:G');
bad = data; bad.is_synthetic(2)=0; expectError(bad,'CCR:Provenance');
bad = data(:,1:5); expectError(bad,'CCR:Columns');
fprintf('CCR acceptance tests passed.\n');
end
function expectError(data,id)
try
    ccr_validate(data);
catch exception
    assert(strcmp(exception.identifier,id),'Unexpected error: %s',exception.message);
    return
end
error('CCR:Test','Expected error %s was not raised.',id);
end
