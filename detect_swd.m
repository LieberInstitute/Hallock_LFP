function [peaks, density, density_time] = detect_swd(test_EEG, fs)
%%

%As described in Born et al., 2014

%hlh 112916
%hlh 113016
%hlh 120116

% Input:
%   train_EEG :: Continuously sampled data used to establish baseline power
%   test_EEG :: Continuously sampled data used for SWD detection
%   fs :: Sampling rate (Hz)

% Output:
%   peaks :: Index of SWD peaks within test_EEG
%   density :: SWD event probability (per minute time bin)
%   density_time :: SWD event probability as a function of time
%                   (size(density_time,2)) = number of minutes in session

%%
% Born et al., 2014 uses EEG from "low SWD" epochs (12:00 - 1:00 a.m.) to
% calculate baseline power and s.d. 

%train_EEG = detrend_LFP(train_EEG');
%train_EEG = train_EEG';

%winsize = fs*2;
%win_idx = [1 : winsize : length(train_EEG)];

%for wini = 1:length(win_idx)-1
%    train_temp = train_EEG(win_idx(1,wini):win_idx(1,wini+1));
%    train_temp = abs(train_temp);
%    avg_amp(1,wini) = mean(train_temp);
%end

%baseline_power = mean(avg_amp);
%baseline_std = std(avg_amp);

%%
% It seems much easier to just use the z-scores from the EEG itself to
% identify peaks. A standard deviation of 8 is an arbitrary value chosen
% by trial and error - the 2.5 s.d. value in the Born paper was much too
% low for this data set. A s.d. of 6 captures some false positives, and a
% s.d. of 8 is probably a bit too conservative, so this will have to be
% tweaked.

%test_EEG = detrend_LFP(test_EEG');
%test_EEG = test_EEG';

%test_normalized = bsxfun(@rdivide, bsxfun(@minus, test_EEG, baseline_power), baseline_std);
test_normalized = zscore(test_EEG);
test_normalized = abs(test_normalized);

peak_idx = find(test_normalized >= 8);

%%
% Born et al. identifies SWD events as short in duration, no longer than
% 5-15 ms. In reality, this seems unreasonably short, but this will need
% further tweaking.

%swd_lim = fs*0.0015;
%swd_lim = round(swd_lim);

%for peaki = 1:length(peak_idx)
%    if test_normalized(peak_idx(1,peaki)-swd_lim) < 2.5 && test_normalized(peak_idx(1,peaki)+swd_lim) < 2.5
%        swd_idx(1,peaki) = 1;
%    else
%        swd_idx(1,peaki) = 0;
%    end
%end

%%
% Try to identify individual SWD events by isolating peaks that occur more
% than 500 milliseconds apart. Find the center of each individual SWD event
% and index it so that you can find it in the raw EEG.

peak_cell = {};
counter = 1;
idx = 1;

for i = 1:length(peak_idx)-1
    if (peak_idx(1,i+1) - peak_idx(1,i)) > fs/2
       peak_cell{counter} = peak_idx(1,idx:i);
       idx = i+1;
       counter = counter+1;
    end
end

for celli = 1:size(peak_cell,2)
    peak_temp = peak_cell{1,celli};
    peak_test = test_normalized(peak_temp);
    [~, max_idx] = max(peak_test);
    max_idx = max_idx(1,1);
    peaks(1,celli) = peak_temp(1,max_idx);
    clear peak_temp peak_test max_idx
end

%%
% Calculate SWD probability by dividing number of SWD events by length of
% the recording session (minutes). Calculate SWD probability for each
% minute of the recording session.

num_sec = length(test_EEG)/fs;
num_min = num_sec/60;

if exist ('peaks', 'var') == 0
    error('No SWD events detected');
end

density = length(peaks)/num_min;

time = [1 : fs*60 : length(test_EEG)];

for i = 1:length(time)-1
    density_idx = find(peaks > time(1,i) & peaks < time(1,i+1));
    density_time(1,i) = length(density_idx);
end
%%

%for i = 1:length(peak_idx)
%    if swd_idx(1,i) == 0
%        peak_idx(1,i) = 0;
%    end
%end

%peak_idx(peak_idx == 0) = [];


        
   


    




