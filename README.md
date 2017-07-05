## API Development with API Connect and OpenShift (***DRAFT***)


Prerequisites:
* Docker 1.12+
* OpenShift 1.5+
* DataPower Docker Image
* APIC OVA

### Overview

In this tutorial, you will develop and publish an API with  API Connect and DataPower running on OpenShift.
You will then perform the following:


1. **Deploy DataPower gateway on OpenShift**
2. **Deploy and configure API Connect to use the DataPower container**
3. ** Create an API using IBM API Connect**


### Setup

The overall flow will look as follows:


### 1. Deploy DataPower gateway on OpenShift

In this tutorial I am running an Ubuntu 16.04 VM with Docker 1.12 and OpenShift 1.5 (running as a docker image). I've also made sure that this machine has enough memory and compute resources to deploy my containers.

There are a couple options available when deploying a DataPower container to achieve the ultimate goal of availability and reproducibility so that a DataPower Pod outage does not result in manual steps to re-deploy and add a new gateway to the API management server or in major loss of state. I will be using hostPath volumes (TODO: and data containers) for simplicity but you may use other kinds. The volumes will store the DataPower configuration in the `config:` directory to persist the connection information to the API management server as well as other artifacts and crypto-material in the `local:` and `sharedcerts:` directories. The goal is to mount

A) Using hostPath volumes.

In this scenario I am using hostPath volumes for simplicity; however, you will need to relax the OpenShift security context constraints (SCC) so that Pods are allowed to use the hostPath volume plug-in without granting everyone access to the privileged SCC. To do this, first switch to the administrative user, the default command is:

    $  oc login -u system:admin

Next, edit the **restricted** SCC:

    $ oc edit scc restricted

then change `alloHostDirVolumePlugin:` to `true` and save. Now you should be able to specify hostPath directories as volumes for your containers.
