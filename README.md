## Crafting APIs with API Connect and OpenShift (***DRAFT***)


Prerequisites:
* Docker 1.12+
* OpenShift 1.5+
* IBM DataPower Gateway for Docker v7.6.0 (available from DockerHub and FixCentral)
* APIC OVA

### Overview

In this tutorial, you will develop and publish an API with API Connect and publish that API to a DataPower gateway running on OpenShift. This tutorial assumes prior knowledge with Docker and Kubernetes as well as APIC. If you do not have prior experience with Kubernetes concepts, I recommend reading the [Getting Started with DataPower in Kubernetes](https://developer.ibm.com/datapower/2017/02/27/getting-started-datapower-kubernetes/) tutorial first. Though this guide uses OpenShift to manage the DataPower API Gateway containers, the concepts demonstrated in this guide are meant to be general enough to be easily translated into any particular choice of container orchestrator or cloud environment.

By the end of the guide, you will perform the following:

1. **Deploy DataPower gateway on OpenShift**
2. **Deploy and configure the API Connect Management Server VM to use the DataPower Docker container**
3. **Create and publish an API using IBM API Connect**


### Setup

The overall flow is as follows:


### 0. OpenShift cluster setup

In this tutorial I am running an Ubuntu 16.04 VM with Docker 17.06.0. I've followed the  OpenShift Origin 1.5 [installation guide](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md) to setup a single node cluster and made sure that the cluster has enough memory and compute resources to deploy my containers.



### 1. Deploy DataPower gateway on OpenShift

For this step, I simply want to make sure that I have a way to persist state in the event that the DataPower container goes down and a new one takes its place, for example.
This ability is important since this is a way to avoid having to manually rejoin a gateway to the API Connect Cloud Manager any time a new DataPower gateway container is started.

In order to achieve this, I will use volumes to persist the following DataPower container directories:

`config:` -- This directory stores the gateway config; it includes config for any domain created by the API Connect Cloud Manager detailing the communication details between the two.

`local:` -- This directory can store crypto-material and other artifacts

`sharedcerts:` -- This directory holds the keys generated for accessing the `web-mgmt` as well as the keys and certs required to communicate with the API Connect Cloud Manager.

\##### EOF #######

There are a couple options available when deploying a DataPower container to achieve the ultimate goal of availability and reproducibility so that a DataPower Pod outage does not result in manual steps to re-deploy and re-join the gateway to the API management server or in major loss of state. I will be using `hostPath` volumes (TODO: and data containers) for simplicity and demonstration but you may and should use other types as appropriate for the deployment. The volumes will store the DataPower configuration in the `config:` directory to persist the connection information to the API management server as well as other artifacts and crypto-material in the `local:` and `sharedcerts:` directories.

#### A) Using hostPath volumes.

In this scenario I am using hostPath volumes for simplicity and illustration purposes; however, you will need to relax the OpenShift security context constraints (SCC) so that Pods are allowed to use the hostPath volume plug-in without granting everyone access to the privileged SCC. To do this, first switch to the administrative user, the default command is:

    $  oc login -u system:admin

Next, edit the **restricted** SCC:

    $ oc edit scc restricted

then change `alloHostDirVolumePlugin:` to `true` and save. Now you should be able to specify hostPath directories as volumes for your containers.

Note:
a) Directories created on the underlying host using the hostPath volume plugin can only be written to by root or by modifying the file permissions on the host to be able to write to a hostPath volume.
b) On some systems, there are also SELinux considerations to get various Volume Plug-ins to function properly such as attaching the right volume label to the directory [1]

Now that you've enabled hostPath volumes, you are ready to deploy the DataPower Pod. To do this, simply change directory to the GitHub project directory and edit the Deployment config file so that the volume paths reflect your local workspace. For example, my Deployment config file, reflecting my home directory of `/home/jpmatamo/` is as follows:

    $ cat kubernetes/deployments/datapower-deployment.yaml
    ...
    volumes:
    - name: config-volume
      hostPath:
        path: /home/jpmatamo/datapower-apic-openshift-demo/datapower/config
    - name: local-volume
      hostPath:
        path: /home/jpmatamo/datapower-apic-openshift-demo/datapower/local
    - name: usrcerts-volume
      hostPath:
        path: /home/jpmatamo/datapower-apic-openshift-demo/datapower/usrcerts
        $ oc create -f kubernetes/deployments/datapower-deployment.yaml

Once you have adapted the config file for your own environment, simply type:

    $ oc create -f kubernetes/deployments/datapower-deployment.yaml
    deployment "datapower" created

To make sure the deployment was created succesfully, you can issue:

    $ oc get deployment
    NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    datapower   1         1         1            1           46m


This will create the datapower deployment which initializes volumes and exposes necessary ports for test and development.
Note: non-root users cannot bind to low ports so make sure you are using ports higher than 1024 or grant capabilities to bind to lower ports.

Next, you will want to make sure to publish some of the ports publicly so that they can be accessed outside of the cluster. To do this, simply create the service as follows:

    $ oc create -f kubernetes/services/datapower-service.yaml
    service "datapower" created

To make sure the service is up, you can issue the following:

    $ oc get service
    NAME        CLUSTER-IP     EXTERNAL-IP   PORT(S)                                                                                                   AGE
    datapower   172.30.61.66   <nodes>       9090:30087/TCP,5550:32643/TCP,5554:31320/TCP,8443:32612/TCP,443:30416/TCP,8000:30360/TCP,8001:32142/TCP   6m


Notice how OpenShift will map the ports that were exposed by the Pod. For example, note how in the example above you will need to reach out to port 30087 on the OpenShift node in order to connect to the DataPower web-management port 9090. Make sure to use the mapped ports from now now when attempting to create connections from outside the cluster such as when adding the DataPower gateway container to the APIC Cloud Manager.
Also note how your firewall settings on your host may restrict certain inbound or outbound traffic so make sure you relax your firewall rules accordingly.

Now that both the `datapower` Deployment and Service are up, it is time to add the container to the cluster.

### 2. Deploy and configure API Connect to use the DataPower container

As always, head to the Services tab of the APIC Cloud Manager and add a DataPower Service. A modal window will ask you for the `Address` of the Datapower Service. For this guide this is the address of the single node OpenShift cluster (not the private IP assigned to the DataPower Pod!).
Next, it will ask you for a port to set as DataPower config. As before, note that the container is running as non-root so you cannot bind to low ports, use port `8443` since this is the port that has been exposed in the Deployment and Service files included in this tutorial for that purpose but you can edit those files and redeploy to use your own values.
Finally, select `External or no load balancer` and click `Save`.
Next, click on `Add Server` on the CMC and provide the public address of the DataPower service as made available by OpenShift, since I have a single node cluster and the Service ports are of type `NodePort` the address is the same as my OpenShift node address. Under the `Port` section, provide the public port that corresponds to the xml-mgmt interface, as seen in the previous section I chose to use port `5550` in DataPower which was mapped to port `32643` by OpenShift, I therefore enter port `32643` in the `Port` field.
Finally, provide the `Username` and `Password` and enter `0.0.0.0` for the `Network Interface` and click `Create`.











## References:

[1] https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/getting_started_with_kubernetes/get_started_provisioning_storage_in_kubernetes
