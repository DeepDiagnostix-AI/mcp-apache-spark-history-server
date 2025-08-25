# Troubleshooting Guide

## Tools on Large Spark Application Timing Out

Certain tools may timeout based on the size of the Spark application. For large Spark applications that process Gigabytes and Terabytes of data, an increase in timeout and java heap size may need to be applied in order for the tool to have enough time and space to produce an output.

**For example**:
The `compare_job_performance` tool can be slow for large applications.

>`Error calling MCP tool: MCP error -32001: Request timed out`

Apply the following changes to resolve this:

### 1. MCP Client Timeouts

**Problem:**
- MCP Client itself (Q CLI, Kiro, ETC) has its own timeout configuration that can be adjusted.

**Solution:**
Update the `timeout` value in your MCP client configuration (e.g., `mcp.json`):

```json
"spark-history-server": {
  "command": "uv",
  "args": [
    "run",
    "-m",
    "spark_history_mcp.core.main",
    "--frozen"
  ],
  "env": {
    "SHS_MCP_TRANSPORT": "stdio"
  },
  "disabled": false,
  "autoApprove": [],
  "timeout": 300000 <--- Update here
}
```

**Note:** Format depends on client of choice.

### 2: MCP Server Timeouts

**Symptoms:**
- `HTTPConnectionPool(host='localhost', port=18080): Read timed out. (read timeout=30)`
- Server-side timeout errors

**Solution:**
Set the server timeout environment variable:

```json
"spark-history-server": {
  "command": "uv",
  "args": [
    "run",
    "-m",
    "spark_history_mcp.core.main",
    "--frozen"
  ],
  "env": {
    "SHS_MCP_TRANSPORT": "stdio",
    "SHS_SERVERS_LOCAL_TIMEOUT": "180" <-- Set this value in seconds
  },
  "disabled": false,
  "autoApprove": [],
  "timeout": 300000
}
```

**Note:** SHS_SERVERS_<Replace with server name in config.yaml>_TIMEOUT

### 3: JVM Heap Exhaustion

**Symptoms:**
- `HTTP ERROR 500 org.sparkproject.guava.util.concurrent.ExecutionError: java.lang.OutOfMemoryError: Java heap space`
- Browser shows 500 error when accessing Spark History Server URLs
- Tool fails with memory-related errors

**Root Cause:**
Spark History Server parses entire Spark event logs (JSON or Snappy-compressed JSON) into memory. For large jobs (many tasks, long-running, heavy shuffle), the log can be hundreds of MBs to multiple GBs.

**Example Error:**
```
HTTP ERROR 500 org.sparkproject.guava.util.concurrent.ExecutionError: java.lang.OutOfMemoryError: Java heap space
URI:    /history/application_id1/jobs/
STATUS: 500
MESSAGE:    org.sparkproject.guava.util.concurrent.ExecutionError: java.lang.OutOfMemoryError: Java heap space
SERVLET:    org.apache.spark.deploy.history.HistoryServer$$anon$1-5fc930f0
CAUSED BY:  org.sparkproject.guava.util.concurrent.ExecutionError: java.lang.OutOfMemoryError: Java heap space
CAUSED BY:  java.lang.OutOfMemoryError: Java heap space
```

**Solution:**
Increase the Spark daemon memory before starting the History Server:

```bash
export SPARK_DAEMON_MEMORY=4g
```

Then restart your Spark History Server.

#### Quick Diagnosis

1. **Check browser first**: Navigate to `http://localhost:18080/history/application_<app_id>/jobs/`
   - If you see HTTP 500 with "OutOfMemoryError" → Problem 3 (increase SPARK_DAEMON_MEMORY)
   - If page loads normally → Problem 1 or 2 (increase timeouts)

2. **Check error message**:
   - `MCP error -32001: Request timed out` → Problem 1 (MCP client timeout)
   - `Read timed out. (read timeout=30)` → Problem 2 (MCP server timeout)
   - `OutOfMemoryError` or `Java heap space` → Problem 3 (JVM heap)
