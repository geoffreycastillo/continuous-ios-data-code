from pathlib import Path

import pandas


def columns_renamed(dataframe_columns, old, new):
    """
    Replace old by new from the column names of the dataframe
    :param dataframe_columns: e.g. data.columns
    :param old: the string in the column names to rename
    :param new: the string to replace the old with
    :return: a list of column names (should typically be given back to data.columns
    """
    return [column.replace(old, new)
            if old in column else column
            for column in dataframe_columns]


print("Statifying the data...")

if Path('redacted-data/data-stata.csv').is_file():
    print(f"The file redacted-data/data-stata.csv already exists.")
else:
    # load the data
    data = pandas.read_csv('redacted-data/data.csv')

    # remove empty columns
    data = data.dropna(axis='columns', how='all')

    # remove participant., player' etc. in the column names
    string_to_remove = ['subsession.', 'participant.',
                        'player.', 'group.', '_matching']
    columns_to_skip = ['participant.code', 'session.code']
    new_column_names = []
    for column in data.columns:
        if column in columns_to_skip:
            pass
        else:
            for string in string_to_remove:
                if string in column:
                    column = column.replace(string, '')
            if column.startswith('session.'):
                column = column.lstrip('session.')
        new_column_names.append(column)
    data.columns = new_column_names

    # rename some columns case-by-case
    data.columns = columns_renamed(
        data.columns, 'display_matches_narrative', 'narrative')
    data.columns = columns_renamed(data.columns, 'ben_students', 'stdts')
    data.columns = columns_renamed(data.columns, 'config', 'cfg')

    # check which columns will cause problems when putting them in STATA
    for column in data.columns:
        if len(column) > 32:
            print('column', column, 'has a length', len(column))

    # save the data
    data.to_csv('redacted-data/data-stata.csv', index=False)
