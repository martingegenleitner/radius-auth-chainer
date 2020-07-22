# radius-auth-chainer
Small docker config containing a freeRadius server that can be used to split credentials from a single RADIUS auth request and validates them against 1. a LDAP server and 2. another RADIUS server. If both proxy server authentications are successful, the initial request will be answered with an Access-Accept, in any other case with Access-Reject.

## Configuration
To overwrite the defaults of this container it is recommended to mount the following files to their according location in the container:
* LDAP-Server-Settings in file `/etc/raddb/mods-available/ldap`
* Upstream RADIUS Proxy in file `/etc/raddb/proxy.conf`
* Allowed RADIUS-Clients in file `/etc/raddb/clients.conf`

You can find the default files of the FreeRADIUS-Project in this repository under the folder `raddb` with minor changes done to fit into this projects use case. Overwriting the defaults can be done by mounting your custom config files like shown below:

```shell
docker run --name frac01 \
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
Before you build this container, configure the [LDAP-Settings](raddb/mods-available/ldap) according to your needs or overwrite its settings at runtime by mounting your own configuration as shown above. The config defaults to authenticating against a specially crafted LDAP server that can be found at [ldap-testing](ldap-testing/Dockerfile) and can be spinned up with [docker-compose](ldap-testing/docker-compose.yml) like so:

```shell
cd ldap-testing
docker-compose up
```

### STA/SAS-RADIUS-Server
Configure the Shared-Secret and IP-Addresses/Hostnames of your upstream STA or SAS RADIUS hosts in the [Proxy-Config](raddb/proxy.conf).

### RADIUS-Clients
Tell the service which clients are allowed to connect to it and which shared secrets shall be used in the [Client-Config](raddb/clients.conf). By default all RADIUS connections with the shared secret `testing123` are allowed. To change this, mount your own `clients.conf` file to the container at `/etc/raddb/clients.conf` like shown above.

## Serving the service
1. Run `docker build -t frac .` after your config adaption. This will build the new container based on the official freeradius image.
2. Run `docker run --name frac01 -p 1812-1813:1812-1813/udp -d frac` to spin up a new container instance.
3. Shoot authentication requests at the exposed ports of your docker host :)