# Experience DataPower management interfaces

**Duration**: 15 minutes

DataPower provides a number of configuration management interfaces. Each of these interfaces is fully capable so anything you can do in the Web UI you can do via our Command Line Interface, likewise with the REST API, neat!

Here is a list of the main configuration management interfaces for more information and the complete list click [here](http://www.ibm.com/support/knowledgecenter/SS9H2Y_7.5.0/com.ibm.dp.doc/networkaccess.html).

 * Command Line Interface (CLI)
 * REST Management Interface (RMI)
 * Web User Interface (Web UI)

# Command Line Interface 

The DataPower CLI syntax was designed to be human readable and editable. All configuration is persisted in this syntax so once you learn the CLI you can use this knowledge to edit the configuration files directly. Configuration files are persisted in `/drouter/config` which corresponds to the `config:` file management identifier. Lets walk through an example:  

1. Create a new directory on your local filesystem (under your `datapower' directory)
	```
	mkdir cli_datapower_example
	cd cli_datapower_example
	```
2. If you already started a DataPower container in the [start with docker](start-with-docker.md) tutorial, you can skip the step to run the container below, otherwise enter this command:
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
3. Login to the CLI, default username is `admin` and also password is `admin`. Confirm that both `config:` and `local:` are empty. We’ll do this via the DataPower CLI and the local filesystem.
	```
	configure terminal
	dir local:
	dir config:

	```
	These directories are empty on your local file system.
4. Now lets enable the SSH service and persist the configuration using the CLI. We use `write memory` to save or persist the configuration, populating `config:` with a file called `autoconfig.cfg`.
	```
	ssh 0.0.0.0 22
	write memory
	```
	Enter `yes` to overwrite current configuration when prompted.
5. On the local file system you should see a new configuration file `config/autoconfig.cfg`, open this file in your favorite editor and search for `ssh`. You’ll find this configuration and the entire DataPower default configuration properties. We persist defaults to aid with forward and backwards compatibility.
6. Now test using SSH to connect to port 9022. 
```
ssh -p 9022 localhost
```
7. Switch back to editing `config/autoconfig.cfg` and directly edit the `rest-mgmt` stanza and change `admin-state “disabled”` to `admin-state “enabled”`. Save the file and restart and attach to the container. (use `docker ps` to determine the container id)
	```
	docker restart <container_id>
	docker attach <container_id>
	```

8. We like to use http://httpie.org to interact with a REST API from the command line. To see whats possible issue the following command:

	```
	http --verify=no --auth admin:admin https://localhost:5554/mgmt/
	```

	which should produce the following JSON output
	```
	{
		"_links":{
				"self":{"href":"/mgmt/"},
				"config":{"href":"/mgmt/config/"},
				"domains":{"href":"/mgmt/domains/config/"},
				"status":{"href":"/mgmt/status/"},
				"actionqueue":{"href":"/mgmt/actionqueue/"},
				"filestore":{"href":"/mgmt/filestore/"},
				"metadata":{"href":"/mgmt/metadata/"},
				"types":{"href":"/mgmt/types/"}
	}}
	```
# REST Management Interface

Now lets do a quick overview of the REST API, which helps developers achieve a faster workflow through its modern API design and descriptive error messages. This section explains how to use the REST management interface to manage and monitor the configuration. It also describes the functions, structure, and capabilities of the REST management interface. 

1. We can use the `config` namespace to query aspects of any configuration object. To complete the URL the application domain must be provided. The following command queries the configuration state of the REST Management Interface in the `default` application domain. To learn more about application domains click [here](http://www.ibm.com/support/knowledgecenter/SS9H2Y_7.5.0/com.ibm.dp.doc/domains.html)

	```
	http --verify=no --auth admin:admin https://localhost:5554/mgmt/config/default/RestMgmtInterface
	```

which should produce the following JSON output
	```
	{
		"RestMgmtInterface": {
			"ACL": {
				"href": "/mgmt/config/default/AccessControlList/rest-mgmt",
				"value": "rest-mgmt"
			},
			"LocalAddress": "0.0.0.0",
			"LocalPort": 5554,
			"SSLConfigType": "server",
			"_links": {
				"doc": {
					"href": "/mgmt/docs/config/RestMgmtInterface"
				},
				"self": {
					"href": "/mgmt/config/default/RestMgmtInterface/RestMgmt-Settings"
				}
			},
			"mAdminState": "enabled",
			"name": "RestMgmt-Settings"
		},
		"_links": {
			"doc": {
				"href": "/mgmt/docs/config/RestMgmtInterface"
			},
			"self": {
				"href": "/mgmt/config/default/RestMgmtInterface"
			}
		}
	}
	```

For more information on how to use and explore this feature we recommend the following tutorial series [REST management interface and IBM DataPower Gateway: Part 1: Introduction to the REST management interface and status monitoring](http://www.ibm.com/developerworks/websphere/library/techarticles/1512_derbakova/1512_Derbakova_P1.html)

# Web User Interface

Now lets do a quick overview of the Web UI. This is where you will spend the majority of your time, so it is good to become familiar with it.

Once you have logged into the Web GUI, you will see an icon to the top-left corner (kinda looks like a hamburger), which provides quick links to common tasks, let's look at some of the key items:

When building gateway configuration, the following items provide:
 * __Services__: create new or view existing gateway services
 * __Status__: view status information about your gateway instance, such as networking, runtime requests/responses, and caches
 * __Import/Export Configuration__: import/export DataPower configuration to/from an external ZIP or XML file 

 When administering or troubleshooting gateway services, the following items provide:
 * __Network__: view and configure network components and management interfaces (ie SSH, REST, SOAP, & Web UI)
 * __Troubleshooting__: list of troubleshooting tools, such as the datapower debugger (ie multi-step probe)
 * __Logs__: view the system log

The same top 6 links are grouped via icons in the left navigation bar, once you start working with the DataPower Web GUI, these icons will become more familiar to you.

The typical workflow is to either create a new gateway service via the __Services__ link or import external configuration, either via a ZIP file __Import Configuration__ or through source control using a Docker volume mount. You configure your service in the __Services__ section, specifically the policy editor. Once finished, you can examine the __Status__ provider to view runtime transactional information. If errors occur, the Troubleshooting tools provide you the ability to walk through a flow via the debugger, or look at system logs for issues. For networking related issues, several networking tools like packet capture, ping, tcp-connect are available for troubleshooting.

# Summary

In this section, you reviewed the existing management interfaces, CLI, RMI and the Web GUI and a few simple commands to give you a basic idea of how to use them.

**Next Step**: [Your First Configuration](hello-world-gateway.md)