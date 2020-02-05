# Manage API Authentication lifecycle for enhanced user experience

In this tutorial, you will learn about the various OAuth token lifecycle operations, such as refresh token, introspection and revocation.

**What is OAuth lifecycle management?**

Web site / Mobile application that use third-party API services (ie login with your Google credentials) using OAuth will obtain an access token containing information about the resource owner. This information is obtained with the resource owner permission. The Web / Mobile application does not need to re-ask for permissions again from the resource. This model is convenient for the Web / Mobile application but if the resource owner changes its mind, it needs a way to remove the previously consented permission.  In other circumstances, you may have lost your mobile device and want to remove the permissions to avoid unauthorized access. In these situtations, you can revoke your permissions granted to an OAuth application to prevent the OAuth application from accessing your resources.

Mobile applications often provide long-lived sessions so you don't need to login to the mobile app everytime you open it. For these use cases, applications can use a refresh token to obtain a new access token for an expired access token without performing the OAuth protocol handshake again.

These capabilities are critical to providing a first-class security experience because things can go wrong but the user experience does not have to suffer along the way. In his article, you will learn about the various OAuth token lifecycle capabilite and how to build them into your application.

**Prerequisites**

 * [IBM LTE](https://developer.ibm.com/apiconnect/2019/08/23/intall-local-test/)
 * [API Designer & CLI](https://www-945.ibm.com/support/fixcentral/swg/doIdentifyFixes)
 * [Clone the GitHub repository](https://github.com/ozairs/apiconnect-2018.git) or [Download the respository zip file](https://github.com/ozairs/apiconnect-2018/archive/master.zip). 
 * Run Bash Scripts - Mac and Linux machines support it directly. For Windows see instructions [here](https://www.howtogeek.com/261591/how-to-create-and-run-bash-shell-scripts-on-windows-10/)
 * Complete the OAuth setup steps [here](../master/oauth/README.md#configuring-the-native-oauth-provider)

**Instructions:** 

The API definitions contain pre-configured OAuth configuration. You will use a test tool to run requests and learn about the various OAuth token lifecycle operations.

If you want to learn about OAuth provider configuration, see [here](https://www.ibm.com/support/knowledgecenter/SSMNED_2018/com.ibm.apic.cmc.doc/capic_cmc_oauth_concepts.html)

Let's first get an access token using the OAuth resource owner grant type. 

1. Obtain an access token from the OAuth provider (using the resource owner grant type)
	```
	./test-api.sh oauth resource-owner
	Resource Owner: https://localhost:9444/localtest/sandbox/oauth2/token

	SUCCESS
	{"token_type":"Bearer","access_token":"AAIgYzkwODFhZTA5MjI4NDAwMWE2ZmJhZGYzMWRkN2M2NWU1QhuOmMkslTHlkdGwxe4UF-yi_jXaAKNY2ipP3uatZV-vtQOZGVxDMODk5vyWVvTjwT1dhIW6SB9eg_Suc5mY","scope":"weather","expires_in":3600,"consented_on":1571847682,"refresh_token":"AAIIsB5QRmVe7MS45AajTPRkxpGVT6UlnScC2sTiTOUH1yz0NaiGAfSBvZ7h6jA-9xC7HtB2e0xn4lULcRC9dl2YZeZ93sKDv1Q4L3d1H5KJ2A","refresh_token_expires_in":2682000}
	```
2. The **OAuth Introspection** request validates the access token and returns the details of the access token. Enter the following command:
	```
	./test-api.sh oauth introspect
	
	Introspect Access Token: https://localhost:9444/localtest/sandbox/oauth2/introspect
	Enter the access token: AAIgY2RmZWEzNzM0NmNjMzQ5ZDYyODJhNzVhN2ZiZTU5MTcYgVO6PCbhO_Zl8lnlyboe3w55mSyRy9PRGHMDthIB9wXwxaSs06YJzb1odvfWaEp7ZSKH2cqtnpNvzcngKZSr

	SUCCESS	
	{
		"active": true,
		"scope": "weather",
		"client_id": "cdfea37346cc349d6282a75a7fbe5917",
		"username": "spoon",
		"token_type": "Bearer",
		"grant_type": "password",
		"ttl": 3409,
		"exp": 1572465540,
		"expstr": "2019-10-30T19:59:00Z",
		"iat": 1572461940,
		"nbf": 1572461940,
		"nbfstr": "2019-10-30T18:59:00Z",
		"consented_on": 1572461940,
		"consented_on_str": "2019-10-30T18:59:00Z",
		"one_time_use": false
	}
	```
4. In the original request to obtain an access token, the OAuth server also returned a refresh token. You can obtain a new access token (ie expiration)  without going through the OAuth handshake again. Copy the refresh token from the previous command or obtain an new accces token again and copy the refresh token.
	```
	./test-api.sh oauth refresh-token
	>>>>>>>>>> OAuth API <<<<<<<<<< 

	Obtain new Access Token using refresh token: https://localhost:9444/localtest/sandbox/oauth2/token
	Enter the refresh token: AAK34hPGK5DnzE1nkGd7eJD6EzHrwVEpHJm86Ug3dzSoHhnmcBK3ezohzygBFFKk1pGWfS_Ljsjjad1sAOZwsMAq8LFGAzbCP29PkuKtIL52yQ

	SUCCESS
	{"token_type":"Bearer","access_token":"AAIgY2RmZWEzNzM0NmNjMzQ5ZDYyODJhNzVhN2ZiZTU5MTemg6bs7UZm2tfbVzUkITUDF-OdVt8MsBrdIAkR_AJyDCa9YfcRjE3thW-XLDn57a_oKLKDB_v1aZZl6u00n5mO","scope":"weather","expires_in":3600,"consented_on":1572462600,"refresh_token":"AAIUT71CSPo8PTXszXG7djChCRGmRwmQX3YpjEMVCV-V7palEtTD63cAD_qbSbieDw-8gz8GNY_Dlen8DuJzq29GSWR9cyU4VxYOlMZTVpkhRg","refresh_token_expires_in":2682000}
	```
	The response contains both a new access token and refresh token. 

5. If you try to use the same refresh token, you will get an error.
	```
	./test-api.sh oauth refresh-token

 	>>>>>>>>>> OAuth API <<<<<<<<<< 

	Obtain new Access Token using refresh token: https://localhost:9444/localtest/sandbox/oauth2/token
	Enter the refresh token: AAK34hPGK5DnzE1nkGd7eJD6EzHrwVEpHJm86Ug3dzSoHhnmcBK3ezohzygBFFKk1pGWfS_Ljsjjad1sAOZwsMAq8LFGAzbCP29PkuKtIL52yQ

	SUCCESS
	{"error":"invalid_grant","error_description":"*[cdfea37346cc349d6282a75a7fbe5917] refresh_token was used before or revoked, message rejected*"}
	```
6. Revocation of tokens is also possible using the test tools but revocation is currently unsupported in the LTE. If you have access to a deployment of non-LTE API Connect, you can perform the following steps to understand token revocation.

	1. Obtain access token: `./test-api oauth resource-owner`
	2. View Token List: `./test-api oauth token-list` => should return access token from step #1
	3. Revoke Token: `./test-api oauth revoke` => should be successful
	4. View Token list: `./test-api oauth token-list` => should not return any access tokens
	
In this tutorial, you learned about the lifecycle of OAuth tokens. Specifically, you obtained a new access token from a refresh token. Revoked and listed tokens and obtained the details of an access token.