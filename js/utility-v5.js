var reqauth = apim.getvariable('request.authorization').split(' ');
var splitval = new Buffer((reqauth[1] || ''), 'base64').toString('utf8').split(':');
var username = splitval[0] || '';
var password = splitval[1] || '';
apim.console.debug('user credential : [' + username + ':' + password + ']');
if (username === apim.getvariable('request.parameters.username') && password === apim.getvariable('request.parameters.password')) {
	session.output.write({ "authenticatedUser": username });
	apim.setvariable('message.headers.api-authenticated-credential', 'cn=' + username + ',email=' + username + '@poon.com');
	apim.setvariable('message.status.code', 200);
	apim.output('application/json');
}
else {
	apim.setvariable('message.status.code', 401);
}