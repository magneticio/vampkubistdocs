# Notifications

Most of the operations done through Vamp Kubist are asynchronous or long running ones, so it is quite useful to have notifications that relieve the user from the need of constantly checking resources status to get a picture of what is going on.
Vamp Kubist supports two kinds of notifications, that is desktop notifications and Slack notifications.

## Table of contents

* [Client notifications](#client-notifications)
* [Slack configuration](#slack-configuration)
* [Filtering notifications](#filtering-notifications)
    * [Notification Levels](#notification-levels)
    * [Configuring notification filters](#configuring-notification-filters)
    * [Configuring global notification filters](#configuring-global-notification-filters)

## Client configuration

Vamp Kubist support notifications of various events such as resources update and deletion or a canary release progress.
In order to receive these notifications, the simplest way is to open a terminal window and use the client by running

```shell
vamp notificationservice
```

All notifications will be then displayed inside the terminal window.
In a similar way it is also possible to enable desktop notificaitons, by running

```shell
vamp notificationservice --desktop
```

While this command is running, all events from the vamp instance you are currently logged in will be send to you as desktop notifications.

## Slack configuration

Vamp Kubist also support sending the notifications to a slack channel.
In order to access this feature it is necessary to configure slack access for given project or cluster.
Doing this is straightforward.
Supposing you have a project named project1 you can run

```shell
vamp edit project project1
```

This will allow you to edit the project definition and add the following value to the project metadata.

- **slack_webhook**: a valid webhook
- **slack_channel**: the name of the channel you want to use. The default is `#vamp-notifications`

This will allow Vamp Kubist to send notifications to the specified Slack channel.

## Filtering notifications

Vmap Kubist allows users to specify notificaiton filters that let through only certain notifications, filtering out all the others.

### Notification levels

All notifications have an associated level.
Notifications levels are no different from logging levels and theya re:

- ERROR
- WARNING
- INFO
- DEBUG
- TRACE

In a standard Vamp Kubist installation the default notification level is set to  INFO.

### Configuring notification filters

As explained in the [executors and policies](EXECUTORS_AND_POLICIES.md) section, it is possible to specify extra parameters for each policy and executor when creating a new entity like a canary release or experiment.
This also allows for configuring notifications filtering.
Available parameters are:

- disable_notifications:    disables all notifications if set to true.
- min_notify_level:         specifyies the minimum logging level allowed. 
- allow_notify_{level}:     will allow notifications for the given level on the provided comma separated list of notifier names.
                            Specifying "all" instead of the list will allow notifications for all notifiers.
- allow_notify_all:         will allow notifications for all levels on the list of notifiers.
                            Specifying "all" instead of the list will allow notifications for all notifiers.


Th available notifiers name are currently:

- User:     handling client and desktop notifications
- Log:      handling logging of notifications
- Slack:    handling slack notifications

The notification configuration parameters can be combined with each other to achieve more complex filtering, as shown in the example configuration below.

```yaml
policies:
  - name: SomePolicy1
    parameters:
      disable_notifications: "true"
      allow_notify_info: slack
      allow_notify_warning": slack
      allow_notify_error": slack,user
```

This configuration will disable all notifications.
It will then allow info and warning level notifications on slack and errors on slack and desktop.


### Configuring global notification filters

Lastly, Vamp Kubist also supports specifying global notification filters for all executors or policies of a certain type.
This is currently only doable by changing the values in Kubist application.conf, but it will soon be possible to achieve the same result through the API.
Below you can find a configuration example.

```
executors {

        ReadOnlyVirtualClusterPolicyExecutor {
          v1 {
            implementation: io.vamp.policies.executors.impl.ReadOnlyVirtualClusterPolicyExecutor
            default-parameters: {
                disable_notifications: "true"
                allow_notify_info: "slack"
                allow_notify_warning: "slack"
                allow_notify_error: "slack,user"
          }
        }
      
  }

}
```

As you can see the configuration is identical to what was specified on the invidual policy in the previous example.
Note that the same configuration can be applied both on policies and executors.
