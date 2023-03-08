%% Stroop task
function stroop(subNo)

% This is a simple Stroop task. It runs a test block where the participant
% can get familiar with the task's setup, and then runs a number of
% experimental blocks that can be specified in n_blocks.
% 
% Test block:
% The participant is first shown instructions on how the experiment works.
% After reading the instructions, the participant will be shown a fixation
% cross and then a stimuli consisting of a word that is either GREEN, BLUE,
% YELLOW or BLUE printed in the color corresponding to the word (congruent
% trials) or another color (incongruent trials). The participant has to
% respond to the print color and ignore the meaning of the word. After the
% participant's response, a feedback will be shown. Then, the next trial
% starts. After ten trials, the test block is over and the real experiment
% starts.
% 
% Experimental blocks:
% After the test block, the participant will again be prompted with the
% instructions. Then, the first experimental block will start. The
% procedure is the same as in the test blocks, except that now, the number
% of trials specified in no_trials will be shown per block.
%
% After the experiment is over, the participant will see a summary of the
% accuracy (AC) and reaction time (RT), including a measure for the stroop effect.
%
% Input:
%   subNo : subject number, default 66
%
% Output:
%   stroop_subxx.txt : result file with 'subID', 'block no', 
%               'test / experiment', 'trial no','congruency', 'accuracy',
%               'reaction time' of subject number xx


%%%%%%%%%%
% SET UP %
%%%%%%%%%%

% clear Matlab window
clc;

% comment out if PTB is not working (e.g., Apple Silicon M1 core)
Screen('Preference', 'SkipSyncTests', 1)

%%% basic experimental settings

% set default values for input argument
if ~exist('subNo','var')
    subNo = 66;
end

% warn if duplicate sub No
fileName = ['stroop_sub' num2str(subNo) '.txt'];
if exist(fileName,'file')
    resp = input(['The file ' fileName ' already exists. Do you want to overwrite it? [Type ok for overwrite]'], 's');
    if ~strcmp(resp,'ok') % abort experiment if overwriting was not confirmed
        disp('Experiment aborted')
        return
    end
end

% define number of blocks, trials and durations
n_blocks = 5; % number of blocks (including test block)
n_trials = 16; % number of trials per block (needs to be dividable by 8)
n_test_trials = 8; % number of test trials (needs to be dividable by 8)
n_total_trials = n_test_trials + (n_blocks-1)*n_trials;
trial_duration = 3; % duration of a trial in seconds
break_duration = 15; % duration of the break between blocks in seconds

% prepare result file
resultfilename = strcat('stroop_sub',num2str(subNo),'.txt'); % name of result file to write to
% prepare output of matlab
colHeaders = {'subID', 'block no', 'test / experiment', 'trial no',...
    'congruency', 'accuracy', 'reaction time'};
results = NaN * ones(n_total_trials,length(colHeaders)); % preallocate results matrix

%%%%%%%%%%%%%%%%%%%%%
% LISTS & SHUFFLING %
%%%%%%%%%%%%%%%%%%%%%

% create list of words
words = {'RED', 'GREEN', 'BLUE', 'YELLOW'};

% create list of font colors
red = [255 0 0];
green = [0 255 0];
blue = [0 0 255];
yellow = [255 255 0];
font_colors = {red, green, blue, yellow};

stim_matrix_cog = [words' font_colors']; % for congruent trials (same font as word)

% lists will be filled and shuffled in block loop

%%% setting up PTB and hardware

% make sure that PTB can run
AssertOpenGL;

