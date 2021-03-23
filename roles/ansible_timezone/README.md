# ansible_timezone
Sets up system timezone. Compatible with most OSes, even Alpine Linux.
Example how to configure timezone variable:

    timezone: "Europe/Berlin"

Look into /usr/share/zoneinfo for a list of available timezones.
Also works for Alpine but it always detects a change even if there isn't any.
