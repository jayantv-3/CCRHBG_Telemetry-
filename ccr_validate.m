function data = ccr_validate(data)
% Reject questionable data instead of silently repairing or guessing units.
required = {'time_s','speed_kmh','latitude_deg','longitude_deg','lateral_g','is_synthetic'};
if ~istable(data) || ~all(ismember(required,data.Properties.VariableNames))
    error('CCR:Columns','Missing required columns; see README.');
end
if height(data) < 3, error('CCR:Rows','At least three samples are required.'); end
for k = 1:numel(required)
    x = data.(required{k});
    if ~isnumeric(x) || ~isreal(x) || size(x,2) ~= 1 || any(~isfinite(x))
        error('CCR:Numeric','%s must contain finite numeric values with no blanks.',required{k});
    end
end
if any(diff(data.time_s)<=0) || any(data.time_s<0)
    error('CCR:Time','time_s must be nonnegative and strictly increasing; no duplicate times.');
end
if any(data.speed_kmh<0) || any(data.speed_kmh>300)
    error('CCR:Speed','speed_kmh must be between 0 and 300. Check units.');
end
if any(abs(data.latitude_deg)>90) || any(abs(data.longitude_deg)>180)
    error('CCR:GPS','Latitude must be within +/-90 and longitude within +/-180 degrees.');
end
if any(abs(data.lateral_g)>5)
    error('CCR:G','lateral_g exceeds +/-5 g. Check units, spikes or sensor calibration.');
end
flag = data.is_synthetic;
if any(flag~=0 & flag~=1) || any(flag~=flag(1))
    error('CCR:Provenance','is_synthetic must be consistently 0 or consistently 1.');
end
% Keep the documented columns only, in a stable order.
data = data(:,required);
dt = diff(data.time_s);
if max(dt)>5*median(dt)
    warning('CCR:Gaps','Large time gaps detected; distance integrates across these gaps.');
end
if max(data.latitude_deg)-min(data.latitude_deg)>0.1 || ...
        max(data.longitude_deg)-min(data.longitude_deg)>0.1
    warning('CCR:Extent','GPS extent is large; local path projection may be inaccurate.');
end
if any(data.latitude_deg==0 & data.longitude_deg==0)
    warning('CCR:GPSZero','GPS includes (0,0); confirm a valid fix before using the path.');
end
end
