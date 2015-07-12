# Reproducible Selenium setup for use with fakechroot

The aim of this project is creating a configuration where Selenium
can be run for several browsers and will behave *exactly* as it does
when using the
[selenium images](https://registry.hub.docker.com/repos/selenium/)
for Docker, i.e. will produce bit for bit the same screenshots and so on.

The current idea is to leverage `fakechroot` to achieve this.
A long-term goal is making this work in Travis CI,
and not to rely on `sudo` for doing so.

As of this writing, the aim has not been reached yet, so the project
isn't usable at the moment. If you want to make it work, feel free to
contribute, e.g. by working towards resolving one of the
[current issues](https://github.com/gagern/selenium-chroot/issues).

## License

This project is subject to the [MIT license](LICENSE).
But note that this only refers to the collection of tools
used to turn the official Selenium Docker images
into something that works in a chroot-like setup.
The content of these images is *not* subject to that license,
so neither is the resulting tarball.
