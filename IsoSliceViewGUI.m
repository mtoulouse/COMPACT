function IsoSliceViewGUI(Rstr,Rdatum,Rwk,Rdsp,Rm)
%ISOSLICEVIEWGUI Scalar field display GUI function.
%   ISOSLICEVIEWGUI takes the needed result information as input and
%   generates a GUI that allows display of 3-D data and multiple sets of
%   3-D data, in both isosurface view and any combination of X/Y/Z slice
%   views, with a slider and editable field to allow adjustment of the 
%   value. The option of overlaying the flow object patch view is also
%   given.

% Extract initial data and result information to display
switch Rdsp
    case '3Dscalar'
        ListStr = Rwk;
        ShowListBox = 'off';
        Rdat = Rdatum;
    case '4Dscalar'
        ListStr = Rstr(2:end);
        ShowListBox = 'on';
        Rstr = Rstr{1};
        Rdat = Rdatum(:,:,:,1);
end

% Some data sets include data inside the walls. The axes limits are
% adjusted accordingly.
res = Rm.Resolution;
if isequal(size(Rdat),Rm.Dimensions./res) % no data in walls
    Xmin = res/2;
    Xmax = Rm.Dimensions(1)-res/2;
    Ymin = res/2;
    Ymax = Rm.Dimensions(2)-res/2;
    Zmin = res/2;
    Zmax = Rm.Dimensions(3)-res/2;
elseif isequal(size(Rdat),2+Rm.Dimensions./res) % data in walls, so two extra nodes in each direction
    Xmin = -res/2;
    Xmax = Rm.Dimensions(1)+res/2;
    Ymin = -res/2;
    Ymax = Rm.Dimensions(2)+res/2;
    Zmin = -res/2;
    Zmax = Rm.Dimensions(3)+res/2;
end

% determine the minimum and maximum vales on the slider
MaxVal = max(max(max(Rdat)));
MinVal = min(min(min(Rdat)));
if MaxVal == MinVal
    MaxVal = MinVal + eps; % just to avoid problems with the slider when 
    % encountering a field of identical values
end

%% Create Figure
h = figure('Name',['Viewing: ' Rstr ' (' Rdsp ')'],...
    'Numbertitle','off',...
    'Position',Center_Fig(800,600),...
    'DefaultUicontrolSliderStep',[0.05 0.10]);

%% Create Panels
OptionPanel = uipanel(h,'Title','Viewing Options',...
    'Units','normalized',...
    'Position',[0,.25,.25,.75]);

ViewPanel = uipanel(h,'Title','3D View',...
    'Units','normalized',...
    'Position',[.25,.25,.75,.75]);

SlidePanel = uipanel(h,'Title','Adjust Value',...
    'Units','normalized',...
    'Position',[0,0,1,.25]);

%% Create buttons for Options Panel

% Choosing view type (isosurface or slice)
ChooseView = uibuttongroup(OptionPanel,'Title','Choose View Type',...
    'Units','normalized',...
    'Position',[0,0,1,.8]);

Iso = uicontrol(ChooseView,...
    'Style','radiobutton',...
    'Units','normalized',...
    'Position',[.1,.8,.8,.1],...
    'String','Isosurface View');

Slic = uicontrol(ChooseView,...
    'Style','radiobutton',...
    'Units','normalized',...
    'Position',[.1,.6,.8,.1],...
    'String','Slice View');

set(ChooseView,'SelectedObject',Slic)

% Choosing slice types (X, Y, and/or Z)
SlicView = uipanel(ChooseView,'Title','Choose Slice Direction',...
    'Units','normalized',...
    'Position',[.2,.2,.7,.4],...
    'Visible','on');

XSlicView = uicontrol(SlicView,...
    'Style','checkbox',...
    'Units','normalized',...
    'Position',[.1,.7,.8,.2],...
    'String','Along X-Axis');
YSlicView = uicontrol(SlicView,...
    'Style','checkbox',...
    'Units','normalized',...
    'Position',[.1,.4,.8,.2],...
    'String','Along Y-Axis');
ZSlicView = uicontrol(SlicView,...
    'Style','checkbox',...
    'Units','normalized',...
    'Position',[.1,.1,.8,.2],...
    'String','Along Z-Axis');

% Show flow objects overlay
ShowFObjBox = uicontrol(OptionPanel,...
    'Style','checkbox',...
    'Units','normalized',...
    'Position',[.1,.8,.8,.1],...
    'String','Show Objects in Room',...
    'Callback',@ShowFObj_callback);

% The list of accessible 3-D data sets (grayed out if there is only one 3-D
% scalar field)
List4D = uicontrol(OptionPanel,...
    'Style','popupmenu',...
    'Units','normalized',...
    'Position',[.1,.85,.8,.1],...
    'BackgroundColor','w',...
    'Enable',ShowListBox,...
    'String',ListStr,...
    'Callback',@DataSet_callback);

