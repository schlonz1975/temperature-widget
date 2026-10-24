# Hardware Temps & Fans (KDE Plasma 6 plasmoid)

Temperatures and fan speeds on the desktop or in a panel. Sources:

- **hwmon** (`/sys/class/hwmon`): every `temp*_input` / `fan*_input`, e.g. `k10temp`, `nct6779`, `it87`, `nvme`
- **nvidia-smi**: GPU temperature, fan %, load %, power (W)

Tested target: Nobara 44, Plasma 6.7, Wayland, Ryzen 5 5500 + RTX 3060.

## Install

```bash
./install.sh            # install or update (kpackagetool6)
./install.sh test       # run in a standalone window (plasmawindowed)
./install.sh restart    # restart plasmashell if the widget looks stale
./install.sh uninstall
```

Then right-click desktop or panel, Add Widgets, **Hardware Temps & Fans**.
Requires `kpackagetool6` (kf6-kpackage) and, for GPU values, the NVIDIA driver's `nvidia-smi`.

## Configure (right-click, Configure)

| Page | Options |
|------|---------|
| Sensors | Tick sensors to show, rename, reorder. Values update live. |
| Display | Numbers only / graphics only / both; gauges or sparklines; small / medium / large; columns; update interval; sparkline length; °C/°F; warm/hot thresholds; fan gauge max; frame; card opacity |
| Colors | Follow Plasma theme (default), Nord, Dracula, Gruvbox, Cyberpunk, Monochrome, or Custom (6 colors) |

Temperature colors blend cool, warm, hot around the thresholds. Fans, load and power use the accent color.
"Graphics only" gauges show no number; hover for a tooltip with the value.

In a panel the widget shows compact colored values; click to open the full view.

## Notes

- Sensors are identified by chip name + channel (`h:nct6779:fan2`), not `hwmonN`, so selection survives reboots. Two chips with the same name (e.g. two NVMe drives) collide.
- Super-I/O chips expose many unused channels reading 0 or constants. Fan header names are chip-specific; find yours by watching values on the Sensors page.
- `nvidia-smi` is only run when a GPU sensor is selected. The RTX 3060 fan reports 0 % when idle (zero-RPM mode).
- Polling runs one shell command through Plasma's `executable` data engine; no daemon or root needed.

## Layout

```
package/
  metadata.json
  contents/config/{main.xml,config.qml}
  contents/code/sensors.js     command, parsing, colors
  contents/ui/{main,SensorCard,Config*}.qml
install.sh
```

## License

MIT, see [LICENSE](LICENSE). Use at your own risk, no warranty.
