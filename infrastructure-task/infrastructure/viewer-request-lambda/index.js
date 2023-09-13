// The structure of events: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#example-viewer-request
function handler(event, context, callback) {
  const request = event.Records[0].cf.request;
  const originalUri = request.uri;
  console.log("Handing request on", originalUri);
  console.log("Headers are", request.headers);
  const lastPart = originalUri.substring(originalUri.lastIndexOf("/") + 1);
  if(lastPart === "home") {
    let cookies = request.headers.cookie;
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
      if(Math.random() <= 0.9) {
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
