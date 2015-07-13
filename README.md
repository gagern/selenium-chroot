# Selenium-Chroot

**Reproducible Selenium setup for use with fakechroot.**

The aim of this project is creating a configuration where Selenium
can be run for several browsers and will behave *exactly* as it does
when using the
[selenium images](https://registry.hub.docker.com/repos/selenium/)
for Docker, i.e. will produce bit for bit the same screenshots and so on.
This can be used for regression tests, e.g. on Travis CI.
Since it builds on `fakechroot`, normal user privileges are sufficient,
and `sudo` is not required.

At the moment, only Firefox is supported.
Chrome will apparently require some more work.

## Usage

To use the project, download and extract the binary tarball
of a release of your choice.
It will extract to a directory of the same name,
which contains, among other things, a file called `run.sh`.

If that script is invoked with no arguments, it will simply launch
the Selenium server, returning the PID for the process that should
be terminated once the Selenium server is no longer needed.

If, on the other hand, the file is invoked with additional arguments,
those will be interpreted as a command which is to be run
while the Selenium server is running.
The server will get stopped automatically after that command completes.

## Building

Simply invoke `./build.sh` and it will build a `selenium-chroot.tar.gz`.

## License

This project is subject to the [MIT license](LICENSE).
But note that this only refers to the collection of tools
used to turn the official Selenium Docker images
into something that works in a chroot-like setup.
The content of these images is *not* subject to that license,
so neither is the resulting tarball.
