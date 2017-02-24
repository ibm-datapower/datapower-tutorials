## Getting Started with DataPower and Kubernetes
This tutorial provides a walkthrough on the basics of getting up and running with DataPower in Kubernetes. Kubernetes is a popular orchestrator for Docker containers.


## Tools
This tutorial uses the Google Container Engine to provide a hosted Kubernetes environment. Naturally,
you can use any Kubernetes environment of your choosing. As such, I will mark the sections pertaining to
the Google Container Engine (GKE) with an "(Optional)" designation.
Below is a list of the tools you will be using in this tutorial:

* Docker
    * We use Docker to package, distribute and run applications
    * https://www.docker.com


* IBM DataPower Gateway for Docker
    * Available as a Docker image in DockerHub
    * https://hub.docker.com/r/ibmcom/datapower/
    * https://developer.ibm.com/datapower/


* Kubernetes
    * Handle the heavy lifting of orchestrating our application
    * http://kubernetes.io


* Google Container Engine (GKE) (Optional)
    * A hosted Kubernetes service from the Google Cloud Platform
    * https://cloud.google.com/container-engine


* Google Cloud Shell (Optional)
    * A shell environment for managing Google Cloud Platform resources
    * https://cloud.google.com/shell/docs/

## Setting up Kubernetes in GKE
This section is optional if you already have Kubernetes. Otherwise, you can follow
along with this section to set up Kubernetes.  

