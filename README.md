# InternDevOpsEngineer

This is repository for studying on Intern DevOps Engineer course in Itransition.

# Installing software

Because I'm prefer to use podman as compatible replacement of docker, I installed it by:

- sudo dnf install -y podman podman-compose
- echo "alias docker='podman'" >> ~/.bashrc
- echo "alias docker-compose='podman-compose'" >> ~/.bashrc

# Doing the first sub task:
- docker run -d --name nginx-1 -p 8443:80 nginx
- sudo firewall-cmd --add-port=8443/tcp
- sudo firewall-cmd --runtime-to-permanent
- docker ps

```
CONTAINER ID  IMAGE                           COMMAND               CREATED        STATUS            PORTS                 NAMES
a49e049b2203  docker.io/library/nginx:latest  nginx -g daemon o...  4 seconds ago  Up 4 seconds ago  0.0.0.0:8443->80/tcp  nginx-1
```

- curl 127.0.0.1:8443

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

# Doing the second sub task
- mkdir ./mysql
- echo "$(openssl rand -base64 16)" > ./mysql.pwd
- docker run --name mysql -d -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root -v ./mysql.pwd:/run/secrets/mysql-root:ro -v ./mysql:/var/lib/mysql mariadb
- docker ps

```
CONTAINER ID  IMAGE                             COMMAND               CREATED         STATUS             PORTS                 NAMES
a49e049b2203  docker.io/library/nginx:latest    nginx -g daemon o...  22 minutes ago  Up 22 minutes ago  0.0.0.0:8443->80/tcp  nginx-1
90c78a368fd2  docker.io/library/mariadb:latest  mariadbd              7 seconds ago   Up 8 seconds ago                         mysql`

- docker exec -it mysql mysql -u root -p
`Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 10.9.3-MariaDB-1:10.9.3+maria~ubu2204 mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

- docker cp ./dbcreate.sql mysql:/tmp/
- docker exec -it mysql mysql -u root -p
- source /tmp/dbcreate.sql

```
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 6
Server version: 10.9.3-MariaDB-1:10.9.3+maria~ubu2204 mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> source /tmp/dbcreate.sql
Query OK, 1 row affected (0.001 sec)

Query OK, 0 rows affected (0.006 sec)

Query OK, 0 rows affected (0.003 sec)

Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| idoe_db            |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.002 sec)
MariaDB [(none)]> use mysql;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [mysql]> select * from user;
+-----------+-------------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
| Host      | User        | Password                                  | Select_priv | Insert_priv | Update_priv | Delete_priv | Create_priv | Drop_priv | Reload_priv | Shutdown_priv | Process_priv | File_priv | Grant_priv | References_priv | Index_priv | Alter_priv | Show_db_priv | Super_priv | Create_tmp_table_priv | Lock_tables_priv | Execute_priv | Repl_slave_priv | Repl_client_priv | Create_view_priv | Show_view_priv | Create_routine_priv | Alter_routine_priv | Create_user_priv | Event_priv | Trigger_priv | Create_tablespace_priv | Delete_history_priv | ssl_type | ssl_cipher | x509_issuer | x509_subject | max_questions | max_updates | max_connections | max_user_connections | plugin                | authentication_string                     | password_expired | is_role | default_role | max_statement_time |
+-----------+-------------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
| localhost | mariadb.sys |                                           | N           | N           | N           | N           | N           | N         | N           | N             | N            | N         | N          | N               | N          | N          | N            | N          | N                     | N                | N            | N               | N                | N                | N              | N                   | N                  | N                | N          | N            | N                      | N                   |          |            |             |              |             0 |           0 |               0 |                    0 | mysql_native_password |                                           | Y                | N       |              |           0.000000 |
| localhost | root        | *D12BEC2C8F9664A534694D1195C6B5DCBE1C6B53 | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | Y          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y                | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      | Y                   |          |            |             |              |             0 |           0 |               0 |                    0 | mysql_native_password | *D12BEC2C8F9664A534694D1195C6B5DCBE1C6B53 | N                | N       |              |           0.000000 |
| %         | root        | *D12BEC2C8F9664A534694D1195C6B5DCBE1C6B53 | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | Y          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y                | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      | Y                   |          |            |             |              |             0 |           0 |               0 |                    0 | mysql_native_password | *D12BEC2C8F9664A534694D1195C6B5DCBE1C6B53 | N                | N       |              |           0.000000 |
| 127.0.0.1 | idoe        | *6F06DF9B0E450291E7BEDDAC1123B0F09F94452B | N           | N           | N           | N           | N           | N         | N           | N             | N            | N         | N          | N               | N          | N          | N            | N          | N                     | N                | N            | N               | N                | N                | N              | N                   | N                  | N                | N          | N            | N                      | N                   |          |            |             |              |             0 |           0 |               0 |                    0 | mysql_native_password | *6F06DF9B0E450291E7BEDDAC1123B0F09F94452B | N                | N       |              |           0.000000 |
+-----------+-------------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
4 rows in set (0.002 sec)
```
