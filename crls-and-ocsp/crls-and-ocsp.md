#CRLs in DataPower
##Introduction

The one way to make sure that certificates we used are to be trusted is to validate if the certificates haven't been revoked. This is done by checking a CRL (Certificate Revocation List) or utilized OCSP (Online Certificate Status Protocol). This blog  covers the support of CRL, but note that OCSP is supported by IBM DataPower Gateway as well.   Most certificates contains an extention which describe the endpoint to acquire the CRL, which is issued by the CA that signed this certificate.

If a CA revokes a certificate, the certificate is  is added to the CRL, and the clients/applications  check this CRL, to determine whether  the certificate, although being in the trust-store, is not to be trusted, because the certificate has been revoked

DataPower supports CRLs in DER or PEM format and can fetch them from an LDAP, HTTP source that might or might not be secure by SSL/TLS

##CRLs On DataPower
###Flows
The following Diagrams should give you an idea what a real world flow could be.

![crl-flow](media/CRLFlow.png)

In the diagram above we see the behaviour in a "ideal" scenario, the certificates are still valid.
The CRL Update Policy checks the CRL endpoints as defined in the certificate.
These endpoints need to be configured, as they are not auto configured from the certificate. However one can specify in the validation credentials that if the CRL endpoint as defined in the rfc3280 compliant extension of the certificate should be checked for validation to succeed.

![crl-flow2](media/CRLFlow2.png)

When the client notices that his key has been compromised he notifies his CA who then add's the serial number of the respective certificate to the CRL. He then resigns it with his certificate and publishes the CRL on the endpoint as listed in the issued certificates.

![crl-flow3](media/CRLFlow3.png)

The next time the CRL endpoint get's polled by DataPower the all validation credentials trying to validate the revoked certificate will now fail.

##Hands On

On DataPower this is a 2 step process
Step 1:
In the default domain we must define a CRL retrieval policy for the CRL endpoint, For every certificate that we want to verify against the CRL the endpoint must have a corresponding CRL endpoint policy.

![crl-retrieval-http](media/crl-retrieval-http.png)

Policy Name: a name given to this specific retrieval rule
Protocol: The protocol that is used to fetch the CRL, it can be HTTP or LDAP (when you have an HTTPS endpoint select HTTP and fill in the SSL client type)
CRL Issuer Validation Credentials: The certificate that is used to validate the signature of the CRL
Refresh Interval: The interval use to poll the CRL endpoint.
SSL Client type: This can be a Client Profile or a Proxy Profile (deprecated)
SSL client profile / Cryptographic Profile (deprecated): The client profile to connect to SSL/TLS secured endpoint
Fetch URL: The CRL endpoint as defined in the certificate extensions that you want to have validated

In case of an LDAP endpoint the Fetch URL is replaced by variables to the define the location of the CRL on LDAP as shown below

![crl-retrieval-ldap](media/crl-retrieval-ldap.png)

Now that we have defined the CRL endpoint update policy. We can use this CRL to verify if certificates that have this CRL endpoint defined in the extension hasn't been revoked

Step 2:
In the domain where we want to use the certificate, the settings for the CRL are found in the validation credentials

![cryptoval](media/cryptoval.png)

Use CRL: Tells us if we are going to make use of the CRL
Require CRL: The validation of the certificate fails if there is no copy of the CRL in the CRL cache.
CRL Distribution Points Handling:
- Require all the CRL distribution points in the certificate are checked against (however they must be fetched by a CRL update policy). If any CRL is no longer in the CRL cache the validation fails.
- Ignore Ignore the certificate extension, if present. However the certificate is till checked against the CRLs in the cache.

For the  CRL distribution points in the certificate extension there should be a retrieval policy if checking is enforced if not and the CRL is not fetched we will see an error stating that the CRL endpoint is not available

![crl-error](media/crl-error.png)

###Example materials
attached you can find zip.
In it  2 clients (alice and bob) and a CA (password of the key is "02april1990"), the certificate of bob is revoked and in the crl.
To test the scenario you can host the crl.crl file in the ca dir on a http server and point the CRL update policy to that endpoint. If you want enforced checking for these certificates you should host the certificates on http://192.168.100.1/crl.crl

You could also "bake" your own client certificates and change the endpoint by changing ca/openssl.cnf
