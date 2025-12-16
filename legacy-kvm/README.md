# Supermicro KVM

A Docker-based web interface for accessing legacy Supermicro IPMI KVM consoles through your browser using noVNC.

## Overview

This project is **specifically designed to connect to old KVM systems** (particularly those using Java applets) that are no longer compatible with modern browsers.

The container runs a virtualized X11 environment with an older Chromium browser and Java 7 plugin inside a noVNC session. This allows you to access legacy IPMI KVM consoles that require Java applets through any modern web browser, without needing to install Java plugins or maintain an old operating system on your local machine.

### Why This Solution?

Modern browsers have removed support for Java applets and NPAPI plugins, making it impossible to access older Supermicro IPMI interfaces that rely on Java-based KVM viewers. This containerized solution provides:
- A sandboxed environment with legacy Java support
- Access through noVNC from any modern browser
- No need to maintain an old Windows/Linux VM or dual-boot setup

## Features

- **Legacy Java applet support** - Access old KVM systems that require Java plugins
- Browser-based VNC access via noVNC - No Java plugin required on your local machine
- Containerized environment with Ubuntu 14.04 and Java 7 for maximum compatibility
- Easy deployment with Docker Compose
- Supports ISO mounting for virtual media
- Customizable display resolution

## Project Structure

```
supermicro-kvm/
├── docker-compose.yml    # Docker Compose configuration
├── src/                  # Source files for building the container
│   ├── Dockerfile        # Container image definition
│   ├── supervisord.conf  # Process management configuration
│   └── novnc.tar.bz2    # noVNC web client
├── images/               # ISO files storage (for KVM virtual media)
│   └── *.iso            # Place your ISO files here
├── .gitignore
└── README.md
```

## Prerequisites

- Docker
- Docker Compose

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd supermicro-kvm
```

2. Build and start the container:
```bash
docker-compose up -d
```

## Usage

### Accessing the KVM Interface

Once the container is running, open your web browser and navigate to:

```
http://localhost:8080
```

You should see a noVNC interface with a Chromium browser running inside. Use this browser to navigate to your Supermicro IPMI interface.

### Using ISO Files

You can place ISO files in the `images/` directory to make them available for virtual media mounting:

1. Copy your ISO files to the `images/` folder:
```bash
cp /path/to/your/installation.iso images/
```

2. The ISO files will be accessible inside the container at `/root/images/`

3. Use the IPMI virtual media interface to mount these ISOs for remote installation or recovery operations

Note: ISO files are automatically ignored by git (see `.gitignore`) to prevent committing large files to the repository.

## Configuration

### Display Resolution

The default resolution is set to 1024x768x24. To change it, modify the `RES` environment variable in `src/Dockerfile`:

```dockerfile
ENV RES 1920x1080x24
```

Then rebuild the container:
```bash
docker-compose up -d --build
```

### Port Configuration

The default port is 8080. To change it, modify the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "8080:8080"  # Change the first port number (host port)
```

## Technical Details

This image is **specifically designed for legacy KVM access** using old Java applet technology. The container provides a complete legacy browser environment accessible via noVNC.

### Components:
- **Ubuntu 14.04 base** - Older OS version for compatibility with legacy software
- **Java 7 (IcedTea plugin)** - NPAPI plugin support for Java applets (removed from modern browsers)
- **Chromium browser** - Older version with Java plugin support enabled
- **Xvfb** (X Virtual Framebuffer) - Virtual display server
- **x11vnc** - VNC server to expose the virtual display
- **noVNC** - Browser-based VNC client for accessing the environment from modern browsers
- **Fluxbox** - Lightweight window manager
- **Supervisor** - Process management

### How It Works:
1. You access the noVNC web interface from your modern browser (http://localhost:8080)
2. noVNC connects to the x11vnc server inside the container
3. Inside the container, a legacy Chromium browser with Java 7 plugin runs
4. This legacy browser can access old IPMI KVM interfaces that require Java applets
5. You control everything through your modern browser without installing any plugins locally

## Troubleshooting

### Container won't start
Check the logs:
```bash
docker-compose logs
```

### Can't access the web interface
Ensure the container is running:
```bash
docker-compose ps
```

Verify port 8080 is not in use by another application:
```bash
netstat -tuln | grep 8080
```

### IPMI console issues
Some Supermicro IPMI versions may require specific Java versions or browser configurations. The container includes Java 7 with relaxed security settings to maximize compatibility.

## Development

To rebuild the container after making changes:

```bash
docker-compose down
docker-compose up -d --build
```

## Security Considerations

This container is designed for use in trusted networks or as a jump host. It includes:
- Chromium running with `--no-sandbox` for compatibility
- Relaxed Java security settings for IPMI compatibility
- VNC without authentication (protected by Docker networking)

For production use, consider:
- Running behind a reverse proxy with authentication
- Using VPN or SSH tunneling for remote access
- Implementing network-level access controls

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file in the repository root for details.

Copyright (c) 2025 Serhii Nesterenko

## Contributing

Contributions are welcome. Please submit pull requests or open issues for bugs and feature requests.
