# Yocto for Beaglebone Black Development board

## Build
### Host requirments:
- Host version from ubuntu 20.04 or later
- Installed `docker` with `docker-compose` plugin
- Installed `repo` tool
## Run
- Run `repo init .` command.
- Run `repo sync`
- Run `docker-compose build` to build docker image to prepare for build
- Run `docker-compose run bitbake console-image` to build bbb image