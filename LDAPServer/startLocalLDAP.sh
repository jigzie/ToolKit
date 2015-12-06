#!/bin/bash

#START LOCAL LDAP SERVER; this takes resources so keep it in the window & closing the window kills the LDAP server (as expected).
sudo /usr/libexec/slapd -d3
