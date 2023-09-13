function handler(event, context, callback) {
    const request = event.Records[0].cf.request;
    const response = event.Records[0].cf.response;
    console.log(request.uri);
    callback(null, response);
}

module.exports = {
  handler
}