# Grafana - Setup and configuration

## Visualizing metrics with Grafana

Grafana is a open source system, making it possible to display metrics data in a visually intriguing and efficient way. Done right, it can be of high value in troubleshooting situations. Or when in need of data for deciding where to use resources when performance optimizing.

Read more on `Grafana` in the official [documentation](http://docs.grafana.org/).

## Configuring your first Grafana dashboard

1. Login to `Grafana`. By opening a browser in order to go to the URI of `Grafana?`.
2. Setup a data source. Which is from where `Grafana` will pull metrics.
    2. See [this site](http://docs.grafana.org/guides/getting_started/#how-to-add-a-data-source) for a helping hand on this.
3. Then read the rest of the [beginners guide](http://docs.grafana.org/guides/getting_started/#beginner-guides) in order to get going in a breeze.
    3. Especially this [video](https://www.youtube.com/watch?v=sKNZMtoSHN4) is informative and helpful in explaining how-to create a dashboard in `Grafana`.

There is great inspiration available if you go to the [dashboard website](https://grafana.com/dashboards) `Grafana` provides. You really should :-). Also, the dashboard can be downloaded and used on your `Grafana` setup and customized to your needs.

## Configuring an alert

1. Login to `Grafana`. By opening a browser in order to go to the URI of `Grafana?`.
2. Find the graph onto which you want to attach an alarm.
3. Go to the `Grafana` [alerting documentation](http://docs.grafana.org/alerting/rules/) in order to read up on how-to configure alarm rules and the ideas behind it.