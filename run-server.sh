#!/bin/bash
# Start server script
# Used as ResetScriptLevel1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/env.sh"

echo "[wfuzz] starting server"
"$GRIFFIN_PATH/bin/attaching_all_child" "$SCRIPT_DIR/start.sh" &

PID=$(jobs -p)

for i in {1..60}
do
    echo "Check server status ... $i"
    curl -s --fail -X POST http://default:@127.0.0.1:$PORT/query -d 'select 1' >/dev/null 2>/dev/null
    if [ "$?" == "0" ]; then
        echo "[wfuzz] server started"
        exit 0
    fi
    sleep 1
done

echo "[wfuzz] server start timeout"
kill $PID
wait $PID
exit 1
