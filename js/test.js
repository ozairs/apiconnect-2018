var response = 'token=ya29.Gl2jBvNNXUGNPVtbpqWSJp9Stl4sc0Q2i_yxT_YO36LezJpqaA9oxAtPCuvW_uwSDMBcp6KXvkq2XikolzZ7D94s1DAzYVN3HNKgVaNTjC8ZX-SI7qbElvARRDW1H4M&token_type_hint=access_token&scope=openid';
var queryList = {};
var queryParams = response.toString().split('&');
for (var i = 0; i < queryParams.length; i++) {
    var tmpArray = queryParams[i].split('=');
    queryList[tmpArray[0]] = tmpArray[1];
    
}
console.log('token %s', queryList);
console.log('token %s', queryList['token']);
//var token = queryList.toString().s
//context.message.body.write(JSON.stringify(response));