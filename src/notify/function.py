import json
import logging
import traceback
from datetime import datetime

import requests
import os
logging.getLogger().setLevel(logging.INFO)
import boto3



def get_secret(secret_name):
    # Create a Secrets Manager client
    client = boto3.client('secretsmanager')

    try:
        # Retrieve the secret
        response = client.get_secret_value(SecretId=secret_name)
        secret = response['SecretString']
        return json.loads(secret)
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        raise

if not os.environ.get('RUNNING_IN_AWS'):
    import dotenv
    dotenv.load_dotenv()
    MAGWEB_USER = os.environ['MAGWEB_USER']
    MAGWEB_PASSWORD = os.environ['MAGWEB_PASSWORD']

else:
    magweb_secret = get_secret('magweb-notifier-creds')
    MAGWEB_USER = magweb_secret['username']
    MAGWEB_PASSWORD = magweb_secret['password']

MAGWEB_ID = os.environ['MAGWEB_ID']
MAGWEB_NAME = os.environ['MAGWEB_NAME']

s3 = boto3.client('s3')
bucket_name = os.environ['MAGWEB_BUCKET_NAME']
key = 'state.json'

sns = boto3.client('sns')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']


def get_state():
    try:
        response = s3.get_object(Bucket=bucket_name, Key=key)
        return json.loads(response['Body'].read())
    except s3.exceptions.NoSuchKey:
        return None  # State does not exist

def save_state(new_state):
    s3.put_object(Bucket=bucket_name, Key=key, Body=json.dumps(new_state))

def lambda_handler(event, context):
    form_data = {
        'username': MAGWEB_USER,
        'password': MAGWEB_PASSWORD
    }
    s = requests.Session()
    # Log in and get session cookie for later requests
    s.post("http://data.magnumenergy.com/", data=form_data)

    try:
        result = s.get(f"http://data.magnumenergy.com/mw/json.php?station_id={MAGWEB_ID}")
    except Exception as e:
        logging.error(f'Unexpected exception occurred while retrieving station data: {traceback.format_exc()}')
        return {
            'statusCode': 500,
            'body': json.dumps({'message': "Unexpected exception occurred while retrieving station data."})
        }

    data = result.json()

    date_format = "%Y-%m-%d %H:%M:%S"
    packet_datetime = datetime.strptime(data['packet_date_local'], date_format)

    ac_volts_in = int(data['i_ac_volts_in'])
    ac_power_on = ac_volts_in > 1 #ac power should be at least 110 volts
    logging.info(f'Current AC power state with volts {ac_volts_in}: {ac_power_on}')

    previous_state = get_state()
    logging.info(f'Previous AC power state: {previous_state}')
    if previous_state is not None:
        if previous_state['ac_power_on'] and not ac_power_on:
            logging.info("State has changed from on to off!")
            logging.info(f"Sending SMS to {SNS_TOPIC_ARN}...")
            response = sns.publish(TopicArn=SNS_TOPIC_ARN, Message=f"{MAGWEB_NAME} Reports AC power LOST at {packet_datetime.strftime('%m/%d/%Y %H:%M:%S')}. Battery Voltage: {data['i_dc_volts']}v")
        if not previous_state['ac_power_on'] and ac_power_on:
            logging.info("State has changed from off to on!")
            logging.info(f"Sending SMS to {SNS_TOPIC_ARN}...")
            response = sns.publish(TopicArn=SNS_TOPIC_ARN, Message=f"{MAGWEB_NAME} Reports AC power RESTORED at {packet_datetime.strftime('%m/%d/%Y %H:%M:%S')}. Battery Voltage: {data['i_dc_volts']}v")


    save_state({'ac_power_on': ac_power_on})

    return {
        'statusCode': 200,
        'body': json.dumps('Lambda successful.')
    }

if __name__ == '__main__':

    lambda_handler(None, None)