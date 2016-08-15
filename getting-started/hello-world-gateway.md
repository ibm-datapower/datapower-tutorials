# Hello World Gateway services

The smoke test for successfully installing and using any software is creating the *hello world* application or service. Like all good `hello world` applications, this one starts from absolutely nothing.

Before creating your first gateway service, let's do a quick overview of the Web GUI. Tasks are grouped via icons in the left navigation bar:

 * __Services__: create new or view existing gateway services
 * __Status__: view status information about your gateway instance, such as networking, runtime requests/responses, and caches
 * __Patterns__: easily create new gateway services using the out-of-the box patterns
 * __Network__: view and configure network components and management interfaces (ie SSH, REST, SOAP, & Web GUI)
 * __Administration__: create application domains (provides configuration isolation), user accounts and much more. 
 	__Note__: Most of these capabilities are available in the __default__ domain (current domain). It is recommended that you create your gateway services in a new domain.
 * __Object__: configure and view objects utilized by your gateway services   

For this tutorial, we will try to catch some virtual __Pokemon__ (it seems that is what everyone is doing in 2016!). You will deploy a gateway service to securely connect to an existing endpoint: [https://pokemons.mybluemix.net/](https://pokemons.mybluemix.net/).

Since, you need to securely connect to this server over https, lets import an SSL/TLS configuration to securely connect to our backend service.

1. Download the SSL client profile from here: [import/ssl-client.zip](import/ssl-client.zip)
2. In the DataPower Web GUI, select the top-left corner icon, and select **Import Configuration**.
3. Select the previously imported file and click **Next** and then **Import**. Click **Close** once complete.

We are now ready to start deploying a gateway service to find our pokemons! 

1. Click the __Patterns__ icon and select the **Mobile REST proxy**.
2. Click **Deploy** and enter the following info (just the mandatory ones):
 - Service name: rest-proxy
 - URL: https://pokemons.mybluemix.net/
 - SSL client profile: ssl-client 
 - Port: 8000 (must be one of the Docker exposed ports)
3. Click **Deploy pattern**.
4. Once deployed, click the __Services__ icon to view the __rest-proxy__ gateway configuration.
5. Click the pencil icon under __Multi-Protocol Gateway Policy__ to view the gateway policy. 
	
**Note**: The gateway service contains different rules for each HTTP methods (GET, POST, PUT, and DELETE). You can proxy any REST service that adheres to REST conventions. 

6. Using your favourite test client (mine is Postman), enter the following GET request:[http://localhost:8000/api/pokemons/9ed78062996515b4db7e1b78d73208b0](http://localhost:8000/api/pokemons/9ed78062996515b4db7e1b78d73208b0) and make sure you get a JSON response. 

	You know what they say, __Catch 'Em All__!

7. Click the __Save changes__ link, so you don't lose all those pokemon :)

8. Create a file called Dockerfile in your local directory with the contents:
```
FROM ibmcom/datapower
ENV DATAPOWER_ACCEPT_LICENSE=true \
    DATAPOWER_WORKDR_THREADS=2 \
    DATAPOWER_INTERACTIVE=true
COPY config /drouter/config
COPY local /drouter/local
```

9. Build your own image. This is taking your source files, the ones in ./config and ./local, and placing them into `myimage`. It's also including the environment variables -- all these are built into the image!

	`docker build -t myimage .`

10. Run your own image. It's entirely self contained!  
	
	`docker run -it myimage` 

# Summary

In this section, you pulled down the latest DataPower Docker image and started the DataPower container. You performed some basic configuration to enable the Web GUI.

**Next Step**: [Modify Gateway transactions ](gatewayscript-101.md)
