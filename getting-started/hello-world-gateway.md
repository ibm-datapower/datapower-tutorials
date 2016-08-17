# Your First Configuration

**Duration**: 10 minutes

The smoke test for successfully installing and using any software is creating the 'hello world' application or service. Like all good `hello world` applications, this one starts from absolutely nothing.

For this tutorial, we will try to catch some virtual __Pokemon__ (this is what everyone is doing in 2016!). You will deploy a gateway service to securely connect to an existing endpoint: [https://pokemons.mybluemix.net/](https://pokemons.mybluemix.net/).

Lets import a sample `hello-world` configuration.

You check out the entire project from our GitHub repository [here](https://github.com/ibm-datapower/datapower-tutorials.git). Alternatively, you can skip these steps (#1-#4) and import the configuration into your running container.

1. Navigate to the directory where you would like to run these tutorials. If you already have a `datapower' directory, you can remove it and start fresh with a new DataPower configuration from source control. This is the ideal path for supporting continous delivery in the docker world.
2. Enter the command `git clone https://github.com/ibm-datapower/datapower-tutorials.git`
3. Navigate to the respective directory: `cd getting-started` .
4. Remove the old DataPower container and start it up again but this time it will reference existing DataPower source directories (`local` and `config`)
	```
    docker run -it \
      -v $PWD/config:/drouter/config \
      -v $PWD/local:/drouter/local \
      -e DATAPOWER_ACCEPT_LICENSE=true \
      -e DATAPOWER_INTERACTIVE=true \
      -p 9090:9090 \
      -p 9022:22 \
      -p 5554:5554 \
      -p 8000-8010:8000-8010 \
      --name idg \
      ibmcom/datapower
	```
If you did not checkout the project from GitHub, then perform the following steps to import the sample configuration.

1. Download the sample gateway configuration from [here](https://github.com/ibm-datapower/datapower-tutorials/blob/master/getting-started/import/hello-world.zip).
2. In the DataPower Web GUI, click the top-left corner icon (hamburger), and select **Import Configuration**.
3. Select the previously imported file and click **Next** and then **Import**. Click **Close** once complete.

You are now ready to start deploying a gateway service to find some pokemons! 

1. Once deployed, click the __Services__ icon to view the __rest-proxy__ gateway configuration.
   This service provides a REST gateway that proxies JSON/HTTP(s) requests. The configuration for the backend service is already pre-populated with [https://pokemons.mybluemix.net/](https://pokemons.mybluemix.net/). 

2. Click the pencil icon under __Multi-Protocol Gateway Policy__ to view the gateway policy. 
	
**Note**: The gateway service contains different rules for each HTTP methods (GET, POST, PUT, and DELETE). You can proxy any service that adheres to REST conventions. 

3. Before you call the DataPower gateway service, lets directly call the backend service to make sure its available, [https://pokemons.mybluemix.net/api/pokemons/1](https://pokemons.mybluemix.net/api/pokemons/1). You can use any test client (or even a Web browser).

	```
	{
	"data": {
		"moves": "slow"
	},
	"height": "70",
	"name": "ivysaur",
	"weight": 200,
	"id": "1"
	}
	```

4. You will simply proxy the same request now using DataPower. Now test with the URL: [http://localhost:8000/api/pokemons/1](http://localhost:8000/api/pokemons/1). 

	Make sure you get the same JSON response. You know what they say about Pokemon - __Catch 'Em All__!
5. Click the __Save changes__ link at the top, so you don't lose all those pokemon :)
6. Now, lets save that **golden** image - create a file called `Dockerfile` in the same location as your `local` and `config` directories.

	```
	$ ls
	config	local Dockerfile 
	```

	with the contents:

	```
	FROM ibmcom/datapower
	ENV DATAPOWER_ACCEPT_LICENSE=true \
		DATAPOWER_WORKDR_THREADS=2 \
		DATAPOWER_INTERACTIVE=true
	COPY config /drouter/config
	COPY local /drouter/local
	```

6. Build your own image. This is taking your source files, the ones in ./config and ./local, and placing them into `myimage`. It's also including the environment variables -- all these are built into the image!
	
	```
	$ docker build -t myimage .
	Sending build context to Docker daemon 4.182 MB
	Step 1 : FROM ibmcom/datapower
	---> 62ce04e36704
	Step 2 : ENV DATAPOWER_ACCEPT_LICENSE true DATAPOWER_WORKDR_THREADS 2 DATAPOWER_INTERACTIVE true
	---> Running in 7bc58a01fc65
	---> b7ecc80676f5
	Removing intermediate container 7bc58a01fc65
	Step 3 : COPY config /drouter/config
	---> 3b7bcba2d155
	Removing intermediate container e7f459b1129b
	Step 4 : COPY local /drouter/local
	---> 381e9e8f0307
	Removing intermediate container 46f232df7c33
	Successfully built 381e9e8f0307
	```

7. Run your own image. It's entirely self contained!  
	
	`docker run -it myimage` 

# Summary

In this section, you imported and deployed a sample gateway service, which defines a REST gateway pattern. You ran a simple test to proxy a RESTful request and obtain a JSON response.

**Next Step**: [Optimize Gateway workloads with JavaScript](../gatewayscript/gatewayscript-101.md)
