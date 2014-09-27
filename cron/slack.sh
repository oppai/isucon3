#!/bin/bash
RESULT=`tail -n 1 /tmp/isucon.score  | cut -d' ' -f2`
RawScore=`tail -n 1 /tmp/isucon.score  | cut -d' ' -f5`
Fails=`tail -n 1 /tmp/isucon.score  | cut -d' ' -f7`
Score=`tail -n 1 /tmp/isucon.score  | cut -d' ' -f9`
HEAD=`cd /home/isucon/isucon3 && git rev-parse HEAD`

TEXT="HEAD-sha:%60$HEAD%60"
curl -X POST https://slack.com/api/chat.postMessage -d "channel=#ulix&text=$TEXT&username=ISUCON3-SCORE&token=xoxp-2500638381-2580872673-2623220604-daf2fd"

TEXT="Result:$RESULT%20%20RawScore:$RawScore%20%20Fails:$Fails%20%20Score:$Score"
curl -X POST https://slack.com/api/chat.postMessage -d "channel=#ulix&text=$TEXT&username=ISUCON3-SCORE&token=xoxp-2500638381-2580872673-2623220604-daf2fd"
