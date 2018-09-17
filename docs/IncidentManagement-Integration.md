# Integrating with an incident management system

This is the rocket fuel for HealOps. Integrating with an incident management system is what takes HealOps all the way to a fully autoamted framework for monitoring, repairing and providing stats for an IT system and its components.
By using an incident management system like e.g. [OpsGenie](https://www.opsgenie.com/) you can automatically have the on-call personnel responsible for an IT system contacted and working on an issue. However, only after HealOps has tried to repair a failed state of your IT system or one of its components.

Get started by configuring an alert in your metrics visualization system. For a helping hand on how-to do this with Grafana go [here](Grafana-ConfigurationAndSetup.md#configuring-an-alert). When that is done find yourself an incident management. Here is a list of the ones I have tested.

* OpsGenie (URI already provided above)
* [PagerDuty](https://www.pagerduty.com/)
* [VictorOps](https://victorops.com/)

They all work with Grafana. They have the same core features. So try them out via a trial and decide from there.

## Configuration tips

When you have landed on the incident management system you want to use. What is left is to:

* add users to the incident management system.
        * allow people to decide how they want to be contacted.
* add an on-call schedule.
* set system priorities.

## The cheap incident alerting solution (but still worth it :-)

If you can't or don't want to pay the price for a professional incident management system you can have the metrics visualization system alert by e-mail, Slack (which you might already be using) or Telegram. Or optionally use the webhook option and then development a receiving system that does xyz to the alert. In order to get your on-call personnel on a raised alert.

Click on [Grafana webhook documentation](http://docs.grafana.org/alerting/notifications/#webhook) for an example on webhooks in `Grafana`, for inspiration and is likely available in a similar way in other metric visualization systems.