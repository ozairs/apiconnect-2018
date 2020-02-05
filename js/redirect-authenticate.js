//username and confirmation code are passed via the HTTP Authorization header
var reqauth = context.get('request.authorization').split(' ');
var splitval = new Buffer((reqauth[1] || ''), 'base64').toString('utf8').split(':');
var username = splitval[0] || '';
var password = splitval[1] || '';

console.error ('Validating Redirect with parameters %s and %s', username, password);
//verify the username and confirmation code (if using the defaults as configured in the API assembly)
if (username === context.get('demo.identity.redirect.username') &&
	password === context.get('demo.identity.redirect.confirmation')) {
      context.set('message.status.code', 200);
      console.error ('Successful validation');

	//if third-party authentication service provided granular scope options, 
	//then it will need to return them via the response header, `x-selected-scope`
	if (context.get('demo.authenticate-url.x-selected-scope') !== '' &&
		context.get('demo.authenticate-url.x-selected-scope') !== undefined) {
            context.set('message.headers.x-selected-scope', context.get('demo.authenticate-url.x-selected-scope'));
	}
	//if third-party authentication service wants to use a different username, 
	//then it will need to return them via the response header, `api-authenticated-credential`
	if (context.get('demo.api-authenticated-credential') !== '' &&
        context.get('demo.api-authenticated-credential') !== undefined) {
        context.set('message.headers.api-authenticated-credential', context.get('demo.api-authenticated-credential'));
	}
	//if third-party authentication service wants to insert metadata into the token, 
	//then it will need to return them via the response header, `api-oauth-metadata-for-accesstoken`	
	if (context.get('demo.authenticate-url.metainfo.token') !== '' &&
        context.get('demo.authenticate-url.metainfo.token') !== undefined) {
        context.set('message.headers.api-oauth-metadata-for-accesstoken', context.get('demo.authenticate-url.metainfo.token'));
	}
	//if third-party authentication service wants to insert metadata into the payload, 
	//then it will need to return them via the response header, `api-oauth-metadata-for-payload`	
	if (context.get('demo.authenticate-url.metainfo.payload') !== '' &&
        context.get('demo.authenticate-url.metainfo.payload') !== undefined) {
            context.set('message.headers.api-oauth-metadata-for-payload', context.get('demo.authenticate-url.metainfo.payload'));
	}
}
else {
	context.set('message.status.code', 401);
}