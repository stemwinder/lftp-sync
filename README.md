# lftp-sync
A simple interface for using lftp to mirror remote data structures based on file modification times.

## Setup
- Download or clone the repository to the instllation path of choice on the target machine.
- Copy `lftp-sync-defaults.cfg` to `lftp-sync.cfg` and add/change parameters
- Ensure the user issuing lftp-sync commands has write permissions to the installation and `lftp-output` directories
- Set execution permission on `lftp-sync.sh`

## Usage
Basic usage:

    ./lftp-sync.sh -s "/remote/source/path/" -t "/path/to/target"
With verbose logging, override date, and download limit:

    ./lftp-sync.sh -s "/remote/source/path/" -t "/path/to/target" -v 3 -o "2015-02-20" -d 5M

## Caveats
* The `lftp-sync.sh` command must currently be issued from its parent directory.
* All dates are converted to UTC before being used for input or output.
* Usage on OS X requires `greadlink` and `gdate` provided by Homebrew `coreutils`.
* Overriding the time spec from the command line will not produce an entry in `lftp-timestamps.log`.
* The override datetime provided at the command line will be passed to and translated by `date`
* Download and upload limits are passed directly to the `set net:limit-total-rate` lftp command and must conform to its format specifications. The default is bytes, but suffixes are supported (eg: 100K, 5M, ...)
* Stream and segment settings have aggressive default settings to enable fast transfer of many large files. The default settings will generate a maximum of ~150 total connections.

## To Do's
* ~~Detect OS X and use `gdate` and `greadlink` instead~~
* ~~Ability to run from any path location~~
* Add "dry run" lftp feature support
* Support for ssh keys
* Remove password from `lftp-output` logs
* Ability to specify logfile locations as arguments
* Support for more verbose argument names
* Support for non-time-based mirroring
* lftp `mirror` command argument passthrough from command line