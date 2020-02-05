context.message.body.readAsJSON(function (error, buffer) {
    console.error ('>> response %s', JSON.stringify(buffer));
    

	if (error || context.get('message.status.code') != '200') {
        console.error ('>> post introspection - error performing introspection');
        context.set('message.status.code', 500);
	}
	else {
        //change the scope value to reflect your API definition
		var response = { 
            "active": true,
            "username" : buffer.email,
            "client_id" : buffer.sub,
		    "scope" : "weather"
		};

        console.info ('>> post introspection - setting response %s', JSON.stringify(response));

        //set the response context
	    context.message.header.set('Content-Type', 'application/json');
	    context.set('message.status.code', 200);
	    context.message.body.write(JSON.stringify(response));
	}
});