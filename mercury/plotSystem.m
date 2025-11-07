% plotSystem(filepath, dt)
% - filepath : 외부 instant 출력 파일 경로 (예: 'output 9.txt')
% - dt       : 내부 적분 간격(초). 미지정 시 10*86400 (10일)
%
% UI
% - 하단 시간 슬라이더(드래그 실시간)
% - 우측 세로 로그-줌 슬라이더(축 ±AU)
% - 토글: Comet / Asteroid / C/A Labels / Center: Origin<->Sat
%
% 의존 함수(사용자 환경 제공): InitialSetup, Conic, IVP, K2S, S2K

function fig = plotSystem(filepath, dt)
    arguments
        filepath 
        dt (1,1) {mustBeReal, mustBePositive} = 10*86400
    end

    %% ===================== 데이터/궤도/궤적 ================================
    [data,indices,const] = InitialSetup();

    conic.Planet   = Conic([data(indices.Planet).K0]') ;
    conic.Asteroid = Conic([data(indices.Asteroid).K0]') ;
    conic.Comet    = Conic([data(indices.Comet).K0]') ;

    % 외부 출력(instant)
    M = readmatrix(filepath, 'Delimiter', ',', 'OutputType', 'double');
    t_output_inst = M(:,3)';                    % 1 x N_inst
    S_output_inst = M(:,4:9)';                  % 6 x N_inst

    t0 = t_output_inst(1);
    mu = const.GM;
    tf = 200 * const.Year * const.Day;

    % 내부 적분 타임라인
    t   = t0:dt:tf;                             % 1 x N
    idxAll = indices.all;
    Nb  = numel(idxAll);
    N   = numel(t);

    function posAll = load_or_calculate_posAll()
        path_cache = "mercury/plotSystem-cache.mat";
        if isfile(path_cache)
            loaded = load(path_cache);
            if loaded.t0 == t0 && loaded.dt == dt
                posAll = loaded.posAll;
                fprintf("Loaded cached posAll from %s.\n", path_cache);
                return;
            end
        end

        K0  = [data(idxAll).K0]';
        K   = IVP(K0, t, mu);
        S   = K2S(K,  mu);

        % posAll: 3 x N x Nb
        S6      = reshape(S, 6, Nb, N);            % 6 x Nb x N
        posAll  = permute(S6(1:3,:,:), [1 3 2]);   % 3 x N x Nb

        save(path_cache, 't0', 'dt', 'posAll');
    end

    posAll = load_or_calculate_posAll();

    % global→local 인덱스
    loc.Planet   = arrayfun(@(g) find(idxAll==g,1), indices.Planet);
    loc.Comet    = arrayfun(@(g) find(idxAll==g,1), indices.Comet);
    loc.Asteroid = arrayfun(@(g) find(idxAll==g,1), indices.Asteroid);

    % 행성 이름
    namesAll = arrayfun(@(i) data(idxAll(i)).Name, 1:Nb, 'UniformOutput', false);

    % 외부 instant → 공통 타임라인 전개 (위성 궤적)
    K_output_inst = S2K(S_output_inst, mu);
    trefIdx = discretize(t, [t_output_inst inf]);

    K_output = zeros(6, N);
    for ii = 1:N
        K_output(:,ii) = IVP(K_output_inst(:,trefIdx(ii)), ...
                             t(ii) - t_output_inst(trefIdx(ii)), mu);
    end
    S_output = K2S(K_output, mu);              % 6 x N
    S_outPos = S_output(1:3,:);                % 3 x N

    %% ===================== 피겨/좌표평면/초기 뷰 ===========================
    a0  = 200;  amin = 1; amax = 200;
    lim = const.AU * a0;
    [Xp,Yp] = meshgrid(lim*[-1 1], lim*[-1 1]); Zp = zeros(size(Xp));

    fig = figure('Color','k');
    ax  = axes('Parent',fig);

    hold(ax,'on'); grid(ax,'on'); axis(ax,'equal'); axis(ax,'off'); axis(ax,'vis3d');
    rotate3d(ax,'on'); view(ax,3)
    xlim(ax, lim*[-1 1]); ylim(ax, lim*[-1 1]); zlim(ax, lim*[-1 1]);

    surf(ax, Xp, Yp, Zp, 'FaceAlpha',0.7, 'EdgeColor','none', ...
        'FaceColor',.1*[1 1 1], 'HitTest','off', 'PickableParts','none', 'Clipping','on');
    set(ax,'Position', [-(2-1)/2  -(2-1)/2  2  2]);   % 캔버스 채우기

    % 상태(appdata)
    setappdata(fig,'centerOnSat', false);
    setappdata(fig,'labelsOn',     false);        % C/A 라벨 토글 상태
    setappdata(fig,'C_labels',     gobjects(0));  % Comet 라벨 핸들
    setappdata(fig,'A_labels',     gobjects(0));  % Asteroid 라벨 핸들
    setappdata(fig,'tidx',         1);
    setappdata(fig,'zoom_amin',    amin);
    setappdata(fig,'zoom_amax',    amax);
    setappdata(fig,'S_outPos',     S_outPos);

    %% ===================== 궤도선(정적, batch) =============================
    orbP = buildOrbitBatch(conic.Planet);
    orbC = buildOrbitBatch(conic.Comet);
    orbA = buildOrbitBatch(conic.Asteroid);

    hP.orb = line(ax, 'XData',orbP(1,:), 'YData',orbP(2,:), 'ZData',orbP(3,:), ...
        'Color','r', 'LineStyle','-', 'Clipping','on');
    bl = [0 0 1 0.7];
    hC.orb = line(ax, 'XData',orbC(1,:), 'YData',orbC(2,:), 'ZData',orbC(3,:), ...
        'Color',bl, 'LineStyle','-', 'Clipping','on');
    gl    = [0 1 0 0.1];
    hA.orb = line(ax, 'XData',orbA(1,:), 'YData',orbA(2,:), 'ZData',orbA(3,:), ...
        'Color',gl, 'LineStyle','-', 'Clipping','on');

    %% ===================== 동적 객체(그룹당 pos/proj/px) ===================
    tidx0 = 1;

    % Planet
    p0 = posAll(:,tidx0,loc.Planet);
    [hP.pos, hP.proj, hP.px] = makeDynamicBatch(ax, p0, 'r');

    % Planet 라벨(이름) — onSeek에서 매 프레임 위치 갱신
    hP.name = gobjects(1,numel(loc.Planet));
    for i=1:numel(loc.Planet)
        p = p0(:,i);
        hP.name(i) = text(ax,p(1),p(2),p(3),namesAll{loc.Planet(i)}, ...
            'Color','w','VerticalAlignment','top','HorizontalAlignment','center', ...
            'HitTest','off','PickableParts','none','Clipping','on');
    end

    % Comet
    c0 = posAll(:,tidx0,loc.Comet);
    [hC.pos, hC.proj, hC.px] = makeDynamicBatch(ax, c0, bl);
    set([hC.orb, hC.pos, hC.proj, hC.px], 'Visible', 'off');

    % Asteroid
    a0pos = posAll(:,tidx0,loc.Asteroid);
    [hA.pos, hA.proj, hA.px] = makeDynamicBatch(ax, a0pos, gl);
    set([hA.orb, hA.pos, hA.proj, hA.px], 'Visible', 'off');

    % 위성 궤적(흰색, 전체 경로 + 현재점/투영)
    plot3(ax, S_outPos(1,:), S_outPos(2,:), S_outPos(3,:), 'w-', 'LineWidth',1.0, ...
        'HitTest','off','PickableParts','none','Clipping','on');
    sp = S_outPos(:,tidx0);
    [hS.pos, hS.proj, hS.px] = makeDynamicBatch(ax, sp, 'w');

    %% ===================== 상단 표시 ======================================
    timeDisp  = annotation(fig,'textbox','String','00Y 000d', ...
        'Position',[0.01 0.95 0.30 0.05], 'FontSize',10,'FontName','Consolas', ...
        'Color','w','EdgeColor','none','HorizontalAlignment','left');
    scaleDisp = annotation(fig,'textbox','String',sprintf('±%.0f AU',a0), ...
        'Position',[0.85 0.05 0.12 0.04], 'FontSize',10,'FontName','Consolas', ...
        'Color','w','EdgeColor','none','HorizontalAlignment','right');

    %% ===================== UI: 슬라이더/토글 ===============================
    % 시간 슬라이더(기본 uicontrol, 드래그 실시간)
    tline = uicontrol(fig, 'Style','slider', 'Units','normalized', ...
        'Position',[0.12 0.03 0.74 0.03], ...
        'Min',1, 'Max',max(1,N), 'Value',1, ...
        'SliderStep',[1/max(1,N-1)  min(1,10/max(1,N-1))], ...
        'Callback', @(h,~) onSeek(h, posAll, loc, hP,hC,hA, hS, timeDisp, t, ...
                                  S_outPos, fig, ax, scaleDisp, const.AU, indices));
    tlist = addlistener(tline,'Value','PostSet', ...
        @(~,evt) onSeek(evt.AffectedObject, posAll, loc, hP,hC,hA, hS, timeDisp, t, ...
                        S_outPos, fig, ax, scaleDisp, const.AU, indices));
    setappdata(fig,'tline_listener', tlist);

    % 줌 슬라이더(세로, 로그 스케일)
    z_sld = uicontrol(fig,'Style','slider','Units','normalized', ...
        'Position',[0.94 0.12 0.02 0.75], ...
        'Min',0, 'Max',1, 'Value', a2v(a0, amin, amax), ...
        'Callback', @(h,~) recomputeLimits(fig, ax, scaleDisp, const.AU, h));
    zlist = addlistener(z_sld,'Value','PostSet', ...
        @(~,evt) recomputeLimits(fig, ax, scaleDisp, const.AU, evt.AffectedObject));
    setappdata(fig,'zoom_listener', zlist);
    setappdata(fig,'z_sld', z_sld);
    recomputeLimits(fig, ax, scaleDisp, const.AU, z_sld);  % 초기 동기화

    % 표시 토글: Comet / Asteroid
    uicontrol(fig,'Style','togglebutton','Units','normalized', ...
        'Position',[0.85 0.86 0.08 0.035], 'String','Comet', 'Value',0, ...
        'BackgroundColor',[0.15 0.15 0.2], 'ForegroundColor','w', ...
        'Callback', @(h,~) onToggleGroup(h, hC, fig, 'C'));
    uicontrol(fig,'Style','togglebutton','Units','normalized', ...
        'Position',[0.85 0.82 0.08 0.035], 'String','Asteroid', 'Value',0, ...
        'BackgroundColor',[0.15 0.15 0.2], 'ForegroundColor','w', ...
        'Callback', @(h,~) onToggleGroup(h, hA, fig, 'A'));

    % 라벨 토글: C/A 인덱스
    uicontrol(fig,'Style','togglebutton','Units','normalized', ...
        'Position',[0.85 0.90 0.08 0.035], 'String','C/A Labels: OFF', 'Value',0, ...
        'BackgroundColor',[0.15 0.15 0.2], 'ForegroundColor','w', ...
        'Callback', @(h,~) onToggleLabels(h, ax, hC, hA, indices, loc, fig));

    % 중심 토글: Origin <-> Sat
    uicontrol(fig,'Style','togglebutton','Units','normalized', ...
        'Position',[0.85 0.78 0.08 0.035], 'String','Center: Origin', 'Value',0, ...
        'BackgroundColor',[0.15 0.15 0.2], 'ForegroundColor','w', ...
        'Callback', @(h,~) onToggleCenter(h, fig, ax, scaleDisp, const.AU));

end % ====== main function end ======


%% ============================ 로컬 함수들 ================================
function B = buildOrbitBatch(C)
    if isempty(C)
        B = zeros(3,0);
        return;
    end
    nOrbit = size(C,1)/3;
    X=[];Y=[];Z=[];
    for i=1:nOrbit
        seg = C((1:3)+3*(i-1),:);
        X = [X, seg(1,:), NaN];
        Y = [Y, seg(2,:), NaN];
        Z = [Z, seg(3,:), NaN];
    end
    B = [X;Y;Z];
end

function [hPos, hProj, hPX] = makeDynamicBatch(ax, P, col)
    if isempty(P)
        hPos = line(); hProj = line(); hPX = line();
        return;
    end
    x = P(1,:); y = P(2,:); z = P(3,:);
    hPos = line(ax, 'XData',x, 'YData',y, 'ZData',z, ...
        'LineStyle','none', 'Marker','.', 'Color',col, ...
        'MarkerSize',12, 'HitTest','off','PickableParts','none','Clipping','on');
    [Xp,Yp,Zp] = projSegments(x,y,z);
    hProj = line(ax, 'XData',Xp, 'YData',Yp, 'ZData',Zp, ...
        'LineStyle','-', 'Color',col, 'HitTest','off','PickableParts','none','Clipping','on');
    hPX = line(ax, 'XData',x, 'YData',y, 'ZData',zeros(size(z)), ...
        'LineStyle','none', 'Marker','x', 'Color',col, ...
        'HitTest','off','PickableParts','none','Clipping','on');
end

function [Xp,Yp,Zp] = projSegments(x,y,z)
    M = numel(x);
    Xp = reshape([x; x; nan(1,M)], 1, []);
    Yp = reshape([y; y; nan(1,M)], 1, []);
    Zp = reshape([z; zeros(1,M); nan(1,M)], 1, []);
end

function onSeek(h, posAll, loc, hP,hC,hA, hS, timeDisp, t, S_outPos, fig, ax, scaleDisp, AU, indices)
    N = size(posAll, 2);
    tidx = round(get(h,'Value'));
    tidx = max(1, min(N, tidx));
    setappdata(fig,'tidx', tidx);

    upd = @(H, idx) updateBatch(H, posAll(:,tidx,idx));
    if ~isempty(loc.Planet),   upd(hP, loc.Planet);   end
    if ~isempty(loc.Comet),    upd(hC, loc.Comet);    end
    if ~isempty(loc.Asteroid), upd(hA, loc.Asteroid); end

    updatePlanetLabelPositions(hP);

    sp = S_outPos(:,tidx);
    updateBatch(hS, sp);

    labelsOn = getappdata(fig,'labelsOn');
    if labelsOn && groupVisible(hC)
        ensureLabels(fig, ax, 'C', hC.pos, indices.Comet,   loc.Comet);
        updateLabelPositions(fig, 'C', hC.pos);
        setVisibleArray(getappdata(fig,'C_labels'), 'on');
    else
        setVisibleArray(getappdata(fig,'C_labels'), 'off');
    end
    if labelsOn && groupVisible(hA)
        ensureLabels(fig, ax, 'A', hA.pos, indices.Asteroid, loc.Asteroid);
        updateLabelPositions(fig, 'A', hA.pos);
        setVisibleArray(getappdata(fig,'A_labels'), 'on');
    else
        setVisibleArray(getappdata(fig,'A_labels'), 'off');
    end

    [YY,dd] = sec2YYdd_3n1l(t(tidx));
    timeDisp.String = sprintf('%03.0fY %03.0fd', YY, dd);

    z_sld = getappdata(fig,'z_sld');
    recomputeLimits(fig, ax, scaleDisp, AU, z_sld);

    drawnow limitrate
end

function updateBatch(H, P)
    if isempty(P)
        if isgraphics(H.pos),  set(H.pos,'Visible','off');  end
        if isgraphics(H.proj), set(H.proj,'Visible','off'); end
        if isgraphics(H.px),   set(H.px,'Visible','off');   end
        return;
    end
    x = P(1,:); y = P(2,:); z = P(3,:);
    if isgraphics(H.pos)
        set(H.pos,  'XData',x, 'YData',y, 'ZData',z);
    end
    if isgraphics(H.proj)
        [Xp,Yp,Zp] = projSegments(x,y,z);
        set(H.proj, 'XData',Xp, 'YData',Yp, 'ZData',Zp);
    end
    if isgraphics(H.px)
        set(H.px,   'XData',x, 'YData',y, 'ZData',zeros(size(z)));
    end
end

function updatePlanetLabelPositions(hP)
    if ~isfield(hP,'name') || isempty(hP.name)
        return;
    end
    [x,y,z] = getXYZ(hP.pos);
    n = min(numel(hP.name), numel(x));
    for i = 1:n
        set(hP.name(i), 'Position', [x(i), y(i), z(i)]);
    end
end

function onToggleGroup(hToggle, H, fig, tag)
    vis = 'on';
    if get(hToggle,'Value')==0
        vis = 'off';
    end
    fields = {'orb','pos','proj','px'};
    for f = 1:numel(fields)
        fn = fields{f};
        if isfield(H,fn) && isgraphics(H.(fn))
            set(H.(fn),'Visible',vis);
        end
    end
    if strcmpi(tag,'C')
        setVisibleArray(getappdata(fig,'C_labels'), vis);
    elseif strcmpi(tag,'A')
        setVisibleArray(getappdata(fig,'A_labels'), vis);
    end
end

function onToggleLabels(h, ax, hC, hA, indices, loc, fig)
    want = get(h,'Value')==1;
    setappdata(fig,'labelsOn', want);
    if want
        set(h,'String','C/A Labels: ON');
        if groupVisible(hC)
            ensureLabels(fig, ax, 'C', hC.pos, indices.Comet,   loc.Comet);
            updateLabelPositions(fig, 'C', hC.pos);
            setVisibleArray(getappdata(fig,'C_labels'), 'on');
        end
        if groupVisible(hA)
            ensureLabels(fig, ax, 'A', hA.pos, indices.Asteroid, loc.Asteroid);
            updateLabelPositions(fig, 'A', hA.pos);
            setVisibleArray(getappdata(fig,'A_labels'), 'on');
        end
    else
        set(h,'String','C/A Labels: OFF');
        setVisibleArray(getappdata(fig,'C_labels'), 'off');
        setVisibleArray(getappdata(fig,'A_labels'), 'off');
    end
end

function tf = groupVisible(H)
    tf = true;
    if isfield(H,'pos') && isgraphics(H.pos)
        tf = strcmpi(get(H.pos,'Visible'),'on');
    end
end

function ensureLabels(fig, ax, tag, hPos, indexArray, idxList)
    key = sprintf('%s_labels', tag);
    hLab = getappdata(fig, key);
    [x,y,z] = getXYZ(hPos);
    n = min(numel(idxList), numel(x));

    needCreate = isempty(hLab) || any(~isgraphics(hLab)) || numel(hLab)~=n;
    if needCreate
        if ~isempty(hLab)
            for i = 1:numel(hLab)
                if isgraphics(hLab(i))
                    delete(hLab(i));
                end
            end
        end
        hNew = gobjects(1,n);
        for i = 1:n
            hNew(i) = text(ax, x(i), y(i), z(i), num2str(indexArray(i)), ...
                'Color','w','VerticalAlignment','top','HorizontalAlignment','center', ...
                'HitTest','off','PickableParts','none','Clipping','on','Visible','off');
        end
        setappdata(fig, key, hNew);
    end
end

function updateLabelPositions(fig, tag, hPos)
    key = sprintf('%s_labels', tag);
    hLab = getappdata(fig, key);
    if isempty(hLab) || any(~isgraphics(hLab))
        return;
    end
    [x,y,z] = getXYZ(hPos);
    m = min(numel(hLab), numel(x));
    for i = 1:m
        set(hLab(i), 'Position', [x(i), y(i), z(i)]);
    end
end

function setVisibleArray(hArr, vis)
    if isempty(hArr)
        return;
    end
    for i = 1:numel(hArr)
        if isgraphics(hArr(i))
            set(hArr(i),'Visible',vis);
        end
    end
end

function [x,y,z] = getXYZ(hPos)
    x = get(hPos,'XData'); 
    y = get(hPos,'YData'); 
    z = get(hPos,'ZData');
    if iscell(x)
        x = x{1}; y = y{1}; z = z{1};
    end
end

function onToggleCenter(h, fig, ax, scaleDisp, AU)
    isSat = get(h,'Value')==1;
    set(h,'String', tern(isSat,'Center: Sat','Center: Origin'));
    setappdata(fig,'centerOnSat', isSat);
    z_sld = getappdata(fig,'z_sld');
    recomputeLimits(fig, ax, scaleDisp, AU, z_sld);
end

function recomputeLimits(fig, ax, scaleDisp, AU, z_sld)
    amin = getappdata(fig,'zoom_amin'); 
    amax = getappdata(fig,'zoom_amax');
    a = v2a(get(z_sld,'Value'), amin, amax);

    centerOnSat = getappdata(fig,'centerOnSat');
    tidx = getappdata(fig,'tidx'); 
    if isempty(tidx), tidx=1; end

    center = [0;0;0];
    if centerOnSat
        S_outPos = getappdata(fig,'S_outPos');
        if ~isempty(S_outPos)
            tidx = max(1, min(size(S_outPos,2), tidx));
            center = S_outPos(:,tidx);
        end
    end
    setLim(ax, scaleDisp, a, AU, center);
end

function setLim(ax, scaleDisp, a, AU, center)
    if nargin<5 || isempty(center), center = [0;0;0]; end
    lim = AU * a;
    xlim(ax, center(1)+[-lim lim]);
    ylim(ax, center(2)+[-lim lim]);
    zlim(ax, center(3)+[-lim lim]);
    if isgraphics(scaleDisp)
        scaleDisp.String = sprintf('±%s', formatAU(a));
    end
end

function out = formatAU(a)
    if a < 10
        out = sprintf('%.1f AU', a);
    elseif a < 1000
        out = sprintf('%.0f AU', a);
    else
        out = sprintf('%.2g AU', a);
    end
end

function [YY, dd] = sec2YYdd_3n1l(tsec)
    SEC_PER_DAY = 86400;
    CYCLE_DAYS  = 365*3 + 366;
    dtotal = floor(double(tsec)/SEC_PER_DAY);
    d_in   = mod(dtotal, CYCLE_DAYS);
    base   = 4 * floor(dtotal / CYCLE_DAYS);
    dd  = zeros(size(d_in));
    yin = zeros(size(d_in));
    m0 = d_in < 365;
    m1 = d_in>=365  & d_in<730;
    m2 = d_in>=730  & d_in<1095;
    m3 = d_in>=1095;
    dd(m0)=d_in(m0);           yin(m0)=0;
    dd(m1)=d_in(m1)-365;       yin(m1)=1;
    dd(m2)=d_in(m2)-730;       yin(m2)=2;
    dd(m3)=d_in(m3)-1095;      yin(m3)=3;
    YY = base + yin;
end

function v = a2v(a, amin, amax)
    v = (log(a) - log(amin)) / (log(amax) - log(amin));
end

function a = v2a(v, amin, amax)
    a = amin * (amax/amin).^v;
end

function s = tern(cond, a, b)
    if cond
        s = a;
    else
        s = b;
    end
end
