# radius-auth-chainer
Small docker config containing a freeRadius server that can be used to split credentials from a single RADIUS auth request and validates them against 1. a LDAP server and 2. another RADIUS server. If both proxy server authentications are successful, the initial request will be answered with an Access-Accept, in any other case with Access-Reject.

## Configuration
To overwrite the defaults of this container it is recommended to mount the following files to their according location in the container:
* LDAP-Server-Settings in file `/etc/raddb/mods-available/ldap`
* Upstream RADIUS Proxy in file `/etc/raddb/proxy.conf`
* Allowed RADIUS-Clients in file `/etc/raddb/clients.conf`
* (optional) If you use tokens generating other OTPs than 6 digits, also adapt [/etc/raddb/sites-available/default](raddb/sites-available/default) at line 314. Edit the regex to split the user input according to your setup.

---
**NOTE**

It is not possible to use tokens generating OTPs with different lengths!

---

You can find the default files of the FreeRADIUS-Project in this repository under the folder `raddb` with minor changes done to fit into this projects use case. Overwriting the defaults can be done by mounting your custom config files like shown below:

```shell
git clone https://github.com/martingegenleitner/radius-auth-chainer
cd radius
docker build -t frac .
docker run \
    --name frac01 \
    -p 1812-1813:1812-1813/udp \
    -d \
    -v <PATH_TO_CUSTOM_ldap>:/etc/raddb/mods-available/ldap \
    -v <PATH_TO_CUSTOM_proxy.conf>:/etc/raddb/proxy.conf \
    -v <PATH_TO_CUSTOM_clients.conf>:/etc/raddb/clients.conf \
    frac
```

---
**HINT**

Each config file has been committed initially in its default form by the freeRADIUS project. To check which changes were applied to them, look into their commit history.

---

### LDAP-Server
Before you build this container, configure the [LDAP-Settings](raddb/mods-available/ldap) according to your needs or overwrite its settings at runtime by mounting your own configuration as shown above. The config defaults to authenticating against a specially crafted LDAP server that can be found at [ldap-testing](ldap-testing/Dockerfile).

LDAP-Authentication requires a user with read permissions to the LDAP tree part where the users reside, that shall be authenticated. The most common adaption to your ldap setup will be changes to the lines configuring...
* `server` directive (at line 19) with your actual LDAP-server
* `base_dn` directive (at line 33) setting the ldap tree part of the users that shall be authenticated
* `identity` & `password` (at lines 28/29) defining the user with read permissions on the `base_dn`

### STA/SAS-RADIUS-Server
Configure the Shared-Secret and IP-Addresses/Hostnames of your upstream STA or SAS RADIUS hosts in the [Proxy-Config](raddb/proxy.conf).

### RADIUS-Clients
Tell the service which clients are allowed to connect to it and which shared secrets shall be used in the [Client-Config](raddb/clients.conf). By default all RADIUS connections with the shared secret `testing123` are allowed. To change this, mount your own `clients.conf` file to the container at `/etc/raddb/clients.conf` like shown above.

## Testing the service with defaults
1. Go into the `ldap-testing` folder and run `docker-compose up -d`. This will build the new container based on the official freeradius image and spins up a new container instance with a openldap container for ldap authentication
2. Add the public ip of your docker host to your virtual server in STA or SAS as a new `Auth Node`
3. Create a user `mobpass` and provision it with an OTP-generating token like MobilePass+ or a hardware token.
4. Shoot authentication requests at the exposed ports of your docker host with a tool like `ntradping.exe` and the user mobpass with password `Testing123!` and the generated OTP
5. Watch the authentication log in your virtual server's `Snapshot` tab and also the logs produced by the freeradius container by running `docker logs -f ldap-testing_freeradius_1`