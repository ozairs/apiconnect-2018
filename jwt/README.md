## Protect access to API services with Auth0 & JWT

In this tutorial, you will protect access to your APIs using [auth0.com](https://auth0.com).

**What is Auth0?**

Auth0 is a cloud-based solution that provides integration with multiple identity providers, such as Google, Facebook, and more. Third-party Web and Mobile applications can easily provide authentication services using Auth0 without having to worry about the integration logic with the identity provider. This helps accelerate delivery of digital solutions and not require technical investment in authentication capabilities.

**Duration**: 20 minutes

 * [IBM LTE](https://developer.ibm.com/apiconnect/2019/08/23/intall-local-test/)
 * [API Designer & CLI](https://www-945.ibm.com/support/fixcentral/swg/doIdentifyFixes)
 * [Clone the GitHub repository](https://github.com/ozairs/apiconnect-2018.git) or [Download the respository zip file](https://github.com/ozairs/apiconnect-2018/archive/master.zip). 

In this tutorial, you will control access to the backend service by requiring a valid JWT (JSON Web Token). For more information about JWT, see [here](https://jwt.io). JWT is a JSON-based token that provides a series of claims that are cryptographically verifyable. The base claim is a subject-audience pair which asserts the token for a particular user.

In our scenario, the API definition requires a valid JWT token generated from a trusted identity provider - [auth0.com](https://auth0.com). 

The following instructions provide guidance on how to setup an auth0 account to issue JWT tokens. Its not a comprehensive step-by-step guide, so it is recommended you check out their [docs](https://auth0.com/docs).

## Auth0 Instructions

1. Login to [auth0](https://www.auth0.com) and create an auth0 account.
2. Click the **APIs** link from the nav bar and create a new API, called `Pokemon` and identifier with `<yourid>.apiconnect.com`. Click Create to complete the API definition.
3. In the **Quick Start** section make a note of the jwsURI (example below):
	```
	secret: jwks.expressJwtSecret({
			.
			.
			jwksUri: "https://ozairs.auth0.com/.well-known/jwks.json"
		}),
	```
4. In the **Scopes** section create new scopes called `read` and `write` and add a description.
5. In the **Non Interactive Clients** section, expand the `Pokemon Client` and select the previously created scopes and click **Update**. Click **Continue** to accept the warning message.
6. In the **Test** section, copy and paste the curl command in a command prompt (if curl is unavailable, use an alternative approach).
	```
	$ curl --request POST \
	>   --url https://ozairs.auth0.com/oauth/token \
	>   --header 'content-type: application/json' \
	>   --data '{"client_id":"<client_id>","client_secret":"<client_secret>","audience":"https://ozairs.apiconnect.com/","grant_type":"client_credentials"}'
	{"access_token":"<token>","expires_in":86400,"scope":"write read","token_type":"Bearer"}
	```
	In a real-world use case, a web / mobile application will issue this request to obtain an access token.

Lets switch back to API Connect and add API assembly policies to validate the Auth0 token. This requires several steps:
* **Invoke**: Obtain the JWK file used to validate the AUth0 generated JWT token
* **GatewayScript**: Save the JWK into a variable
* **Validate JWT**: validate the JWT token using the JWK variable
* **Gatewascript**: return the JWT claims for test validation  

## API Connect Instructions

1. In the API designer, click the **APIs** tab (if not selected), click the **Add (+)** button and select **Import API from a file or URL**.
2. Click **Add** and select **API**. Click **Existing OpenAPI** and click Next. Browse to **<workspace>/jwt/pokemon_1.0.0.yaml** and click **Next** to finish the task. Click **Edit API** to switch to the API designer.
3. Open the `pokemon` API. In the **Design** tab, select **Paths** and click the **Add** button to add a new Path named `/validate` to the existing Pokemon API. Click **Add** under Operations to add the GET operation. Click Save once complete.
5. Click the **Assemble** tab and select the existing  `switch` policy. Add a new case for the `/validate`.
6. For the `/validate` case, add the following policies. You need to drag the assembly policies into the `/validate` row.
	* Add a `Invoke` policy (side call to get the JWK key which will be used to validate the JWT token), named `get-jwk-key` with the following:
    	* **URL**: https://ozairs.auth0.com/.well-known/jwks.json
		* **Cache Type**: Time to Live
		* **Cache Time to Live**: 900
		* **Response object variable**: rsa256-key
	* Add a GatewayScript policy after the Invoke (get-jwk-key) to extract the JSON Web Key (JWK) and save it as a context variable
	```
	var rsa256Key = JSON.parse(context.get('rsa256-key'));
	context.set('jwk-key', JSON.stringify(rsa256Key.body.keys[0]));
	```
	* Add a `Validate JWT` policy with the following:
		* **JWT**: request.headers.authorization
		* **Output Claims**: decoded.claims
		* **Issuer Claim**: .*\.auth0\.com\/
		* **Audience Claim**: .*\.apiconnect\.com
		* **Verify Crypto JWK variable name**: jwk-key
		
		**Note**: You can create a stronger regular expression in the issuer and audience claims field for enhanced security if you want to control access between specific users and providers

	* Add a GatewayScript policy to return the decoded claims
	```
	context.set('message.body', context.get('decoded.claims'));
	```

	![alt](_images/jwt_validate.jpg)

	Notice that the `/validate` does not have a backend Invoke policy although it would in a real-world scenario. We are simply returning the decoded claims to verify the JWT token was successfully validated.

## Testing the Full Scenario

1. Test the JWT policy to make sure it successfully validates the Auth0 token. A real-world (mobile) application will use two endpoints:
	* **Auth0**: obtain the JWT token against the Auth0 authorization server directly (ie no API Connect involvement).
	```
	curl --request POST \
	>   --url https://ozairs.auth0.com/oauth/token \
	>   --header 'content-type: application/json' \
	>   --data '{"client_id":"<client_id>","client_secret":"<client_secret>","audience":"https://ozairs.apiconnect.com/","grant_type":"client_credentials"}'
	```
	* **API Connect**: validate the JWT token from Auth0
		* Enter the following curl command, replacing the <access_token> with the previous `access_token` value into the Authorization header.
		```
		curl -k -X GET \
		'https://localhost:9444/localtest/sandbox/api/validate' \
		-H 'x-ibm-client-id: <client_id>' \
		-H 'Authorization: Bearer <access_token>' -k
		```
		* The response will contain the decoded JWT
		```
		{
		 "iss": "https://ozairs.auth0.com/",
		 "sub": "gHXm6ss79Jm866TYdyMCtPyyZ25iFpWq@clients",
		 "aud": "https://ozairs.apiconnect.com/",
		 "exp": 1494354567,
		 "iat": 1494268167,
		 "scope": "write read"
		}
		```

2. Test the API using the actual backend endpoint. The `/validate` operation does not trigger the backend. Modify the `curl` command to invoke the backend:

	```
	curl -k -X GET \
	'https://localhost:9444/localtest/sandbox/api/pokemon/1' \
	-H 'x-ibm-client-id: <client_id>' \
	-H 'Authorization: Bearer <access_token>' -k
	```
	* The response will contain Pokemon
	```
	{
		"id": 1,
		"name": "bulbasaur",
		"height": 7,
		"weight": 69,
		"base_experience": 64,
		"data": {"moves": "slow"}
	}
	```

3. Send another request message, but use an invalid access token in the Authorization header. You should get an error

	```
	curl -k -X GET \
	'https://localhost:9444/localtest/sandbox/api/pokemon/1' \
	-H 'x-ibm-client-id: <client_id>' \
	-H 'Authorization: Bearer bad' -k
	```
	* The response will contain Pokemon
	```
	{"message": "Error occurred during search operation."}
	```

For more information about JWT, you can read [here](https://developer.ibm.com/apiconnect/2016/08/16/securing-apis-using-json-web-tokens-jwt-in-api-connect-video-tutorial/)

Summary of the JWT security actions:
 - `jwt-validate`: validate the identity assertion claims from a jwt token
 - `jwt-generate` (not used in tutorial): generate jwt token with identity assertion claims

In this tutorial, you used a JWT validate policy to verify the JSON Web signature (JWT) of a JWT token that was generated from Auth0 (external identity provider).

**Next Tutorial**: [Protect access to APIs using OAuth](../master/oauth/README.md)