First you will need a Google Cloud Platform (GCP) account. You can use an existing account or sign up for a free trial
[here](https://console.cloud.google.com/freetrial "Create a Google Cloud Platform account").

Next you will need a GCP project. You may use the default project, an existing project, or create a new one as described
 [here](https://support.google.com/cloud/answer/6251787 "Create a GCP project").


You will also need to enable some Google Cloud APIs from the
 [Google API Console](https://console.developers.google.com/):
* __Compute Engine API__ - To allow external network access to the application
* __Container Engine API__ - To provide Kubernetes

Here is a screenshot of where you can enable those APIs.

![Google API Console](media/gcp_api_manager.png)

In addition, you will use the Google Cloud Shell to manage your
Google Cloud Platform resources. You can find a getting started for the Google Cloud Shell
[here](https://cloud.google.com/shell/docs/quickstart "Google Cloud Shell Getting Started").
Once ready, head over to your project page in the Google Cloud Platform web console and start a Google Cloud Shell session.

![Activate Google Cloud shell](media/gcp_activate_gcs.png)

To avoid having to specify the --zone flag when required, set the "compute zone"  with:

```
$ gcloud compute zones list
NAME               REGION           STATUS  NEXT_MAINTENANCE  TURNDOWN_DATE
...
us-east1-b         us-east1         UP
...

$ gcloud config set compute/zone us-east1-b
```

Now you are ready to create the Kubernetes cluster. A cluster is a group of nodes
that run Kubernetes.
To provision a cluster with 3 nodes, run the following command:

```
$ gcloud container clusters create k8s-cluster

kubeconfig entry generated for k8s-cluster.
NAME          ZONE        MASTER_VERSION  MASTER_IP       MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
k8s-cluster  us-east1-b  1.4.7           104.196.69.190  n1-standard-1  1.4.7         3          RUNNING
```

This might take a couple of minutes.

With your cluster up and running, you are now ready to run containers.


## Get the Source Code
Now that you have Kubernetes running it's time to get the source code for this tutorial. If you are running in GKE you can `git clone` in the Google Cloud Shell. Otherwise clone the repository wherever you run `kubectl` (the command line interface to interact with kubernetes clusters).
```
$ git clone https://github.com/ibm-datapower/datapower-tutorials.git
$ cd datapower-tutorials/using-datapower-in-kubernetes/
```



##  Introduction to Kubernetes

One of the reasons that Kubernetes is widely used is because Kubernetes provides a useful set of abstractions that let you think of your applications as services instead of getting bogged down by the details of the underlying infrastructure. As a result, you will be more concerned with the state of the system and will make use of Pods, ReplicaSets, and Services which are the fundamental units that compose an application in Kubernetes.
I will go through each of those briefly in this section before we move on to the world-view of deploying a composed application in Kubernetes.

### Pods
In Kubernetes, all containers run in what's called a pod. A pod represents a logical application composed of co-located and co-scheduled containers, that share certain resources. Pods are the units of deployment, replication, and scheduling. Pods, not containers, are the smallest deployable artifact in Kubernetes.

To run a pod directly, we can issue a `kubectl run` command and specify an image. A better approach is to expressly declare the pod you want to deploy by writing a [pod configuration file](https://kubernetes.io/docs/user-guide/pods/multi-container/#pod-configuration-file) in YAML (or JSON) such as the one below:



```
$ cat kubernetes/pods/datapower-pod.yaml
apiVersion: v1
kind: Pod
metadata:
    name: datapower
    labels:
        app: datapower
spec:
    containers:
        - name: datapower
          image: ibmcom/datapower:latest
          stdin: true
          tty: true
          env:
          - name: DATAPOWER_ACCEPT_LICENSE
            value: "true"
          - name: DATAPOWER_INTERACTIVE
            value: "true"
```

To create the pod, we simply run:

```
$ kubectl create -f kubernetes/pods/datapower-pod.yaml
pod "datapower" created
```

We can check the status of the pod by running:

```
$ kubectl get pods
NAME        READY     STATUS    RESTARTS   AGE
datapower   1/1       Running   0          4m
```

Additionally, we can get more detailed information about the pod by running:
```
$ kubectl describe pods
```

Once the pod is running, we can attach to the container and log in using the familiar "admin/admin" default credentials by running:

```
$ kubectl attach datapower --stdin --tty
If you don't see a command prompt, try pressing enter.
login: admin
Password: *****
```

To delete the pod, you can open a new Cloud Shell session and run:

```
$ kubectl delete pods datapower
pod "datapower" deleted
```

### ReplicaSets

A ReplicaSet ensures that a given number of pods are running, spawning pods when there are fewer than specified or removing some if there are more than specified.
ReplicaSets can also be defined in config files similar to the pod configuration file above. The following is a sample ReplicaSet configuration file:
```
$ cat kubernetes/replicasets/datapower-replicaset.yaml
apiVersion: extensions/v1beta1
kind: ReplicaSet
metadata:
    name: datapower
spec:
    replicas: 3
    selector:
        matchLabels:
            app: datapower
    template:
        metadata:
            labels:
                app: datapower
        spec:
            containers:
            - name: datapower
              image: ibmcom/datapower
              tty: true
              stdin: true
              env:
              - name: DATAPOWER_ACCEPT_LICENSE
                value: "true"
              - name: DATAPOWER_INTERACTIVE
                value: "true"
```
Note the `replicas: 3` declaration, here we are declaring that we want three instances of the pod defined later in the `template` section.

To create the ReplicaSet above we run:
```
$ kubectl create -f kubernetes/replicasets/datapower-replicaset.yaml
replicaset "datapower" created
```

We can quickly check the status of the Pods by running:
```
$ kubectl get replicasets -o wide
NAME        DESIRED   CURRENT   READY     AGE       CONTAINER(S)   IMAGE(S)           SELECTOR
datapower   3         3         3         56s       datapower      ibmcom/datapower   app=datapower
```

To demonstrate the role of ReplicaSets, let's manually delete one of the replicas that was created.

```
$ kubectl get pods
NAME              READY     STATUS    RESTARTS   AGE
datapower-2fh7r   1/1       Running   0          4m
datapower-nmwzx   1/1       Running   0          4m
datapower-x5vx7   1/1       Running   1          4m

$ kubectl delete pods datapower-2fh7r
pod "datapower-2fh7r" deleted

$ kubectl get pods
NAME              READY     STATUS              RESTARTS   AGE
datapower-2fh7r   1/1       Terminating         0          4m
datapower-mb42t   0/1       ContainerCreating   0          5s
datapower-nmwzx   1/1       Running             0          4m
datapower-x5vx7   1/1       Running             1          4m
```

Notice how immediately after a pod was deleted, the ReplicaSet created a new pod `datapower-mb42t`.

Once you are done with the ReplicaSet, you can run:
```
$ kubectl delete replicasets datapower
replicaset "datapower" deleted
```

Now that you've had a taste for ReplicaSets and Pods and seen how useful they are, I'd just like to add
that for the most part, you won't be interacting directly with Pod and ReplicaSet objects in Kubernetes
since there is a higher-order object called a `Deployment` that helps to manage Pods, replicas, updates
and more in a declarative way. I will introduce Deployments in a later section.

### Services

The main idea behind Services is that we recognize that Pods are ephemeral and ReplicaSets
start and delete Pods dynamically so we cannot rely on a particular IP address assigned to a Pod.
If we have a set of Pods that provide a function, we need a way to reach that set of Pods that
does not involve keeping track of each individual address. The `Service` abstraction allows for
this type of decoupling.

In order to use the service you first need to deploy the application that provides the service.
To deploy the sample backend Pod, you can run:

```
$ kubectl create -f kubernetes/pods/backend-pod.yaml
```

The `backend` Pod consists of a single container that responds with "Hello world from [hostname]"
when reached on port `8080`, the Pod also has a label "app=backend" that the Service will
use as a selector. The Service object looks as follows:

```
$ cat kubernetes/services/backend-service.yaml
apiVersion: v1
kind: Service
metadata:
    name: "backend"
spec:
    selector:
        app: "backend"
    type: LoadBalancer
    ports:
        - port: 8080
          protocol: TCP
          targetPort: 8080
```

To create the Service object, we run the familiar command:

```
$ kubectl create -f kubernets/services/backend-service.yaml
service "backend" created
```

You will have to wait for a while for the Service object to provide an external endpoint
for the service. You can check the status of the Service by running:

```
$ kubectl get service
NAME         CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
backend      10.23.248.249   35.185.37.88   8080:32621/TCP   2h
kubernetes   10.23.240.1     <none>         443/TCP          2d
```

Once the service is up and running, Kubernetes will make the Service name available
to the cluster. You can test the Service by launching a test Pod and sending a request
to the Service like so:


```
$ kubectl create -f kubernetes/pods/busybox-test-pod.yaml
pod "busybox" created

$ kubectl exec --tty --stdin busybox -- wget -O -  backend:8080
Connecting to backend:8080 (10.23.248.249:8080)
Hello world from backend
-                    100% |*******************************|    25   0:00:00 ETA
```
Note that the request is sent to the Service name and not a specific IP address but we
still receive the expected `Hello world from backend` response.

Once you are done with the example above, you can delete by running:

```
$ kubectl delete service backend
service "backend" deleted
$ kubectl delete pods busybox backend
pod "busybox" deleted
pod "backend" deleted
```

## Deploying Microservices

Now  we can begin to deploy a simple composed application.
For this tutorial, we will use a similar application to the one in the [Docker Compose Hello World sample](https://developer.ibm.com/datapower/2016/11/11/a-datapower-with-docker-compose-hello-world-application/).
The applications consists of an nginx 'backend' that just responds with a simple `Hello from <hostname>` message and a DataPower service
on the front that proxies the request and transforms the response from the backend, using Gatewayscript, by prepending
"DataPower proxied: " to the response from the nginx service.
In order to achieve this in Kubernetes, we will:
* Provide the DataPower application configuration as a Kubernetes *ConfigMap*
* Deploy our application in Kubernetes
* Expose the Kubernetes *Service* so that our *datapower*  can communicate to our *backend* without knowing all the details of the backend application


### Configuring our Application Using ConfigMaps

One best practice is to separate your application code from your configuration. To this end,
Kubernetes provides a `ConfigMap` resource as of version 1.2.
A ConfigMap is a flexible object for providing your application with non-secret configuration data. The data
is presented as key-value pairs and can represent cli arguments, environment variables, and files in a mounted volume.

Let's create a ConfigMap from our `datapower/config` and `datapower/local` directories which look as follows:

```
$ tree datapower
datapower
├── config
│   ├── auto-startup.cfg
│   ├── auto-user.cfg
│   └── foo
│       └── foo.cfg
└── local
    └── foo
        └── hello.js

4 directories, 4 files
```

These will set up our DataPower domain with application logic and services; it will also place applicaiton data, such as our gatewayscript file, in the right directory.

To create the ConfigMaps, simply `cd` to the `datapower` directory and type:

`$ kubectl create configmap datapower-config --from-file=config/ --from-file=config/foo`

`$ kubectl create configmap datapower-local-foo --from-file=local/foo`

And to get more details about the ConfigMaps we just created, we can type:

`$ kubectl describe configmap `

We are now ready to consume the `datapower-config` and `datapower-local-foo` ConfigMaps in a Kubernetes deployment.


### Kubernetes Deployments

For pretty much any non-trivial application deployment, we want to have a more reproducible way to define,
compose and deploy our application.
 Therefore, a best practice is to define
our application using *Deployments*. A *Deployment* is a higher-order object in Kubernetes that manages Pods and ReplicaSets. Below is the sample *deployment* YAML for the *datapower* application
 we use for this tutorial:

```
$ cat kubernetes/deployments/datapower-deployment.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: datapower
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: datapower
        track: stable
    spec:
      containers:
      - name: datapower
        image: "ibmcom/datapower:latest"
        stdin: true
        tty: true
        ports:
        - name: web-mgmt
          containerPort: 9090
        env:
        - name: DATAPOWER_ACCEPT_LICENSE
          value: "true"
        - name: DATAPOWER_INTERACTIVE
          value: "true"
        volumeMounts:
        - mountPath: /drouter/config/foo/foo.cfg
          name: config-volume
          subPath: foo.cfg
        - mountPath: /drouter/config/auto-startup.cfg
          name: config-volume
          subPath: auto-startup.cfg
        - mountPath: /drouter/config/auto-user.cfg
          name: config-volume
          subPath: auto-user.cfg
        - mountPath: /drouter/local/foo
          name: local-foo-volume
      volumes:
      - name: config-volume
        configMap:
          name: datapower-config
      - name: local-foo-volume
        configMap:
          name: datapower-local-foo
```

Note that we use the `datapower-config` and `datapower-local-foo` ConfigMaps as a `volumes` parameter and mount it in the `volumeMounts` section.
The `mountPath: /drouter/config` is special in this case because DataPower will automatically execute a config file named
*auto-startup.cfg* if found in the */drouter/config* directory, which we have placed in this configMap.

There is likewise a *deployment* config file for our *backend* application which can be found under `kubernetes/deployments/backend-deployment.yaml`

To create the deployments we head over to the `kubernetes/deployments` directory and issue the following commands:

`$ kubectl create -f datapower-deployment.yaml`

`$ kubectl create -f backend-deployment.yaml`

### Exposing Our Application to the Internet

Before we continue, let's stop and reflect for a minute on what we have accomplished so far. At this time, we have deployed an applicaiton
 that can recover from a failure in one of our nodes in our Kubernetes cluster. We can deploy this applicaiton in a highly reproducible way.
 Additionally, the application's configuration is managed independently of the application and can be changed easily without having to rebuild our applicaiton.

Now, we want to expose the application service so that we can access it from the public internet.
We can expose the datapower multi-protocol gateway service running on port 80 that was configured using our  `datapower-config` ConfigMap by
heading over to the `kubernetes/services` directory and running:

`$ kubectl create -f datapower-service.yaml`

Likewise, create the backend service by running:
```
$ kubectl create -f backend-service.yaml

```

This will create a Kubernetes *Service* that we can use to get the external IP and port we just exposed. To view it, run:

`$ kubectl get service datapower`

```
$ kubectl get service datapower
NAME        CLUSTER-IP    EXTERNAL-IP       PORT(S)           AGE
datapower   10.7.246.47   104.196.131.123   80/TCP            12h ```

Which might take a minute or two to populate the external IP.
If you are following along with GKE as in this tutorial,  you will also need make sure that traffic from
external IPs is allowed by opening a firewall traffic rule on port 80 as follows:

```
$ gcloud compute firewall-rules create datapower-mpgw --allow=tcp:80
```

We should now be able to send a request to our service from the public internet.

```
$ curl -k 104.196.131.123:80
DataPower Proxied: Hello world from backend-113429680-tmq5q
```

Success!

## Cleaning it Up

In order to prevent incurring charges in Google Cloud Platform when not using our cluster we will
want to delete the Kubernetes cluster we created earlier. In a Google Cloud Shell session, type:

```
$ gcloud container clusters delete k8s-cluster
```

## Conclusion

We hope this introduction to running DataPower in Kubernetes was helpful in building a foundation
that you can use when proceeding to build more complex applications that follow industry best-practices.

From here, we are ready to explore more advanced topics. Some example next steps include:
* Services provisioning and discovery
* Scaling microservices in your application
* Managing secrets in Kubernetes
* Update rollouts
* Application health checks and monitoring

Thank you and please let us know what you think by commenting or submitting your own pull request
in our [GitHub repo](https://github.com/ibm-datapower/datapower-tutorials)
