# Protect access to APIs using OAuth

**Prerequisites:** 

 * [IBM LTE](https://developer.ibm.com/apiconnect/2019/08/23/intall-local-test/)
 * [API Designer & CLI](https://www-945.ibm.com/support/fixcentral/swg/doIdentifyFixes)
 * [Clone the GitHub repository](https://github.com/ozairs/apiconnect-2018.git) or [Download the respository zip file](https://github.com/ozairs/apiconnect-2018/archive/master.zip). 
 * Run Bash Scripts - Mac and Linux machines support it directly. For Windows see instructions [here](https://www.howtogeek.com/261591/how-to-create-and-run-bash-shell-scripts-on-windows-10/)

**Instructions:** 

<!-- TOC -->autoauto- [Protect access to APIs using OAuth](#protect-access-to-apis-using-oauth)auto    - [Configuring the Native OAuth Provider](#configuring-the-native-oauth-provider)auto    - [Testing the Resource Owner Flow](#testing-the-resource-owner-flow)auto    - [Testing the OAuth Application Flow](#testing-the-oauth-application-flow)auto    - [Testing the OAuth Access Code Flow](#testing-the-oauth-access-code-flow)auto    - [Testing the OAuth Implicit Flow](#testing-the-oauth-implicit-flow)autoauto<!-- /TOC -->

## Configuring the Native OAuth Provider

In this tutorial, you will learn about the various OAuth use cases (ie grant types) and how to protect API definitions. You will submit requests to obtain an access token and then invoke the API using the access token.

The Native OAuth provider supports the following grant types.
  * **Password (resource-owner)**: resource owner grant type to obtain an access token. The resource owner provides its credentials to the OAuth client to obtain an access token.
  * **Application (client credentials)**: client credential grant type to obtain an access token. No resource owner credentials are needed, just the client id and secret.
  * **Access Code (code)**: the resource owner provides access to its resource to a third-party OAuth application without sharing its credentials. Two steps are required to obtain an access token.
  * **Implicit (public)**: implicit grant type to obtain an access token. The resource owner credentails are provided in a Basic Auth header. The access token is available in the URL. For example `https://www.getpostman.com/oauth2/callback#access_token=`.

You will need to configure a security definition, identifying the OAuth server configuration and then configure the APIs that you want to protect using OAuth. For more information on setting up OAuth, see the article [here](https://www.ibm.com/support/knowledgecenter/SSMNED_2018/com.ibm.apic.cmc.doc/tapic_cmc_oauth_native.html). The LTE does not contain a UX so you will import an OAuth server configuration using a script, which supports the OAuth grant types mentioned above. 

1. Import and publish the following API definition files: utility and weather (you can skip this step if you already have published these APIs). 
	* <workspace>/oauth/weather_1.0.0.yaml 
	* <workspace>/openapi/utility_1.0.0.yaml
	
2. Test the Weather API
	```
	./test-api.sh weather current

	>>>>>>>>>> Calling Weather API: https://localhost:9444/weather/current <<<<<<<<<< 

	SUCCESS
	{"zip":"90210","temperature":62,"humidity":90,"city":"Beverly Hills","state":"California","platform":"Powered by IBM API Connect"}
	```

In the next step, you will protect the Weather API with an OAuth 2 server. 

3. The LTE does not include the UI for creating and managing OAuth providers; however, you can still create OAuth providers using either the CLI or REST API. In this tutorial, you will use the REST API (via script) to configure a default native OAuth provider. 

4. The OAuth provider uses a Authentication URL scheme to authentication and authorize users. This service is deployed in the Utility API. The OAuth definition needs the IP address of the API Gateway container to invoke the Utility API. Enter the following commands to obtain the IP address for the API Gateway container.

	```
	docker ps -aqf "name=datapower-api-gateway"
	6158880ed70d
	```

	Note the container id returned. It will be different than the example above.

	```
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'  <container id>
	172.22.0.6
	```

	Note the IP address of the container. It will be different than the example above.

5. Open the `<workspace>/scripts/config.cfg` file and scroll down to the `USER_REGISTRY_URL` variable. Change the IP address to reflect your environment, For example, `USER_REGISTRY_URL=https://172.22.0.6:9443/localtest/sandbox/utility/basic-auth/spoon/spoon`

6. Run the script to create an OAuth provider. Enter 1 for the Authentication URL when prompted. It will create an OAuth server with the name `oauth2-server` that uses an Authentication URL for authentication/authorization.

	```
	<workspace>/scripts/deploy-oauth.sh
	.
	.
	.
	Enter the User Registry type you would like to create (1/2) (1 - Authentication URL / 2 - LDAP) 
	1
	.
	.
	```

Validate the responses within the script to make sure there are no errors.

7. Create an OAuth2 security definition. Select the **weather-1.0.0** API. Perform the following steps and enter the following values:
 * Select **Security Definitions** and click the **Add** button.
 * Enter the name `oauth2-server`. Select `OAuth` as the **Type**. In the OAuth Provider drop-down, select `oauth2-server` and flow `Resource Owner` (all flows are supported but specific flows can be shown in the dev portal)
 * Leave the remaining fields at their default values and click **Save**. 

8. Apply the `OAuth2-server` security definition to the `weather` API. Select the **Security** section in the left nav bar. Check **oauth2-server** and the scope `weather`. Save the API definition.

9. Test the Weather API, you will now get an error because the API is protected using OAuth. In the next step you will obtain an access token to call the same APIs
	```
	./test-api.sh weather current

	>>>>>>>>>> Calling Weather API: https://localhost:9444/weather/current <<<<<<<<<< 

	FAIL
	Failed call with error {"httpCode":"401","httpMessage":"Unauthorized","moreInformation":"Cannot pass the security checks that are required by the target API or operation, Enable debug headers for more details."}
	```

In the next section(s), you will obtain an access token to call the same Weather API, using the various OAuth grant types.

## Testing the Resource Owner Flow

The resource owner flow passes in the resource owner and application credentials (ie client id and secret) to the OAuth server. This flow is used when the resource owner and the OAuth application are trusted (or the same)

1. Obtain an access token from the OAuth provider (using the resource owner grant type)
	```
	./test-api.sh oauth resource-owner
	Resource Owner: https://localhost:9444/localtest/sandbox/oauth2/token

	SUCCESS
	{"token_type":"Bearer","access_token":"AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWU1QhuOmMkslTHlkdGwxe4UF-yi_jXaAKNY2ipP3uatZV-vtQOZGVxDMODk5vyWVvTjwT1dhIW6SB9eg_Suc5mY","scope":"weather","expires_in":3600,"consented_on":1571847682,"refresh_token":"AAIIsB5QRmVe7MS45AajTPRkxpGVT6UlnScC2sTiTOUH1yz0NaiGAfSBvZ7h6jA-9xC7HtB2e0xn4lULcRC9dl2YZeZ93sKDv1Q4L3d1H5KJ2A","refresh_token_expires_in":2682000}
	```
2. If you just want the access token from the response, use the following command
	```
	./test-api.sh oauth resource-owner | grep { | jq -r '.access_token'
	
	Resource Owner: https://localhost:9444/localtest/sandbox/oauth2/token

	SUCCESS
	AAIgODMxZGM5ZTAzMWFlMGFjYjY3M2QyOGU1MmI5ZjM2MWMohB_m00-Fq_d0cXZLBDYGV56lxAr4jeDPIINEm9vEkfTdhU2Vil8Kk_gULDxAFiIkVtbJH-BiAc9yc8NbwmaJlVEQcj7h5dlV-3MkBYfRxXj61gSCKvz6dEOclF2H4AM

	```
	Copy the access token so it remains on your clipboard. You are now ready to call the Weather API!

3. Invoke the Weather API with the access token from the previous step.
	```
	./test-api.sh weather-oauth current
	>>>>>>>>>> Weather API <<<<<<<<<< 

	Enter the access token: AAIgOTM0MDIxY2IzYTM5ZWRiYTY4MzEwYTIwMzk5MDQ1YjM0lOwc8u30GpjgoKa47SueZUDh7zhJMBClvLlIAFUcdfm_affwgtbSOgN246283LqxQBWLI8dWYOGPTGEIYjq7WY_-kqvuF63dr_Xp1XsumnmdripakeoK4p4mFYF_0KU

	SUCCESS
	{"zip":10504,"temperature":89,"humidity":36,"city":"Armonk, North Castle","state":"New York","message":"Sample Randomly Generated","platform":"Powered by IBM API Connect"}
	```

4. 	Run the same command again but using invalid access token. You will get an error.

	```
	./test-api.sh weather-oauth current

	>>>>>>>>>> Weather API <<<<<<<<<< 

	Enter the access token: bad

	FAIL
	Failed call with error {"httpCode":"401","httpMessage":"Unauthorized","moreInformation":"Cannot pass the security checks that are required by the target API or operation, Enable debug headers for more details."}
	```

## Testing the OAuth Application Flow

In this section, you will use the Application flow to obtain an access token for calling the Weather API.

The Application flow simply uses the client id and secret as credentials to obtain an access token. It does not need any resource owner information.

1. Obtain an access token from the OAuth provider using the application flow (ie client credentials grant type)

	```
	./test-api.sh oauth application
	>>>>>>>>>> OAuth API <<<<<<<<<< 

	Client Credentials: https://localhost:9444/localtest/sandbox/oauth2/token

	SUCCESS
	{"token_type":"Bearer","access_token":"AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWUKJaqovVJ9qW49m87YtZhfL-enpmHTEc4V9AF1_5ta_rJh6bC53GGZb7LXwYpVPDdEQWefUafgFO3_nTvvxf6O7bTf18vJLenzsVZCu9ML_Q2_ELs7ZBDkG3eJPGS8Dq0","scope":"weather","expires_in":3600,"consented_on":1571846229}
	```

2. If you want just the `access token` value, you can apply the following command

	```
	./test-api.sh oauth application | | grep { | jq -r '.access_token'
	
	Client Credentials: https://localhost:9444/localtest/sandbox/oauth2/token

	SUCCESS
	AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWUFmGqfpGwJW1G8En3HZgR5FlacRGopNrhKu3l1Xzu9JmEsMNTW5lRvV82T1H62o_fMbU5EMQunEV19BHZdzuqcg2MwAUvYVaG5gmKZ2DjJQodeWlwifI9CzFYdUSrD848
	```

3. Invoke the Weather API with the access token from the previous step.

	```
	./test-api.sh weather-oauth current
	>>>>>>>>>> Weather API <<<<<<<<<< 

	Enter the access token: AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWUFmGqfpGwJW1G8En3HZgR5FlacRGopNrhKu3l1Xzu9JmEsMNTW5lRvV82T1H62o_fMbU5EMQunEV19BHZdzuqcg2MwAUvYVaG5gmKZ2DjJQodeWlwifI9CzFYdUSrD848

	SUCCESS
	{"zip":10504,"temperature":89,"humidity":36,"city":"Armonk, North Castle","state":"New York","message":"Sample Randomly Generated","platform":"Powered by IBM API Connect"}
	```

## Testing the OAuth Access Code Flow

In this section, you will obtain an access token using the Access Code Flow, which requires multiple steps to obtain an access token. 
1) The first request obtains an authorization code, which is a temporary code that is sent to the application identified in the redirect URI (ie third-party). 
2) The authorization code is then exchanged for an access token. This is usually done by the third-party OAuth application but we will simplify it by simulating the OAuth application using a command-line tool.

1. Obtain an authorization code from the OAuth provider using the access code flow (ie authorization code grant))

	```
	./test-api.sh oauth access-code
	>>>>>>>>>> OAuth API <<<<<<<<<< 

	Access Code: https://localhost:9444/localtest/sandbox/oauth2/authorize

	SUCCESS
	Location: https://www.getpostman.com/oauth2/callback?code=AAKrWBNaw_pxLpabx9BTLFktJh8jddI3Sbxypu03PnAm2tzdkH4w57jW1dlSjURC723Kuq1KzdTMHHlPOPE10dLaRui9noGaVQXjspnGEtvWUA

	```

2. If you want just the `code` value, you can apply the following command

	```
	./test-api.sh oauth access-code | cut -d'=' -f 2
	>>>>>>>>>> OAuth API <<<<<<<<<< 

	Access Code: https://localhost:9444/localtest/sandbox/oauth2/authorize

	SUCCESS
	AAJr2oexz1dDPAz_26LTFc6y3cTSfGj7j2_EczwrmylBEGJn7wq_nzNM4FZeNARrUkQW21i6rG0nnDX87rX724iyHHS1vqjlipXO2nTMRKRDUA
	```

3. Obtain an access token using the authorization code 

	```
	./test-api.sh oauth code
	>>>>>>>>>> OAuth API <<<<<<<<<< 

	Exchange Code for Access Token: https://localhost:9444/localtest/sandbox/oauth2/token
	Enter the authorization code: AAJr2oexz1dDPAz_26LTFc6y3cTSfGj7j2_EczwrmylBEGJn7wq_nzNM4FZeNARrUkQW21i6rG0nnDX87rX724iyHHS1vqjlipXO2nTMRKRDUA

	SUCCESS
	AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWVtH3r5da-59CNP5ZzMWDITMqR1bs79ZTlZfCcXZn36wWXo_8pEigRvqcoD4DLN0zwTwBEdQXhHFarZNI5uzvNH
	```

4. Invoke the Weather API with the access token from the previous step.

	```
	./test-api.sh weather-oauth current
	>>>>>>>>>> Weather API <<<<<<<<<< 

	Enter the access token: AAIgOTM0MDIxY2IzYTM5ZWRiYTY4MzEwYTIwMzk5MDQ1YjM0lOwc8u30GpjgoKa47SueZUDh7zhJMBClvLlIAFUcdfm_affwgtbSOgN246283LqxQBWLI8dWYOGPTGEIYjq7WY_-kqvuF63dr_Xp1XsumnmdripakeoK4p4mFYF_0KU

	SUCCESS
	{"zip":10504,"temperature":89,"humidity":36,"city":"Armonk, North Castle","state":"New York","message":"Sample Randomly Generated","platform":"Powered by IBM API Connect"}
	```

## Testing the OAuth Implicit Flow

In this section, you will obtain an access code using the Implicit flow. Unlike other flows, this one returns an access token as part of the URL response.

1. Obtain an access token from the OAuth provider using the implicit flow.

	The Implicit flow passes the client id, client secret, resource owner credentails to obtain an access token. This flow is used when the OAuth application is unable to perform redirects nor is a trusted third-party application.

	```
	./test-api.sh oauth implicit
	>>>>>>>>>> OAuth API <<<<<<<<<< 

	Implicit: https://localhost:9444/localtest/sandbox/oauth2/authorize

	SUCCESS
	Location: https://www.getpostman.com/oauth2/callback#access_token=AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWUUmZDSWL-W2Bl4yV2up33L4tDv0V-ulL23zjhc97Fx-ASA3KpIv3Xp63OxfEYWh7NKYzEjvcnFxRMNW7BomD77&expires_in=3600&token_type=Bearer&scope=weather&consented_on=1571847093
	```

2. If you want just the `access token` value, you can apply the following command

	```
	./test-api.sh oauth implicit | cut -d'#' -f 2 | cut -d'=' -f 2 | cut -d'&' -f 1
	>>>>>>>>>> OAuth API <<<<<<<<<< 

	Implicit: https://localhost:9444/localtest/sandbox/oauth2/authorize

	SUCCESS
	AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWWtPdUK60ojXT6PZdPyx0RzAww_Ac2ngA-vTe4G-55yjI8KPqW8_AeI-jzwSPkZci_3c7Yupmezbf93eprlTe4u
	```

3. Invoke the Weather API with the access token from the previous step.

	```
	./test-api.sh weather-oauth current
	>>>>>>>>>> Weather API <<<<<<<<<< 

	Enter the access token: AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWWtPdUK60ojXT6PZdPyx0RzAww_Ac2ngA-vTe4G-55yjI8KPqW8_AeI-jzwSPkZci_3c7Yupmezbf93eprlTe4u

	SUCCESS
	{"zip":10504,"temperature":89,"humidity":36,"city":"Armonk, North Castle","state":"New York","message":"Sample Randomly Generated","platform":"Powered by IBM API Connect"}
	```

In this tutorial, you learned how to obtain an access token for the resource-owner, application, access code and implicit OAuth flows and use the access token to call a protected API service.

**Next Tutorial**: [Manage digital applications with OAuth lifecycle management](../master/oauth-token-mgmt/README.md)