# Optimize Gateway workloads with JavaScript

**Duration**: 10 minutes

In this tutorial, you will learn how to write GatewayScript, a secure and optimized Javascript runtime to optimize gateway transactions. If you have never written a line of GatewayScript and are getting worried that you get redirected you to the [documentation](http://www.ibm.com/support/knowledgecenter/SS9H2Y_7.5.0/com.ibm.dp.doc/gatewayscript_model.html) - you can relax because as a developer, we know that the best way to learn is to experiment. For this reason, we have created the [DataPower playground](https://developer.ibm.com/datapower/datapower-playground) for you. Now, off to the playground to build a sand castle ... in JavaScript!

Let's start with a basic example of generating a log message from an existing HTTP header.
 
1. Point your Web browser to [https://developer.ibm.com/datapower/datapower-playground/](https://developer.ibm.com/datapower/datapower-playground/).
2. Select the **Samples** tab and click the first **Edit and Test** buttons (under Exercise 1: Hello GatewayScript).
3. Enter the following code
	```
	var hm = require('header-metadata'); 
	
	var allHeaders = hm.current.get();
	console.log(JSON.stringify(allHeaders));
	
	var contentType = hm.current.get('Content-Type');
	console.log("Content-Type header %s", contentType);
	```
	This code retrieves all the runtime headers or a named header (Content-Type) and outputs it to the system logs.

4. Select the **Request** tab and click the **Test** button
5. Click the **Log** tab to examine the response. You should see the log messages in the output.
	```
	Mon Aug 15 2016 16:01:54 GMT-0400 (EDT) Logs corresponding to transaction id (625)
	20160815T200144.357Z [0x8580009e][gatewayscript][info] mpgw(fiddle): tid(625)[request] gtid(625): Running the script file 'local:///fiddleExecute.js'
	20160815T200144.358Z [0x8580009e][gatewayscript][info] mpgw(fiddle): tid(625)[request] gtid(625): Running the script file 'temporary:///temp_00003'
	20160815T200144.359Z [0x8580005c][gatewayscript-user][info] mpgw(fiddle): tid(625)[request] gtid(625): {"Content-Type":"application/json","Host":"localhost:42451","Content-Length":"0","Via":"1.1 AAAAAPiD+o0-","X-Client-IP":"127.0.0.1","X-Global-Transaction-ID":"625"}
	20160815T200144.359Z [0x8580005c][gatewayscript-user][info] mpgw(fiddle): tid(625)[request] gtid(625): Content-Type header application/json
	```
	Now that you have got the `hello world experience`, lets do something more interesting. Let's write code to inject data into the message.
6. Select the **Code** tab and enter the following code
	```
	session.input.readAsJSON(function (error, json) {
		if (error) throw error;

		console.log("json %s", JSON.stringify(json));
		json.data['platform'] = 'Powered by IBM DataPower Gateways';

		// Write the output to the 'output' context. This
		// is creating a new body in the flow
		session.output.write(json);
		console.info("readAsJSON success: %s", json);
	});
	```
	This code performs the following:
	- Injects an attribute named **platform** with value  **Powered IBM DataPower Gateways** into an existing `data' JSON object 
	- Writes the modified `json` variable as the response message
  
7. Click the **Request** tab
8. Insert the following JSON request into the textbox:
	```
	{
		"data": {
		"moves": "too fast"
		},
		"height": "180",
		"name": "dp-pokemon",
		"weight": 100,
		"id": "1"
	}
	```
9. Click the **Test** button
10. Select the **Response** tab to examine the response. You should see the modified JSON response.

Now its time to build the uber medieval castle using an actual GatewayScript file in the DataPower Gateway.

These next steps will be a little bit different than what you did in the last section. The DataPower playground is like an *echo service*, you send some data, and it will give you a response. In a traditional request/response gateway flow, you send a request to a backend service provider via the gateway, which has visibility into the transaction. In this next step, you will modify the response message to inject the JSON **platform** attribute. 

1. In your datapower project directory, (remember the **config** and **local** directories created when you initially ran the container) create a new file called **gs-header.js** inside the **local** directory.
2. Add the same code from the last step into the file
	```
	session.input.readAsJSON(function (error, json) {
		if (error) throw error;

		console.log("json %s", JSON.stringify(json));
		json.data['platform'] = 'Powered IBM DataPower Gateways';

		// Write the output to the 'output' context. This
		// is creating a new body in the flow
		session.output.write(json);
		console.info("readAsJSON success: %s", json);
	});
	```
3. In the Web GUI, open the *rest-proxy* page and then the policy (click the Pencil icon).
4. Select the *Server to Client* rule 
	*Note:* Rules are triggered based on whether the transaction is a request, response, or error.
5. Drag a GatewayScript action into the policy editor between the existing two actions.
6. Double-click the action and select **local:///gs-header.js** file.
7. Click **Done** and then **Apply Policy** to save your changes. 
8. Lets run a test again, enter the GET request: `[http://localhost:8000/api/pokemons/9ed78062996515b4db7e1b78d73208b0](http://localhost:8000/api/pokemons/9ed78062996515b4db7e1b78d73208b0) and make sure you get a JSON response.
	```
	{
	"data": {
		"moves": "slow",
		**"platform": "Powered by IBM DataPower Gateways"**
	},
	"height": "70",
	"name": "ivysaur",
	"weight": 200,
	"id": "12c1731a06233e6a933ba92106334ac9"
	}
	```
	You just caught some Pokemon with DataPower!

# Summary

In this tutorial, you learned how to write JavaScript to optimize gateway workloads. You wrote a simple GatewayScript file to modify a JSON response and quickly tested it against a real backend service.

**Next Step**: TBD