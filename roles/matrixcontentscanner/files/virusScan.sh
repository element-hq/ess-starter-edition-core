#!/bin/bash

# Copyright 2023-2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


res=`c-icap-client -i $ICAP_HOST -p $ICAP_PORT -s $ICAP_SVC -f $1 -v 2>&1`
if [[ $? -ne 0 ]]; then
	exit 1  # c-icap-client exited with error
fi

if [[ ! $(echo $res | grep "ICAP HEADERS") ]]; then
	exit 21  # c-icap-client did not receive an icap answer
fi

if [[ ! $(echo $res | grep -E "ICAP/[^ ]+ 2[0-9]{2} [a-zA-Z]+") ]]; then
	exit 22  # c-icap-client received an invalid status code
fi

if [[ $(echo $res | grep "$DETECTION_KEYWORD") ]]; then
	exit 30  # file is infected
fi

exit 0
