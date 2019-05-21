# Notificaitons

Most of the operations done through Vamp Kubist are asynchronous or long running ones, so it is quite useful to have notifications that relieve the user from the need of constantly checking resources status to get a picture of what is going on.
Vamp Kubist supports two kinds of notifications, that is desktop notifications and Slack notifications.

## Table of contents

* [Desktop notifications](#desktop-notifications)
* [Slack notifications](#slack-notifications)

## Desktop notifications

Desktop notifications can be enabled from vamp kubist client by opening a new terminal and running 

```shell
vamp notificationservice --desktop
```

While this command is running, all events from the vamp instance you are currently logged in will be send to you as desktop notifications.

## Slack notifications

In order to set up Slack notifications it is necessary to configure Slack access for given project or cluster.
Doing this is traightforward.
Supposing you have a project named project1 you can run

```shell
vamp edit project project1
```

This will allow you to edit the project definition and add the following value to the project metadata.

- **slack_webhook**: a valid webhook
- **slack_channel**: the name of the channel you want to use. The default is `#vamp-notifications`

This will allow Vamp Kubist to send notifications to the specified Slack channel.
