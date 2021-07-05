# Monitor on-prem availability with Google Stackdriver

**By using `collectd` with `ping` running in GKE**

*Based on https://github.com/salrashid123/stackdriver_ping_plugin*

We wanted to monitor availability of on-prem hardware (things like firewalls, network switches and WiFi access points) using simple ping probes from inside GCP.

This article covers how to use an off the shelf [Ping Plugin](https://collectd.org/documentation/manpages/collectd.conf.5.shtml#plugin_ping) for `collectd` together with Google Cloud's logging and monitoring facilities to acquire and process latency statistics, with the ability to enable alerting when things go down.

## Custom ping module

As part of the Docker build process, we patch `ping.c` in the collectd source and build a custom module, which emits the ping statistics to `stdout` as JSON.

This allows custom log metrics to be created to ingest the data, while also keeping the data in Stackdriver Logging as a more solid audit log.