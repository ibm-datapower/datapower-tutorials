# DataPower MVP 1: Simple "DataPower in AWS"
## DRAFT

* *Who*: Infrastructure and DataPower specialists (some prior DataPower knowledge assumed)
* *What*: What it's really like to implement manually a Debian image of DataPower into Amazon EC2
* *Wow!*: Once deployed, it's DataPower ! 

## Introduction

IBM DataPower Gateway (IDG) is available in a variety of different form factors. A summary of the available form factors is shown in the following diagram:

> > > diagram < < < 

In the diagram above, note the comment on the bottom right: "*Once deployed, it's DataPower*".
This emphasises the fact that the function provided, the developer experience and how you use the product remains the same.
There are some subtle differences operationally, and the performance and the security characteristics differ.
However, this article assumes that all that is understood, and concentrates simply on deploying DataPower onto Amazon EC2.

For deployment onto Amazon EC2, the following form factor applies:

> > > diagram < < < 

A DataPower Gateway can be deployed onto Amazon EC2 both as RHEL software and as Ubuntu software.
The rest of this article discusses Ubuntu only, and deploying DataPower as a Debian image.

## The Process

An overview of the process to install the DataPower Debian package is available in the DataPower Knowledge Center here:
[http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_deployingcloud.html](http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_deployingcloud.html).
This information is also contained in the Quick Start Guide that one downloads with the package.

That documentation provides an excellent summary of the process from a DataPower point of view.
It assumes some basic DataPower skills (including some prior experience of initial DataPower configuration),
as well as some basic AWS skills.
This section adds some real-world pragmatic comments on the process.

### The Installation Files

The DataPower Debian package comprises three files:

* **`xxx.image_amd64.deb`** - approximately 1.3 GiB in size
* **`xxx.common_amd64.deb`** - approximately 500 KiB in size
* **`5725CloudQuickStartGuide.pdf`** - approximately 500 KiB in size

