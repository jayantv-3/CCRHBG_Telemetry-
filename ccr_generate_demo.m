function data = ccr_generate_demo()
% Deterministic 120-second circular demonstration, sampled at 10 Hz.
% Position, speed and lateral g are consistent with an ideal flat circle.
t = (0:0.1:120)';
radius = 45; earthRadius = 6371000;
v = 10 + 3*sin(2*pi*t/30); % m/s, always positive
angle = cumtrapz(t,v/radius);
east = radius*cos(angle); north = radius*sin(angle);
lat0 = 40; lon0 = -77; % Arbitrary origin, not a surveyed CCR track.
latitude = lat0 + rad2deg(north/earthRadius);
longitude = lon0 + rad2deg(east/(earthRadius*cosd(lat0)));
lateral = v.^2/(radius*9.80665); % Positive = left turn in this demo.
data = table(t,v*3.6,latitude,longitude,lateral,ones(size(t)), ...
    'VariableNames',{'time_s','speed_kmh','latitude_deg','longitude_deg','lateral_g','is_synthetic'});
end
