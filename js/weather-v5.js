//get the payload
var json = apim.getvariable('message');
console.info("json %s", JSON.stringify(json));

//check error in response
if (json.body && json.status.code == '404') {
	console.error("throwing apim error %s", JSON.stringify(json.status.code));
	apim.error('ConnectionError', 500, 'Service Error', 'Failed to retrieve data');
	
}
else {
	json.body.platform = 'Powered by IBM API Connect';
	json.headers.platform = 'Powered by IBM API Connect';
}

//set the payload
apim.setvariable('message.body', json.body);
apim.setvariable('message.headers', json.headers);