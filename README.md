DNSProspect
===========

Summary
-------

This tools tries to find port and servers where a service is being provided by
a domain or domains list.

The tool avoid using port scanning methods (nmap, masscan, etc.) to detect 
valid services being provided by the targeted domain(s). The method used to
detect this is by querying the DNS for SRV records (RFC2782).

The list of SRV records being queried is found in the text files found inside
the folder "services".

Usage
-----

``
Usage: ./dnsprospect.sh <domains file | domain name> <output csv file>
[<extended | small>]
``

Where the parameters are:
- _domains file_: A file containing one domain per line
- _domain name_: A single domain name
- _output csv file_: The services found wil be dumped to this CSV file
- _extended_: The script will use a long list of SRV records to query
- _small:_ The script will use a smaller list of SRV records to query


Output Example
--------------

root@stark /home/perico/Tools/DNSProspect # ./dnsprospect.sh domains/top1000domains.txt output.csv small

Prospecting with the following configuration:
 - Domains: File domains/top1000domains.txt
 - SRV records to detect: File services/commonsrv.txt
 - Open Resolvers used: File openresolvers/spain.txt

===== google.com =====

 XMPP Client to Server: 5 servers listening
 - alt3.xmpp.l.google.com. listening on port 5222/TCP
 - alt2.xmpp.l.google.com. listening on port 5222/TCP
 - alt1.xmpp.l.google.com. listening on port 5222/TCP
 - xmpp.l.google.com. listening on port 5222/TCP
 - alt4.xmpp.l.google.com. listening on port 5222/TCP

 XMPP Server to Server: 5 servers listening
 - alt1.xmpp-server.l.google.com. listening on port 5269/TCP
 - alt2.xmpp-server.l.google.com. listening on port 5269/TCP
 - alt3.xmpp-server.l.google.com. listening on port 5269/TCP
 - alt4.xmpp-server.l.google.com. listening on port 5269/TCP
 - xmpp-server.l.google.com. listening on port 5269/TCP

 Jabber Client to Server: 5 servers listening
 - alt2.xmpp.l.google.com. listening on port 5222/TCP
 - alt3.xmpp.l.google.com. listening on port 5222/TCP
 - alt4.xmpp.l.google.com. listening on port 5222/TCP
 - alt1.xmpp.l.google.com. listening on port 5222/TCP
 - xmpp.l.google.com. listening on port 5222/TCP

 Active Directory: 1 servers listening
 - ldap.google.com. listening on port 389/TCP

 Active Directory SSL/TLS: 1 servers listening
 - ldap.google.com. listening on port 636/TCP

 Domain Controller of the Domain: 0 servers listening
 It does not have Domain Controller of the Domain servers

[...]
