# Ansible FragDenStaat.de

Based on [ansible-django-stack](https://github.com/jcalazan/ansible-django-stack).

Ansible to deploy FragDenStaat.de - a Django app with Postgres database, ElasticSearch search engine, Celery+RabbitMQ background queue and a full email server with postfix and dovecot on Ubuntu Xenial.


## Deploy FragDenStaat.de

Run this to deploy FragDenStaat.de

    ansible-playbook fragdenstaat.de.yml -v


## Deploy VirtualBox with Vagrant

    vagrant up