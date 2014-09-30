AlarmDecoder
============

Redis backed utilities for sending and retrieving messages from an Ademco
Vista Alarm to Computer interface board (AD2USB / AD2SERIAL).

## Configuration

Configuration is done through the `AlarmDecoder.config` hash. Options are as
follows:

- `port`: Port for your alarm decoder. Usually something like `/dev/ttyUSB0`
- `baud`: Baud rate for the alarm decoder. Defaults to `8`
- `zones`: List of zone numbers and zone names. e.g.
    `{ 1 => "Front Door", 2 => "Back Door" }`

## Connecting to the alarm

AlarmDecoder uses redis's pub/sub functionality to pass messages between the
alarm decoder box and various services which act on the alarm. A redis server
will need to be running for the libary to work.

To start listening for messages, launch `bin/listen PORT` specifying the
appropriate port. For more options / help run `bin/listen -h`. This will need to
be run in the background for any message updates or writes to occur.

## Reading and writing messages

AlarmDecoder has two helper methods for reading and writing to the alarm. To
get status updates from the alarm use `AlarmDecoder.watch`. This method yields
the latest status message from the alarm:

```ruby
AlarmDecoder.watch do |status|
  puts "READY" if status["ready"] == true
end
```

The following states are reported and parsed:

- `ready`: Indicates if the panel is READY
- `armed_away`: Indicates if the panel is ARMED AWAY
- `armed_home`: Indicates if the panel is ARMED HOME
- `alarm_occurred`: Indicates that an alarm has occurred. This is sticky and
  will be cleared after a second disarm.
- `alarm_sounding`: Indicates that an alarm is currently sounding. This is
  cleared after the first disarm.
- `armed_instant`: Indicates that entry delay is off (ARMED INSTANT/MAX)
- `fire`: Indicates that there is a fire
- `zone_issue`: Indicates an issue with a zone
- `perimeter_only`: Indicates that the panel is only watching the perimeter
  (ARMED STAY/NIGHT)
- `zone_number`: This number specifies which zone is affected by the message
- `zone_name`: Optional human friendly name for the zone_number. See the
  Configuration section above for more details.

For additional information see the official protocol docs:

http://www.alarmdecoder.com/wiki/index.php/Protocol

To write messages to the panel use the `AlarmDecoder.write` method.

```ruby
AlarmDecoder.write("1234")
#=> Sends 1234 to the alarm panel
```

## Bonus executables!!

### bin/idle

Watches the display message for `Press * Key` and then sends the `*` key.
This ensures `zone_name` and `zone_number` always reflect which zone is
currently faulted.

### bin/console

Tiny console program for interacting with the alarm from the command line,
including sending a test alarm for exercising services built around AlarmDecoder

### bin/watch

Prints the parsed status updates from the alarm to `STDOUT`

### bin/notify

Sends notifications via Prowl / Mail when an alarm is triggered or zone is
faulted. Uses environment variables for configuration. See source code for more
details / usage information.

## License

Copyright (c) 2014 Jordan Byron

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
