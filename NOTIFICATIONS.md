# Notificaitons

Vmap Kubist support slack notifications of various events such as resources update and deletion or a canary release progress.
In order to access this feature it is necessary to configure slack access for given project or cluster.
Doing this is traightforward.
Supposing you have a project named project1 you can run

```shell
vamp edit project project1
```

This will allow you to edit the project definition and add the following value to the project metadata.

- **slack_webhook**: a valid webhook
- **slack_channel**: the name of the channel you want to use. The default is `#vamp-notifications`

This will allow Vamp Kubist to send notifications to the specified Slack channel.
