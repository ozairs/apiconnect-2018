context.message.body.readAsBuffer(function (error, response) {
        if (error) {
            console.error ('>> pre introspection - error performing introspection');
            return;
        }

        console.info("pre introspection: response %s", response);

        var queryList = {};
        var queryParams = response.toString().split('&');
        for (var i = 0; i < queryParams.length; i++) {
            var tmpArray = queryParams[i].split('=');
            queryList[tmpArray[0]] = tmpArray[1];

        }
        //setting third-party token into Authorization header
        console.info('token %s', queryList['token']);
        context.message.header.set('Authorization', 'Bearer ' + queryList['token']);
    });