import argparse
import boto3
import time
import datetime
import random
import faker
import json
from faker import Faker


class StreamDataPusher(object):

    def __init__(self, kinesis_stream, region, frequency, time):
        self.kinesis_stream = kinesis_stream
        self.frequency = frequency
        self.time = time
        self.client = boto3.client('firehose',
                                   endpoint_url="http://localhost:4573",
                                   region_name=region)
        self.faker = Faker()

    def generate_mock_data(self):
        return str(self.faker.local_latlng(country_code='US', coords_only=False))

    def push_data(self):
        start_time = int(round(time.time() * 1000))
        expected_end_time = start_time + (self.time*1000)
        frequency_time = 60 / self.frequency

        print('Starting to push data to ' + self.kinesis_stream)

        while int(round(time.time() * 1000)) <= expected_end_time:
            data = {
                'timestamp': str(datetime.datetime.now().time()),
                'data': self.generate_mock_data()
            }
            time.sleep(frequency_time)
            self.client.put_record(
                DeliveryStreamName=self.kinesis_stream,
                Record={
                    'Data': json.dumps(data)
                }
            )
            print('Record ' + str(data) + ': successful')


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='This tool pushes random data \
                                                  to a given kinesis stream')
    parser.add_argument('-s', '--kinesis-stream', action='store',
                        required=True, help='The kinesis stream to push data \
                                             to')
    parser.add_argument('-r', '--region', action='store', required=False,
                        help='The region of the kinesis stream',
                        default='us-east-1')
    parser.add_argument('-f', '--frequency', action='store', required=False,
                        help='How frequent to push a data object to the \
                              stream per minute', default=60)
    parser.add_argument('-t', '--time', action='store', required=False,
                        help='How long to continue pushing data for in \
                              seconds', default=60)
    args = parser.parse_args()

    data_pusher = StreamDataPusher(args.kinesis_stream, args.region,
                                   args.frequency, args.time)
    print(data_pusher.push_data())
