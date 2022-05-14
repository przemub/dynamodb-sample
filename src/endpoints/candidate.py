import json

import boto3

client = boto3.client("dynamodb")


def get_candidate_handler(event, context):
    query_parameters = event["queryStringParameters"] or {}

    if "first_name" in query_parameters and "last_name" in query_parameters:
        first_name = query_parameters["first_name"]
        last_name = query_parameters["last_name"]
        name = f"{first_name} {last_name}"

        response = client.get_item(
            TableName="candidates", Key={"name": {"S": name}}, ConsistentRead=True
        )

        return {
            "statusCode": 200 if "Item" in response else 404,
            "body": json.dumps(response.get("Item", {})),
        }
    elif "id" in query_parameters:
        response = client.query(
            TableName="candidates",
            IndexName="by_id",
            KeyConditionExpression="#id = :id",
            ExpressionAttributeNames={"#id": "id"},
            ExpressionAttributeValues={":id": {"S": query_parameters["id"]}},
            # ConsistentRead=True, FIXME: Cannot do it on GSI. Does it matter?
            Limit=1
        )

        return {
            "statusCode": 200 if response["Count"] == 1 else 404,
            "body": json.dumps(response["Items"][0] if response["Count"] == 1 else {}),
        }
    else:
        response = client.scan(
            TableName="candidates"
        )
        return {
            "statusCode": 200,
            "body": json.dumps(response["Items"])
        }


def _get_counter(name: str) -> int:
    """
    Gets a value from the counters table and increments it using
    a conditional expression, in order to make sure that no other call
    will receive the same value.
    :param: name The name of the counter.
    """

    response = client.get_item(
        TableName="counters",
        Key={"counterName": {"S": name}},
        ConsistentRead=True,
    )

    if "Item" not in response:
        # Create the counter
        try:
            client.put_item(
                TableName="counters",
                Item={"counterName": {"S": name}, "value": {"N": "0"}},
                ConditionExpression="attribute_not_exists(counterName)",
            )
        except client.exceptions.ConditionalCheckFailedException:
            # The counter has been created in the meantime, retry
            return _get_counter(name)
        else:
            return 0

    # Update the counter
    value = int(response["Item"]["value"]["N"])

    try:
        client.put_item(
            TableName="counters",
            Item={"counterName": {"S": name}, "value": {"N": str(value + 1)}},
            ConditionExpression="#value = :oldValue",
            ExpressionAttributeNames={"#value": "value"},
            ExpressionAttributeValues={":oldValue": {"N": str(value)}},
        )
    except client.exceptions.ConditionalCheckFailedException:
        # Someone snatched our value in the meantime, try again
        return _get_counter(name)

    return value


def post_candidate_handler(event, context):
    query_parameters = event["queryStringParameters"]
    if (
        "first_name" not in query_parameters
        or "last_name" not in query_parameters
    ):
        return {
            "statusCode": 400,
            "body": json.dumps(
                "Please provide first_name and last_name as query parameters."
            ),
        }

    first_name = query_parameters["first_name"]
    last_name = query_parameters["last_name"]
    name = f"{first_name} {last_name}"

    # Check if the user does not exist already so we do not increment
    # the counter senselessly.
    response = client.get_item(
        TableName="candidates",
        Key={"name": {"S": name}},
    )
    if "Item" in response:
        return {
            "statusCode": 409,
            "body": json.dumps("A user with this name already exists."),
        }

    id_number = _get_counter("candidate_id")
    if id_number > 9999:
        # FIXME: This part here is an easy target for a DoS attack.
        return {
            "statusCode": 400,
            "body": json.dumps("We ran out of candidate IDs! Come back next year.")
        }

    candidate_id = f"CI{id_number:04d}"
    item = {
        "name": {"S": name},
        "first_name": {"S": first_name}, "last_name": {"S": last_name},
        "id": {"S": candidate_id}
    }

    try:
        response = client.put_item(
            TableName="candidates",
            Item=item,
            ConditionExpression="attribute_not_exists(#name)",
            ExpressionAttributeNames={"#name": "name"},
        )
    except client.exceptions.ConditionalCheckFailedException:
        return {
            "statusCode": 409,
            "body": json.dumps("A user with this name already exists."),
        }

    return {
        "statusCode": response["ResponseMetadata"]["HTTPStatusCode"],
        "body": json.dumps(item),
    }


def delete_candidate_handler(event, context):
    query_parameters = event["queryStringParameters"] or {}

    if "first_name" in query_parameters and "last_name" in query_parameters:
        first_name = query_parameters["first_name"]
        last_name = query_parameters["last_name"]
        name = f"{first_name} {last_name}"

        try:
            client.delete_item(
                TableName="candidates",
                Key={"name": {"S": name}},
                ConditionExpression="attribute_exists(#name)",
                ExpressionAttributeNames = {"#name": "name"},
            )
        except client.exceptions.ConditionalCheckFailedException:
            return {
                "statusCode": 404
            }
        else:
            return {
                "statusCode": 204
            }
    elif "id" in query_parameters:
        response = client.query(
            TableName="candidates",
            IndexName="by_id",
            KeyConditionExpression="#id = :id",
            ExpressionAttributeNames={"#id": "id"},
            ExpressionAttributeValues={":id": {"S": query_parameters["id"]}},
            # ConsistentRead=True, FIXME: Cannot do it on GSI. Does it matter?
            Limit=1
        )

        if response["Count"] == 0:
            return {"statusCode": 404}

        client.delete_item(
            TableName="candidates",
            Key={"name": response["Items"][0]["name"]},
        )

        return {"statusCode": 204}
    else:
        return {
            "statusCode": 400,
            "body": json.dumps("Specify (first_name and last_name) or id as query parameters.")
        }
