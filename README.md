# Monitoring Logs and Server in Grafana

## Download nssm.exe
We will install Prometheus, Loki, Promtail as a Windows Service, then you need to download nssm.exe in [here](https://nssm.cc/download)

## Install Windows Exporter
We will install Windows exporter you can download in [here](https://github.com/prometheus-community/windows_exporter/releases/tag/v0.22.0) for example I'm download `windows_exporter-0.22.0-amd64.msi`. Then you move to `C:\Program Files\Windows Exporter`
Open Command Promt (CMD)
```bash
# We need to enabled some metrics to the installer
msiexec /i "C:\Program Files\Windows Exporter\windows_exporter.msi" LISTEN_PORT=9182 ENABLED_COLLECTORS=ad,adcs,adfs,cache,cpu,cpu_info,cs,container,dfsr,dhcp,dns,exchange,fsrmquota,hyperv,iis,logical_disk,logon,memory,msmq,mssql,netframework_clrexceptions,netframework_clrinterop,netframework_clrjit,netframework_clrloading,netframework_clrlocksandthreads,netframework_clrmemory,netframework_clrremoting,netframework_clrsecurity,net,os,process,remote_fx,service,smtp,tcp,time,thermalzone,terminal_services,vmware TEXTFILE_DIR="C:\custom_metrics"
```
![image](https://user-images.githubusercontent.com/64786139/250080033-d2b15ee3-9438-4344-a75e-7ec890aaf64d.png)

Then you install node exporter, by clicking the installer!
Open http://localhost:9182

![image](https://user-images.githubusercontent.com/64786139/250079942-b712b70d-bca0-4908-a8ed-fd2a1ffdb421.png)

## Install Prometheus
You need to download Prometheus in [here](https://github.com/prometheus/prometheus/releases/tag/v2.45.0) for example I'm download `prometheus-2.45.0.windows-amd64.zip` then extract the file. Then move to `C:\Program Files\prometheus-2.45.0`

### Edit config of prometheus `prometheus.yml`
```yaml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "wmi_exporter"
    
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    scrape_interval: 1s
    static_configs:
      - targets: ["localhost:9182"]
```

### Running Prometheus as Windows Service
Open Command Promt (CMD), and pointing to your nssm.exe directory
```cmd
nssm.exe install prometheus "C:\Program Files\prometheus-2.45.0\prometheus.exe"
sc start prometheus
```

![image](https://user-images.githubusercontent.com/64786139/250080158-52d60261-68e0-4d81-ac3c-16ba0432b69c.png)

Open http://localhost:9090

![image](https://user-images.githubusercontent.com/64786139/250080244-297a993d-9d69-436b-b2da-4c635bd633bd.png)

## Install Grafana
Donwload Grafana in [here](https://grafana.com/grafana/download?platform=windows), for this case I install Edition OSS and version 10.0.1

![image](https://user-images.githubusercontent.com/64786139/250080839-0421d26a-1585-4b1f-bac3-616f3f79f6f4.png)

</br> Open http://localhost:3000, and username = admin, password = admin

![image](https://user-images.githubusercontent.com/64786139/250080388-569e8644-5392-41d7-9cdb-760e78f70c4b.png)

## Install Promtail
Download Promtail in [here](https://github.com/grafana/loki/releases), for this case I used `promtail-windows-amd64.exe.zip`.
Extract the file and moved to `C:\Program Files\Grafana Loki\promtail_v2.8.2`

### Create config `config.yaml` file for promtail
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0
positions:
  filename: c:/promtail/positions.yaml
clients:
  - url: http://localhost:3100/loki/api/v1/push
scrape_configs:
- job_name: windows_event_camstar
  windows_events:
    use_incoming_timestamp: false
    bookmark_path: "./bookmark.xml"
    eventlog_name: "Camstar"
    xpath_query: '*'
    labels:
      job: camstar
  relabel_configs:
    - source_labels: ['computer']
      target_label: 'host'
      
- job_name: system
  pipeline_stages:
  
  - output:
      source: message
      action_on_failure: skip
   
  static_configs:
  - targets:
      - localhost
    labels:
      job: iislogs
      agent: promtail
      __path__: c:/inetpub/logs/logfiles/*/*
```

### Running Promtail as a Windows Service
Open Command Promt (CMD), and pointing to your nssm.exe directory
```bash
nssm.exe install promtail "C:\Program Files\Grafana Loki\promtail_v2.8.2\promtail-windows-amd64.exe" --config.file=config.yaml
nssm.exe set promtail AppDirectory "C:\Program Files\Grafana Loki\promtail_v2.8.2"
sc start promtail

# or if you don't want to install as a windows service
cd C:\Program Files\Grafana Loki\promtail_v2.8.2
.\promtail-windows-amd64.exe --config.file=config.yaml
```

![image](https://user-images.githubusercontent.com/64786139/250080451-0b115ffa-5128-4c66-92e1-18e520d5942c.png)

Open http://localhost:9080

![image](https://user-images.githubusercontent.com/64786139/250080510-0ea23be6-804d-421b-9337-3ef5fa5b3f46.png)


## Install Grafana Loki
Download Loki in [here](https://github.com/grafana/loki/releases), for this case I used `loki-windows-amd64.exe.zip`.
Extract the file and moved to `C:\Program Files\Grafana Loki\loki_v2.8.2`.

### Create config `config.yaml` file for loki
```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

ingester:
  wal:
    enabled: true
    dir: /tmp/wal
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h       # Any chunk not receiving new logs in this time will be flushed
  max_chunk_age: 1h           # All chunks will be flushed when they hit this age, default is 1h
  chunk_target_size: 1048576  # Loki will attempt to build chunks up to 1.5MB, flushing first if chunk_idle_period or max_chunk_age is reached first
  chunk_retain_period: 30s    # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
  max_transfer_retries: 0     # Chunk transfers disabled

schema_config:
  configs:
    - from: 2020-12-22
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    cache_ttl: 24h         # Can be increased for faster performance over longer query periods, uses more disk space
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

compactor:
  working_directory: /tmp/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s

ruler:
  storage:
    type: local
    local:
      directory: /tmp/loki/rules
  rule_path: /tmp/loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
```

### Running Loki as a Windows Service
Open Command Promt (CMD), and pointing to your nssm.exe directory
```bash
nssm.exe install loki "C:\Program Files\Grafana Loki\loki_v2.8.2\loki-windows-amd64.exe" --config.file=config.yaml
nssm.exe set loki AppDirectory "C:\Program Files\Grafana Loki\loki_v2.8.2"
sc start loki

# or if you don't want to install as a windows service
cd C:\Program Files\Grafana Loki\loki_v2.8.2
.\loki-windows-amd64.exe --config.file=config.yaml
```

![image](https://user-images.githubusercontent.com/64786139/250080677-ed184d32-0d7a-4cde-b650-aaf630c72cf9.png)

Open http://localhost:3100/ready

![image](https://user-images.githubusercontent.com/64786139/250080641-c8736d08-9f62-41a7-9333-88d874103dbb.png)


## Visualized your data in Grafana
### Show the Windows Exporter
Add Data Source in `Home > Connections > Data Source > Add New Data Source > Prometheus > <Put your config> > Save and Test`
Then we can setup Dashboard Windows Exporter using [this](https://grafana.com/grafana/dashboards/14694-windows-exporter-dashboard/)

![image](https://user-images.githubusercontent.com/64786139/250079778-2075de0a-6dc4-4dc3-b352-21b623831ba1.png)


### Show Windows IIS log and Windows Event Viewer
Add Data Source in `Home > Connections > Data Source > Add New Data Source > Loki > Put your config > Save and Test`
Then Try with `Home > Explore > Loki`

![image](https://user-images.githubusercontent.com/64786139/250079698-e41ecea1-5719-486e-b4a0-2296ce45922c.png)

# Create AlertManager from Prometheus
Now we will create some alert to notify if something happens

## Create some Prometheus Rules
### Create file prometheus rule
Create file called `prometheus_rules.yml`
```yaml
groups:
  - name: custom_rules
    rules:
      - record: cpu_usage_of_wmi_exporter
        expr: 100 - (avg by (instance) (irate(windows_cpu_time_total{mode="idle"}[1m])) * 100)
      - record: memory_usage_of_wmi_exporter
        expr: (windows_cs_physical_memory_bytes - windows_os_physical_memory_free_bytes) / windows_cs_physical_memory_bytes * 100
  - name: alert_rules
    rules:
      - alert: instance_down
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance [{{ $labels.instance }}] down"
          description: "[{{ $labels.instance }}] of job [{{ $labels.job }}] has been down for more than 1 minute."
      - alert: memory_greater_than_equal_70
        expr: memory_usage_of_wmi_exporter >= 70
        labels:
          severity: warning
        annotations:
          summary: "Instance [{{ $labels.instance }}] has 70% usage of memory"
          description: "[{{ $labels.instance }}] has use {{ $value }}% usage of memory."
      - alert: cpu_greater_than_equal_70
        expr: cpu_usage_of_wmi_exporter >= 70
        labels:
          severity: warning
        annotations:
          summary: "Instance [{{ $labels.instance }}] has 70% usage of cpu"
          description: "[{{ $labels.instance }}] has use {{ $value }}% usage of cpu."
```
### Check the Rule
Open CMD, and verify your rule whether correct or not
```bash
cd C:\Program Files\prometheus-2.45.0
.\promtool.exe check rules prometheus_rules.yml
```
After checking success, we need to tell prometheus about rules, and enable the alertmanager which later will be installed

### Mofify `prometheus.yml`
```yaml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "prometheus_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "wmi_exporter"
    
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    scrape_interval: 1s
    static_configs:
      - targets: ["localhost:9182"]
  - job_name: "loki_metrics"
    
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    scrape_interval: 1s
    static_configs:
      - targets: ["localhost:3100"]
  - job_name: "grafana_metrics"
    
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    scrape_interval: 1s
    static_configs:
      - targets: ["localhost:3000"]
  - job_name: "promtail_metrics"
    
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    scrape_interval: 1s
    static_configs:
      - targets: ["localhost:9080"]
  - job_name: "alertmanagers_metrics"
    
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    scrape_interval: 1s
    static_configs:
      - targets: ["localhost:9093"]
```
Then Restart the Prometheus Service, now we can see the rules and alert being created.
![image](https://user-images.githubusercontent.com/64786139/250147141-039573ca-2539-4c49-81bd-f4dbeeffbb1e.png)
![image](https://user-images.githubusercontent.com/64786139/250147201-3ac6b192-3abf-466d-90f7-60c4cf4f5a91.png)

## Install the Alertmanager prometheus
You can download alertmanager in [here](https://prometheus.io/download/), for example I used `alertmanager-0.25.0.windows-amd64.zip`.
Extract the file and move to C, for example `C:\Program Files\alertmanager-0.25.0`

### Edit configuration of `alertmanager.yml`
Now we will configure to send alert of email notification to SMTP Gmail
```yaml
global:
  resolve_timeout: 5m
  
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 1m
  repeat_interval: 1m
  receiver: 'email'
receivers:
  - name: 'email'
    email_configs:
    - send_resolved: true
      to: 'jack@gmail.com'
      from: 'abc@gmail.com'
      smarthost: smtp.gmail.com:587
      auth_username: 'abc@gmail.com'
      auth_identity: 'abc@gmail.com'
      auth_password: 'the password sender'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```
### Check the alertmanager
Check whether configuration is correct or not
```bash
cd C:\Program Files\alertmanager-0.25.0
.\amtool.exe check-config alertmanager.yml
```

### Install the Alertmanager
Pointing to the nssm folder, then we install alertmanager as a service
```bash
nssm.exe install alertmanager "C:\Program Files\alertmanager-0.25.0\alertmanager.exe" --config.file=alertmanager.yml
nssm.exe set alertmanager AppDirectory "C:\Program Files\alertmanager-0.25.0"
sc start alertmanager
```
## Test the Alert

Try to shutdown the windows exporter
![image](https://user-images.githubusercontent.com/64786139/250148497-631894e6-2edf-4006-9c04-589557a5cb7e.png)

you should see the message on email, something like this
![image](https://user-images.githubusercontent.com/64786139/250148629-2aaee36e-9c33-49f3-add3-98a3a6b51ef6.png)
