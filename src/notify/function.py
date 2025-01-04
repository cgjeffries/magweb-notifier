import json
import logging
logging.getLogger().setLevel(logging.INFO)

def lambda_handler(event, context):
    logging.info("Hello world!")

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }