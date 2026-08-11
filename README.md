# Arcata

Containerized [Dedicated Servers](https://wiki.warframe.com/w/Dedicated_Servers) for [Warframe](https://www.warframe.com/en)'s [Conclave](https://wiki.warframe.com/w/Conclave).
It runs Warframe in a Debian container using [Proton](https://github.com/ValveSoftware/Proton) with [UMU](https://github.com/Open-Wine-Components/umu-launcher).

This way, the servers can be deployed on any device capable of running OCI containers, regardless of operating system.
It also includes a simplified configuration setup to easily spin up multiple instances and game modes.

> [!NOTE]
> Arcata is in no way affiliated with Digital Extremes or Warframe.

## Usage

To use Arcata, you'll need a contianer runtime.
The most popular ones include [Podman](https://podman.io/) and [Docker](https://www.docker.com/).

Spin up a Docker container using the basic setup described in the [`compose.yaml`](./compose.yaml).

I recommend running the containers in Host-Network mode and enable UPnP on your router to simplify port handling.
Otherwise, you can manually forward your server ports, more details on that below.
Make sure you create the two directories bound to `~/.wine/pfx` and `~/.local/share/Steam/compatibilitytools.d` in you bind them to your host to avoid permission errors; no special setup should be required when using Docker volumes.

You'll need around 50 Gigs of free storage, as the container requires a full Warframe installation.
Dont worry though, it will do essentially everything for you, all you need to do is wait awhile during the first time.

You'll also need to mount an `arcata.yaml` into `/opt/arcata/arcata.yaml` to configure the servers you want to run, as described below.

Once the container is up and running, you can connect to it via [VNC](https://en.wikipedia.org/wiki/VNC) as configured in `VNC_PORT` and `VNC_PASSWORD` to view and interact with the container's virtual display.

### Configuration

The container itself is configured via environment variables, while the dedicated servers are configured via `/opt/arcata/arcata.yaml`.
The file is fairly straight forward and simplifies the setup described on the [Warframe Wiki](https://wiki.warframe.com/w/Dedicated_Servers#Server_Settings_Properties) while staying true to its keys.

A typical `arcata.yaml` will look something like this:

```yaml
# Setting this will attribute your account to the servers.
# This way, they might eventually end up on https://api.warframe.com/cdn/dedServerStats.php
# Leave empty to host anonymously (which is the default when unset)
email: tenno@warframe.com

# This list contains your seperate dedicated server settings
# You must set at least one config.
servers:
  - name: EveryoneLovesLunaro # An arbitrary name for your config. Should be purely [A-Za-z] with no spaces, although I haven't tested it
    instances: 4 # The amount of instances to run for this config. Default is 1

    # The server properties to use, the names match the wiki.
    # Please consult it at https://wiki.warframe.com/w/Dedicated_Servers#Server_Settings_Properties
    settings:
      missionId: SB_Title
      motd: "Welcome to Lunaro, Tenno! Come play with us: lunaro.wf/discord"
      allowXPlatform: 1
      highBandwidth: 2

  # You can add as many configs as you like here (none of these are tested)

  - name: CephalonCaptureForNoobs
    settings:
      serverPort: 9999 # Manually forward this port on your router. Will likely cause issues with multiple instances
      missionId: CTF_Title
      eloRating: 0

  - name: OpticorMadness # Variant mode for https://wiki.warframe.com/w/Conclave#Annihilation
    instances: 2
    settings:
      missionId: DM_Title
      useAlternativePVPMode: 1
      matchmakingRegionOverride: NORTH_AMERICA
```

For completeness' sake, here's also a list of useful environment variables:

| Variable           | Effect                                                      | Default  |
| :----------------- | :---------------------------------------------------------- | :------- |
| `AUTO_ACCEPT_EULA` | Auto-accepts the Warframe EULA. See below for details       | `0`      |
| `VNC_PORT`         | Port to run the VNC server on                               | `5900`   |
| `VNC_PASSWORD`     | Password to use for VNC. Leave blank for no password prompt | `lunaro` |
| `TZ`               | Your IANA time zone, used for logs                          | `UTC`    |

### Warframe's EULA

Given the grey legality of auto-accepting a licence agreement on a human's behalf, auto-accepting is strictly opt-in.
Setting `AUTO_ACCEPT_EULA=1` in your environment will allow the container to automatically update today's and future EULAs.
I take no responsibility for any of your EULA violations, it is your decision to auto-accept.

If you do not want to auto-accept the EULA, you will have to connect to the container using VNC and manually click the `I AGREE` button on first startup and any time the EULA updates in the future.

## Roadmap

Arcata is in its early stages, and there's at least a few more things I'd like to implement.

- Hosting an image on GHCR
- Graceful shutdown when stopping the container (essentially pressing Q in the server windows)
- Healthchecks for the container
- Sync with https://conclave.gg (message me if you know anything about this)

## Contributing

Feel free to open issues an PRs on this project, as long as they're not about the roadmap I've listed above (unless the repo's been dead for like 6+ months).
You can also message me on Discord with questions or issues, you can find me as `quonnz` at https://lunaro.wf/discord

Please also feel free to help maintain the [Warframe Wiki page on Dedicated Servers](https://wiki.warframe.com/w/Dedicated_Servers)!
Any outdated information helps both this project and anyone else interested in Conclave.

