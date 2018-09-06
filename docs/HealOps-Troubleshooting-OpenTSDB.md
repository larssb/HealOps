# Troubleshooting OpenTSDB

OpenTSDB is a time-series database. It is a storage engine for metrics. OpenTSDB is the first time-series database supported by HealOps.

## Specific issues you might bump into

* Chunking needs to be enabled in the OpenTSDB config file. i.e.:

1. Open the conf file, it is located at e.g.
    1. /opt/opentsdb/opentsdb-"version"/src/opentsdb.conf
    2. Find the section named `# Enable chunking`
    3. Set these two:
        1. tsd.http.request.enable_chunked = true
        2. tsd.http.request.max_chunk = 4096

2. For the chunking config change to be picked you need to:
    2. Add --config= e.g.:
        ```
        /opt/opentsdb/opentsdb-${TSDB_VERSION}/build/tsdb tsd --config=/opt/opentsdb/opentsdb-${TSDB_VERSION}/src/opentsdb.conf --port=4242 --staticroot=/opt/opentsdb/opentsdb-${TSDB_VERSION}/build/staticroot --cachedir=/tmp --auto-metric
        ```

## Where to get info

* Find the official info [here][http://opentsdb.net/docs/build/html/index.html]{:.no-mark-external}

### Logs

Go to the "Logs" tab in the Web interface. Or view logs directly on the OpenTSDB Srv.

    _The logs tab_
    * Go to the URI of the OpenTSDB webinterface.
    * Click on the "Logs" tab in the top left corner.