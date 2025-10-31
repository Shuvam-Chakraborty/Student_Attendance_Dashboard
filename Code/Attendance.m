% Student Attendance Data Visualizer
% A comprehensive tool for analyzing and visualizing attendance data
% with interactive controls and multiple plot types

function attendance_visualizer()
    % Main function wrapper to handle variables properly
    
    %% ===== STEP 1: Load Data =====
    fprintf('=== Student Attendance Data Visualizer ===\n\n');
    
    % Prompt user for CSV file
    [filename, pathname] = uigetfile('*.csv', 'Select the attendance CSV file');
    if isequal(filename, 0)
        error('No file selected. Exiting...');
    end
    
    % Read the CSV file
    fullpath = fullfile(pathname, filename);
    fprintf('Loading data from: %s\n', filename);
    data = readtable(fullpath, 'VariableNamingRule', 'preserve');
    
    % Display basic info
    fprintf('\nDataset loaded successfully!\n');
    fprintf('Total records: %d\n', height(data));
    fprintf('Columns: %s\n', strjoin(data.Properties.VariableNames, ', '));
    
    % Convert Date to datetime if it's not already
    if ~isdatetime(data.Date)
        data.Date = datetime(num2str(data.Date), 'InputFormat', 'yyyyMMdd');
    end
    
    %% ===== STEP 2: Data Preprocessing =====
    fprintf('\nPreprocessing data...\n');
    
    % Calculate attendance rate and absence rate
    data.AttendanceRate = (data.Present ./ data.Enrolled) * 100;
    data.AbsenceRate = (data.Absent ./ data.Enrolled) * 100;
    
    % Handle any NaN values
    data.AttendanceRate(isnan(data.AttendanceRate)) = 0;
    data.AbsenceRate(isnan(data.AbsenceRate)) = 0;
    
    % Get unique schools
    schools = unique(data.('School DBN'));
    fprintf('Number of unique schools: %d\n', length(schools));
    
    %% ===== STEP 3: Create Main Visualization Figure =====
    fig = figure('Name', 'Student Attendance Data Visualizer', ...
        'NumberTitle', 'off', 'Position', [100, 100, 1400, 900]);
    
    %% ===== STEP 4: Create UI Controls =====
    % School selection dropdown
    uicontrol('Style', 'text', 'Position', [20, 860, 100, 20], ...
        'String', 'Select School:', 'HorizontalAlignment', 'left', ...
        'FontWeight', 'bold');
    schoolDropdown = uicontrol('Style', 'popupmenu', ...
        'Position', [120, 855, 150, 30], ...
        'String', ['All Schools'; schools]);
    
    % Plot type selection
    uicontrol('Style', 'text', 'Position', [290, 860, 80, 20], ...
        'String', 'Plot Type:', 'HorizontalAlignment', 'left', ...
        'FontWeight', 'bold');
    plotTypeDropdown = uicontrol('Style', 'popupmenu', ...
        'Position', [370, 855, 150, 30], ...
        'String', {'Time Series', 'Bar Chart', 'Scatter Plot', ...
                   'Box Plot', 'Histogram', '3D Surface'});
    
    % Metric selection
    uicontrol('Style', 'text', 'Position', [540, 860, 70, 20], ...
        'String', 'Metric:', 'HorizontalAlignment', 'left', ...
        'FontWeight', 'bold');
    metricDropdown = uicontrol('Style', 'popupmenu', ...
        'Position', [610, 855, 150, 30], ...
        'String', {'Attendance Rate', 'Absence Rate', 'Enrolled', ...
                   'Present', 'Absent'});
    
    % Update button
    uicontrol('Style', 'pushbutton', 'Position', [780, 855, 100, 30], ...
        'String', 'Refresh', 'FontWeight', 'bold', ...
        'Callback', @(src, evt) updatePlots());
    
    % Statistics button
    uicontrol('Style', 'pushbutton', 'Position', [900, 855, 120, 30], ...
        'String', 'Show Statistics', 'FontWeight', 'bold', ...
        'Callback', @(src, evt) showStatistics());
    
    % Set callbacks for dropdowns (after creating all controls)
    set(schoolDropdown, 'Callback', @(src, evt) updatePlots());
    set(plotTypeDropdown, 'Callback', @(src, evt) updatePlots());
    set(metricDropdown, 'Callback', @(src, evt) updatePlots());
    
    %% ===== STEP 5: Create Plot Panels =====
    % Main plot panel
    mainPanel = uipanel('Position', [0.02, 0.35, 0.96, 0.58], ...
        'Title', 'Main Visualization', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Secondary plot panel
    secondaryPanel = uipanel('Position', [0.02, 0.02, 0.48, 0.30], ...
        'Title', 'Trend Analysis', 'FontSize', 10, 'FontWeight', 'bold');
    
    % Statistics panel
    statsPanel = uipanel('Position', [0.52, 0.02, 0.46, 0.30], ...
        'Title', 'Quick Statistics', 'FontSize', 10, 'FontWeight', 'bold');
    
    %% ===== STEP 6: Initial Plot =====
    updatePlots();
    
    %% ===== CALLBACK FUNCTIONS =====
    
    function updatePlots()
        % Get current selections
        schoolIdx = get(schoolDropdown, 'Value');
        plotTypeIdx = get(plotTypeDropdown, 'Value');
        metricIdx = get(metricDropdown, 'Value');
        
        % Filter data based on school selection
        if schoolIdx == 1  % All schools
            filteredData = data;
            schoolName = 'All Schools';
        else
            selectedSchool = schools{schoolIdx - 1};
            filteredData = data(strcmp(data.('School DBN'), selectedSchool), :);
            schoolName = selectedSchool;
        end
        
        % Get metric name and data
        metricNames = {'AttendanceRate', 'AbsenceRate', 'Enrolled', 'Present', 'Absent'};
        metricLabels = {'Attendance Rate (%)', 'Absence Rate (%)', ...
                       'Enrolled Students', 'Present Students', 'Absent Students'};
        metricName = metricNames{metricIdx};
        metricLabel = metricLabels{metricIdx};
        
        % Clear previous plots
        delete(get(mainPanel, 'Children'));
        delete(get(secondaryPanel, 'Children'));
        delete(get(statsPanel, 'Children'));
        
        % Create main plot based on selection
        ax1 = axes('Parent', mainPanel, 'Position', [0.08, 0.12, 0.88, 0.82]);
        
        switch plotTypeIdx
            case 1  % Time Series
                plotTimeSeries(ax1, filteredData, metricName, metricLabel, schoolName);
            case 2  % Bar Chart
                plotBarChart(ax1, filteredData, metricName, metricLabel, schoolName);
            case 3  % Scatter Plot
                plotScatter(ax1, filteredData, metricName, metricLabel, schoolName);
            case 4  % Box Plot
                plotBoxPlot(ax1, filteredData, metricName, metricLabel, schoolName);
            case 5  % Histogram
                plotHistogram(ax1, filteredData, metricName, metricLabel, schoolName);
            case 6  % 3D Surface
                plot3DSurface(ax1, filteredData, schoolName);
        end
        
        % Create secondary plot (trend analysis)
        ax2 = axes('Parent', secondaryPanel, 'Position', [0.12, 0.18, 0.82, 0.72]);
        plotTrendAnalysis(ax2, filteredData, metricName, metricLabel);
        
        % Display statistics
        displayStatistics(statsPanel, filteredData, metricName, metricLabel);
    end

    function plotTimeSeries(ax, pdata, metric, label, school)
        if strcmp(school, 'All Schools')
            % Aggregate by date
            dailyData = groupsummary(pdata, 'Date', 'mean', metric);
            plot(ax, dailyData.Date, dailyData.(['mean_' metric]), ...
                'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 4);
        else
            plot(ax, pdata.Date, pdata.(metric), ...
                'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 4);
        end
        
        grid(ax, 'on');
        xlabel(ax, 'Date', 'FontSize', 11);
        ylabel(ax, label, 'FontSize', 11);
        title(ax, sprintf('%s Over Time - %s', label, school), ...
            'FontSize', 13, 'FontWeight', 'bold');
        
        % Add trend line
        hold(ax, 'on');
        if strcmp(school, 'All Schools')
            dailyData = groupsummary(pdata, 'Date', 'mean', metric);
            x = datenum(dailyData.Date);
            y = dailyData.(['mean_' metric]);
        else
            x = datenum(pdata.Date);
            y = pdata.(metric);
        end
        
        if length(x) > 1
            p = polyfit(x, y, 1);
            trendline = polyval(p, x);
            plot(ax, datetime(x, 'ConvertFrom', 'datenum'), trendline, ...
                '--r', 'LineWidth', 1.5, 'DisplayName', 'Trend');
            legend(ax, 'Data', 'Trend', 'Location', 'best');
        end
        hold(ax, 'off');
    end

    function plotBarChart(ax, pdata, metric, label, school)
        if strcmp(school, 'All Schools')
            % Show average by school
            schoolData = groupsummary(pdata, 'School DBN', 'mean', metric);
            % Limit to top 20 schools for readability
            if height(schoolData) > 20
                schoolData = sortrows(schoolData, ['mean_' metric], 'descend');
                schoolData = schoolData(1:20, :);
            end
            bar(ax, categorical(schoolData.('School DBN')), schoolData.(['mean_' metric]));
            xlabel(ax, 'School', 'FontSize', 11);
        else
            weeklyData = groupsummary(pdata, 'Date', 'mean', metric);
            bar(ax, weeklyData.Date, weeklyData.(['mean_' metric]));
            xlabel(ax, 'Date', 'FontSize', 11);
        end
        
        ylabel(ax, label, 'FontSize', 11);
        title(ax, sprintf('%s Distribution - %s', label, school), ...
            'FontSize', 13, 'FontWeight', 'bold');
        grid(ax, 'on');
        xtickangle(ax, 45);
    end

    function plotScatter(ax, pdata, metric, ~, school)
        scatter(ax, pdata.Enrolled, pdata.(metric), 50, datenum(pdata.Date), 'filled');
        colorbar(ax);
        xlabel(ax, 'Enrolled Students', 'FontSize', 11);
        ylabel(ax, metric, 'FontSize', 11);
        title(ax, sprintf('%s vs Enrollment - %s', metric, school), ...
            'FontSize', 13, 'FontWeight', 'bold');
        grid(ax, 'on');
        
        % Add correlation line
        if length(pdata.Enrolled) > 1
            hold(ax, 'on');
            p = polyfit(pdata.Enrolled, pdata.(metric), 1);
            enrollRange = [min(pdata.Enrolled), max(pdata.Enrolled)];
            plot(ax, enrollRange, polyval(p, enrollRange), '--r', 'LineWidth', 2);
            hold(ax, 'off');
        end
    end

    function plotBoxPlot(ax, pdata, metric, label, school)
        if strcmp(school, 'All Schools')
            % Sample schools if too many
            uniqueSchools = unique(pdata.('School DBN'));
            if length(uniqueSchools) > 20
                uniqueSchools = uniqueSchools(1:20);
                pdata = pdata(ismember(pdata.('School DBN'), uniqueSchools), :);
            end
            boxplot(ax, pdata.(metric), pdata.('School DBN'));
            xlabel(ax, 'School', 'FontSize', 11);
            xtickangle(ax, 90);
        else
            % Box plot by week
            pdata.Week = week(pdata.Date);
            boxplot(ax, pdata.(metric), pdata.Week);
            xlabel(ax, 'Week Number', 'FontSize', 11);
        end
        
        ylabel(ax, label, 'FontSize', 11);
        title(ax, sprintf('%s Distribution - %s', label, school), ...
            'FontSize', 13, 'FontWeight', 'bold');
        grid(ax, 'on');
    end

    function plotHistogram(ax, pdata, metric, label, school)
        histogram(ax, pdata.(metric), 30, 'FaceColor', [0.2, 0.6, 0.8]);
        xlabel(ax, label, 'FontSize', 11);
        ylabel(ax, 'Frequency', 'FontSize', 11);
        title(ax, sprintf('%s Distribution - %s', label, school), ...
            'FontSize', 13, 'FontWeight', 'bold');
        grid(ax, 'on');
        
        % Add mean line
        hold(ax, 'on');
        meanVal = mean(pdata.(metric));
        yl = ylim(ax);
        plot(ax, [meanVal, meanVal], yl, '--r', 'LineWidth', 2, ...
            'DisplayName', sprintf('Mean: %.2f', meanVal));
        legend(ax, 'show');
        hold(ax, 'off');
    end

    function plot3DSurface(ax, pdata, school)
        % Create 3D surface plot of attendance metrics over time
        dates = unique(pdata.Date);
        if strcmp(school, 'All Schools')
            schoolList = unique(pdata.('School DBN'));
            if length(schoolList) > 20
                schoolList = schoolList(1:20);
            end
            
            Z = zeros(length(dates), length(schoolList));
            for i = 1:length(dates)
                for j = 1:length(schoolList)
                    idx = strcmp(pdata.('School DBN'), schoolList{j}) & ...
                          pdata.Date == dates(i);
                    if any(idx)
                        Z(i,j) = mean(pdata.AttendanceRate(idx));
                    end
                end
            end
            
            [X, Y] = meshgrid(1:length(schoolList), datenum(dates));
            surf(ax, X, Y, Z, 'EdgeColor', 'none');
            set(ax, 'YTickLabel', datestr(get(ax, 'YTick'), 'mm/dd'));
            xlabel(ax, 'School Index', 'FontSize', 11);
        else
            % For single school, show multiple metrics
            Z = [pdata.AttendanceRate, pdata.AbsenceRate, pdata.Enrolled/max(pdata.Enrolled)*100];
            surf(ax, Z', 'EdgeColor', 'interp');
            xlabel(ax, 'Date Index', 'FontSize', 11);
        end
        
        ylabel(ax, 'Date', 'FontSize', 11);
        zlabel(ax, 'Value', 'FontSize', 11);
        title(ax, sprintf('3D Surface View - %s', school), ...
            'FontSize', 13, 'FontWeight', 'bold');
        colorbar(ax);
        view(ax, 45, 30);
        grid(ax, 'on');
    end

    function plotTrendAnalysis(ax, pdata, metric, label)
        % Moving average trend
        if height(pdata) > 5
            dailyData = groupsummary(pdata, 'Date', 'mean', metric);
            movAvg = movmean(dailyData.(['mean_' metric]), ...
                min(5, floor(height(dailyData)/2)));
            
            plot(ax, dailyData.Date, dailyData.(['mean_' metric]), ...
                'o-', 'LineWidth', 1, 'Color', [0.7, 0.7, 0.7]);
            hold(ax, 'on');
            plot(ax, dailyData.Date, movAvg, 'LineWidth', 2.5, ...
                'Color', [0.2, 0.4, 0.8]);
            hold(ax, 'off');
            
            legend(ax, 'Daily', 'Moving Avg', 'Location', 'best');
            xlabel(ax, 'Date', 'FontSize', 10);
            ylabel(ax, label, 'FontSize', 10);
            title(ax, 'Trend with Moving Average', 'FontSize', 11);
            grid(ax, 'on');
        end
    end

    function displayStatistics(panel, pdata, metric, label)
        % Calculate statistics
        vals = pdata.(metric);
        stats = {
            sprintf('Mean: %.2f', mean(vals));
            sprintf('Median: %.2f', median(vals));
            sprintf('Std Dev: %.2f', std(vals));
            sprintf('Min: %.2f', min(vals));
            sprintf('Max: %.2f', max(vals));
            sprintf('Range: %.2f', range(vals));
            sprintf('Records: %d', length(vals));
            sprintf('Date Range:');
            sprintf('  %s to', datestr(min(pdata.Date), 'yyyy-mm-dd'));
            sprintf('  %s', datestr(max(pdata.Date), 'yyyy-mm-dd'));
        };
        
        uicontrol('Parent', panel, 'Style', 'text', ...
            'String', sprintf('%s\n', stats{:}), ...
            'Position', [10, 10, 300, 180], ...
            'HorizontalAlignment', 'left', ...
            'FontName', 'Courier', 'FontSize', 10, ...
            'BackgroundColor', 'white');
    end

    function showStatistics()
        % Create detailed statistics window
        statFig = figure('Name', 'Detailed Statistics', ...
            'NumberTitle', 'off', 'Position', [200, 200, 600, 500]);
        
        % Get filtered data
        schoolIdx = get(schoolDropdown, 'Value');
        if schoolIdx == 1
            statData = data;
        else
            selectedSchool = schools{schoolIdx - 1};
            statData = data(strcmp(data.('School DBN'), selectedSchool), :);
        end
        
        % Create statistics text
        statsText = sprintf(['ATTENDANCE STATISTICS SUMMARY\n\n' ...
            'Total Records: %d\n' ...
            'Date Range: %s to %s\n\n' ...
            'ATTENDANCE RATE:\n' ...
            '  Mean: %.2f%%\n' ...
            '  Median: %.2f%%\n' ...
            '  Std Dev: %.2f%%\n' ...
            '  Min: %.2f%% | Max: %.2f%%\n\n' ...
            'ENROLLMENT:\n' ...
            '  Average: %.1f students\n' ...
            '  Total Capacity: %d students\n\n' ...
            'DAILY AVERAGES:\n' ...
            '  Present: %.1f students\n' ...
            '  Absent: %.1f students\n' ...
            '  Absence Rate: %.2f%%'], ...
            height(statData), ...
            datestr(min(statData.Date), 'yyyy-mm-dd'), ...
            datestr(max(statData.Date), 'yyyy-mm-dd'), ...
            mean(statData.AttendanceRate), ...
            median(statData.AttendanceRate), ...
            std(statData.AttendanceRate), ...
            min(statData.AttendanceRate), ...
            max(statData.AttendanceRate), ...
            mean(statData.Enrolled), ...
            sum(statData.Enrolled), ...
            mean(statData.Present), ...
            mean(statData.Absent), ...
            mean(statData.AbsenceRate));
        
        uicontrol('Parent', statFig, 'Style', 'text', ...
            'String', statsText, ...
            'Position', [20, 20, 560, 460], ...
            'HorizontalAlignment', 'left', ...
            'FontName', 'Courier', 'FontSize', 11, ...
            'BackgroundColor', 'white');
    end

    fprintf('\n=== Visualizer Ready! ===\n');
    fprintf('Use the dropdowns to:\n');
    fprintf('  - Select different schools\n');
    fprintf('  - Change plot types\n');
    fprintf('  - View different metrics\n');
    fprintf('Click "Show Statistics" for detailed analysis\n\n');
end