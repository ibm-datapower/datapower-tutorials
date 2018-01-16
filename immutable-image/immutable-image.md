## DataPower Immutable Image Concepts and Creation

With the advent of container orchestration, immutable infrastructure is more attainable than ever before. An immutable image is an image where by all file system objects are read-only or immutable, preventing changes to app binaries or configuration data at runtime.

## Why is this important, three main reasons

1) Security. Security is an end to end approach with many levels of defenses, defense in depth. Immutable images provide a defense against attackers modifying the persisted state of a running application or allowing them to make their malicious changes permanent.

2) Configuration drift. Leaving a system open to configuration changes overtime will result in configuration inconsistencies across the cluster or differences from the original well tested configuration state. Live production debugging sessions are one of the main sources of drift.

3) Forces a engineering team to develop a well thought out plan for rolling out updates vs ad-hoc changes to a production environment. Rollout scheme at a minimum should support canary deployments, whereby a configuration change is tested against a small subset of the total user population.

These three benefits describe the foundation of a modern deployment system. They are the precursers to a pipeline. They are prerequisites to continuous integration and continuous delivery. 

Immutable images are like guardrails on deployment process -- they prevent you from falling off the edge by making it more difficult to make changes outside the official process. If someone tries to make a change outside the process -- ether by mistake or with malice -- they are less likely to succeed if the image is immutable. 

Using an immutable image allows you more certainty to know that what you have deployed what you have intended to deploy. This is a valuble and useful property of any deployment wheather or not you are using CI/CD. If you are thinking about CI/CD with DataPower, using immutable images can help adoption. If you are already using CI/CD with DataPower, using immutable images provides a greater level of assurance that changes can only be made inside your pipeline.

## Prerequisites

Before you attempt this tutorial, please be sure that you:

- Have Docker installed and running
- Have run DataPower as described on the [DataPower Docker Hub page](https://hub.docker.com/r/ibmcom/datapower/)
- Good understanding of Unix filesystem permissions

## Lets first take a look at an example DataPower configuration

This [project](https://github.com/ibm-datapower/datapower-tutorials/immutable-image) is a simple loopback (no backend required) HTTP service that responds back with details of the request in JSON format. The details of what the configuration does is not important here but that it is easy to test and verify before and after we make the image configuration immutable.

```
git clone https://github.com/ibm-datapower/datapower-tutorials/immutable-image

cd immutable-image

docker build . -t datapower

docker run --name datapower --rm -p 8080:8080 -d datapower
```

DataPower is now running in the background. Use `docker ps` to view the state of the running container:
```
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                    NAMES
31e13aad5539        datapower           "/bin/drouter"      7 seconds ago       Up 16 seconds       0.0.0.0:8080->8080/tcp   datapower
```

Next test the configuration by issuing the following curl command:
```
curl http://localhost:8080/stillmutable
```

If everything went successfully so far you should see the following response:
```
{"method":"GET","uri":"/stillmutable"}
```

## Understanding the current Dockerfile contents

Lets start by explaining some of key aspects of the example Dockerfile:

```
 1: FROM ibmcom/datapower:latest
 2: ENV  DATAPOWER_ACCEPT_LICENSE=true \
 3:      DATAPOWER_INTERACTIVE=true \
 4:      DATAPOWER_FAST_STARTUP=true
 5:
 6: COPY src/config /drouter/config
 7: COPY src/local /drouter/local
 8:
 9: USER root
10: RUN  set-user drouter
11: USER drouter
12:
13: EXPOSE 8080
```

Lines 1-3 can are explained [here](https://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.6.0/com.ibm.dp.doc/virtual_fordocker.html)

Line 4 enables the fast startup option. This dramatically speeds up initial process load times and reduces the amount of memory needed to start the container. The catch is slower initial access to the WebUI, SOAP management and REST management services.

Lines 6 & 7 copy our source into the image. `/drouter/config` contains the configuration files and `/drouter/local` contains other non-configuration files such as scripts and other ancillary files that are referenced by config. In our case it contains the echo.js GatewayScript implementation.

By default, docker COPY will recursively copy files and directories with ownership under `root`. In this case root ownership is desired because all non-root users are automatically part of the `root` user group. With this knowledge we now know we will need to focus on `group` and `other` permissions to make our images immutable. COPY also typically preserves the file permissions found on the host or build system, therefore its always a best practice to explicitly set file and directory permissions after a COPY or ADD instructions.

Line 9 is required because all DataPower images run as non-root and the RUN instruction inherits its user from the parent Dockerfile. So we are effectively switching back to the root user temporarily to make changes to the image.

Line 10 runs a utility script to fixup permissions when switching from root to non-root.

Line 11 using the USER instruction to set the user name back to its default non-root value of drouter. The USER instruction sets the user name (or UID) to use when running the image and for any RUN, CMD and ENTRYPOINT instructions that follow.

Line 13 informs Docker that the container listens on TCP port 8080 at runtime. This is the port we configured the HTTP Frontside Protocol Handler to use.

## Time to make the configuration immutable

Open the Dockerfile using a text editor and add the following lines after `RUN set-user drouter`. The first line recursively finds all directories in local and config (including local and config) and sets the permissions to `drwxr-xr-x`. The second line is similar but for normal files and sets the permissions to `-rw-r--r--`. Since process 0 runs as non-root (drouter), it cannot create new files or directories in these locations or move files in or out, or modify any existing files.

```
RUN find /drouter/local /drouter/config -type d | xargs chmod 755
RUN find /drouter/local /drouter/config -type f | xargs chmod 644
```

Combining the two lines into a single RUN command as per Dockerfile best practices, the completed Dockerfile should look like this:

```
FROM ibmcom/datapower:latest
ENV  DATAPOWER_ACCEPT_LICENSE=true \
     DATAPOWER_INTERACTIVE=true \
     DATAPOWER_FAST_STARTUP=true

COPY src/config /drouter/config
COPY src/local /drouter/local

USER root
RUN set-user drouter \
 && find /drouter/local /drouter/config -type d | xargs chmod 755 \
 && find /drouter/local /drouter/config -type f | xargs chmod 644
USER drouter

EXPOSE 8080
```

Build and confirm the image is still working as intended:

```
docker kill datapower

docker build . -t datapower

docker run --name datapower --rm -p 8080:8080 -d datapower

curl http://localhost:8080/immutable
```

## Conclusion

Adding the two lines to the Dockerfile recursively altered and reduced the permissions scope making it impossible for the gateway runtime to make any future modifications to the configuration, hence immutable. Using a read-only data volume containing the necessary `config` and `local` mount points would be another great way to achieve a similar result.
