# Overview

DataPower provides a number of configuration management interfaces. Each of these interfaces is fully capable so anything you can do in the Web UI you can do via our Command Line Interface, likewise with the REST API, neat!

Here is a list of the main configuration management interfaces for more information and the complete list click [here](http://www.ibm.com/support/knowledgecenter/SS9H2Y_7.5.0/com.ibm.dp.doc/networkaccess.html)

 * Command Line Interface (CLI)
 * Web User Interface (Web UI)
 * REST Management Interface (RMI)

# Command Line Interface 

The DataPower CLI syntax was designed to human readable and editable. All configuration is persisted in this syntax so once you learn the CLI you can use this knowledge to edit the configuration files directly. Configuration files are persisted in `/drouter/config` which corresponds to the `config:` file management identifier. Lets walk through an example to demonstrate this:  

1. Create a new directory on your local filesystem
```
mkdir cli_datapower_example
cd cli_datapower_example
```
2. Start the DataPower container mounting volumes relative to the current working directory. Map port 9022 -> 22 for SSH access, port 9090 for the Web UI and 5554 for the REST API, all of which we will enable and use shortly 

```
docker run --rm --it \
  -v $PWD/config:/drouter/config \
  -v $PWD/local:/drouter/local \
  -e DATAPOWER_ACCEPT_LICENSE=true \
  -e DATAPOWER_INTERACTIVE=true \
  -p 90220:22 \
  -p 9090:9090 \
  -p 5554:5554 \
  ibmcom/datapower
```

3. Login to the CLI, default username is `admin` and also password is `admin`. Confirm that both `config:` and `local:` are empty. We’ll do this via the DataPower CLI and the local filesystem.

```
configure terminal
dir local:
dir config:

```
and
```
find .
```

4. Now lets enable the SSH service and persist the configuration using the CLI. We use `write memory` to save or persist the configuration, populating `config:` with a file called autoconfig.cfg.

```
ssh 0.0.0.0 22
write memory
```

5. On the local file system you should see a new configuration file `config/autoconfig.cfg`, open this file in your favorite editor and search for `ssh`. You’ll find this configuration and also all the DataPower default configuration properties. We persist defaults to aid with forward and backwards compatibility.

6. Now test using SSH to connect to port 9022. 

```
ssh -p 9022 localhost
```

7. Switch back to editing `config/autoconfig.cfg` and directly edit the `web-mgmt` stanza and change `admin-state “disabled”` to `admin-state “enabled”`. Save the file and restart and attach to the container. (use `docker ps` to determine the container id)

```
docker restart <container_id>
docker attach <container_id>
```

8. Now test that you can successfully connect to the Web UI, via `https://localhost:9090/

# Web User Interface

Now lets do a quick overview of the Web UI. Tasks are grouped via icons in the left navigation bar:

 * __Services__: create new or view existing gateway services
 * __Status__: view status information about your gateway instance, such as networking, runtime requests/responses, and caches
 * __Patterns__: easily create new gateway services using the out-of-the box patterns
 * __Network__: view and configure network components and management interfaces (ie SSH, REST, SOAP, & Web UI)
 * __Administration__: create application domains (provides configuration isolation), user accounts and much more.
   __Note__: Most of these capabilities are available in the __default__ domain (current domain). It is recommended that you create your gateway services in a new domain.
 * __Object__: configure and view objects utilized by your gateway services


# REST Management Interface

Now lets do a quick overview of the REST API, which helps developers achieve a faster workflow through its modern API design and descriptive error messages. This section explains how to use the REST management interface to manage and monitor the configuration. It also describes the functions, structure, and capabilities of the REST management interface. 

1. To get started lets enable the REST interface. We can do this quickly from the CLI using the following commands

```
top; confg
rest-mgmt
admin-state enabled
exit
```

2. We like to use http://httpie.org to interact with a REST API from the command line. To see whats possible issue the following command:

```
http --verify=no --auth admin:admin https://localhost:5554/mgmt/
```

which should produce the following JSON output
```
{
    "_links": {
        "actionqueue": {
            "href": "/mgmt/actionqueue/"
        },
        "config": {
            "href": "/mgmt/config/"
        },
        "domains": {
            "href": "/mgmt/domains/config/"
        },
        "filestore": {
            "href": "/mgmt/filestore/"
        },
        "metadata": {
            "href": "/mgmt/metadata/"
        },
        "self": {
            "href": "/mgmt/"
        },
        "status": {
            "href": "/mgmt/status/"
        },
        "types": {
            "href": "/mgmt/types/"
        }
    }
}
```

3. We can use the `config` namespace to query aspects of any configuration object. To complete the URL the application domain must be provided. The following command queries the configuration state of the REST Management Interface in the `default` application domain. To learn more about application domains click [here](http://www.ibm.com/support/knowledgecenter/SS9H2Y_7.5.0/com.ibm.dp.doc/domains.html)

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
