## Prerequisites
* Complete Installation and logged in as a user who has user create permission such as root user.

## User Management

There is a specific permission for managing users. Root user has all user management permissions. It is recommended that root user should not be used all the time. Please create an administrator user for projects:

## Creating a new user

```shell
vamp add user projectadmin
```
This command will create a user and print the command that is required for the new user to login.

Sample output:
```shell
User created.
User can login with:
vamp login --url https://ip:port --user projectadmin --initial --token TOKEN --cert <<EOF "-----BEGIN CERTIFICATE-----
...
...
...
-----END CERTIFICATE-----
"
EOF
```

Follow the instructions and send this command to the new user.

On new user computer, user can login with:

```shell
vamp login --url https://ip:port --user projectadmin --initial --token TOKEN --cert <<EOF "-----BEGIN CERTIFICATE-----
...
...
...
-----END CERTIFICATE-----
"
EOF
```

Certificate will be stored in the vamp user configuration. As you can see only token is used for this process and currently user password is not set up. User needs to update their password in their first login.

To update user password user should update:

```shell
vamp passwd
```
Follow the instructions that will ask for the same password twice.
It is not possible to get the password back and password is not stored locally. If you lose your password as a user, ask your root user to update it. Even the root user doesn't have read access to the password.

Re-login with your username and new password:
```shell
vamp login --user projectadmin
```

Now try to list projects:
```shell
vamp list projects
```

You will get an empty list since new user doesn't have access to any projects yet.

On the root user's shell run this command to grant project access rights for the default project to projectadmin user.

```shell
vamp grant --user projectadmin --role admin -p default
```

projectadmin can list projects and has admin access to default project, it is visible if the projects are listed.
```shell
vamp list projects
- default
```

Please, use projectadmin or similar users for all operations. Root user should only be used for creating top level administrator users.
