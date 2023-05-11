from flask import Flask, jsonify, request,send_file
from tensorflow.keras.models import load_model
import os
from datetime import datetime, timedelta
import pickle
from preproccess_and_combine_data import SleepStage, rmssd, combine_stages, prepare_data_for_training, combine_pred, change_values_to_majority, create_dataframe, my_main
import uuid
import shutil
app = Flask(__name__)
hr_path = 'data/hr_data.txt'

def write_error_to_file(error_message: str, file_name: str):
    with open(file_name, 'a') as error_file:
        error_file.write(error_message + "\n")

def find_closest_datetime(time_str):
    now = datetime.now()
    time = datetime.strptime(time_str, "%H:%M").time()
    target = datetime.combine(now.date(), time)
    if now.time() > target.time():
        target += timedelta(days=1)
    return target
    
def find_optimal_wakeup(sleep_stages, timestamps, alarm_time, givefront, giveback):

    if len(sleep_stages) != len(timestamps):
        error_message = f"Error: Lengths of sleep_stages ({len(sleep_stages)}) and timestamps ({len(timestamps)}) are not equal."

        error_file_name = "error_log.txt"
        write_error_to_file(error_message, error_file_name)
        
        
    difference = (timestamps[-1] - alarm_time).total_seconds()

    X = 5 * 60 # number of seconds of deep sleep required to not wake up during leeway
    updated_alarm_time = alarm_time

    if difference <= 0 and abs(difference) < givefront:
        #We have entered the leeway and the alarm is ahead
        deep_sleep_duration = 0
        start_time = None
        end_time = None

        for i in range(len(sleep_stages)):
            if sleep_stages[-1] == 3 or sleep_stages[-1] == 2:
                if start_time is None:
                    start_time = timestamps[i]
                end_time = timestamps[i]

            else:
                if start_time is not None and end_time is not None:
                    deep_sleep_duration += (end_time - start_time).total_seconds()
                start_time = None
                end_time = None

        if start_time is not None and end_time is not None:
            deep_sleep_duration += (end_time - start_time).total_seconds()

        if deep_sleep_duration < X:
            if sleep_stages[-1] == 3 or sleep_stages[-1] == 2:
                updated_alarm_time = timestamps[-1]  # Wake up user now
            else:
                updated_alarm_time = alarm_time  # Set alarm for normal time

        else:
            if sleep_stages[-1] == 3 or sleep_stages[-1] == 2:
                updated_alarm_time = alarm_time + timedelta(seconds=giveback)  # Set alarm for max giveBack
            else:
                updated_alarm_time = alarm_time  # Set alarm for normal time

    elif difference > 0 and abs(difference) < giveback:

        if sleep_stages[-1] == 3 or sleep_stages[-1] == 2:
            updated_alarm_time = alarm_time + timedelta(seconds=giveback)  # Set alarm for max giveBack
        else:
            updated_alarm_time = timestamps[-1]  # Wake up user now

    else:
        return updated_alarm_time
    return updated_alarm_time



def convert_seconds_to_dataetime(seconds_list, dt):
    date_times = []
    for sec in seconds_list:
        date_time = dt + timedelta(seconds=sec)
        date_times.append(date_time)
    return date_times

def get_heart_rate():
    first_line = True
    with open(hr_path) as f:
       
        data = f.read().strip().split('\n')

    time_list = []
    value_list = []
    first_line = True
    for line in data:
        if first_line:
            first_line = False
            continue
        time, value = line.split(',')
        time_list.append(float(time))
        value_list.append(int(value))

    return time_list, value_list

def transformdata(result_lines):
    data_dict = []
    for line in result_lines:
        seconds, heart_rate = line.strip().split(',')
        data_dict.append({'filename': 'test', 'seconds': float(seconds), 'heart_rate': float(heart_rate)})


    testing_dataframes = create_dataframe(data_dict)

    with open('preproccessedData/testing_dataframes.pkl', 'wb') as f:
        pickle.dump(testing_dataframes, f)
    pred = my_main()
    return pred
