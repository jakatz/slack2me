# Slack2Me - Cater2.me Slack Integration

Simple express server that handles `/lunch` and `/lunch tomorrow` commands from Slack, returning a Cater2.me menu

## Usage

Drop a Slack Incoming Webhook URL in [here](index.coffee#L31), and then:

```
# starts a server on port 4567
coffee index.coffee
```

Setup a Slack Outgoing Webhook to POST to the above port, e.g. `/lunch`.

ex:
![Screenshot](https://raw.githubusercontent.com/mmissey/slack2me/master/img/slack2meSS.png)