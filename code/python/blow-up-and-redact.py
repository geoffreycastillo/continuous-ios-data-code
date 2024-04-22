from pathlib import Path
import pandas
import json


def json_to_series(text):
    """
    Adapted from https://stackoverflow.com/a/25512372/3248229
    """
    keys, values = zip(*[item for dct in json.loads(text) for item in dct.items()])
    keys = list(keys)
    num_matches = len(json.loads(text))
    data_per_match = len(keys)
    for i in range(0, len(keys)):
        for num_match in range(1, num_matches + 1):
            if i > (num_match - 1) * data_per_match - 1 and i <= num_match * data_per_match - 1:
                keys[i] = 'match' + str(num_match - 1) + '.' + keys[i]
    return pandas.Series(values, index=keys)


print("Redacting the data...")

if Path('./redacted-data/data.csv').exists():
    print(f"The file redacted-data/data.csv already exists.")
else:
    # load otree data
    try:
        otree_data = pandas.read_csv('unredacted-data/data-objective-distance-corrected.csv')
    except FileNotFoundError:
        otree_data = pandas.read_csv('unredacted-data/data.csv')

    # keep only participants who made it to the end
    otree_data = otree_data[(otree_data['participant._current_page_name'] == 'End')
                            & (otree_data['participant.mturk_worker_id'].notnull())]

    # find who is mTurker
    otree_data['is_mturker'] = otree_data['participant.mturk_worker_id'].notnull()

    # create a unique ID
    otree_data['participant_unique_id'] = otree_data.groupby(['participant.mturk_worker_id']).ngroup()

    # blow up the data from the matches
    # do it only if we're not in the no transparency batch (in there we didn't save the data of the matches, just the codes)
    if 'survey.1.player.matches' in otree_data.columns:
        matches_column = 'survey.'
    elif 'survey_matching.1.player.matches' in otree_data.columns:
        matches_column = 'survey_matching.'
    else:
        raise ValueError('Cannot find the column survey.1.player.matches or survey_matching.1.player.matches')

    matches_column = matches_column + '1.player.matches'

    otree_data = pandas.concat([otree_data, otree_data[matches_column].apply(json_to_series)], axis=1)

    for column in otree_data:
        if any(string in column for string in ['mturk_worker_id', 'mturk_assignment_id']):
            otree_data.loc[otree_data['is_mturker'] == True, column] = [string[:4] + '*****' + string[-4:]
                                                                        for string in otree_data.loc[otree_data['is_mturker'] == True, column]]

    # drop columns
    otree_data = otree_data.drop(columns=[
        'revealed.27.player.payment_info',
        'Recipient ID', 'Assignment ID',
        matches_column
    ],
        errors='ignore')

    # save it back
    otree_data.to_csv('redacted-data/data.csv', index=False)
