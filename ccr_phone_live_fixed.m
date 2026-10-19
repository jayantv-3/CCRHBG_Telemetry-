function ccr_phone_live_fixed(phoneURL)
% Live phone speed, lateral-g and local GPS path snapshot viewer. Base MATLAB R2020a+.
% Run: ccr_phone_live_fixed('http://YOUR-PHONE-ADDRESS')
% Requires one active phyphox experiment with GPS + linear acceleration.
% This polls latest values, not the complete 50 Hz sensor recording.
if nargin<1
    answer=inputdlg('Exact phyphox address from the laptop browser:', ...
        'Connect to phone',1,{'http://66.71.55.171'});
    if isempty(answer), return; end
    phoneURL=answer{1};
end
phoneURL=regexprep(strtrim(char(phoneURL)),'/+$','');
opts=weboptions('ContentType','json','Timeout',5);
try
    config=webread([phoneURL '/config'],opts);
catch err
    error('CCR:Connection','Cannot connect. Keep phyphox remote access on and check the full browser address. Details: %s',err.message);
end
% Configuration provides names without assuming a particular experiment.
buffers=config.buffers;
if iscell(buffers), buffers=[buffers{:}]; end
names={buffers.name};
if isempty(names), error('CCR:Channels','No sensor channels available.'); end
% Names verified from the user's phyphox configuration screenshot.
speedName='gpsV'; accName='lin_accX'; latName='gpsLat'; lonName='gpsLon';
required={speedName,accName,latName,lonName};
if ~all(ismember(required,names))
    error('CCR:Channels','Open the phyphox experiment containing GPS and Linear Acceleration. Required channels: gpsV, lin_accX, gpsLat, gpsLon.');
end
showMap=true;
fprintf('Channels: speed gpsV, lateral acceleration lin_accX, GPS gpsLat/gpsLon.\n');
fprintf('Mount phone flat, screen up, top toward vehicle front for lateral X.\n');
fig=figure('Name','CCR | Live phone telemetry','NumberTitle','off','Color','w');
if showMap
    a1=subplot(2,2,1); a2=subplot(2,2,3);
else
    a1=subplot(2,1,1); a2=subplot(2,1,2);
end
 speedLine=animatedline(a1,'Color',[0 .4 .8],'MaximumNumPoints',600);
grid(a1,'on'); ylabel(a1,'Speed (km/h)'); xlabel(a1,'Laptop elapsed time (s)');
gLine=animatedline(a2,'Color',[.8 .2 .1],'MaximumNumPoints',600);
grid(a2,'on'); ylabel(a2,'Lateral acceleration (g)'); xlabel(a2,'Laptop elapsed time (s)');
if showMap
    mapAxes=subplot(2,2,[2 4]);
    pathLine=animatedline(mapAxes,'Color',[0 .5 .3],'LineWidth',1.5);
    hold(mapAxes,'on');
    currentPoint=plot(mapAxes,NaN,NaN,'ro','MarkerFaceColor','r');
    grid(mapAxes,'on'); axis(mapAxes,'equal');
    xlabel(mapAxes,'East from first fix (m)'); ylabel(mapAxes,'North from first fix (m)');
    title(mapAxes,{'Phone GPS path','Waiting for coordinates - local approximation'});
end
lat0=NaN; lon0=NaN; previousPosition=[NaN NaN];
heading=sgtitle('Waiting for phone - press Play in phyphox');
query=[phoneURL '/get?' urlencode(speedName) '&' urlencode(accName)];
if showMap
    query=[query '&' urlencode(latName) '&' urlencode(lonName)];
end
clockStart=tic; session=''; failures=0;
fprintf('Live viewer: close figure to stop. Phone recording is controlled in phyphox.\n');
fprintf('Latest-value snapshots at about 5 polls/s; time is laptop elapsed time.\n');
while isgraphics(fig)
    try
        reply=webread(query,opts);
    catch err
        if ~isgraphics(fig), break; end
        failures=failures+1;
        heading.String='CONNECTION LOST - no fresh readings';
        addpoints(speedLine,toc(clockStart),NaN); addpoints(gLine,toc(clockStart),NaN);
        drawnow;
        if failures>=3
            warning('CCR:Disconnected','Stopped after three failed requests: %s',err.message); break;
        end
        pause(.2); continue;
    end
    if ~isgraphics(fig), break; end
    failures=0;
    newSession=char(reply.status.session);
    if isempty(session), session=newSession; end
    if ~strcmp(session,newSession)
        heading.String='PHONE EXPERIMENT CHANGED - restart viewer'; break;
    end
    t=toc(clockStart);
    if reply.status.measuring
        speed=lastValue(reply.buffer,speedName);
        accel=lastValue(reply.buffer,accName);
        if speed<0, speed=NaN; end % GPS unavailable indicator is not vehicle speed.
        addpoints(speedLine,t,speed*3.6);
        addpoints(gLine,t,accel/9.80665);
        if showMap
            latitude=lastValue(reply.buffer,latName); longitude=lastValue(reply.buffer,lonName);
            valid=isfinite(latitude) && isfinite(longitude) && abs(latitude)<85 && ...
                abs(longitude)<=180 && ~(latitude==0 && longitude==0);
            if valid
                if isnan(lat0), lat0=latitude; lon0=longitude; end
                dlon=mod(longitude-lon0+180,360)-180;
                east=6371000*cosd(lat0)*deg2rad(dlon);
                north=6371000*deg2rad(latitude-lat0);
                if any(previousPosition~=[latitude longitude])
                    addpoints(pathLine,east,north);
                    previousPosition=[latitude longitude];
                end
                set(currentPoint,'XData',east,'YData',north);
                title(mapAxes,{'Phone GPS path - local approximation','Red dot: latest received position'});
            else
                title(mapAxes,{'Phone GPS path','No usable coordinates received'});
            end
        end
        heading.String=sprintf('LIVE snapshots | Speed %.1f km/h | Lateral %.3f g',speed*3.6,accel/9.80665);
    else
        addpoints(speedLine,t,NaN); addpoints(gLine,t,NaN);
        heading.String='PAUSED on phone - press Play in phyphox';
    end
    xlim(a1,[max(0,t-60) max(60,t)]); xlim(a2,[max(0,t-60) max(60,t)]);
    drawnow limitrate;
    pause(.2);
end
end
function value=lastValue(buffers,name)
% MATLAB changes JSON object keys to valid structure field names.
key=matlab.lang.makeValidName(name);
value=NaN;
if ~isfield(buffers,key), return; end
x=buffers.(key).buffer;
if isnumeric(x) && ~isempty(x) && isfinite(x(end)), value=double(x(end)); end
end