%% Create Sliders and Slider Value Fields

% X slider
Text_X = uicontrol(SlidePanel,'Style','text',...
    'Units','normalized',...
    'Position',[0 .7 .1 .2],...
    'FontSize',14,...
    'String','X');

SLIDE_X = uicontrol(SlidePanel,'Style','slider',...
    'Units','normalized',...
    'Position',[.1 .7 .7 .2],...
    'Max',Xmax,...
    'Min',Xmin,...
    'Value',.5*(Xmax+Xmin));

Sval_X = uicontrol(SlidePanel,'style','edit',...
    'Units','normalized',...
    'Position',[.85 .7 .1 .2],...
    'BackgroundColor','w',...
    'String', num2str(get(SLIDE_X,'Value')));

Xslider = [Text_X SLIDE_X Sval_X];
set(SLIDE_X,'Callback',{@Slide2Val,Sval_X})
set(Sval_X,'Callback',{@Val2Slide,SLIDE_X})
set(Xslider,'Enable','off')

% Y slider
Text_Y = uicontrol(SlidePanel,'Style','text',...
    'Units','normalized',...
    'Position',[0 .4 .1 .2],...
    'FontSize',14,...
    'String','Y');

SLIDE_Y = uicontrol(SlidePanel,'Style','slider',...
    'Units','normalized',...
    'Position',[.1 .4 .7 .2],...
    'Max',Ymax,...
    'Min',Ymin,...
    'Value',.5*(Ymax+Ymin));

Sval_Y = uicontrol(SlidePanel,'style','edit',...
    'Units','normalized',...
    'Position',[.85 .4 .1 .2],...
    'BackgroundColor','w',...
    'String', num2str(get(SLIDE_Y,'Value')));

Yslider = [Text_Y SLIDE_Y Sval_Y];
set(SLIDE_Y,'Callback',{@Slide2Val,Sval_Y})
set(Sval_Y,'Callback',{@Val2Slide,SLIDE_Y})
set(Yslider,'Enable','off')

% Z slider
Text_Z = uicontrol(SlidePanel,'Style','text',...
    'Units','normalized',...
    'Position',[0 .1 .1 .2],...
    'FontSize',14,...
    'String','Z');

SLIDE_Z = uicontrol(SlidePanel,'Style','slider',...
    'Units','normalized',...
    'Position',[.1 .1 .7 .2],...
    'Max',Zmax,...
    'Min',Zmin,...
    'Value',.5*(Zmax+Zmin));

Sval_Z = uicontrol(SlidePanel,'style','edit',...
    'Units','normalized',...
    'Position',[.85 .1 .1 .2],...
    'BackgroundColor','w',...
    'String', num2str(get(SLIDE_Z,'Value')));

Zslider = [Text_Z SLIDE_Z Sval_Z];
set(SLIDE_Z,'Callback',{@Slide2Val,Sval_Z})
set(Sval_Z,'Callback',{@Val2Slide,SLIDE_Z})
set(Zslider,'Enable','off')

