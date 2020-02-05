#! /bin/sh

nice_echo() {
    echo "\n\033[1;36m >>>>>>>>>> $1 <<<<<<<<<< \033[0m\n"
}

FILENAME='';
while getopts hf: option
do
case "${option}"
in
f) FILENAME=${OPTARG};;
h) echo "Usage: ./test-api.sh [OPTION] [API] [RESOURCE]
          OPTION:
          -f FILENAME
          -h, --help        Display this help and exit

          API: name of API
          RESOURCE: resource name of API
          "
esac
done

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# no parameters passed, using default config file
if [ "$FILENAME" == '' ]; then
  source config.cfg
  echo 'Using default config file at ' ${CURRENT_DIR}/config.cfg 
  COMMAND=$1
  SUBCOMMAND=$2
  EXTRA_CURL_COMMANDS=$3
# config file passed as argument
else 
    if [ -e $FILENAME ]; then
        source $FILENAME; # load the file
        echo 'Using config file located at' $FILENAME
    else 
        echo 'Bad config file passed at ' $FILENAME
        exit
    fi
  COMMAND=$3
  SUBCOMMAND=$4
  EXTRA_CURL_COMMANDS=$5
fi

case $COMMAND in

  oauth)
    nice_echo "OAuth API"
      case $SUBCOMMAND in

        resource-owner)
          echo "Resource Owner: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token"
          CURL_BODY='a=b&client_id='${CONSUMER_CLIENT_ID}'&client_secret='${CONSUMER_CLIENT_SECRET}'&grant_type=password&scope='${CONSUMER_SCOPE}'&username='$CONSUMER_USERNAME'&password='${CONSUMER_PASSWORD}

          RESPONSE=`curl -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token`

          RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.access_token'`
        ;;

        application)
          echo "Client Credentials: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token"
          CURL_BODY='a=b&client_id='${CONSUMER_CLIENT_ID}'&client_secret='${CONSUMER_CLIENT_SECRET}'&grant_type=client_credentials&scope='${CONSUMER_SCOPE}'&b=c'

          RESPONSE=`curl -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token`

          RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.access_token'`
        ;;

        implicit)
          echo "Implicit: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/authorize"
          CURL_BODY='a=b&response_type=token&grant_type=authorization_code&client_id='${CONSUMER_CLIENT_ID}'&client_secret='${CONSUMER_CLIENT_SECRET}'&redirect_uri='${CONSUMER_REDIRECT_URL}'&scope='${CONSUMER_SCOPE}'&b=c'

          RESPONSE=`curl -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded"  -u "${CONSUMER_USERNAME}:${CONSUMER_PASSWORD}" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/authorize --include 2>&1 | grep 'Location'`
          
          RESPONSE_STATUS=`echo "$RESPONSE"`

          #example to parse access_code `./test-api.sh oauth implicit | cut -d'#' -f 2 | cut -d'=' -f 2 | cut -d'&' -f 1`
        ;;

        jwt)
          echo "JWT Grant Type: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token"
          CURL_BODY='a=b&client_id='${CONSUMER_CLIENT_ID}'&client_secret='${CONSUMER_CLIENT_SECRET}'&grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&scope='${CONSUMER_SCOPE}'&assertion='${CONSUMER_JWT_TOKEN}

          RESPONSE=`curl -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token`

          RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.access_token'`
        ;;

        access-code)
          echo "Access Code: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/authorize"
          CURL_BODY='?client_id='${CONSUMER_CLIENT_ID}'&response_type=code&scope='${CONSUMER_SCOPE}'&redirect_uri='${CONSUMER_REDIRECT_URL}

          RESPONSE=`curl -s -k -H "Content-Type: application/x-www-form-urlencoded" -u "${CONSUMER_USERNAME}:${CONSUMER_PASSWORD}" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/authorize$CURL_BODY --include 2>&1 | grep 'Location'`

          RESPONSE_STATUS=`echo "$RESPONSE"`

          if [[ $RESPONSE_STATUS == '' ]];   #item does not exist
          then
            RESPONSE_STATUS=null            
          fi

          #example to parse access_code `./test-api.sh oauth access-code | cut -d'=' -f 2`
        ;;

        code)
          echo "Exchange Code for Access Token: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token"

          read -p "Enter the authorization code: " TOKEN_RESPONSE

          CURL_BODY='a=b&grant_type=authorization_code&client_id='${CONSUMER_CLIENT_ID}'&client_secret='${CONSUMER_CLIENT_SECRET}'&redirect_uri='${CONSUMER_REDIRECT_URL}'&code='$TOKEN_RESPONSE'&b=c'

          RESPONSE=`curl -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token`

          #example parse access code | grep { | jq -r '.access_token'

          RESPONSE_STATUS=`echo "$RESPONSE"`

          if [[ $RESPONSE_STATUS == '' ]];   #item does not exist
          then
            RESPONSE_STATUS=null            
          fi
        ;;

        refresh-token)
          echo "Obtain new Access Token using refresh token: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token"

          read -p "Enter the refresh token: " TOKEN_RESPONSE

          CURL_BODY='a=b&grant_type=refresh_token&refresh_token='$TOKEN_RESPONSE'&b=c'

          APPLICATION_BASIC_AUTH=`echo "${CONSUMER_CLIENT_ID}:${CONSUMER_CLIENT_SECRET}" | tr -d '\n' | base64`

          RESPONSE=`curl -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Basic $APPLICATION_BASIC_AUTH" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/token`

          RESPONSE_STATUS=`echo "$RESPONSE"`

          if [[ $RESPONSE_STATUS == '' ]];   #item does not exist
          then
            RESPONSE_STATUS=null            
          fi
        ;;

        introspect)
          echo "Introspect Access Token: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/introspect"

          read -p "Enter the access token: " TOKEN_RESPONSE

          CURL_BODY='a=b&token_type_hint=access_token&client_id='${CONSUMER_CLIENT_ID}'&client_secret='${CONSUMER_CLIENT_SECRET}'&token='$TOKEN_RESPONSE'&b=c'

          RESPONSE=`curl -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Basic ${CONSUMER_BASIC_AUTH}" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/introspect`

          RESPONSE_STATUS=`echo "$RESPONSE"`

          if [[ $RESPONSE_STATUS == '' ]];   #item does not exist
          then
            RESPONSE_STATUS=null            
          fi
        ;;

        token-list)
          echo "Token List for Application: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/issued"
        
          RESPONSE=`curl -s -k -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Basic ${CONSUMER_BASIC_AUTH}" -H "x-ibm-client-id: ${CONSUMER_CLIENT_ID}" -H "x-ibm-client-secret: ${CONSUMER_CLIENT_SECRET}" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/issued`

          RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.'`
        ;;

        revoke)
          echo "Revoke Token for Application: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/issued"

          read -p "Enter the access token to revoke or 'all' to revoke every token: " TOKEN_RESPONSE

          # revokes all tokens for the resource owner
          if [[ $TOKEN_RESPONSE == 'all' ]];
          then
            PARAMS='?client-id='${CONSUMER_CLIENT_ID}
            
            RESPONSE=`curl -s -k -X DELETE -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Basic ${CONSUMER_BASIC_AUTH}" -H "x-ibm-client-id: ${CONSUMER_CLIENT_ID}" -H "x-ibm-client-secret: ${CONSUMER_CLIENT_SECRET}" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/issued$PARAMS`
          # removes specific access token
          else

            read -p "Enter 1 for access token or 2 for refresh token: " TOKEN_TYPE
            CURL_BODY='a=b&token_type_hint='$TOKEN_TYPE'&token='$TOKEN_RESPONSE'&b=c'

            if [[ $TOKEN_TYPE == 1 ]];   
            then
              RESPONSE_HINT='access_token'
            elif [[ $TOKEN_TYPE == 2 ]];   
            then
              RESPONSE_HINT='refresh_token'
            else
              echo "Invalid option selected ... exiting"
              exit
            fi

            APPLICATION_BASIC_AUTH=`echo "${CONSUMER_CLIENT_ID}:${CONSUMER_CLIENT_SECRET}" | tr -d '\n' | base64`
            RESPONSE=`curl -s -k -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Basic $APPLICATION_BASIC_AUTH" ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/oauth2/revoke`
          fi
        
          RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.'`
        ;;

        *)
          echo "Usage: ./test-api.sh [OPTION] [API] [RESOURCE]
          OPTION:
          -f FILENAME
          -h, --help        Display this help and exit

          API: name of API
          RESOURCE: resource name of API
          "
          ;;
      esac
    ;;

  weather)
    nice_echo "Calling Weather API: ${DP_APIGW_ENDPOINT}/weather/$SUBCOMMAND"
    RESPONSE=`curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "x-ibm-client-id: ${CONSUMER_CLIENT_ID}" -H "x-ibm-client-secret: ${CONSUMER_CLIENT_SECRET}" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/weather/$SUBCOMMAND`
    
    STATUS=`echo "$RESPONSE" | jq -r '401'`
    if [[ $RESPONSE == null ]];   #item exists 
    then
      RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.'`
    else
      RESPONSE_STATUS=null
    fi
    
    ;;

  utility)
    nice_echo "Utility API: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/utility/$SUBCOMMAND"
    RESPONSE=`curl -s -k -u "${CONSUMER_USERNAME}:${CONSUMER_PASSWORD}" -H "Content-Type: application/json" -H "Accept: application/json" -H "$EXTRA_CURL_COMMANDS" ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/utility/$SUBCOMMAND`
    
    RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.'`
    ;;

  utility-introspect)
    nice_echo "Utility API: ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/utility/introspect/$SUBCOMMAND"

    read -p "Enter the JWT token: " TOKEN_RESPONSE
    CURL_BODY='a=b&token_type_hint=access_token&token='$TOKEN_RESPONSE'&b=c'
    
    RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/utility/introspect/$SUBCOMMAND`

    RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.'`
    ;;

  weather-oauth)
    nice_echo "Weather API"

    read -p "Enter the access token: " TOKEN_RESPONSE
    RESPONSE=`curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN_RESPONSE" -H "x-ibm-client-id: ${CONSUMER_CLIENT_ID}" -H "x-ibm-client-secret: ${CONSUMER_CLIENT_SECRET}" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/weather/$SUBCOMMAND?zipcode=10510`

    RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.httpCode'`

    if [[ $RESPONSE_STATUS == 401 ]];   #failed call
    then
      RESPONSE_STATUS=null
    else 
      RESPONSE_STATUS='OK'
    fi
    ;;

  sports)
    nice_echo "Team API"

    #RESPONSE=`curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "x-ibm-client-id: ${CONSUMER_CLIENT_ID}" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/sports/$SUBCOMMAND?league=nba`
    RESPONSE=`curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "x-ibm-client-id: ${CONSUMER_CLIENT_ID}" $EXTRA_CURL_COMMANDS "https://127.0.0.1.xip.io/api/team/list?league=nba"`
    ;;

  pokemon)
    nice_echo "Pokemon API"
    RESPONSE=`curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/api/$SUBCOMMAND`
    ;;

  google)
    nice_echo "Google OpenID Provider API" 

    echo "Enter the following URL into the Web browser " ${GOOGLE_OPENID_URL}
    #RESPONSE=`curl -k -H "Content-Type: application/json" -H "Accept: application/json" "${GOOGLE_OPENID_URL}"`
    ;;

  auth0)
    nice_echo "Auth0 API: " ${AUTHO_URL}

    read -p "Enter the JWT token: " TOKEN_RESPONSE
    CURL_BODY='a=b&token_type_hint=access_token&token='$TOKEN_RESPONSE'&b=c'
    
    RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" --data "'"$CURL_BODY"'" $EXTRA_CURL_COMMANDS ${DP_APIGW_ENDPOINT}/${pORG_NAME}/${CATALOG_NAME}/utility/introspect/$SUBCOMMAND`

    RESPONSE_STATUS=`echo "$RESPONSE" | jq -r '.'`
    ;;

  *)
    echo "Usage: ./test-api.sh [OPTION] [API] [RESOURCE]
          [OPTION]:
          -f FILENAME
          -h, --help        Display this help and exit

          [API] name of API
          [RESOURCE] resource name of API
          "
    ;;
esac


RED='\n\033[1;31m'
GREEN='\n\033[1;32m'
END_COLOR='\033[0m'

if [[ $RESPONSE_STATUS == null ]];   #item exists 
then
 echo "${RED}FAIL${END_COLOR}"
 echo 'Failed call with error' $RESPONSE
else
  echo "${GREEN}SUCCESS${END_COLOR}"
  echo $RESPONSE
fi