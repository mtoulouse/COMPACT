function ProfObj = FlowObjProfileGUI(FObj,ProfObj,direc)
% FLOWOBJPROFILEGUI Flow Object Profile-setting GUI.
%   FLOWOBJPROFILEGUI is used to specify the values in a flow or heat or
%   temperature profile on the face of a flow object in the room. There are
%   multiple options, like centering and uniform and checking individual
%   rows/columns etc. Just play with it.
%
%   FObj: the flow object whose profiles we are defining
%   ProfObj: the initial profile settings. It'll be zeroes if this is a new
%   object, but otherwise it'll have the existing values if you're editing.
%   direc: the direction of flow (in case it's a server rack)
%   
%   Take a look at the "Profile" class definition file before deciphering
%   this, it'll help.

datatype = ProfObj.Type;
disttype = ProfObj.DistributionType;
distsubtype = ProfObj.DistributionSubtype;
res = FObj.Room.Resolution;

switch datatype
    case 'HG'
        uni = 'Watts';
        datatypefull = 'Heat Generation';
    case 'TR'
        uni = 'degrees C';
        datatypefull = 'Temperature Rise';
    case 'FR'
        uni = [Air.units '/second'];
        datatypefull = 'Flow Rate';
end

switch class(FObj)
    case 'ServerRack'
        [A,B,ARC,BRC] = GetFace(FObj,direc);
    case {'Inlet','Outlet'}
        [A,B,ARC,BRC] = GetFace(FObj);
end
RCD = nonzeros(B-A)'/res;
num_x = RCD(1); % profile matrix size, x
num_y = RCD(2); % profile matrix size, y
def = {'[1.5 2 3.2 4.6]*0.25','[2 9 7 3]'}; % just some example default numbers to fill the blank for custom distributions

% fill in default profile values
if IsProfileEmpty(ProfObj)
    RProf = zeros(num_y,num_x);
else
    RProf = ProfObj.Value;
    if size(distsubtype,1) == 2
        def = {num2str(distsubtype{1}),...
            num2str(distsubtype{2})};
    end
end

%% Create the GUI
% Make a figure
F = Center_Fig(1000,600);
Rfig = figure('Name',['Rack Profile: ' datatypefull],'NumberTitle','off',...
    'menubar','none','Position',F,'Resize','off');
RearViewPanel = uipanel(Rfig,'Title','Rear View of Panel',...
    'Position',[0 0 F(4)/F(3) 1]);
DistribPanel = uipanel(Rfig,'Title','Value Distribution',...
    'Position',[F(4)/F(3) 0 1-F(4)/F(3) 1]);

% Create the rear view editable boxes and checkboxes
AR = num_y/num_x;
if AR>=1
    rhgt = .9;
    rwid = rhgt/AR;
elseif AR<1
    rwid = .9;
    rhgt = rwid*AR;
end

bwid = rwid/(num_x+1);
bhgt = rhgt/(num_y+1);
x_corner = (1-rwid)/2;
y_corner = (1-rhgt)/2;
rwid = rwid-bwid;
rhgt = rhgt-bhgt;

for j = 1:num_x
    VertChecks(j) = uicontrol(RearViewPanel,'Style','checkbox',...
        'Units','normalized',...
        'Position',[x_corner+(j-1)*bwid,y_corner+rhgt,bwid,bhgt],...
        'Callback',@uncheck);
    for i = 1:num_y
        RPVal(i,j) = uicontrol(RearViewPanel,'Style','edit',...
            'BackGroundColor','w',...
            'Units','normalized',...
            'Position',[x_corner+(j-1)*bwid,y_corner+(num_y-i)*bhgt,bwid,bhgt],...
            'String',num2str(RProf(i,j)),...
            'Callback', @RPVal_callback);
    end
end
for i = 1:num_y
    HorizChecks(i) = uicontrol(RearViewPanel,'Style','checkbox',...
        'Units','normalized',...
        'Position',[x_corner+rwid,y_corner+rhgt-i*bhgt,bwid,bhgt],...
        'Callback',@uncheck);
end

% Create the checkboxes and buttons for distribution options
SelecPanel = uipanel(DistribPanel,'Title','Auto Select Options',...
    'Position',[.1 .75 .8 .2]);
CheckAll = uicontrol(SelecPanel,'Style','checkbox',...
    'Units','normalized',...
    'String','Check All',...
    'Position',[.1,.7,.9,.3],...
    'Callback',@checkall_callback);
CheckHoriz = uicontrol(SelecPanel,'Style','checkbox',...
    'Units','normalized',...
    'String','Check Horizontal',...
    'Position',[.1,.4,.9,.3],...
    'Callback',@checkhoriz_callback);
CheckVert = uicontrol(SelecPanel,'Style','checkbox',...
    'Units','normalized',...
    'String','Check Vertical',...
    'Position',[.1,.1,.9,.3],...
    'Callback',@checkvert_callback);

PresetDistPanel = uipanel(DistribPanel,'Title','Familiar Distributions',...
    'Position',[.1 .3 .8 .4]);
Unif = uicontrol(PresetDistPanel,'Style', 'pushbutton', 'String', 'Uniform',...
    'Units','normalized',...
    'Position', [.1,.7,.8,.2],...
    'Callback', @uniform_callback);
Cent = uicontrol(PresetDistPanel,'Style', 'pushbutton', 'String', 'Centered',...
    'Units','normalized',...
    'Position', [.1,.4,.8,.2],...
    'Callback', @center_callback);
Cust = uicontrol(PresetDistPanel,'Style', 'pushbutton', 'String', 'Custom',...
    'Units','normalized',...
    'Position', [.1,.1,.8,.2],...
    'Callback', @custom_callback);

Norm = uicontrol(DistribPanel,'Style', 'pushbutton', 'String', 'Normalize',...
    'Units','normalized',...
    'Position', [.1 .175 .5 .1],...
    'Callback', @normalize_callback);

RPStats = uicontrol(DistribPanel,'Style', 'pushbutton', 'String', 'Stats',...
    'Units','normalized',...
    'Position', [.625 .175 .275 .1],...
    'Callback', @stats_callback);

% Create an OK and Cancel Button
OKButt = uicontrol(DistribPanel,'Style', 'pushbutton', 'String', 'OK',...
    'Units','normalized',...
    'Position', [.1 .025 .35 .075],...
    'Callback', @ok_callback);
CancelButt = uicontrol(DistribPanel,'Style', 'pushbutton', 'String', 'Cancel',...
    'Units','normalized',...
    'Position', [.55 .025 .35 .075],...
    'Callback', 'close(gcf)');

checkall_callback; % just default to checking all boxes
%% Now that the UI is made, pause it until a button is pressed
uiwait(Rfig)

%% The checkbox callbacks
    function checkall_callback(src,eventdata)
        NV = get(gcbo,'Value');
        uncheck;
        set(CheckAll,'Value',NV)
        set(VertChecks,'Value',NV)
        set(HorizChecks,'Value',NV)
    end
    function checkhoriz_callback(src,eventdata)
        NV = get(gcbo,'Value');
        uncheck;
        set(CheckHoriz,'Value',NV)
        set(HorizChecks,'Value',NV)
    end
    function checkvert_callback(src,eventdata)
        NV = get(gcbo,'Value');
        uncheck;
        set(CheckVert,'Value',NV)
        set(VertChecks,'Value',NV)
    end
    function uncheck(src,eventdata)
        set([CheckAll, CheckHoriz, CheckVert],'Value',0)
    end
%% The button callbacks: uniform, center, custom, normalize, stats, ok
    function uniform_callback(src,eventdata)
        answer = inputdlg(['Set all selected rows/columns to (' uni '):'],...
            'Uniform Distribution');
        if ~isempty(answer)
            V = str2double(answer{1});
            setRackValues('row',V)
            setRackValues('column',V)
            if get(CheckAll,'Value') == 1
                disttype = 'uniform';
            end
        end
    end
    function center_callback(src,eventdata)
        button = questdlg('Set all selected rows/columns to a centered distribution which decreases proportional to:',...
            'Centered Distribution','1/r','1/r^2','Cancel','1/r');
        if ~isempty(button) && ~strcmp(button,'Cancel') % If dialog is not canceled
            for ii = 1:num_y
                r_col(ii) = abs(ii-(num_y+1)/2);
                for jj = 1:num_x
                    r_row(jj) = abs(jj-(num_x+1)/2);
                    r_all(ii,jj) = sqrt(r_col(ii)^2 + r_row(jj)^2);
                end
            end
            switch button
                case '1/r'
                    prof_col = min(1./r_col,2);
                    prof_row = min(1./r_row,2);
                    prof_all = min(1./r_all,2);
                case '1/r^2'
                    prof_col = min(1./r_col.^2,4);
                    prof_row = min(1./r_row.^2,4);
                    prof_all = min(1./r_all.^2,4);
            end
            if get(CheckAll,'Value') == 1 % Was "Check All" checked?
                % Then center whole profile
                setRackValues('all',prof_all)
                disttype = 'centered';
                distsubtype = button;
            else % otherwise just center individual rows/columns
                % centering rows
                setRackValues('row',prof_row)
                %centering columns
                setRackValues('column',prof_col)
            end
        end
    end
    function custom_callback(src,eventdata)
        HC = cell2mat(get(HorizChecks,'Value'));
        VC = cell2mat(get(VertChecks,'Value'));
        C = [any(HC) any(VC)];
        cdirs = {'left' 'bottom'};
        if xor(any(HC),any(VC))
            prompt = {['Enter coordinates (distance in ' Air.units ' from ' cdirs{find(C)} '):'],'Enter values:'};
            dlg_title = 'Custom distribution';
            num_lines = 1;
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            if ~isempty(answer)
                coords = str2num(answer{1});
                vals = str2num(answer{2});
                if any(coords > num_x*res) && any(coords > num_y*res)
                    errordlg('Coordinates are not even on the rack face. Try again.')
                elseif ~isequal(size(coords),size(vals))
                    errordlg('# of coordinates and # of values do not match.')
                else
                    switch 1
                        case any(HC)
                            profx = customdist(coords,vals,num_x);
                            setRackValues('row',profx)
                            disttype = 'horiz. custom';
                        case any(VC)
                            profy = customdist(coords,vals,num_y);
                            setRackValues('column',fliplr(profy))
                            % flipped because the columns are set from the
                            % top, even though the input coordinates are
                            % from the bottom.
                            disttype = 'vert. custom';
                    end
                    distsubtype = {coords; vals};
                end
            end
        elseif any(HC) && any(VC)
            errordlg('Custom distributions should be done in one direction at a time.')
        end
    end
    function normalize_callback(src,eventdata)
        RProf = reshape(get(RPVal,'String'),num_y,num_x);
        RProf = cellfun(@str2num,RProf);
        switch datatype
            case 'HG'
                normtype = 'sum up to';
                nxmult = 1/num_x;
                nymult = 1/num_y;
            case {'TR','FR'}
                normtype = 'average';
                nxmult = 1;
                nymult = 1;
        end
        answer = inputdlg(['Normalize all selected rows or columns to ' normtype ' (' uni '):'],...
            'Normalize the distribution');
        if ~isempty(answer)
            V = str2double(answer{1});
            if get(CheckAll,'Value') == 1
                RProf = RProf/mean(mean(RProf));
                RProf = RProf*V*nxmult*nymult;
            else
                for ii = 1:num_y
                    if get(HorizChecks(ii),'Value') == 1
                        RProf(ii,:) = RProf(ii,:)/mean(RProf(ii,:))*V*nxmult;
                    end
                end
                for jj = 1:num_x
                    if get(VertChecks(jj),'Value') == 1
                        RProf(:,jj) = RProf(:,jj)/mean(RProf(:,jj))*V*nymult;
                    end
                end
            end
            setRackValues('all',RProf)
        end
    end

    function stats_callback(src,eventdata)
        % lists some quick stats about mean or summed values of the profile
        % both overall and in vert/horiz directions
        
        RProf = reshape(get(RPVal,'String'),num_y,num_x);
        RProf = cellfun(@str2num,RProf);
        Mcols = mean(RProf,1);
        Mrows = mean(RProf,2);
        Scols = sum(RProf,1);
        Srows = sum(RProf,2);
        Mtot = mean(mean(RProf));
        Stot = sum(sum(RProf));
        msg = {'Column-wise mean values (left to right): '
            num2str(Mcols,'%-7g')
            'Row-wise mean values (top to bottom): '
            num2str(Mrows','%-7g')
            'Total mean value: '
            num2str(Mtot,'%-7g');
            '--------------'
            'Column-wise summed values (left to right): '
            num2str(Scols,'%-7g')
            'Row-wise summed values (top to bottom): '
            num2str(Srows','%-7g')
            'Total summed value: '
            num2str(Stot,'%-7g')};
        msgbox(msg,'Current Statistics','help')
    end

    function ok_callback(src,eventdata)
        RProf = reshape(get(RPVal,'String'),num_y,num_x);
        RProf = cellfun(@str2num,RProf);
        ProfObj.Value = RProf;
        ProfObj.DistributionType = disttype;
        ProfObj.DistributionSubtype = distsubtype;
        close(gcf);
    end

%% Utility functions + editable field callback

    function RPVal_callback(src,eventdata)
        % if any value is individually manually changed, the profile type 
        % is changed to 'custom'.
        disttype = 'custom';
        distsubtype = {};
    end

% Used in the custom distribution:
    function prof = customdist(coords,vals,numnodes)
        wallcoords = res*(0:numnodes);
        coords = [wallcoords(1) coords wallcoords(end)];
        switch datatype
            case {'HG','FR'}
                vals = [0 vals 0];
            case 'TR'
                vals = [vals(1) vals vals(end)];
        end
        wallvals = interp1(coords,vals,wallcoords);
        [C m n] = unique([wallcoords coords]);
        V = [wallvals vals];
        V = V(m);
        wh = ~mod(C(2:end),res);
        A = diff(cumtrapz(C,V))/res;
        prof = zeros(1,nnz(wh));
        n = 1;
        for c = 1:length(wh)
            prof(n) = prof(n) + A(c);
            if wh(c)
                n = n+1;
            end
        end
        if strcmp(datatype,'HG')
            prof = prof*sum(vals)/sum(prof);
        end
    end

% Used to set multiple rack values at once, so you don't have to do
% multiple for loops and if statements throughout the main function.
    function setRackValues(rackdir,prof)
        if isequal(size(prof),[1 1])
            prof = prof*ones(1,max(num_x,num_y));
        end
        switch rackdir
            case 'row'
                for ii = 1:num_y
                    if get(HorizChecks(ii),'Value') == 1
                        for jj = 1:num_x
                            set(RPVal(ii,jj),'String',num2str(prof(jj)))
                        end
                    end
                end
            case 'column'
                for jj = 1:num_x
                    if get(VertChecks(jj),'Value') == 1
                        for ii = 1:num_y
                            set(RPVal(ii,jj),'String',num2str(prof(ii)))
                        end
                    end
                end
            case 'all'
                for ii = 1:num_y
                    for jj = 1:num_x
                        set(RPVal(ii,jj),'String',num2str(prof(ii,jj)))
                    end
                end
        end
    end
end