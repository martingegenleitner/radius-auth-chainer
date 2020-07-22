FROM freeradius/freeradius-server:latest

# Copy configuration files
COPY raddb/ /etc/raddb/

# Enable ldap config by symlinking it
RUN cd /etc/raddb/mods-enabled && \
    ln -s ../mods-available/ldap ldap