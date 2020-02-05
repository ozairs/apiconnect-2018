// output to the system logs, the input parameters passed in the URL query string
console.error('original-url : ', context.get('request.parameters.original-url'));
console.error('app-name : ', context.get('request.parameters.app-name'));
console.error('appid : ', context.get('request.parameters.appid'));
console.error('org : ', context.get('request.parameters.org'));
console.error('orgid : ', context.get('request.parameters.orgid'));
console.error('catalog : ', context.get('request.parameters.catalog'));
console.error('catalogid : ', context.get('request.parameters.catalogid'));
console.error('provider : ', context.get('request.parameters.provider'));
console.error('providerid : ', context.get('request.parameters.providerid'));

//extract the username and confirmation code once the user is successfully authenticated and authorized
var username = context.get('demo.identity.redirect.username');
var confirmationCode = context.get('demo.identity.redirect.confirmation')

//build the callback URL using the original URL passed into the service
var origUrl = decodeURIComponent(context.get('request.parameters.original-url').values[0] || '');
var location = origUrl + '&rstate=5yXZSNocRPpJm9MZHR15MDc9hZhTiSRy10EhV28' + '&username=' + username + '&confirmation=' + confirmationCode;

//set the response headers to trigger a redirect back to API Connect
context.set('message.status.code', 302);
context.set('message.headers.location', location);
console.error('redirect back to apic ', location);