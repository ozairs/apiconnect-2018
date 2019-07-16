//get the payload
console.debug("json %s", JSON.stringify(context.get('message')));

//check error in response
if (context.message.body && context.message.statusCode == '404') {
    console.error("throwing apim error %s", JSON.stringify(context.message.statusCode));
    context.reject('ConnectionError', 'Failed to retrieve data');
    context.set('message.status.code', 500);
}
else {
    context.message.header.set('platform', 'Powered by IBM API Connect');
    // var json = context.get('message').body;
    // json.platform = 'Powered by IBM API Connect';
    context.message.body.readAsJSON(function (error, json) {
        if (error) {
            console.error('readAsJSON error: ' + error);
        } else {
            json.platform = 'Powered by IBM API Connect';
            context.message.body.write(json);
        }
    })
}