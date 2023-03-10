import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
    DynamoDBDocumentClient,
    ScanCommand,
    PutCommand,
    GetCommand,
    DeleteCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});

const dynamo = DynamoDBDocumentClient.from(client);

const tableName = "Visitors";

export const handler = async (event, context) => {
    let body;
    let statusCode = 200;
    const headers = {
        "Content-Type": "application/json",
    };

    try {
        switch (`${event.httpMethod} ${event.resource}`) {
            case "GET /visitors":
                body = await dynamo.send(
                    new ScanCommand({ TableName: tableName })
                );
                body = body.Items;
                break;
            case "PUT /visitors":
                let requestJSON = JSON.parse(event.body);
                await dynamo.send(
                    new PutCommand({
                        TableName: tableName,
                        Item: {
                            id: requestJSON.id,
                            count: requestJSON.count,
                        },
                    })
                );
                body = `Put item ${requestJSON.id}`;
                break;
            case "GET /visitors/{id}":
                body = await dynamo.send(
                    new GetCommand({
                        TableName: tableName,
                        Key: {
                            id: event.pathParameters.id,
                        },
                    })
                );
                body = body.Item;
                await dynamo.send(
                    new PutCommand({
                        TableName: tableName,
                        Item: {
                            id: body.id,
                            count: body.count + 1
                        },
                    })
                );
                break;
            default:
                throw new Error(`Unsupported route: "${Object.entries(event)}"`);
        }
    } catch (err) {
        statusCode = 400;
        body = err.message;
    } finally {
        body = JSON.stringify(body);
    }

    return {
        statusCode,
        body,
        headers,
    };
};
