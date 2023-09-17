const awsS3Library = require("@aws-sdk/client-s3");
const s3 = new awsS3Library.S3Client({region: "us-east-1"});
const configReference = new awsS3Library.GetObjectCommand({
    Bucket: 'fft-assignment-files-831746801341', // FIXME: hardcoded generated name. would need a templating engine like moustache. out of scope for assignment
    Key: 'config/experiments/home.json',
});

async function handler(event, context, callback) {
    const request = event.Records[0].cf.request;
    const response = event.Records[0].cf.response;
    const configurationResponse = await s3.send(configReference);
    const configurationBody = await configurationResponse.Body.transformToString("utf-8");
    const configuration = JSON.parse(configurationBody);
    if(configuration["EXPERIMENT_ENABLED"]) {
        const primaryCookie = "Experiment=A";
        const secondaryCookie = "Experiment=B";
        const cookieMap = {
            "/home/variant-1.html": primaryCookie,
            "/home/variant-2.html": secondaryCookie
        }
        const chosenCookie = cookieMap[request.uri];
        // users may switch experiments daily
        if(chosenCookie !== undefined) {
            response.headers["set-cookie"] = [
                {
                  "key": "Set-Cookie",
                  "value": `${chosenCookie}; Max-Age=86400; SameSite=Strict`
                }
            ];
        }
    }
    return callback(null, response);
}

module.exports = {
  handler
}