#!/bin/bash
if nmcli radio wifi | grep -q "enabled"; then echo "true"; else echo "false"; fi