Note that **xxx** above indicates the version of the package and the licensed edition (for Production, Non-Production and Developers').
The installation process is otherwise identical.

You first need to download those files from IBM.

* If you have paid IBM for the requisite licence to use Virtual DataPower, those files will be available
on your [IBM Passport Advantage web-site](https://www-01.ibm.com/software/passportadvantage/), from where they can be downloaded.
* IBM also provides an Evaluation Licence for DataPower. This can be requested from your IBM Sales Rep;
it allows you to download and use the software for up to 150 days free of charge (for evaluation purposes only).

When downloading, bear in mind the size of the 1.3 GiB file. Typically you will download to the installer's laptop/computer.

### Configuring the Ubuntu Instance

You then need to set up on Amazon EC2 an Ubuntu instance, onto which you will copy those .deb files and on which you will create the DataPower Gateway.
A good description of the available instances can be found in the Amazon documentation here: [https://aws.amazon.com/ec2/instance-types/](https://aws.amazon.com/ec2/instance-types/).

The DataPower documentation here: [http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_deployingcloud.html](http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_deployingcloud.html)
defines the minimum system requirements, which I summarise as: 

* Operating system : 64-bit Ubuntu 14.04 LTS.
* Absolute minimal configuration is two virtual processors (vCPU) and 4 GB RAM.
* 2 GiB of free storage must be available on /opt.
* 17 GiB of free storage must be available on /var.

The smallest appropriate EC2 instance is an Ubuntu 14.04 LTS (HVM) server: **t2.medium**.
This should be fine for a test and development system. See the images below.

> > > diagram < < <

> > > diagram < < <

However, for Production-sized instances, IBM recommends a minimum of 4 vCPUs, which means that
for Production you should consider an **m4.xlarge** or bigger.
This also has the advantage of High network performance.

You should select and configure your chosen instance referring to the Amazon EC2 Getting Started Guide here:
[http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html).
When configuring your instance, you can leave most options to default.
However, ensure you specify a disk storage size of 30 GiB minimum (to permit installation of the product with plenty of overhead for installation files etc).

For access to the instance, you should create the following rules in the Security Group:

* SSH to port 22, to allow access for installation and initial configuration.
This may be disabled after initial configuration, for extra security.
* Custom TCP Rule to port 9090, to allow initial access for the web-management GUI.
This may be changed to a different port after initial configuration, for extra security.
* Later on, when configuring Front-Side Handlers within DataPower,
ensure you configure a rule to permit access to the front-side port.


### Signing on to the Ubuntu instance

You can connect and sign on to the Ubuntu instance (to port 22) using either of the following:
* A standalone SSH client
* A Java SSH Client directly from your browser 


If you use a standalone client, you will need to set up security. This is described well in the Amazon documentation here: [https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html?icmpid=docs_ec2_console](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html?icmpid=docs_ec2_console) .
However, it is not entirely clear about the SSH configuration on the Ubuntu instance.
Make note of the following:

* Omitted from the Amazon documentation, but as described here and elsewhere:
[http://www.daveperrett.com/articles/2010/09/14/ssh-authentication-refused/](http://www.daveperrett.com/articles/2010/09/14/ssh-authentication-refused/) ,
you must change the user's home directory permissions to **g-w**.
* As described here: [https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/managing-users.html](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/managing-users.html) ,
you must create a directory called **`.ssh`** in the user's home directory, and change its file permissions to **700**.
* As described here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/managing-users.html ,
you must create a file called **`authorized_keys`** in **`.ssh`** , and change its file permissions to **600**.

> > > diagram < < <

If you want to use PuTTY as your standalone client, make sure you have an up-to-date version (eg Release 0.62),
otherwise it will not recognise an Amazon-generated .pem file.

Note: if you have problems connecting to your instance, refer to the Amazon EC2 Troubleshooting Instance Connections guide here:
[http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/TroubleshootingInstancesConnecting.html](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/TroubleshootingInstancesConnecting.html).

### Uploading the .deb Files

You now need to make those .deb files available to the new Ubuntu instance.
You could consider using FTP; however for these reasons that is not recommended:

* Whether you use FTP Client on the Ubuntu instance, or you install FTP Server on the Ubuntu instance and use an FTP Client elsewhere,
that is likely to result in a very slow transfer rate (100Kbps or less has been seen).
* If you install and use an FTP Server on the Ubuntu instance, this then becomes redundant software
that is not needed for runtime DataPower.
* If you use an FTP Server on the Ubuntu instance, you'll need to set up an Inbound security rule to permit access to the FTP port;
this is a potential security loophole that is not needed for runtime DataPower.

Instead, you should follow this process to make those files available to the Ubuntu instance:

1. Upload the two .deb files to an Amazon S3 bucket, as documented here:
[http://docs.aws.amazon.com/AmazonS3/latest/gsg/GetStartedWithS3.html](http://docs.aws.amazon.com/AmazonS3/latest/gsg/GetStartedWithS3.html). 
2. Use the wget utility, when signed on to the instance, to copy the files from the S3 bucket to the Ubuntu instance, as documented here:
[http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonS3.html](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonS3.html). 


After you have uploaded the files, follow the DataPower documentation here:
[http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_deployingcloud.html](http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_deployingcloud.html)
to install the product, using your signed-on session.

### Once Installation has Completed

As described in the DataPower documentation here: [http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_deployingcloud.html](http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_deployingcloud.html) ,
the DataPower Gateway will start automatically.

You should then use telnet from your signed-on session to access the DataPower Gateway's Command Line Interface (CLI)
and use standard DataPower techniques to perform initial configuration of the DataPower Gateway. 

For further discussions about considerations that apply to DataPower in Amazon EC2 (from a DataPower point of view),
see the DataPower Knowledge Center here: [http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_considerations.html](http://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/virtual_considerations.html) .

## Summary

This document has described how to set up a single instance of IBM DataPower Gateway in Amazon EC2 manually,
using Debian files and an Ubuntu instance.

Further MVPs will provide guidance on some more realistic practical implementations - including automated installation, 
better resilience and better security.
