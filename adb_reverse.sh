#!/bin/bash
if adb reverse tcp:4455 tcp:4455; then
  echo 'Android should now be able to communicate with oathkeeper / unified api'
else
  echo 'There is no running android device. If you start one, please rerun this command'
fi