% try catch construct to prevent user from getting stuck in PTB fullscreen
try
    % make sure keyboard mapping is the same on all supported operating systems
    % Apple MacOS/X, MS-Windows and GNU/Linux
    KbName('UnifyKeyNames');
    
    % do dummy calls to GetSecs, WaitSecs, KbCheck to make sure they are loaded
    % and ready when we need them - without delays in the wrong moment
    KbCheck;
    WaitSecs(0.1);
    GetSecs;
    
    % disable output of keypresses to Matlab
    ListenChar(2);
    
    % set higher DebugLevel
    olddebuglevel = Screen('Preference', 'VisualDebuglevel', 3);
    
    % identify screens
    screens = Screen('Screens');
    screenNumber = max(screens); % if a participant uses several screens, the one with the maximum index will be used
    
    % returns as default the mean black value of screen
    black = BlackIndex(screenNumber); 
    % open a black full screen window
    [w,rect] = Screen('OpenWindow',screenNumber,black); % w: window; rect: reactangle defining the size of that window
    
    % hide mouse cursor
    HideCursor;
    
    % set text size
    Screen('TextSize', w, 48);
    
    %%%%%%%%%%%%%%
    % EXPERIMENT %
    %%%%%%%%%%%%%%
    
    %%% instructions
    
    % This is our intro text
    intro = ['Stroop task instructions\n'...
        'In this task, you will see color names (red, green,\n'...
        'blue, yellow) in different print colors. You need\n'...
        'to respond to the print color. For example, if you\n'...
        'see:\n'...
        '\n\n\n'...
        'You need to respond to the print color (red), and\n'...
        'press the associated button ("r"). The other buttons\n'...
        'used in this study are "g","b", and "y", for green, blue,\n'...
        'and yellow.\n'...
        '(Press any key to continue)\n'];
    intro_color = 'GREEN\n';

    % draw intro text in the center of the display window in white color
    DrawFormattedText(w, intro, 'centerblock', 'center', WhiteIndex(w));
    DrawFormattedText(w, intro_color, 'centerblock', 'center', [255 0 0]);
    
    % show the drawn text at next display refresh cycle
    Screen('Flip', w); 
    
    % wait for keyboard stroke: first make sure that all keys are released,
    % then wait for a keypress and release
    KbWait([], 3);

    DrawFormattedText(w, ['You will first start with a test block '...
        'consisting of \n' num2str(n_test_trials) ' trials where you '...
        'can practice. After the test block is over,\n' ...
        'you will see the instructions again and then\n'...
        'the experiment will start.\n'...
        '(Press any key to continue)\n'], 'centerblock', 'center', WhiteIndex(w));
    Screen('Flip', w); 
    KbWait([], 3);

    % write subject number in result matrix
    results(1:n_total_trials, 1) = subNo;
    
    % block loop
    for b = 1:n_blocks
        
        %%% creating stimulus lists and shuffling

        if b == 1 % test block has a different number of trials than other blocks
            nu_trials = n_test_trials;
        else
            nu_trials = n_trials;
        end
    
        stim_matrix_cog_block = repmat(stim_matrix_cog,(0.25*nu_trials)/(0.5*size(stim_matrix_cog,1)),1); % half of trials should be congruent
        
        stim_matrix_incog_block = []; % for incongruent trials (different font as word)
        for t = 1:0.5*nu_trials % half of trials should be incongruent
            word = randsample(words,1); % choose a random word
            if word == "RED"
                font_colors_without_red = font_colors(2:end); % exclude congruent font
                font = randsample(font_colors_without_red,1); % choose random font
                stim_matrix_incog_block = [stim_matrix_incog_block;word font];
            elseif word == "GREEN"
                font_colors_without_green = font_colors([1 3:end]); % exclude congruent font
                font = randsample(font_colors_without_green,1); % choose random font
                stim_matrix_incog_block = [stim_matrix_incog_block;word font];
            elseif word == "BLUE"
                font_colors_without_blue = font_colors([1:2 end]); % exclude congruent font
                font = randsample(font_colors_without_blue,1); % choose random font
                stim_matrix_incog_block = [stim_matrix_incog_block;word font];
            elseif word == "YELLOW"
                font_colors_without_yellow = font_colors(1:3); % exclude congruent font
                font = randsample(font_colors_without_yellow,1); % choose random font
                stim_matrix_incog_block = [stim_matrix_incog_block;word font];
            end
        end
    
        stim_block = [stim_matrix_cog_block; stim_matrix_incog_block]; % add two lists together
        stim_list = stim_block(randperm(size(stim_block,1)),:); % shuffle final block test list

        %%% test block
        if b == 1

            % write block number in result matrix
            results(1:n_test_trials, 2) = b;
            % write whether block is test block (0) or experimental block (1) in result matrix
            results(1:n_test_trials, 3) = 0;

            DrawFormattedText(w, 'Are you ready for the experiment?\n(Press any key to start experiment)', 'centerblock', 'center', WhiteIndex(w));
            Screen('Flip', w);
            KbWait([], 3);
            
            % test trial loop
            for t = 1:n_test_trials

                % write trial number in result matrix
                results(t, 4) = t;

                %%% presenting stimuli
                
                % display fixation cross
                FixCr = ones(20,20)*0;
                FixCr(10:11,:) = 255;
                FixCr(:,10:11) = 255;  % try imagesc(FixCr) to display the result in Matlab
                fixcross = Screen('MakeTexture',w,FixCr);
                Screen('DrawTexture', w, fixcross)
                tfixation = Screen('Flip',w);

                % present stimulus for max. 3s or until a key is pressed
                DrawFormattedText(w, stim_list{t, 1}, 'centerblock', 'center', [stim_list{t, 2}]);
                [VBLTimestamp, startrt] = Screen('Flip', w, tfixation + 0.5);
                
                while (GetSecs - startrt) <= trial_duration
                    [keyIsDown, endrt, keyCode] = KbCheck; % get participant response
                    keyCode = find(keyCode, 1); % converts 1 to actual key pressed
                    % check whether key pressed responds to stimulus font color
                    anscorrect = 0;
                    if stim_list{t,2} == red
                       targetkey = KbName('r');
                       if keyCode == targetkey
                          anscorrect = 1;
                       end
                    elseif stim_list{t,2} == blue
                        targetkey = KbName('b');
                        if keyCode == targetkey
                            anscorrect = 1;
                        end
                    elseif stim_list{t,2} == yellow
                         targetkey = KbName('z'); % y is z on German keyboards (change when using English keyboard)
                         if keyCode == targetkey
                            anscorrect = 1;
                         end
                    elseif stim_list{t,2} == green 
                         targetkey = KbName('g');
                         if keyCode == targetkey
                            anscorrect = 1;
                         end
                    end
                    if keyIsDown
                        break
                    else
                        endrt = startrt + 3;
                    end
                end
                
    
                % give feedback whether response was correct or incorrect
                % (should we set up a timing?) 
                if anscorrect == 1
                   DrawFormattedText(w, 'Correct!', 'centerblock', 'center', WhiteIndex(w));
                else 
                   DrawFormattedText(w, 'Incorrect!', 'centerblock', 'center', WhiteIndex(w));
                end
                Screen('Flip', w)
                WaitSecs(0.75)
    
    
                %%% writing results into results matrix
                % congruency
                if ((stim_list{t,1} == "RED" & stim_list{t,2} == red ) | ... 
                    (stim_list{t,1} == "GREEN" & stim_list{t,2} == green ) | ... 
                    (stim_list{t,1} == "BLUE" & stim_list{t,2} == blue ) | ... 
                    (stim_list{t,1} == "YELLOW" & stim_list{t,2} == yellow ))
                    results(t, 5) = 1; % congruent
                else 
                    results(t, 5) = 0; % incongruent
                end
                
                % accuracy
                results(t, 6) = anscorrect;
                
                % reaction time
                rt = endrt - startrt;
                results(t, 7) = rt;
    
            end % end of test trial loop
    
            % display end of test block message
            DrawFormattedText(w, ['This was the end of the test block.\n' ...
                'You will now have a short break of ' num2str(break_duration)...
                ' seconds.\n After the break, you will see the instructions \n'...
                'again. Then the experiment will start.\n'...
                '(Press any key to skip the break and continue right now)\n'],...
                'centerblock', 'center', WhiteIndex(w));
            Screen('Flip', w);
            startSecs = GetSecs; % get current time
            endbreak = startSecs + break_duration; % calculate time of break end
            KbWait([], 3, endbreak); % wait until break end or until a key is pressed
    
        %%%% experimental blocks
        else

            % write block number in result matrix
            if b == 2
                results((n_test_trials+1):(n_test_trials+n_trials+1), 2) = b;
                % write whether block is test block (0) or experimental block (1) in result matrix
                results((n_test_trials+1:n_test_trials+n_trials+1), 3) = 1;
            else
                results((n_test_trials+(b-2)*n_trials+1):(n_test_trials+(b-2)*n_trials+n_trials), 2) = b;
                % write whether block is test block (0) or experimental block (1) in result matrix
                results((n_test_trials+(b-2)*n_trials+1):(n_test_trials+(b-2)*n_trials+n_trials), 3) = 1;
            end

            if b == 2
    
                % display instructions again
                DrawFormattedText(w, ['The experiment will start shortly.\n' ...
                    'Here is a small reminder of the instructions:\n\n'...
                    'You will see color names in different print colors.\n'...
                    'Your task is to respond to the print color by pressing\n'...
                    '"r" for red, "g" for green,"b" for blue, and "y" for yellow.\n'...
                    'The experiment will consist of ' num2str(n_blocks-1) ' blocks.\n'...
                    'At the end of each block, you will have a short break of\n' ...
                    num2str(break_duration) ' seconds. You will get a feedback on your performance at\n' ...
                    'end of the experiment.\nThank you for participating!\n' ...
                    '(Press any key to start the experiment)'],...
                    'centerblock', 'center', WhiteIndex(w));
                Screen('Flip', w);
                KbWait([], 3)
    
            end
    
            % trial loop
            for t = 1:n_trials
               
                % write trial number in result matrix
                if b == 2
                    results(n_test_trials+t, 4) = t;
                else
                    results((n_test_trials+(b-2)*n_trials)+t, 4) = t;
                end

                %%% presenting stimuli
 
                % display fixation cross
                FixCr = ones(20,20)*0;
                FixCr(10:11,:) = 255;
                FixCr(:,10:11) = 255;  % try imagesc(FixCr) to display the result in Matlab
                fixcross = Screen('MakeTexture',w,FixCr);
                Screen('DrawTexture', w, fixcross)
                tfixation = Screen('Flip', w);

                % present stimulus for max. 3s or until a key is pressed
                DrawFormattedText(w, stim_list{t, 1}, 'centerblock', 'center', [stim_list{t, 2}]);
                [VBLTimestamp, startrt] = Screen('Flip', w, tfixation + 0.5);
                
                while (GetSecs - startrt) <= trial_duration
                    [keyIsDown, endrt, keyCode ] = KbCheck; % get participant response
                    keyCode = find(keyCode, 1); % converts 1 to actual key pressed
                    % check whether key pressed responds to stimulus font color
                    anscorrect = 0;
                    if stim_list{t,2} == red
                       targetkey = KbName('r');
                       if keyCode == targetkey
                          anscorrect = 1;
                       end
                    elseif stim_list{t,2} == blue
                        targetkey = KbName('b');
                        if keyCode == targetkey
                            anscorrect = 1;
                        end
                    elseif stim_list{t,2} == yellow
                         targetkey = KbName('z'); % y is z on German keyboards (change when using English keyboard)
                         if keyCode == targetkey
                            anscorrect = 1;
                         end
                    elseif stim_list{t,2} == green 
                         targetkey = KbName('g');
                         if keyCode == targetkey
                            anscorrect = 1;
                         end
                    end
                    if keyIsDown
                        break
                    else
                        endrt = startrt + 3;
                    end
                end
                
    
                % give feedback whether response was correct or incorrect
                % (should we set up a timing?) 
                if anscorrect == 1
                   DrawFormattedText(w, 'Correct!', 'centerblock', 'center', WhiteIndex(w));
                else 
                   DrawFormattedText(w, 'Incorrect!', 'centerblock', 'center', WhiteIndex(w));
                end
                Screen('Flip', w)
                WaitSecs(0.75)
    
    
                %%% writing results into results matrix
                % congruency
                if ((stim_list{t,1} == "RED" & stim_list{t,2} == red ) | ... 
                    (stim_list{t,1} == "GREEN" & stim_list{t,2} == green ) | ... 
                    (stim_list{t,1} == "BLUE" & stim_list{t,2} == blue ) | ... 
                    (stim_list{t,1} == "YELLOW" & stim_list{t,2} == yellow ))
                    if b == 2
                        results(n_test_trials+t, 5) = 1; % congruent
                    else
                        results((n_test_trials+(b-2)*n_trials)+t, 5) = 1; % congruent
                    end
                else
                    if b == 2
                        results(n_test_trials+t, 5) = 0; % incongruent
                    else
                        results((n_test_trials+(b-2)*n_trials)+t, 5) = 0; % incongruent
                    end
                end

                % accuracy
                if b == 2
                    results(n_test_trials+t, 6) = anscorrect;
                else
                    results((n_test_trials+(b-2)*n_trials)+t, 6) = anscorrect;
                end
                
                % reaction time
                rt = endrt - startrt;
                if b == 2
                    results(n_test_trials+t, 7) = rt;
                else
                    results((n_test_trials+(b-2)*n_trials)+t, 7) = rt;
                end

            end % end of trial loop
    
            if b == n_blocks
    
                % display end of whole experiment message
                DrawFormattedText(w, ['This was the end of the last block.\n' ...
                    'The experiment is over. Thank you for participating!\n'...
                    '(Press any key to see your results)\n'],...
                    'centerblock', 'center', WhiteIndex(w));
                Screen('Flip', w);
                KbWait([], 3)
    
            else
    
                % display end of block message
                DrawFormattedText(w, ['This was the end of the ' num2str(b-1) '. block.\n' ...
                    'You will now have a short break of ' num2str(break_duration)...
                    ' seconds.\nAfter the break, the next block will start.\n'...
                    '(Press any key to skip the break and continue right now)\n'],...
                    'centerblock', 'center', WhiteIndex(w));
                Screen('Flip', w);
                startSecs = GetSecs; % get current time
                endbreak = startSecs + break_duration; % calculate time of break end
                KbWait([], 3, endbreak); % wait until break end or until a key is pressed
    
            end
    
        end
    
    end % end of block loop
    
    %%% present results

    % create new results matrix with experimental trials only (test trials are ignored)
    results_experiment = [];
    for i = 1:size(results,1)
        if results(i,3) == 1 % if ith trial was an experimental trial
            results_experiment = [results_experiment; results(i,:)];
        end
    end

    sum_correct = 0;
    sum_all = 0;
    sum_rt = 0;
    sum_rt_congruent = 0;
    sum_rt_incongruent = 0;
    sum_congruent = 0;
    sum_incongruent = 0;
    for r = 1:size(results_experiment,1)
        sum_correct = sum_correct + results_experiment(r,6); % add accuracy value (1 = correct; 0 = incorrect)
        sum_all = sum_all + 1;
        sum_rt = sum_rt + results_experiment(r,7); % add reaction time
        if results_experiment(r,5) == 1 % if trial was congruent
            sum_rt_congruent = sum_rt_congruent + results_experiment(r,7);
            sum_congruent = sum_congruent + 1;
        else % if trial was incongruent
            sum_rt_incongruent = sum_rt_incongruent + results_experiment(r,7);
            sum_incongruent = sum_incongruent + 1;
        end
    end
    
    percentage_correct = round((sum_correct/sum_all),2) * 100; % percentage of correct answers
    average_rt = round((sum_rt/sum_all),3) * 1000; % average reaction time over all trials
    rt_congruent = round((sum_rt_congruent/sum_congruent),3) * 1000; % average reaction time in congruent trials
    rt_incongruent = round((sum_rt_incongruent/sum_incongruent),3) * 1000; % average reaction time in incongruent trials
    stroop_effect = rt_incongruent - rt_congruent; % stroop effect (incongruent - congruent)

    DrawFormattedText(w, ['Results Summary:\nCorrect Answers: '...
        num2str(sum_correct) ' trials out of ' num2str(n_total_trials - n_test_trials)...
        ' trials\nPercentage of Correct Answers: '...
        num2str(percentage_correct) ' %\nAverage Reaction Time: '...
        num2str(average_rt) ' ms\nReaction Time in Congruent Trials: '...
        num2str(rt_congruent) ' ms\nReaction Time in Incongruent Trials: '...
        num2str(rt_incongruent) ' ms\nStroop Effect: ' ...
        num2str(stroop_effect) ' ms\n'...
        '(Press any key to exit the experiment)\n'],...
        'centerblock', 'center', WhiteIndex(w));
    Screen('Flip', w);
    KbWait([], 3)   

    % add column headings to result matrix
    result_table = array2table(results,'VariableNames', colHeaders);
    % write results to textfile with tab as delimiter
    writetable(result_table, resultfilename, 'delimiter', '\t')
    
    %%%%%%%%%%%%
    % CLEAN UP %
    %%%%%%%%%%%%

    ShowCursor;
    sca; % or sca
    ListenChar(0);
    Screen('Preference', 'VisualDebuglevel', olddebuglevel);

catch
    
    % this section is executed only in case an error happens in the
    % experiment code implemented between try and catch
    ShowCursor;
    sca; % or sca
    ListenChar(0);
    Screen('Preference', 'VisualDebuglevel', olddebuglevel);
    % output the error message
    psychrethrow(psychlasterror);

end