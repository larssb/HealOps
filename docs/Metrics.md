# Metrics

A metric is simply put a data point on a measured entity. Where the entity could be anything that can be polled or in itself gives an output. So something you can measure can be turned into a metric. To be more specific a metric has a value, a name and possibly some annotation tags to go along with it.
Metrics are always reported along with a timestamp. Making it possible to measure an entity over time. Every metric is stored in a database. A so called time-series database. A time-series database system, is optimized for storing time-series data which is exactly what a metric is.

## Specifics on metrics in regards to HealOps

- Metrics are generated whenever a Tests, Repairs or Stats file is executed.

### Guidelines

When generating metrics with HealOps ensure that:
- You give the metric a _name_
- That the metric has a _value_ and the type of that value is _int32_
- Add some tags to a metric. At least _one_. Adding tags makes it possible to slice and dice (drill down into) on the metrics data in the time-series database.
- Do not be overly specific when naming a metric. A metric named e.g. `mssqlserver.mysqlsrv1.cpu.1` is not a good way to go. Most time-series databases will have to store a data point for each reported metric. Resulting in extra use of storage and even more inconvenient, constraints on your drilling and dicing options on data.
    > Read more [here](http://opentsdb.net/docs/build/html/user_guide/writing/index.html) < the "Naming Schema" section.