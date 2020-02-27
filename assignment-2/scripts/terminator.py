import argparse
import boto3
import time

class Terminator(object):

    def __init__(self, asg_name, region):
        self.asg_name = asg_name

        self.asg_client = boto3.client('autoscaling',
                                       region_name=region)
        self.ec2_client = boto3.client('ec2',
                                       region_name=region)

        self.expected_instances = self.asg_client.describe_auto_scaling_groups(
                                        AutoScalingGroupNames=[
                                            self.asg_name
                                        ]
                                    )['AutoScalingGroups'][0]["DesiredCapacity"]

    def asg_is_healthy(self):
        asg_status = self.asg_client.describe_auto_scaling_groups(
                            AutoScalingGroupNames=[self.asg_name]
                        )['AutoScalingGroups'][0]

        sufficient_num_instances = len(asg_status['Instances']) == self.expected_instances
        all_healthy = all('Healthy' == instance['HealthStatus'] for instance in asg_status['Instances'])
        all_running = all('InService' == instance['LifecycleState'] for instance in asg_status['Instances'])

        return sufficient_num_instances and all_healthy and all_running

    def wait_until_healthy(self):
        while not self.asg_is_healthy():
            print('\t\tNot all instances are healthy - waiting...')
            time.sleep(10)

    # note this is different to the status within ec2 - asg takes more time
    def get_instance_status_in_asg(self, instance_id):
        instances = self.asg_client.describe_auto_scaling_groups(
                                        AutoScalingGroupNames=[
                                            self.asg_name
                                        ]
                                    )['AutoScalingGroups'][0]["Instances"]
        for instance in instances:
            if instance['InstanceId'] == instance_id:
                return instance['HealthStatus']
        return None

    # ASG takes time to be notified of unhealthy instance
    def wait_until_asg_updated(self, instance_id):
        while self.get_instance_status_in_asg(instance_id) == 'Healthy':
            print('\t\tASG not yet notified of unhealthy instance. Waiting...')
            time.sleep(10)

    def recycle_instances(self):
        instances = self.asg_client.describe_auto_scaling_groups(
                                        AutoScalingGroupNames=[
                                            self.asg_name
                                        ]
                                    )['AutoScalingGroups'][0]["Instances"]
        instance_ids = [ instance['InstanceId'] for instance in instances ]

        for instance_id in instance_ids:
            print('Terminating instance: ' + instance_id)
            self.ec2_client.terminate_instances(InstanceIds=[
                                                    instance_id
                                                ])
            print('\tWaiting for ASG to update status after instance termination...')
            self.wait_until_asg_updated(instance_id)
            print('\tWaiting for new instance to replace old...')
            self.wait_until_healthy()



if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='This tool pushes random data \
                                                  to a given kinesis stream')
    parser.add_argument('-g', '--asg-name', action='store',
                        required=True, help='The kinesis stream to push data \
                                             to')
    parser.add_argument('-r', '--region', action='store', required=False,
                        help='The region of the kinesis stream',
                        default='eu-west-1')
    args = parser.parse_args()

    arnold = Terminator(args.asg_name, args.region)
    print(arnold.expected_instances)
    arnold.recycle_instances()
