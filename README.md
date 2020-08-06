# Ansible FragDenStaat.de

Based on [ansible-django-stack](https://github.com/jcalazan/ansible-django-stack).

Ansible to deploy FragDenStaat.de - a Django app with Postgres database, ElasticSearch search engine, Celery+RabbitMQ background queue, Redis server and a full email server with postfix and dovecot on Ubuntu 18.04 / 20.04.


## Deploy FragDenStaat.de

Run this to deploy FragDenStaat.de

    ansible-playbook fragdenstaat.de.yml -v

There are tags available:

    - `deploy-web` – updates app and reloads app server
    - `deploy-backend` – like `deploy-web` but also restarts workers
    - `deploy-frontend` - rebuilds frontend and reloads app server
    - `nginx` – rebuilds nginx config and reload nginx

Use like this:

```
ansible-playbook fragdenstaat.de.yml -v -t deploy-web -t deploy-frontend
```

## Deploy VirtualBox with Vagrant

Start and provision (run ansible) like this:

    vagrant up --provision
