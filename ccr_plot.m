function fig = ccr_plot(data,label,showPlots)
% Local equirectangular approximation; no map service or extra toolbox.
visibility = 'off'; if showPlots, visibility = 'on'; end
fig = figure('Name',['CCR Telemetry v1.0 | ' label], ...
    'NumberTitle','off','Color','w','Visible',visibility,'Position',[100 100 1150 760]);
t = data.time_s-data.time_s(1);
a1 = subplot(2,2,1); plot(t,data.speed_kmh,'LineWidth',1.2);
xlabel('Elapsed time (s)'); ylabel('Speed (km/h)'); title('Vehicle speed'); grid on;
a2 = subplot(2,2,2); plot(t,data.lateral_g,'LineWidth',1.2);
xlabel('Elapsed time (s)'); ylabel('Lateral acceleration (g)'); title('Signed cornering g'); grid on;
linkaxes([a1 a2],'x');
R = 6371000; lat0 = data.latitude_deg(1); lon0 = data.longitude_deg(1);
dlon = mod(data.longitude_deg-lon0+180,360)-180;
east = R*cosd(lat0)*deg2rad(dlon);
north = R*deg2rad(data.latitude_deg-lat0);
subplot(2,2,3); plot(east,north,'Color',[.7 .7 .7]); hold on;
scatter(east,north,12,data.speed_kmh,'filled');
plot(east(1),north(1),'go','MarkerSize',9,'LineWidth',2);
plot(east(end),north(end),'rx','MarkerSize',9,'LineWidth',2);
axis equal; grid on; xlabel('East from first fix (m)'); ylabel('North from first fix (m)');
title('GPS path: green start, red end'); cb = colorbar; ylabel(cb,'Speed (km/h)');
subplot(2,2,4); scatter(data.speed_kmh,data.lateral_g,10,t,'filled');
xlabel('Speed (km/h)'); ylabel('Lateral acceleration (g)'); title('Speed vs cornering g'); grid on;
cb = colorbar; ylabel(cb,'Elapsed time (s)');
sgtitle({'Capital College Racing | Telemetry Analyzer v1.0',label},'Interpreter','none');
end
