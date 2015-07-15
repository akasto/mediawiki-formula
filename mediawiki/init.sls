{% from "mediawiki/map.jinja" import settings with context %}

install apache:
  pkg.installed:
    - name: apache2
  service:
    - name: apache2
    - running

install php5:
  pkg.installed:
    - name: php5

install php5-mysql:
  pkg.installed:
    - name: php5-mysql

install libapache2-mod-php5:
  pkg.installed:
    - name: libapache2-mod-php5
 
install imagemagick:
  pkg.installed:
    - name: imagemagick

mediawiki:
  archive.extracted:
    - name: /var/www/html
    - source: https://releases.wikimedia.org/mediawiki/1.25/mediawiki-1.25.1.tar.gz
    - source_hash: md5=12d6c2d2d0cbf068ae678abc92b6a4f9
    - tar_options: xf
    - archive_format: tar
    - if_missing: /var/www/html/mediawiki

rename to mediawiki:
  file.rename:
    - name: /var/www/html/mediawiki
    - source: /var/www/html/mediawiki-1.25.1
    - force: True

mediawiki LocalSettings:
  file.managed:
    - name: /var/www/html/mediawiki/LocalSettings.php
    - source: salt://mediawiki/files/LocalSettings.php
    - template: jinja
    - defaults:
        site_name: {{ settings.site_name }}
        fqdn: {{ settings.fqdn }}
        user: {{ settings.db.user }}
        password: {{ settings.db.password }}
        upgrade_key: {{ settings.upgrade_key }}
        emergency_contact: {{ settings.emergency_contact }}
        password_sender: {{ settings.password_sender }}
        secret_key: {{ settings.secret_key }}

mysql_setup:
  debconf.set:
    - name: mysql-server-5.5
    - data:
        'mysql-server/root_password': {'type': 'password', 'value': '{{ settings.db.root_password }}'}
        'mysql-server/root_password_again': {'type': 'password', 'value': '{{ settings.db.root_password }}'}

# needed to start mysql on machines with low memory.
mysql limited memory config:
  file.managed:
    - name: /etc/mysql/conf.d/limited_memory.cnf
    - source: salt://mediawiki/files/limited_memory.cnf

mysql-server:
  pkg:
    - installed
    - require:
      - debconf: mysql_setup
  service:
    - name: mysql
    - running
    - watch:
      - pkg: mysql-server

# Needed for saltstack mysql management.
install python-mysqldb:
  pkg.installed:
    - name: python-mysqldb

