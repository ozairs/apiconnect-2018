function getIDToken() {
  var idtoken = context.get('oauth.oidc.idtoken');
  if (idtoken !== undefined)
  {
    if (idtoken.startsWith('Bearer '))
    {
      idtoken = idtoken.substring(7);
    }
  }
  return idtoken;
}

function injectTokenInHeader(token) {
  if (token === undefined)
    return;
  
  var location = context.message.header.get('location');
  if (location === undefined)
  {
    location = "id_token=" + token;
  }
  else
  {
    location = location + "&id_token=" + token;
  }
  context.message.header.set('location', location);
}

function injectTokenInBody(token) {
  if (token === undefined)
    return;

  context.message.body.readAsJSON(function (error, jsonBody)
  {
    if (error)
    {
      return;
    }
    
    if (jsonBody === undefined)
    {
      jsonBody = {"id_token": token};
    }
    else
    {
      jsonBody.id_token = token;
    }
    context.message.body.write(jsonBody);
  });
}

function displayError(error) {
  if (error !== null)
    console.error(error);
}

var oidc_enabled = context.get('oauth.oidc.enabled');
if ((oidc_enabled === undefined) || !oidc_enabled) {
  console.debug('OIDC disabled');
  return;
}

var token = getIDToken();
if (token === undefined) {
  displayError('No ID Token available');
  return;
}

var requestType = context.get('oauth.oidc.request_type');
var error = null;
if (requestType === undefined) {
  error = 'Undefined request type';
} else if (requestType === 'implicit') {
  injectTokenInHeader(token);
} else if (requestType === 'azcode_get') {
  injectTokenInHeader(token);
} else if (requestType === 'azcode_grant') {
  injectTokenInBody(token);
} else {
  error = 'Invalid request type ' + requestType;
  displayError(error);
  return;
}