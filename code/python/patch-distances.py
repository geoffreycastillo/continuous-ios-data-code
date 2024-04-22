import json
from datetime import datetime
from pathlib import Path

import numpy
import pandas
from geopy.distance import distance as geopydistance


class Matching:
    def __init__(self):

        self.fields_to_compute_distance = ['sex', 'date', 'miles',
                                           'ethnicity', 'ethnicity_choice', 'race',
                                           'religion', 'religion_denomination',
                                           'country_growing_up', 'us_state_grow_up', 'another_country_grow_up']

        fields_to_import = self.fields_to_compute_distance

        # if we want to compute the distance for miles we need a few more fields
        if 'miles' in self.fields_to_compute_distance:
            fields_to_import = [field for field in fields_to_import if field != 'miles']
            extra_fields_for_miles = ['zip', 'city',
                                      'lat', 'long', 'state', 'state_short']
            fields_to_import = fields_to_import + extra_fields_for_miles

        self.fields_to_compute_distance_column = ['player.' + field for field in self.fields_to_compute_distance]
        self.fields_to_compute_distance_column_data = ['survey.1.player.' + field for field in self.fields_to_compute_distance]
        fields_to_import_column = ['player.' + field for field in fields_to_import]
        additional_fields_to_import = ['participant.code', 'participant.time_started',
                                       'participant.mturk_worker_id', 'participant.mturk_assignment_id',
                                       'session.code', 'session.mturk_HITId', 'session.mturk_HITGroupId']
        self.fields_to_import_column = fields_to_import_column + additional_fields_to_import

        self.fields_to_normalise = ['date', 'miles']

        self.database = self.import_database()

    @property
    def database_length(self):
        return len(self.database.index)

    def import_database(self):
        # which columns to parse date
        columns_date = ['participant.time_started', 'player.date']
        columns_to_parse = list(set(columns_date) & set(self.fields_to_import_column))

        # Read database and change the type of some fields
        # Might be redundant later when we have the real data
        database = pandas.read_csv("unredacted-data/database.csv",
                                   dtype={
                                       'player.zip': 'object',
                                       'player.ethnicity': 'bool',
                                       'player.religion': 'bool',
                                       'player.guns': 'bool',
                                       'player.us_citizen': 'bool',
                                       'player.elementary_secondary_choices_incomplete_high_school': 'Int64'
                                   },
                                   parse_dates=columns_to_parse,
                                   na_values=['NA'],
                                   usecols=self.fields_to_import_column
                                   )

        for column in database:
            if database[column].dtype == 'object':
                database[column].fillna('NA', inplace=True)

        return database


def create_distances_table():
    """
    Creates the distance table from the database
    :return: the distance table filled with NaN
    """

    fields_to_na = matching.fields_to_compute_distance_column

    if 'player.miles' in fields_to_na:
        fields_to_na = [field for field in fields_to_na if field != 'player.miles']
        extra_fields_for_miles = ['zip', 'city', 'lat', 'long']
        fields_to_na = fields_to_na + ['player.' + field for field in extra_fields_for_miles]

    # create a copy of the database for each player
    distances = matching.database.copy()

    # indicate the fields with which we want to compute the distance
    # remove the data in the actual fields
    distances[fields_to_na] = numpy.nan

    return distances


def compute_distances(distances, player, old_distance=False):
    """
    Computes the distances
    :param distances: the distance table
    """

    # import parameters
    database = matching.database
    fields_to_normalise = matching.fields_to_normalise
    fields_to_compute_distance = matching.fields_to_compute_distance
    database_columns = matching.fields_to_compute_distance_column
    number_fields = len(fields_to_compute_distance)

    # loop over the fields to compute the distance
    for field in fields_to_compute_distance:

        # if field is miles we have to find it using the lat and long
        if field == 'miles':
            # find the difference in miles between player and target
            distances['player.miles'] = [
                geopydistance((database_lat, database_long),
                              (player['survey.1.player.lat'], player['survey.1.player.long'])).miles
                for database_lat, database_long in zip(database['player.lat'], database['player.long'])
            ]

        # if field is date have to convert it to days
        elif field == 'date':
            # get the date from the db
            self_date_string = player['survey.1.player.' + field]
            # convert it to a date type
            self_date_date = datetime.strptime(self_date_string, '%m/%d/%Y').date()
            # compute the distance
            distances['player.date'] = abs((pandas.to_datetime(database['player.date']) - pandas.Timestamp(self_date_date)).dt.days)

        # otherwise we check the other fields
        else:
            # get the field value (of the player)
            self_field_value = player['survey.1.player.' + field]
            # get the column name
            column = 'player.' + field
            # get the field type (of the player)
            field_type = matching.database[column].dtype

            # if string or bool we just look whether they are equal
            if field_type == object or field_type == bool:
                if old_distance is False:
                    if self_field_value is numpy.nan:
                        self_field_value = 'NA'
                distances[column] = (database[column] != self_field_value)

            # if int or float we look at the difference
            # elif self_field_type == 'FloatField' or self_field_type == 'IntegerField':
            #     print('DEBUG we are in case 2')
            #     if self_field_value is None:
            #         print('DEBUG the field was None')
            #         self_field_value = 0
            #     distances[column] = abs(database[column] - self_field_value)

            else:
                print("I haven't done anything with the field:", field)

    # some fields are not between 0 and 1 and so need to be normalised afterwards
    # get the intersection between the fields to use and the fields to normalise
    fields_to_normalise = [field for field in fields_to_normalise if field in fields_to_compute_distance]
    for field in fields_to_normalise:
        column = 'player.' + field
        max = distances[column].max()
        distances[column] = distances[column] / max

    # sum the distances and put them in a new column then normalise
    distances['distance'] = distances[database_columns].sum(1) / number_fields

    # sort by the distance column
    distances.sort_values(by=['distance'], inplace=True)
    # reset the index so that participants in the distance table are 0, 1, 2, 3...
    distances.reset_index(drop=True, inplace=True)


print('Patching the distances...')

if Path('./unredacted-data/data-objective-distance-corrected.csv').exists():
    print(f"The objective distance has already been patched.")
else:
    matching = Matching()
    data = pandas.read_csv('unredacted-data/data.csv')

    for index, player in data.iterrows():
        if player['participant.mturk_worker_id'] is not None and player['participant._current_page_name'] == 'End':
            distances = create_distances_table()
            compute_distances(distances, player)
            matches = json.loads(player['survey.1.player.matches'])
            for num, match in enumerate(matches):
                mturk_id = match['participant.mturk_worker_id']
                distance_all = distances[distances['participant.mturk_worker_id'] == mturk_id]
                for field in matching.fields_to_compute_distance:
                    data.loc[index, f'match{num}.distance_{field}'] = distance_all[f'player.{field}'].values[0]
                data.loc[index, f'match{num}.objective_distance_corrected'] = distance_all['distance'].values[0]

    data.to_csv('unredacted-data/data-objective-distance-corrected.csv', index=False)
