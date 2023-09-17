// The structure of events: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#example-viewer-request

const awsS3Library = require("@aws-sdk/client-s3");
const s3 = new awsS3Library.S3Client({region: "us-east-1"});
const configReference = new awsS3Library.GetObjectCommand({
    Bucket: 'fft-assignment-files-831746801341', // FIXME: hardcoded generated name. would need a templating engine like moustache. out of scope for assignment
    Key: 'config/experiments/home.json',
});


async function handler(event, context, callback) {
  const request = event.Records[0].cf.request;
  const originalUri = request.uri;
  const configurationResponse = await s3.send(configReference);
  const configurationBody = await configurationResponse.Body.transformToString("utf-8");
  const configuration = JSON.parse(configurationBody);
  const lastPart = originalUri.substring(originalUri.lastIndexOf("/") + 1);
  const isEnabled = configuration["EXPERIMENT_ENABLED"];
  if(isEnabled && lastPart.indexOf("home") === 0) {
    if(lastPart.indexOf("home/variant") === 0) {
      // user is trying to access experimental pages directly, return a redirect
      const redirectResponse = {
        status: '307', // must return 307 Moved Temporarily because busting 301 Moved Permanently is painful
        statusDescription: 'Moved Temporarily',
        headers: {
          'location': [{
            key: 'Location',
            value: '/home',
          }],
          'cache-control': [{
            key: 'Cache-Control',
            value: "no-cache"
          }],
        },
      };
      return callback(null, redirectResponse);
    }
    let cookies = request.headers.cookie;
    const weight = configuration["TRAFFIC_WEIGHT"];
    const primaryCookie = "Experiment=A";
    const secondaryCookie = "Experiment=B";
    const experimentMap = {
      [primaryCookie]: "/variant-1.html",
      [secondaryCookie]: "/variant-2.html"
    };

    if(cookies === null || cookies === undefined) {
      // in case no cookies are sent just initialize it
      // as if there were no values sent for the header
      cookies = [];
    }
    // the spec permits having multiple headers with same name
    // so servers group them. as a result iterate over all
    // of them to try to find the AB test cookie "Experiment"
    let experimentCookieValue = undefined;
    for(let it of cookies) {
      // edge function does not parse cookies so have to do it here
      const cookieKeyValuePairs = it.value.split("; ?")
      for(let cookieKeyValuePair of cookieKeyValuePairs) {
        if(cookieKeyValuePair in experimentMap) {
          experimentCookieValue = cookieKeyValuePair;
          break;
        }
      }
    }
    if(experimentCookieValue === undefined) {
      // user isnt in AB testing yet so give variant 1 90% of the time
      // or user blocks cookies.
      // might want to use a more consistent mechanism here but its fine for now
      if(Math.random() <= weight) {
        experimentCookieValue = primaryCookie;
      }
      else {
        experimentCookieValue = secondaryCookie;
      }
    }
    request.uri = originalUri + experimentMap[experimentCookieValue];
  }
  else if (lastPart.length > 0 && lastPart.indexOf(".") == -1) {
    // If there is a final part of the URL with no file extension, it's probably a page (HTML)
    request.uri = originalUri + ".html";
  }
  return callback(null, request);
}

module.exports = {
  handler,
};
