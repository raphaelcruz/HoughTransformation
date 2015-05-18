function A_GUI_Hough
%% Function to to detect slip bands from a micrograph using Hough transformations

% author: d.mercier@mpie.de

%% Initialization
clear all;
clear classes; % not included in clear all
close all;
commandwindow;
clc;
delete(findobj(allchild(0), '-regexp', 'Tag', '^Msgbox_'));

%% Check License of Image Toolbox
license_msg = ['Sorry, no license found for the Matlab ', ...
    'Image Processing Toolbox� !'];
if  license('checkout', 'Image_Toolbox') == 0
    helpdlg(license_msg, ' Error');
    gui.flag.licenceFlag = 0;
else
    gui.flag.licenceFlag = 1;
end

%% Set the GUI
gui.config.path_GUI = pwd;
gui.flag.picture_load = 0;
gui.flag.HoughTrans = 0;

if gui.flag.licenceFlag
    %% Main Window Coordinates Configuration
    scrsize = get(0, 'ScreenSize');   % Get screen size
    WX = 0.05 * scrsize(3);           % X Position (bottom)
    WY = 0.10 * scrsize(4);           % Y Position (left)
    WW = 0.90 * scrsize(3);           % Width
    WH = 0.80 * scrsize(4);           % Height
    
    %% Main window setting
    main_window = figure(...
        'Name', 'Slip lines detection by Hough transformation',...
        'NumberTitle', 'off',...
        'Color', [0.9 0.9 0.9],...
        'toolBar', 'figure',...
        'PaperPosition', [0 7 50 15],...
        'Position', [WX WY WW WH]);
    
    gui.figure.main_window = main_window;
    
    %% Importation of SEM image
    gui.handles.ImpImage1Title = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style','text',...
        'Position', [0.035 0.975 0.13 0.017],...
        'String', 'Path of the SEM observation',...
        'HorizontalAlignment', 'left');
    
    gui.handles.ImpImage1File = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'edit',...
        'Position', [0.035 0.915 0.13 0.057],...
        'String', matlabroot,...
        'BackgroundColor', [1 1 1],...
        'HorizontalAlignment', 'left');
    
    %% Buttons
    gui.handles.Button_Load = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style','pushbutton',...
        'Position', [0.035 0.825 0.08 0.06],...
        'String', '1) LOAD IMAGE',...
        'Callback', 'picture_load');
    
    gui.handles.Txt_Load = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'text',...
        'Position', [0.125 0.85 0.08 0.017],...
        'String', 'Import .tif files only !!!',...
        'HorizontalAlignment', 'left');
    
    gui.handles.Button_Crop = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'pushbutton',...
        'Position', [0.035 0.745 0.08 0.06],...
        'String', '2) CROP IMAGE (option.)',...
        'Callback', 'picture_crop');
    
    gui.handles.Button_Rotate = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'pushbutton',...
        'Position', [0.125 0.745 0.08 0.06],...
        'String', '3) ROTATION (option.)',...
        'Callback', 'picture_rotate');
    
    gui.handles.Button_EdgeDetec = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'pushbutton',...
        'Position', [0.035 0.665 0.08 0.06],...
        'String', '4) EDGE DETECTION',...
        'Callback', 'picture_edge_detection');
    
    gui.handles.Button_Hough = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'pushbutton',...
        'Position',[0.035 0.585 0.08 0.06],...
        'String','5) HOUGH TRANSFO.',...
        'Callback','picture_HoughTransformation', ...
        'Visible', 'off');
    
    gui.handles.Button_ClearAll = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'pushbutton',...
        'Position', [0.035 0.025 0.085 0.04],...
        'String', 'RESET',...
        'Callback', 'close(gcf); A_GUI_Hough');
    
    gui.handles.Button_SaveData = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'pushbutton',...
        'Position', [0.125 0.025 0.085 0.04],...
        'String', 'SAVE',...
        'Callback', 'export_results');
    
    gui.handles.Button_Quit = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'pushbutton',...
        'Position', [0.215 0.025 0.085 0.04],...
        'String', 'QUIT',...
        'Callback', 'exit_GUI');
    
    %% Buttons for algorithm for edge detection
    gui.handles.AlgoTitle = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'text',...
        'Position', [0.13 0.705 0.07 0.02],...
        'String', 'Algorithm',...
        'HorizontalAlignment', 'left');
    
    gui.handles.AlgoChoice = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style','popupmenu',...
        'Position', [0.13 0.685 0.07 0.02],...
        'String', 'sobel|prewitt|roberts|canny|log',...
        'BackgroundColor', [1 1 1],...
        'Value', 4,...
        'Callback', 'picture_edge_detection');
    
    gui.handles.ThresBefTitle = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'text',...
        'Position', [0.21 0.705 0.05 0.02],...
        'String', 'Threshold',...
        'HorizontalAlignment', 'left');
    
    gui.handles.ThresBefValue = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'edit',...
        'Position', [0.21 0.680 0.05 0.025],...
        'String', '0.1',...
        'BackgroundColor', [1 1 1],...
        'Callback', 'picture_edge_detection');
    
    %% Buttons for Hough transformation
    gui.handles.HT_RHO_TITLE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style','text',...
        'Position', [0.13 0.625 0.05 0.02],...
        'String', 'HT_Rho',...
        'HorizontalAlignment', 'left', ...
        'Visible', 'off');
    
    gui.handles.HT_RHO_VALUE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'edit',...
        'Position', [0.13 0.600 0.05 0.025],...
        'String', '0.5',...
        'BackgroundColor', [1 1 1], ...
        'Visible', 'off',...
        'Callback','picture_HoughTransformation');
    
    %     gui.handles.HT_THETA_TITLE = uicontrol('Parent', main_window,...
    %         'Units', 'normalized',...
    %         'Style', 'text',...
    %         'Position', [0.19 0.625 0.05 0.02],...
    %         'String', 'HT_Theta',...
    %         'HorizontalAlignment', 'left');
    %
    %     gui.handles.HT_THETA_VALUE = uicontrol('Parent', main_window,...
    %         'Units', 'normalized',...
    %         'Style','edit',...
    %         'Position', [0.19 0.600 0.05 0.025],...
    %         'String', '0.05',...
    %         'BackgroundColor', [1 1 1],...
    %         'Callback','picture_HoughTransformation');
    
    gui.handles.HT_H_TITLE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'text',...
        'Position', [0.13 0.575 0.05 0.02],...
        'String', 'HP_H',...
        'HorizontalAlignment', 'left', ...
        'Visible', 'off');
    
    gui.handles.HT_H_VALUE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'edit',...
        'Position', [0.13 0.550 0.05 0.025],...
        'String', '50',...
        'BackgroundColor', [1 1 1], ...
        'Visible', 'off',...
        'Callback','picture_HoughTransformation');
    
    gui.handles.HT_THRES_TITLE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'text',...
        'Position', [0.19 0.575 0.05 0.02],...
        'String', 'HP_Threshold',...
        'HorizontalAlignment', 'left', ...
        'Visible', 'off');
    
    gui.handles.HT_THRES_VALUE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style','edit',...
        'Position', [0.19 0.550 0.05 0.025],...
        'String', '0.1',...
        'BackgroundColor', [1 1 1], ...
        'Visible', 'off',...
        'Callback','picture_HoughTransformation');
    
    gui.handles.HT_FILLGAP_TITLE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'text',...
        'Position', [0.13 0.525 0.05 0.02],...
        'String', 'HL_FillGap',...
        'HorizontalAlignment', 'left', ...
        'Visible', 'off');
    
    gui.handles.HT_FILLGAP_VALUE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'edit',...
        'Position', [0.13 0.5 0.05 0.025],...
        'String', '5',...
        'BackgroundColor', [1 1 1], ...
        'Visible', 'off',...
        'Callback','picture_HoughTransformation');
    
    gui.handles.HT_MINLENGTH_TITLE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'text',...
        'Position', [0.19 0.525 0.05 0.02],...
        'String', 'HL_MinLength',...
        'HorizontalAlignment', 'left', ...
        'Visible', 'off');
    
    gui.handles.HT_MINLENGTH_VALUE = uicontrol('Parent', main_window,...
        'Units', 'normalized',...
        'Style', 'edit',...
        'Position', [0.19 0.5 0.05 0.025],...
        'String', '10',...
        'BackgroundColor', [1 1 1], ...
        'Visible', 'off',...
        'Callback','picture_HoughTransformation');
    
    %% Creates axes
        gui.axes = axes('Parent', gui.figure.main_window,...
        'Position',[0.38 0.06 0.6 0.9]);
        gui.axes_2 = axes('Parent', gui.figure.main_window,...
        'Position',[0.04 0.15 0.3 0.3], ...
        'Visible', 'off');

end

guidata(gcf, gui);
end