import os
import pandas as pd
import numpy as np

import matplotlib.pyplot as plt
import itertools
import heartpy as hp
from scipy.signal import welch


def plot_all_combinations(subject_id, dataframe):
    variables = [col for col in dataframe.columns if col.startswith(('heartVariability', 'heartRateDeviation', 'heartRateMean'))]
    combinations = list(itertools.combinations(variables, 2))

    num_rows = len(combinations) // 10 + len(combinations) % 10
    fig, axs = plt.subplots(num_rows, 10, figsize=(15, num_rows * 5))

    for index, (var1, var2) in enumerate(combinations):
        ax = axs[index // 10, index % 10]

        awake = dataframe[dataframe['stage'] == 0]
        asleep = dataframe[dataframe['stage'] > 0]

        ax.scatter(awake[var1], awake[var2], c='blue', label='Awake')
        ax.scatter(asleep[var1], asleep[var2], c='red', label='Asleep')

        ax.set_title(f'Sleep Stages for Subject {subject_id}')
        ax.set_xlabel(var1)
        ax.set_ylabel(var2)
        ax.legend()

    plt.tight_layout()
    plt.show()

def plot_sleep_stages(subject_id, dataframe):
    fig, ax = plt.subplots()

    awake = dataframe[dataframe['stage'] == 0]

    asleep = dataframe[dataframe['stage'] > 0]

    ax.scatter(awake['heartVariability_last_1_min'], awake['heartVariability_last_30_min'], c='blue', label='Awake')
    ax.scatter(asleep['heartVariability_last_1_min'], asleep['heartVariability_last_30_min'], c='red', label='Asleep')

    ax.set_title(f'Sleep Stages for Subject {subject_id}')
    ax.set_xlabel('heartVariability_last_1_min')
    ax.set_ylabel('heartVariability_last_30_min')
    ax.legend()

    plt.show()

def create_dataframe(subject_data, feature_extraction=False):

    heart_rate_data = [x for x in subject_data if 'heart_rate' in x]
    sleep_stage_data = [x for x in subject_data if 'stage' in x]
    heart_rate_df = pd.DataFrame(heart_rate_data).sort_values(by='seconds')
    sleep_stage_df = pd.DataFrame(sleep_stage_data).sort_values(by='seconds')


    heart_rate_df['stage'] = None
    last_sleep_stage_time = sleep_stage_df['seconds'].max()
    for index, row in heart_rate_df.iterrows():
        if row['seconds'] < 0:
            heart_rate_df.at[index, 'stage'] = 0
        elif row['seconds'] > last_sleep_stage_time:
            heart_rate_df.at[index, 'stage'] = None
        else:
            closest_index = sleep_stage_df['seconds'].sub(row['seconds']).abs().idxmin()
            heart_rate_df.at[index, 'stage'] = sleep_stage_df.at[closest_index, 'stage']

    heart_rate_df.dropna(subset=['stage'], inplace=True)
    heart_rate_df.index = pd.to_timedelta(heart_rate_df['seconds'], unit='s')
    time_windows = ['5T', '10T', '30T']  # 'T' stands for minutes
    heart_rate_df['rr_interval'] = 60000 / heart_rate_df['heart_rate']

    for window in time_windows:
        heart_rate_df[f'heartRateDeviation_last_{window[:-1]}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).apply(lambda x: np.std(x) / np.mean(x), raw=True)
        #heart_rate_df[f'heartRateMean_last_{window//60}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).mean()
    

    for window in time_windows:
        minute_value = int(window[:-1])
        heart_rate_df[f'heartVariability_last_{minute_value}_min'] = heart_rate_df['rr_interval'].rolling(window=window, min_periods=1, center=False).apply(lambda x: np.std(x), raw=True)
        heart_rate_df[f'RMSSD_last_{window[:-1]}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).apply(rmssd, raw=True)

    for window in time_windows:
        mean_heart_rate = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1).mean()
        heart_rate_df[f'heart_rate_last_{window[:-1]}_min'] = heart_rate_df['heart_rate'] / mean_heart_rate
        
    heart_rate_df.dropna(subset=['heart_rate'], inplace=True)
    heart_rate_data.dropna(subset=['rr_interval'], inplace=True)
    return heart_rate_df

def create_dataframe__(subject_data, feature_extraction=False):

    heart_rate_data = [x for x in subject_data if 'heart_rate' in x]
    sleep_stage_data = [x for x in subject_data if 'stage' in x]
    heart_rate_df = pd.DataFrame(heart_rate_data).sort_values(by='seconds')
    sleep_stage_df = pd.DataFrame(sleep_stage_data).sort_values(by='seconds')


    heart_rate_df['stage'] = None
    last_sleep_stage_time = sleep_stage_df['seconds'].max()
    for index, row in heart_rate_df.iterrows():
        if row['seconds'] < 0:
            heart_rate_df.at[index, 'stage'] = 0
        elif row['seconds'] > last_sleep_stage_time:
            heart_rate_df.at[index, 'stage'] = None
        else:
            closest_index = sleep_stage_df['seconds'].sub(row['seconds']).abs().idxmin()
            heart_rate_df.at[index, 'stage'] = sleep_stage_df.at[closest_index, 'stage']

    heart_rate_df.dropna(subset=['stage'], inplace=True)

    time_windows = [60, 60*5, 60*10, 60*30, 60*60]  # 1, 5, 10, and 30 minutes in seconds
    for window in time_windows:
        print(heart_rate_df)
        heart_rate_df[f'heartRateDeviation_last_{window//60}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).apply(lambda x: np.std(x) / np.mean(x), raw=True)
        #heart_rate_df[f'heartRateMean_last_{window//60}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).mean()
    

    for window in time_windows:
        heart_rate_df[f'heartVariability_last_{window//60}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).apply(lambda x: np.std(x), raw=True)
        heart_rate_df[f'RMSSD_last_{window//60}_min'] = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1, center=False).apply(rmssd, raw=True)

    for window in time_windows:
        mean_heart_rate = heart_rate_df['heart_rate'].rolling(window=window, min_periods=1).mean()
        heart_rate_df[f'heart_rate_last_{window//60}_min'] = heart_rate_df['heart_rate'] / mean_heart_rate
    
    heart_rate_df.dropna(subset=['heart_rate'], inplace=True)
    return heart_rate_df


def rmssd(rr_intervals):
    if len(rr_intervals) <= 1:
        return 0
    differences = np.diff(rr_intervals)
    squared_diff = np.square(differences)
    mean_squared_diff = np.mean(squared_diff)
    return np.sqrt(mean_squared_diff)

def getData():

    data_dict = {}

    # loop through the heart_rate directory and read the files
    for filename in os.listdir('data/hr_data/heart_rate'):
        if filename.endswith('.txt') and 'heart' in filename:
            subject_id = filename.split('_')[0]
            with open(os.path.join('data/hr_data/heart_rate', filename), 'r') as f:
                for line in f:
                    # split the line into seconds and heart rate values
                    seconds, heart_rate = line.strip().split(',')
                    # add the data to the dictionary
                    if subject_id in data_dict:
                        data_dict[subject_id].append({'filename': filename, 'seconds': float(seconds), 'heart_rate': float(heart_rate)})
                    else:
                        data_dict[subject_id] = [{'filename': filename, 'seconds': float(seconds), 'heart_rate': float(heart_rate)}]

    # loop through the labels directory and read the files
    for filename in os.listdir('data/hr_data/labels') :
        if filename.endswith('_labeled_sleep.txt'):
            subject_id = filename.split('_')[0]
            with open(os.path.join('data/hr_data/labels', filename), 'r') as f:
                for line in f:
                    # split the line into date and stage values
                    date, stage = line.strip().split()
                    # add the data to the dictionary
                    if subject_id in data_dict:
                        data_dict[subject_id].append({'filename': filename, 'seconds': float(date), 'stage': float(stage)})
                    else:
                        data_dict[subject_id] = [{'filename': filename, 'seconds': float(date), 'stage': float(stage)}]

    
    l = len(data_dict.items())
    x = 0
    dataframes = {}
    for subject_id, subject_data in data_dict.items():
        print('x'*x, '-'*(l-x))
        dataframes[subject_id] = create_dataframe(subject_data)
        x+=1
    
    return dataframes
        
def getTestData():

    data_dict = {}

    # loop through the heart_rate directory and read the files
    for filename in os.listdir('data/test'):
        if filename.endswith('.txt') and 'heart' in filename:
            subject_id = filename.split('_')[0]
            with open(os.path.join('data/test', filename), 'r') as f:
                for line in f:
                    # split the line into seconds and heart rate values
                    seconds, heart_rate = line.strip().split(',')
                    # add the data to the dictionary
                    if subject_id in data_dict:
                        data_dict[subject_id].append({'filename': filename, 'seconds': float(seconds), 'heart_rate': float(heart_rate)})
                    else:
                        data_dict[subject_id] = [{'filename': filename, 'seconds': float(seconds), 'heart_rate': float(heart_rate)}]

    # loop through the labels directory and read the files
    for filename in os.listdir('data/test') :
        if filename.endswith('_labeled_sleep.txt'):
            subject_id = filename.split('_')[0]
            with open(os.path.join('data/test', filename), 'r') as f:
                for line in f:
                    # split the line into date and stage values
                    date, stage = line.strip().split()
                    # add the data to the dictionary
                    if subject_id in data_dict:
                        data_dict[subject_id].append({'filename': filename, 'seconds': float(date), 'stage': float(stage)})
                    else:
                        data_dict[subject_id] = [{'filename': filename, 'seconds': float(date), 'stage': float(stage)}]

    
    dataframes = {}
    for subject_id, subject_data in data_dict.items():
        dataframes[subject_id] = create_dataframe(subject_data)
    return dataframes



if __name__ == '__main__':
    dataframes = getData()
