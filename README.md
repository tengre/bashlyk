```
# $Id: README.md 884 2018-09-06 02:49:28+04:00 yds $
```

A tool for easy accumulation of recipes and code reuse. Depending on the purpose
of the code is divided into a number of separate libraries, which are connected
to the script by a special loader. This loader allows you to set conditions such
as directories for storing a configuration, log, etc.
ROBODOC is used to document the code. The EXAMPLE section is used not only for
showing examples, but also for generating tests

**liberr.sh:**
contains two types of error generation, for example:
```
[[ -f $filename ]] || error NoSuchFile throw -- $filename
throw on NoSuchFile "$filename1" "$filename2"
```
Error handling is based on access to the source code of the script, so its
capabilities directly in the command interpreter (interactive input) are limited

**libcfg.sh:**
Management of configuration data of various sources - files (including INI style)
and command line options

Example:
```
#create instance from CFG class
CFG cfg

# define CLI options and bind to the 'cfg' instance
cfg.bind.cli auth{a}: config{c}: source{s}:-- help{h} mode{m}: show-conf{C} show-data{d}

# if set --help (-h) option then show usage only
[[ $( cfg.getopt help ) ]] && usage_n_exit

# get value of the --config (-c) option to the variable $config
config=$( cfg.getopt config )

# set this value as source of the configuration data
cfg.storage.use $config

# load selected options from INI-style configuration file and combine with relevant CLI options.
# [!] CLI options with the same name have higher priority
 cfg.load                    \
                []auth,mode  \
            [show]conf,data  \
          [source]=

# check value of the option 'conf' from section 'show'
if [[ $( cfg.get [show]conf ) ]]; then
  echo "view current config:"
  # show configuration in the INI-style
  cfg.show
  exit 0
fi

# set new value for 'mode' options from global section
cfg.set []mode = demo # or cfg.set mode = demo

# set new option 'date' to the global section
cfg.set date = $( date -R )

# add new items to list of unique values
cfg.set [source] = $HOME
cfg.set [source] = /var/mail/$USER

# save updated configuration to the file $config
cfg.save

# or to "other file.ini"
cfg.save other file.ini

# destroy CFG object, free resources
cfg.free
```
**liblog.sh:**
a set of functions for controlling the output of the script messages

**libpid.sh:**
control of the processes, autoclean on exit
A set of functions for process control from shell scripts:
* create a PID file
* protection against restarting
* stop some processes of the specified command
* autoclean temporary resourcces on exit

**libmsg.sh:**
A set of functions for delivering messages from the script using various transports:
* X Window System Notification System
* e-mail
* write utility

**libnet.sh:**
at the moment manipulating IPv4 addresses - validation, iteration, etc.
Based on the sipcalc tool
