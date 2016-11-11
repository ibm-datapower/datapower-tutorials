## A DataPower with Docker Compose Hello World Application

If you find yourself scratching your head when asked the question "How do I build portable composed applications with DataPower?", you've come to the right place. This tutorial will show you how to build an application consisting of a load driver, a DataPower Gateway, and a back-end server where each of the parts are separate containers held together with Docker Compose.

This application is most similar to what one might find in an automated test kicked off by a CI/CD tool, but it's real purpose is to open a discussion on the ways DataPower andapplications can be composed.

## Prerequisites

Before you attempt this tutorial, please be sure that you:

- Have Docker installed and running
- Have run DataPower as described on the [DataPower Docker Hub page](https://hub.docker.com/r/ibmcom/datapower/)
- Have [installed Docker Compose](https://docs.docker.com/compose/install/)

## Meet the Band

There are four parts to this example, one for each of the three images that makes up the application and one for Docker Compose to hold it all together. It's like a band -- they each have different parts that work together to create a whole that is more pleasing than any of the parts alone.

My apologies in advance for this extended analogy, I sometimes just can't help myself. Let's think of what each of the containers that make up the application would be if they were in a band.

Don't worry, this is just the introduction. Later on we'll dive deeper into how each are built to play together nicely. 

### Backup Singer(s) -- `nodejs-hostname` / `backend`

As the backup singers, we have `nodejs-hostname`. While they vary in number, their HTTP containerised NodeJS rendition of "Hello World" adds a touch of harmony -- they're all singing the same tune but you can still pick out each voice! 

When asked a question on port `8080`, it answers with `Hello World from <hostname>`. To keep things interesting, the back end also logs `Answered request with <hostname>` to stdout for every request.

### Front Man -- `datapower`

This DataPower application has been in a number of bands, you can check them out over in [DataPower Labs](https://github.com/ibm-datapower/datapower-labs). This same application was recently in `ibmcom-datapower-example` and `customer-build`, he's given up his `Makefile` ways and is going Compose for this collaboration.

Mr. Power is keeping it pretty mellow in this band, adding the pleasing ping of `HTTPS` to the endeavor and a little bit of Gateway Script to modify the response. Every HTTP request that comes in on port 443 DataPower sends to one of the backends on port 8080. When the response comes back, DataPower prepends `DataPower Proxied:` to the content of the backend's response.

### Recording Engineer -- `curldriver`

He doesn't tour with the band, but he makes sure the band sounds great in the studio. It's through his ears that we know how the band sounds. Every new take is run past him, and he dutifully gives immediate feedback about how the band sounds.

If there's a wrong note, Earl or Carl (we never know what to call him) lets us know so the band can lock in their sound for their tour.

A container like `curldriver` would drive tests in the pre-deployment phases of a container-based CI/CD system.

### Manager -- `docker-compose`

As the booker of gigs and the reserver of studios for both practice and recording, no one sees the band without Docker Compose. Since the group could be a duet or an octet, it's Compose that gets the right number of backup singers. Mr. Power and the Hostnames aren't in the same city unless the Manager puts them there. Compose is what ties the venue to the band to the audience -- there's no show without the Manager.

And with that, I'll stop torturing the analogy. We know that the four pieces each have their role -- that `curldriver` generates requests and sends them to `datapower`, which in turn proxies requests to `backend`. Responses that return from `backend` are modified by `datapower` and returned to `curldriver`. These are the three types of containers that make up this composed application.

## The Composed Application

Let's start by taking a look at how the whole application is put together. The `docker-compose.yml` file describes the relationships between the different images, containers, and directories. Let's take a look at what it has:

```
version: '2'
services:
   curldriver:
     build: curldriver
     depends_on:
      - datapower
   datapower:
     build: datapower
     depends_on:
      - backend
   backend:
     build: nodejs-hostname
```

There are three services: `curldriver`, `datapower`, and `backend`. Each can be built by `docker-compose`; the `build:` line defines the directory that contains the source for `docker build`.

The `docker-compose.yml` file describes the dependencies between the applications. So we know that `curldriver` can't work without `datapower` which likewise can't work without `backend`.

We know that `curldriver`, `datapower`, and `backend` are DNS hostnames in the `docker network` that `docker-compose` creates for the application.

We know that the `nodejs-hostname` directory is used to build the `backend` image.

We know that `docker-compose` will use network, container, and image names based on the `--project-name` on the `docker-compose` command, and that the project name defaults to the name of the directory in which the `docker-compose.yml` file resides.

It turns out that all these things we know are artifacts that the applications in each container leverage. Every time the group of containers is deployed, the DNS names of their dependencies stay constant.

Because `docker-compose` keeps each project in its own network the DNS names can can be reused. The hosts `datapower` and `backend` are `datapower` and `backend` in each and every project I start.  I can -- and do -- use the hostname `datapower` in my `curldriver` container and the hostname `backend` in my `datapower` container. Similarly, when I `docker-compose build`, I get images named `<project>_<service>`, where `<service>` is `curldriver`, `datapower`, and `backend`. Similarly, when I `docker-compose up` I get Docker containers named `<project>_<service>_1`

In short, `docker-compose` is keeping track of all the collating that makes deployments vary. Now all my URLs are constant because Docker and Compose manage the hostnames. Now all my ports are static because every container gets its own IP address. 

## Docker Images and Compose Artifacts

Two of the images, `curldriver` and `datapower`, make use of the DNS names that `docker-compose` gives to containers.

The case of `curldriver` is trivial. Since `curldriver` uses cURL against a URL, the URL simply includes the name `datapower`. All `curldriver` is doing is running a shell script:

```
#!/bin/sh

while true
do
  curl --silent --insecure https://datapower || echo curl error $?
  sleep 5
done
```

Notice the url? All it does is poke at `https://datapower/`, and `datapower` is the DNS name of the DataPower container in the network in which both `curldriver` and `datapower` are running. The image has the hostname `datapower` burned-in, and `docker-compose` guarantees that the DNS name `datapower` refers to the correct address at run time.

Things are a little bit more complicated for the `datapower` image because it does not know how many `backend` hosts there will be. So instead of being truly hardcoded the way `curldriver` referred to `datapower`, `datapower` has to figure where the one or more `backend` hosts are.

Let's take a look at how this admittedly extremely simplistic way of discovering services works. Consider this snippet from `src/datapower/src/start/loadbalancer-group.sh`, which is run before DataPower itself starts and generates a config file for the DataPower `loadbalancer-group`:

```
{
  cat <<-EOF
        top; co

        loadbalancer-group lbg-backend
          reset
        EOF

  ( \
    env | grep '^[a-zA-Z0-9_-]*_PORT_8080_TCP_ADDR'| cut -d= -f2- ; \
    nslookup backend | sed -n -e '/^$/,$p' | awk '/^Address /{print $4}'; \
  ) \
  | while read ADDR
  do
    echo "  server $ADDR 1 8080 enabled"
  done

  cat <<-EOF
        exit

        xml-manager default
          loadbalancer-group lbg-backend
        exit
        EOF
} | tee /drouter/config/foo/loadbalancer-group.cfg
```

This script writes DataPower config out to the file `/drouter/config/foo/loadbalancer-group.cfg`, which is read by DataPower because it is in an `include-config` referenced in the `foo` application domain.

It knows how to look for information from two sources. First, it looks at environment variables for the variables that Docker provides when a container is linked with `docker run --link` to another container. For each such environment variable, the address is extracted.

It also does a DNS lookup on the name `backend`. Every address it finds is a back-end server that is added to the `loadbalancer-group`.

By looking for both sources of truth, the same script and thus the same image works both with Compose v1 which uses `docker run --link` and with Compose v2 which uses the `docker run --network` approach.

This approach is limited -- it means that only when the container starts can it discover new back-end servers. This is not what we want long-term, but it is a simple thing that is easy to understand that we can demonstrate today. Can you think of other approaches that would work properly with `docker-compose scale`? I won't spoil it, but there are a couple of interesting ways to do this.

I suggest starting with the `Dockerfile` for each of the images if you want to understand how each are put together.

## See it Run

Now that we know what our images do, it's time to see it run. You can follow along too, just:

```
git clone https://github.com/ibm-datapower/datapower-tutorials.git
cd datapower-tutorials/datapower-docker-compose-hello-world/src
```

First we need to build our images. Since the project includes sample `docker-compose.yml` files for both v1 and v2, we'll be explicit about the one we're using. Also, we're going to be explicit about the name of the project. The name `foo` seems like a good project name to start with:

```
docker-compose -f docker-compose-v2.yml -p foo build
```

With that command, `docker-compose` will build each of the three images. Remember that subsequent builds will take far less time because of the way `docker build` caches results. Let's see what `docker-compose` made for us:

```
$ docker images
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
foo_curldriver             latest              480845f3937a        2 minutes ago       182.3 MB
foo_datapower              latest              f75ada45d168        3 minutes ago       716.7 MB
foo_backend                latest              33c166b09106        3 minutes ago       377.7 MB
```

Now that the images are built, let's run them. The standard way is to use `docker-compose up`, so that's what we'll do but we'll include our explicit file and project:

```
$ docker-compose -f docker-compose-v2.yml -p foo up
Creating network "foo_default" with the default driver
Creating foo_backend_1
Creating foo_datapower_1
Creating foo_curldriver_1
Attaching to foo_backend_1, foo_datapower_1, foo_curldriver_1
backend_1     | Example app listening at http://0.0.0.0:8080
datapower_1   | + cut -d= -f1
datapower_1   | + grep ^DATAPOWER_
datapower_1   | + env
datapower_1   | + export DATAPOWER_INTERACTIVE DATAPOWER_LOG_STDOUT DATAPOWER_ACCEPT_LICENSE DATAPOWER_WORKER_THREADS DATAPOWER_LOG_COLOR
datapower_1   | Processing /start/loadbalancer-group.sh
curldriver_1  | curl error 7
. . .
```

OK, let's walk through what `docker-compose` has done for us. 

- It has created a new `docker network`
- It has created and run three containers
  - `foo_backend_1`,
  - `foo_datapower_1`, and
  - `foo_curldriver_1`
- It has `docker attach`ed all three running containers to the current terminal
- It is showing us real-time logs of all the containers in the composed application interleaved with each other. In that log, we can see
  - That `backend_1` is started and is listening
  - The startup script in `datapower_1` is running and learning about the backend servers
  - that `curldriver_1` is running but is failing. Not too surprising given that DataPower is not yet up.

Let's skip to the end of the startup process.

```
datapower_1   | 20161108T180039.218Z [foo][0x00350015][mgmt][notice] smtp-server-connection(default): tid(33423): Operational state down
datapower_1   | 20161108T180039.218Z [foo][0x00350014][mgmt][notice] smtp-server-connection(default): tid(33423): Operational state up
datapower_1   | 20161108T180039.224Z [foo][0x00350016][mgmt][notice] source-https(https-fsph-foo): tid(111): Service installed on port
datapower_1   | 20161108T180039.224Z [foo][0x00350014][mgmt][notice] source-https(https-fsph-foo): tid(111): Operational state up
datapower_1   | 20161108T180039.224Z [foo][0x00350014][mgmt][notice] mpgw(MPGW-foo): tid(111): Operational state up
datapower_1   | 20161108T180039.228Z [0x8100003b][mgmt][notice] domain(foo): Domain configured successfully.
backend_1     | Answered request with f2c36bb7d356
curldriver_1  | DataPower Proxied: Hello world from f2c36bb7d356
backend_1     | Answered request with f2c36bb7d356
curldriver_1  | DataPower Proxied: Hello world from f2c36bb7d356
backend_1     | Answered request with f2c36bb7d356
curldriver_1  | DataPower Proxied: Hello world from f2c36bb7d356
^C
Gracefully stopping... (press Ctrl+C again to force)
Stopping foo_curldriver_1 ... done
Stopping foo_datapower_1 ... done
Stopping foo_backend_1 ... done
```

Still watching the logs from each of the containers, we can see that once DataPower says `domain(foo): Domain configured successfully`, `backend` logs that it has answered a request, then `curldriver` logs the successful response that has been transformed by DataPower running in container `datapower_1` with the configuration we added via the `Dockerfile`.

At this point, I'm finished with this run so I press `Ctrl+C` which causes `docker-compose` to gracefully stop.

I'm done with this run, so I `docker-compose rm` my work:

```
$ docker-compose -f docker-compose-v2.yml -p foo rm
Going to remove foo_curldriver_1, foo_datapower_1, foo_backend_1
Are you sure? [yN] y
Removing foo_curldriver_1 ... done
Removing foo_datapower_1 ... done
Removing foo_backend_1 ... done
```

That's it! I can change any of my containers, re-build, re-run and it is all in a nice portable package. I could simultaneously run a second deployment in a package called `bar` and both would on at the same time but with different networks.

## Scaling the Application

But what if I want more than one `backend`? Easy, `docker-compose` will scale for you!

```
$ docker-compose -f docker-compose-v2.yml -p foo scale backend=3
Creating and starting foo_backend_1 ... done
Creating and starting foo_backend_2 ... done
Creating and starting foo_backend_3 ... done
```

Then I `docker-compose up` as I did before. But this time let us take a close look at the logs from the startup script in the `datapower_1` container:

```
$ docker-compose -f docker-compose-v2.yml -p foo up
foo_backend_2 is up-to-date
foo_backend_1 is up-to-date
foo_backend_3 is up-to-date
Creating foo_datapower_1
Creating foo_curldriver_1
Attaching to foo_backend_2, foo_backend_1, foo_backend_3, foo_datapower_1, foo_curldriver_1
. . .
datapower_1   | + tee /drouter/config/foo/loadbalancer-group.cfg
datapower_1   | + cat
datapower_1   | + read ADDR
backend_1     | Example app listening at http://0.0.0.0:8080
datapower_1   | + cut -d= -f2-
datapower_1   | + grep ^[a-zA-Z0-9_-]*_PORT_8080_TCP_ADDR
datapower_1   | + env
datapower_1   | + awk /^Address /{print $4}
datapower_1   | + sed -n -e /^$/,$p
datapower_1   | + nslookup backend
datapower_1   | + echo   server foo_backend_2.foo_default 1 8080 enabled
datapower_1   | + read ADDR
datapower_1   |   server foo_backend_2.foo_default 1 8080 enabled
datapower_1   |   server foo_backend_1.foo_default 1 8080 enabled
datapower_1   | + echo   server foo_backend_1.foo_default 1 8080 enabled
datapower_1   | + read ADDR
datapower_1   | + echo   server foo_backend_3.foo_default 1 8080 enabled
datapower_1   | + read ADDR
datapower_1   |   server foo_backend_3.foo_default 1 8080 enabled
datapower_1   | + cat
datapower_1   | exit
. . .
```

This time, the three `backend` instances are already up, so `docker-compose` uses them as they are. As before, `docker-compose` attaches to all the containers that make up the composed application; this time there are more. We still see the backend starting.

But pay special attention to the hostnames, such as `foo_backend_2.foo_default`. This is how the names and domains of each of the backends are given when `nslookup backend` was run inside the container, and these are the entries added to the DataPower `loadbalancer-group`.

Skipping ahead to the time the DataPower application domain is fully configured, we can see that each `backend` is answering requests and that the different responses are seen by `curldriver`.

```
datapower_1   | 20161108T181934.634Z [0x8100003b][mgmt][notice] domain(foo): Domain configured successfully.
backend_2     | Answered request with b6521fe5bdd0
curldriver_1  | DataPower Proxied: Hello world from b6521fe5bdd0
backend_1     | Answered request with f5c242202487
curldriver_1  | DataPower Proxied: Hello world from f5c242202487
backend_3     | Answered request with d885b804e83a
curldriver_1  | DataPower Proxied: Hello world from d885b804e83a
backend_2     | Answered request with b6521fe5bdd0
curldriver_1  | DataPower Proxied: Hello world from b6521fe5bdd0
backend_1     | Answered request with f5c242202487
curldriver_1  | DataPower Proxied: Hello world from f5c242202487
backend_3     | Answered request with d885b804e83a
curldriver_1  | DataPower Proxied: Hello world from d885b804e83a
backend_2     | Answered request with b6521fe5bdd0
curldriver_1  | DataPower Proxied: Hello world from b6521fe5bdd0
```

As before, I stop the contaiers with `Ctrl+C` and remove the containers with `docker-compose rm`.

```
^C
Gracefully stopping... (press Ctrl+C again to force)
Stopping foo_curldriver_1 ... done
Stopping foo_datapower_1 ... done
Stopping foo_backend_2 ... done
Stopping foo_backend_1 ... done
Stopping foo_backend_3 ... done
hstenzel@harleys-mbp:src$ docker-compose -f docker-compose-v2.yml -p foo rm
Going to remove foo_curldriver_1, foo_datapower_1, foo_backend_2, foo_backend_1, foo_backend_3
Are you sure? [yN] y
Removing foo_curldriver_1 ... done
Removing foo_datapower_1 ... done
Removing foo_backend_2 ... done
Removing foo_backend_1 ... done
Removing foo_backend_3 ... done
```

Will you take up the challenge of making this scale dynamically?

## Conclusion

One of the hardest tasks of deploying DataPower has traditionally been changing the DataPower configuration appropriately for each environment and each appliance into which DataPower configuration is deployed. Using Docker and an orchestrator like `docker-compose`, we can deploy complete applications that include DataPower in ways that are completely independent of each other. We can allow the orchestrator to solve the deployment problem on our behalf.

There are many more steps on the road to CI/CD through containerization and orchestration. I hope that this example shows you the first few steps and gives you an idea of what the road ahead holds. Thank you for your attention, please let us know what you think!