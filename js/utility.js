var reqauth = context.get('request.authorization').split(' ');
var splitval = new Buffer((reqauth[1] || ''), 'base64').toString('utf8').split(':');
var username = splitval[0] || '';
var password = splitval[1] || '';
console.debug('user credential : [' + username + ':' + password + ']');
if (username === context.get('request.parameters.username') && password === context.get('request.parameters.password')) {
	context.message.body.write({ "authenticatedUser": username });
	context.set('message.headers.api-authenticated-credential', 'cn=' + username + ',email=' + username + '@poon.com');
	context.set('message.status.code', 200);
	context.message.header.set('Content-Type', 'application/json');
}
else {
	context.set('message.status.code', 401);
}