% Value slider (for the range of field's scalar values)
Text_T = uicontrol(SlidePanel,'Style','text',...
    'Units','normalized',...
    'Position',[.2 .7 .6 .25],...
    'FontSize',14,...
    'String',[Rwk ': ' num2str(MinVal) ' to ' num2str(MaxVal)]);

SLIDE_T = uicontrol(SlidePanel,'Style','slider',...
    'Units','normalized',...
    'Position',[.05 .25 .75 .4],...
    'Max',MaxVal,...
    'Min',MinVal,...
    'Value',.5*(MinVal+MaxVal));

Sval_T = uicontrol(SlidePanel,'style','edit',...
    'Units','normalized',...
    'Position',[.85 .25 .1 .5],...
    'BackgroundColor','w',...
    'String', num2str(get(SLIDE_T,'Value')));

Tslider = [Text_T SLIDE_T Sval_T];
set(SLIDE_T,'Callback',{@Slide2Val,Sval_T})
set(Sval_T,'Callback',{@Val2Slide,SLIDE_T})
set(Tslider,'Visible','off')

set(ChooseView,'SelectionChangeFcn',@ViewChange_callback)
set(XSlicView,'Callback',{@SlicCheck_callback,Xslider})
set(YSlicView,'Callback',{@SlicCheck_callback,Yslider})
set(ZSlicView,'Callback',{@SlicCheck_callback,Zslider})

%% Create plot view
ax = findobj(Rm.Figure,'Tag','3D Axes');
ViewAxes = copyobj(ax,ViewPanel);
rotate3d on;
axis(ViewAxes);
if isequal(size(Rdat),2+Rm.Dimensions./res)
    xlim(ViewAxes,[Xmin-res/2 Xmax+res/2])
    ylim(ViewAxes,[Ymin-res/2 Ymax+res/2])
    zlim(ViewAxes,[Zmin-res/2 Zmax+res/2])
end
% Grab all the displayed objects and add them the the display.
allpatches = findobj(ViewAxes,'Type','patch');
set(allpatches,'LineWidth',0.5)
set(allpatches,'Visible','off')
set(allpatches,'HandleVisibility','off')

%% Callbacks for Option controls
    function ViewChange_callback(src,eventdata) %#ok<INUSL>
        % Changes the view of the data between iso and slice. Makes the
        % appropriate sliders and editable fields visible or invisible.
        newobj = eventdata.NewValue;
        if newobj == Slic
            set(get(SlicView,'Children'),'Enable','on')
            set(get(SlidePanel,'Children'),'Visible','on')
            set([Text_T SLIDE_T Sval_T],'Visible','off')
        elseif newobj == Iso
            set(get(SlicView,'Children'),'Enable','off')
            set(get(SlidePanel,'Children'),'Visible','off')
            set([Text_T SLIDE_T Sval_T],'Visible','on')
        end
        ChangeDisp_callback % Update the 3-D display
    end

    function SlicCheck_callback(src,eventdata,SlideSet)
        % This callback associates the checkbox for slice views with
        % enabling/disabling the corresponding slider.
        if get(gcbo,'Value') == get(gcbo,'Max')
            set(SlideSet,'Enable','on');
        elseif get(gcbo,'Value') == get(gcbo,'Min')
            set(SlideSet,'Enable','off');
        end
        ChangeDisp_callback; % Update the 3-D display
    end

    function ShowFObj_callback(src,eventdata)
        % Check the checkbox for flow object display, and make them visible
        % as necessary.
        if get(gcbo,'Value') == get(gcbo,'Max')
            set(allpatches,'Visible','on')
        elseif get(gcbo,'Value') == get(gcbo,'Min')
            set(allpatches,'Visible','off')
        end
    end

    function Slide2Val(src,eventdata,VBox)
        % Changes the editable field to the current slider value
        set(VBox,'String',num2str(get(gcbo,'Value')))
        ChangeDisp_callback
    end

    function Val2Slide(src,eventdata,SL)
        % Changes the slider to the current editable field value, rounding
        % to the max/min possible values if necessary.
        V = str2double(get(gcbo,'String'));
        MinV = get(SL,'Min');
        MaxV = get(SL,'Max');
        if V<MinV
            set(SL,'Value',MinV)
            set(gcbo,'String',num2str(MinV))
        elseif V>MaxV
            set(SL,'Value',MaxV)
            set(gcbo,'String',num2str(MaxV))
        else
            set(SL,'Value',V)
            set(gcbo,'String',num2str(V))
        end
        ChangeDisp_callback
    end

    function DataSet_callback(src,eventdata)
        % Changes the currently displayed 3-D data set, depending on the
        % selected set in the list.
        dat_ind = get(List4D,'Value');
        Rdat = Rdatum(:,:,:,dat_ind);
        MaxVal = max(max(max(Rdat)));
        MinVal = min(min(min(Rdat)));
        set(SLIDE_T,'Max',MaxVal);
        set(SLIDE_T,'Min',MinVal);
        set(SLIDE_T,'Value',(MaxVal+MinVal)/2);
        set(Text_T,'String',[Rwk ': ' num2str(MinVal) ' to ' num2str(MaxVal)]);
        ChangeDisp_callback;
    end

    function ChangeDisp_callback(src,eventdata)
        % Updates the display, depending on the desired display options
        axes(ViewAxes);
        cla;
        ShowIso = get(Iso,'Value');
        ShowSlices = get(Slic,'Value');
        ShowSliceX = get(XSlicView,'Value');
        ShowSliceY = get(YSlicView,'Value');
        ShowSliceZ = get(ZSlicView,'Value');
        C1 = Xmin:res:Xmax;
        C2 = Ymin:res:Ymax;
        C3 = Zmin:res:Zmax;
        if ShowIso
            colorbar('off');
            V = get(SLIDE_T,'Value');
            % set color of surface (scale colormap against range of scalar
            % values)
            cmap = colormap;
            i_cmap = 1+round((V-MinVal)/(MaxVal-MinVal)*(length(cmap)-1));
            SurColor = cmap(i_cmap,:);
            % now plot the surface
            p = patch(isosurface(C1,C2,C3,permute(Rdat,[2 1 3]),V));
            isonormals(Rdat,p);
            set(p,'FaceColor',SurColor,'FaceAlpha',0.6);
        elseif ShowSlices
            caxis([MinVal MaxVal]);
            colorbar;
            sx = [];
            sy = [];
            sz = [];
            if ShowSliceX
                sx = get(SLIDE_X,'Value');
            end
            if ShowSliceY
                sy = get(SLIDE_Y,'Value');
            end
            if ShowSliceZ
                sz = get(SLIDE_Z,'Value');
            end
            hold on;
            slice(ViewAxes,C1,C2,C3,permute(Rdat,[2 1 3]),sx,sy,sz);
            hold off;
        end
    end
end