## Crafting APIs with API Connect and OpenShift

Prerequisites:
* Docker 1.12+
* OpenShift 1.5+
* IBM DataPower Gateway for Docker v7.6.0 (available from DockerHub and FixCentral)
* IBM API Connect OVA

### Overview

In this tutorial, you will develop and publish an API with API Connect and publish that API to a DataPower gateway running on OpenShift. This tutorial assumes prior experience with Docker and Kubernetes. If you do not have prior experience with Docker or Kubernetes concepts, I recommend reading the [Getting Started with DataPower in Kubernetes](https://developer.ibm.com/datapower/2017/02/27/getting-started-datapower-kubernetes/) tutorial first. Though this guide uses OpenShift to manage the DataPower API Gateway containers, the concepts demonstrated in this guide are meant to be general enough to be easily integrated into any particular choice of container orchestrator or cloud environment.

By the end of the guide, you will perform the following:

1. **Deploy DataPower gateway on OpenShift**
2. **Deploy and configure the API Connect Management Server VM to use the DataPower Docker container**
3. **Create and publish an API using IBM API Connect**


### Setup

The overall flow is as follows:


### 0. OpenShift cluster setup

In this tutorial I am running an Ubuntu 16.04 VM with Docker 17.06.0. I've followed the  OpenShift Origin 1.5 [installation guide](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md) to setup a single node cluster and made sure that the cluster has enough memory and compute resources to deploy my containers.



### 1. Deploy DataPower gateway on OpenShift
\###TODO: Explain how/which DP objects to enable since cannot add config to EmptyDir

For this step, I simply want to make sure that I have a way to persist state in the event that the DataPower container goes down and a new one takes its place, for example.
This ability is important since this is a way to avoid having to manually rejoin a gateway to the API Connect Cloud Manager any time a new DataPower gateway container is started.

In order to achieve this, I will use volumes to persist the following DataPower container directories:

`config:` -- This directory stores the gateway config; it includes config for any domain created by the API Connect Cloud Manager detailing the communication details between the two.

`local:` -- This directory can store crypto-material and other artifacts

`sharedcerts:` -- This directory holds the keys generated for accessing the `web-mgmt` as well as the keys and certs required to communicate with the API Connect Cloud Manager.

The volumes in this tutorial are defined in the kubernetes Deployment file located at `kubernetes/deployments/datapower-deployment.yaml` as `EmptyDir` volumes for simplicity, you may use any Volume type that suits your needs and environment.

To create the Deployment, simply type the following wherever you run `oc` cluster commands:

    $ oc create -f kubernetes/deployments/datapower-deployment.yaml
    deployment "datapower" created

To make sure the deployment was created succesfully, you can issue:

    $ oc get deployment
    NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    datapower   1         1         1            1           46m

Next, publish the ports exposed by the datapower deployment you just created so that they can be access outside the cluster. To do this, simply issue the following:

    $ oc create -f kubernetes/services/datapower-service.yaml
    service "datapower" created

To make sure the service is up, you can issue the following:

    $ oc get service
    NAME        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                                                                   AGE
    datapower   172.30.86.213   <nodes>       9090:31799/TCP,5550:30091/TCP,5554:30065/TCP,8443:30851/TCP,443:31810/TCP,8000:32128/TCP,8001:30912/TCP   24m    

Notice how OpenShift will map the ports that were exposed by the Pod. For example, note how in the example above you will need to reach out to port `31799` on the OpenShift node in order to connect to the DataPower web-management port 9090 (once it's been enabled).
Also note how your firewall settings on your host may restrict certain inbound or outbound traffic so make sure you relax your firewall rules accordingly.

Now that both the `datapower` Deployment and Service are up, it is time to add the container to the API Connect Cloud Manager (CMC).

### 2. Configure API Connect Cloud Manager to use the DataPower container
\###TODO: ADD screenshots
First, deploy the API Connect OVA in the usual way. In a browser, head to `https://<ip-of-APIC-vm>/cmc` and log in, if it is your first time you can use the `admin:admin` credentials.

To add the DataPower Service, head to the `Services` tab of the APIC Cloud Manager and select `Add DataPower Service` after clicking the `Add` button. A modal window will ask you for the `Address` of the Datapower Service. For this guide this is the address of the Kubernetes Service for DataPower (In my case, it is the IP of the node running Docker).

Next, it will ask you for a port to set as DataPower config. As before, note that the container is running as non-root so you cannot bind to low ports by default, use port `8443` since this is the port that has been exposed in the Deployment and Service files included in this tutorial for that purpose. Naturally, you can edit those files and redeploy to use your own values.
Finally, select `External or no load balancer` and click `Save`.

Now that the Service has been added, it is time to add a server.
First, click on `Add Server` on the CMC under the DataPower Service you just created. A new modal window with a form will appear. Provide the public address of the DataPower service as made available by OpenShift; since I have a single node cluster and the Service ports are of type `NodePort`, the address is the same as my OpenShift node address. Under the `Port` section, provide the public port that corresponds to the xml-mgmt interface, as seen in the previous section I chose to use port `5550` in DataPower which was mapped to port `30091` by OpenShift, I therefore enter port `30091` in the `Port` field.
Finally, provide the `Username` and `Password` and enter `0.0.0.0` for the `Network Interface` and click `Create`.

The use of INADDR_ANY (0.0.0.0) in the `Network Interface` field is a workaround when joining a gateway behind a NAT device (such as in cloud environments / container orchestrators) since the IP address of the interface may not be the same every time the container comes up.

You will also need to make sure there exists an `Organization` to manage developers of an API. To do this, simply head to the `Organizations` tab of the CMC and add an Organization with users if one does not exist.

### 3. Create and publish an API using IBM API Connect

Now you are ready to create and publish APIs. In a browser, head to `https://<ip-of-APIC-vm>/apim` and log in.

Once logged in, head to the `Products` tab and add a product. I will name mine `demo-product`.

Next, head click on the hamburger button on the top left and click on `Drafts` and then click on the `APIs` tab. Create a `New API`; I named mine `demo-api`.

Click on `Paths` which is located on the menu on the left, then click on the `+` sign which will create a GET operation by default.

Optionally, you can head to the `Security` section also located on the menu on the left and delete the default security requirement for demonstration purposes.

Now, click on `Assemble` at the top and select the green `invoke` object. A menu should appear to the right. In the URL section, replace `$(target-url)$(request.path)` with, for example, `http://httpbin.org/get` and click the `Save` icon located in the top right corner.

To publish the API, click on the `play` icon located above the `invoke` object, this will open a menu to the left of the screen. Select the product you created from the dropdown, click the `Add API` button, and click `Next`.

If you deleted the Security requirement in a previous step, you can try out your api in the browser by heading to:

`https://<dp-docker-ip>:<mapped-8443-port>/demo-org/sb/demo-api/path-1`

And you should get a response similar to:

    {"args":{},"headers":{"Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8","Accept-Language":"en-US,en;q=0.5","Cache-Control":"max-stale=0","Connection":"close","Host":"httpbin.org","If-Modified-Since":"Thu, 27 Jul 2017 14:23:41 GMT","Upgrade-Insecure-Requests":"1","User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:52.0) Gecko/20100101 Firefox/52.0","X-Bluecoat-Via":"9c4a8c2845b5df31","X-Client-Ip":"172.17.0.1","X-Global-Transaction-Id":"2278096d5979f7ae00012191"},"origin":"9.42.102.24, 129.42.208.179","url":"http://httpbin.org/get"}

Congratulations! You've just developed and deployed and API with IBM API Connect using a cloud gateway.

### Bonus Round: Resiliency test

Developing and deploying and API is good and all but it doesn't showcase the reason why you've gone to the trouble of deploying the gateway as a container managed by a container orchestrator such as OpenShift.

In this section, you will forcefully remove the gateway container and find that OpenShift will schedule a new container on the Pod, mount the configuration and API definitions of our previous container into the new one, and make the API available with very little down-time and with no manual steps necessary.

 On your docker host, find the datapower image with:

    $ docker ps
    CONTAINER ID        IMAGE                         COMMAND                  CREATED             STATUS              PORTS               NAMES
    2ecc5c77e8ce        ibmcom/datapower:7.6.0        "/bin/drouter"           8 minutes ago       Up 8 minutes                            k8s_datapower.c6cc4092_datapower-3531478514-gq11q_myproject_b9d9e655-7227-11e7-9c5e-000c29a97e41_4db1189a
    efe1253921d5        openshift/origin-pod:v1.5.1   "/pod"                   22 hours ago        Up 22 hours                             k8s_POD.38dfe2cf_datapower-3531478514-gq11q_myproject_b9d9e655-7227-11e7-9c5e-000c29a97e41_4074effa
    db6a7f6c051b        openshift/origin:v1.5.1       "/usr/bin/openshif..."   47 hours ago        Up 47 hours                             origin

Next, kill the datapower container with:

    $ docker rm -f <container-id>

Note how OpenShift will immediately schedule a new container on the Pod, to inspect this, type:

    $ oc describe pods

    Events:
      FirstSeen	LastSeen	Count	From			SubObjectPath			Type		Reason	Message
      ---------	--------	-----	----			-------------			--------	------	-------
      11m		11m		1	{kubelet 9.42.102.24}	spec.containers{datapower}	Normal		Created	Created container with docker id 2ecc5c77e8ce; Security:[seccomp=unconfined]
      11m		11m		1	{kubelet 9.42.102.24}	spec.containers{datapower}	Normal		Started	Started container with docker id 2ecc5c77e8ce
      21h		39s		3	{kubelet 9.42.102.24}	spec.containers{datapower}	Normal		Pulled	Container image "ibmcom/datapower:7.6.0" already present on machine
      39s		39s		1	{kubelet 9.42.102.24}	spec.containers{datapower}	Normal		Created	Created container with docker id 179f8fadad9c; Security:[seccomp=unconfined]
      39s		39s		1	{kubelet 9.42.102.24}	spec.containers{datapower}	Normal		Started	Started container with docker id 179f8fadad9c


After a moment, your gateway should be fully initialized and ready to handle traffic again. To demonstrate this, invoke the API you created in previous steps as before:

    $ curl -k https://9.42.102.24:30851/demo-org/sb/demo-api/path-1
    {"args":{},"headers":{"Accept":"*/*","Cache-Control":"max-stale=0","Connection":"close","Host":"httpbin.org","If-Modified-Since":"Thu, 27 Jul 2017 15:16:16 GMT","User-Agent":"curl/7.35.0","X-Bluecoat-Via":"089572fb005cd253","X-Client-Ip":"172.17.0.1","X-Global-Transaction-Id":"2278096d597a03e200000c91"},"origin":"9.42.102.24, 129.42.208.182","url":


You have now seen how IBM API Connect can integrate with a DataPower Gateway deployed on a container orchestrator such as OpenShift. Additionally, you have experienced some of the benefits of such as setup which include enhanced reproducibility and resiliency.
