import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))


def lambda_handler(event, context):
    logger.info("Processing %d records", len(event.get("Records", [])))
    batch_item_failures = []

    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            logger.debug("Record body: %s", body)
            # TODO: implement processing logic
        except Exception as exc:
            logger.error(
                "Failed to process record %s: %s", record["messageId"], exc
            )
            batch_item_failures.append({"itemIdentifier": record["messageId"]})

    return {"batchItemFailures": batch_item_failures}
