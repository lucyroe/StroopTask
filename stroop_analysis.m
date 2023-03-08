%% data analysis Stroop task

%% read in datafiles

% path of datafiles
data_pathway = sprintf("/Users/Lucy/Documents/Berlin/FU/MCNB/1Semester/Programming/Project/StroopTask/data/");
% go to folder
cd(data_pathway)

% list all datafiles in folder
list = dir('*.txt');

% create empty matrix to put all data into
data_matrix = [];

% loop over all datafiles in folder
for file = 1:length(list)
    filename = list(file).name;
    % read in textfile as matrix with a tab as delimiter
    file_matrix = readmatrix(filename, "delimiter", "\t");
    % add matrix to all data matrix
    data_matrix = [data_matrix; file_matrix];
end

% split matrix into test and experimental trials

test_data = [];
experimental_data = [];
for row = 1:size(data_matrix,1)
    if data_matrix(row,3) == 0 % test trial
        test_data = [test_data; data_matrix(row,:)];
    else % experimental trial
        experimental_data = [experimental_data; data_matrix(row,:)];
    end
end

%% statistical analysis

%%% DESCRIPTIVE STATS

% create matrix for averaging over participants
descriptive_matrix = [];
for vp = 1:length(list)

    % initiating variables
    sum_correct = 0;
    sum_all = 0;
    sum_rt = 0;
    sum_rt_congruent = 0;
    sum_rt_incongruent = 0;
    sum_congruent = 0;
    sum_incongruent = 0;
    vp_matrix = experimental_data(((vp-1)*64+1):((vp-1)*64+1)+63,:);

    % loop over all trials
    for r = 1:size(vp_matrix,1)
        sum_correct = sum_correct + vp_matrix(r,6); % add accuracy value (1 = correct; 0 = incorrect)
        sum_all = sum_all + 1;
        sum_rt = sum_rt + vp_matrix(r,7); % add reaction time
        if vp_matrix(r,5) == 1 % if trial was congruent
            sum_rt_congruent = sum_rt_congruent + vp_matrix(r,7);
            sum_congruent = sum_congruent + 1;
        else % if trial was incongruent
            sum_rt_incongruent = sum_rt_incongruent + vp_matrix(r,7);
            sum_incongruent = sum_incongruent + 1;
        end
    end

    percentage_correct = round((sum_correct/sum_all),2) * 100; % percentage of correct answers
    average_rt = round((sum_rt/sum_all),3) * 1000; % average reaction time over all trials
    rt_congruent = round((sum_rt_congruent/sum_congruent),3) * 1000; % average reaction time in congruent trials
    rt_incongruent = round((sum_rt_incongruent/sum_incongruent),3) * 1000; % average reaction time in incongruent trials
    stroop_effect = rt_incongruent - rt_congruent; % stroop effect (incongruent - congruent)
    
    % save descriptives for participant to matrix
    vp_descriptive = [percentage_correct average_rt rt_congruent rt_incongruent stroop_effect];
    descriptive_matrix = [descriptive_matrix; vp_descriptive];
end

% percentage of correct answers over all participants
percentage_correct_all = sum(descriptive_matrix(:,1))/length(list);
% average reaction time over all participants
average_rt_all = sum(descriptive_matrix(:,2))/length(list);
% average reaction time in congruent trials over all participants
rt_congruent_all = sum(descriptive_matrix(:,3))/length(list);
% average reaction time in incongruent trials over all participants
rt_incongruent_all = sum(descriptive_matrix(:,4))/length(list);
% stroop effect (incongruent - congruent) over all participants
stroop_effect_all = sum(descriptive_matrix(:,5))/length(list);

%%% INFERENTIAL STATS
% t-test: reaction time in congruent trials vs. incongruent trials

% create matrices with all participant's data for rt in congruent and
% incongruent trials
rt_congruent_trials = [];
rt_incongruent_trials = [];
for row = 1:size(experimental_data,1)
    if experimental_data(row,5) == 1  % trial was congruent
        rt_congruent_trials = [rt_congruent_trials; experimental_data(row,7)];
    else % trial was incongruent
        rt_incongruent_trials = [rt_incongruent_trials; experimental_data(row,7)];
    end
end

% perform paired t-test
% alpha = 0.05
[H,P,CI,STATS] = ttest(rt_congruent_trials,rt_incongruent_trials);

% correlation between trial and reaction time (boredom/improvement?)

% create matrix with trials (1-64) and reaction time over all participants
trial_rt_matrix_vp = zeros(64,2,18);
for vp = 1:length(list)
    vp_matrix = experimental_data(((vp-1)*64+1):((vp-1)*64+1)+63,:);
    % loop over all trials
    for r = 1:size(vp_matrix,1)
        trial_no = r;
        trial_rt = vp_matrix(r,7);
        trial_rt_matrix_vp(r,:,vp) = [trial_no trial_rt];
    end
end

% calculate average rt over all participants
trial_rt_matrix = mean(trial_rt_matrix_vp,3);

% correlate trials with reaction time
[r,p] = corr(trial_rt_matrix(:,1), trial_rt_matrix(:,2));

%% save results to file

% path of resultfiles
result_pathway = sprintf("/Users/Lucy/Documents/Berlin/FU/MCNB/1Semester/Programming/Project/StroopTask/results/");
results_descriptive_name = strcat(result_pathway,'stroop_results_descriptive.txt');
results_inf_name = strcat(result_pathway,'stroop_results_inferential.txt');
results_boxplot_name = strcat(result_pathway,'stroop_results_boxplot.txt');
results_corrplot_name = strcat(result_pathway,'stroop_results_corrplot.txt');

% create results matrix with variables of interest
results_descriptive = [percentage_correct_all average_rt_all rt_congruent_all rt_incongruent_all stroop_effect_all];
colHeaders_descriptive = {'percentage correct', 'average rt', 'rt congruent', 'rt incongruent', 'stroop effect'};
results_descriptive_table = array2table(results_descriptive,'VariableNames', colHeaders_descriptive);

results_inf = [P, CI(1), CI(2), STATS.tstat, STATS.df, STATS.sd, r, p];
colHeaders_inf = {'p-value of t-test', 'CI lower bound', 'CI upper bound', 't-value', 'df', 'sd', 'r-value of correlation', 'p-value of correlation'};
results_inf_table = array2table(results_inf,'VariableNames', colHeaders_inf);

results_boxplot = [rt_congruent_trials rt_incongruent_trials];
colHeaders_boxplot = {'rt congruent trials', 'rt incongruent trials'};
results_boxplot_table = array2table(results_boxplot,'VariableNames', colHeaders_boxplot);

results_corrplot = trial_rt_matrix;
colHeaders_corrplot = {'trials', 'rt time'};
results_corrplot_table = array2table(results_corrplot,'VariableNames', colHeaders_corrplot);

% write results to textfile with tab as delimiter
writetable(results_descriptive_table, results_descriptive_name, 'delimiter', '\t')
writetable(results_inf_table, results_inf_name, 'delimiter', '\t')
writetable(results_boxplot_table, results_boxplot_name, 'delimiter', '\t')
writetable(results_corrplot_table, results_corrplot_name, 'delimiter', '\t') 