@app.route('/get_sleep_pattern', methods=['POST'])
def get_sleep_pattern():
    print("got")
    data = request.get_json()
    heartRateSamples = data['heartRateSamples']
    heart_rate_dates_str = data['heartRateDates']
    start_date = data['startDate']

    # Use '%H:%M' format to parse hour and minute
    heart_rate_dates = [datetime.strptime(date_str, '%H:%M:%S') for date_str in heart_rate_dates_str]
    start_date_datetime = datetime.strptime(start_date, '%H:%M:%S')
    result_lines = []
    for heart_rate, heart_rate_date in zip(heartRateSamples, heart_rate_dates):
        time_diff = heart_rate_date - start_date_datetime
        result_lines.append(f"{time_diff.total_seconds()},{int(heart_rate)}")


    pred = transformdata(result_lines)
    
    print(pred) # pred is of type list
    print(len(pred))
    return jsonify({'pred': pred})
@app.route('/predict', methods=['POST'])
def predict():
    
    # Get the input data from the request
    data = request.get_json()
    uuid = data['uuid']
    start_date_str = data['startDate']
    start_date = datetime.fromisoformat(start_date_str.rstrip("Z"))
    heart_rate_samples = data['heartRateSamples']
    heart_rate_dates_str = data['heartRateDates']
    heart_rate_n = data['NHeart']
    heart_rate_dates = [datetime.fromisoformat(date_str.rstrip("Z")) for date_str in heart_rate_dates_str]
    alarm = data['alarm']
    giveBack = data['giveBack']
    giveFront = data['giveFront']
    if len(alarm) == 0:
        return jsonify({})
    result_lines = []
    for heart_rate, heart_rate_date in zip(heart_rate_samples, heart_rate_dates):
        time_diff = heart_rate_date - start_date
        result_lines.append(f"{time_diff.total_seconds()},{int(heart_rate)}")


    last_time_diff = None
    try:
        with open(hr_path, "r") as file:
            lines = file.readlines()
            first_line = lines[0]
            last_line = lines[-1]
            last_time_diff = float(last_line.split(',')[0])
    except (FileNotFoundError, IndexError, ValueError):
        print(f"Error trying to open the hr file {FileNotFoundError} {IndexError}")

    if last_time_diff == None:
        with open(hr_path, 'w') as file:
            file.write(uuid + '\n')
    else:
        if uuid != first_line.strip():
            print(f"WARNING: CHANGING UUID. uuid is ({uuid}) and compairer is ({first_line.strip()})")
            
            # Saving the existing file to a new file in /storage
            storage_path = 'data/storage/'
            new_file_name = f"{uuid}_backup.txt"
            new_file_path = os.path.join(storage_path, new_file_name)
            shutil.copy(hr_path, new_file_path)


            with open(hr_path, 'w') as file:
                file.write(uuid + '\n')
    found_match = False
    with open(hr_path, "a") as file:
        for line in result_lines:
            current_time_diff = float(line.split(',')[0])
            if current_time_diff == last_time_diff:
                found_match = True

            if last_time_diff is None or current_time_diff > last_time_diff:
                file.write(line + '\n')
                last_time_diff = current_time_diff
    if not found_match:
        print("DID NOT FIND MATCH")



    time_list, heart_rates = get_heart_rate()
    assert len(heart_rates) == len(time_list)
    try:
        pred = transformdata([f"{s},{int(h)}" for s,h in zip(time_list, heart_rates)])  
    except KeyError: 
        return jsonify({'NewAlarm':  str(alarm)})  
       
    time_list = convert_seconds_to_dataetime(time_list, start_date)
    alarm = find_closest_datetime(alarm)
    newAlarm = find_optimal_wakeup(pred, time_list, alarm, giveFront*60, giveBack*60)
    print(newAlarm)
    return jsonify({'NewAlarm':  str(newAlarm)})

@app.route('/reportBug', methods=['POST'])
def reportBug():
    bugPath = "data"
    data = request.get_json()
    bug = data['bug']

    filename = "bug_reports.txt"


    if not os.path.exists(bugPath):
        os.makedirs(bugPath)


    with open(os.path.join(bugPath, filename), 'a') as file:
        file.write("\n\n"+"^"*10 + "\n")
        file.write(f"{bug}")
        file.write("\n"+"v"*10 + "\n\n")
    return {"success": True, "message": "Bug report saved."}


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
