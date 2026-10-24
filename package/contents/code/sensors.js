.pragma library

// One shell command prints every hwmon temp/fan input plus nvidia-smi values.
// hwmon line:  H|chip|tempN|label|raw     nvidia line: N|temp, fan%, util%, powerW
function command(includeNvidia) {
    var c = 'for d in /sys/class/hwmon/hwmon*; do n=$(cat "$d/name" 2>/dev/null); ' +
            'for f in "$d"/temp*_input "$d"/fan*_input; do [ -r "$f" ] || continue; ' +
            'b=${f##*/}; b=${b%_input}; l=$(cat "${f%_input}_label" 2>/dev/null); ' +
            'echo "H|$n|$b|$l|$(cat "$f" 2>/dev/null)"; done; done';
    if (includeNvidia) {
        c += '; nvidia-smi --query-gpu=temperature.gpu,fan.speed,utilization.gpu,power.draw ' +
             '--format=csv,noheader,nounits 2>/dev/null | head -n1 | sed "s/^/N|/"';
    }
    return c;
}

var NAMES = {
    "k10temp:Tctl": "CPU Temperature",
    "k10temp:Tdie": "CPU Die",
    "nvme:Composite": "NVMe SSD",
    "nct:SYSTIN": "Motherboard",
    "nct:CPUTIN": "CPU Socket",
    "nct:TSI0_TEMP": "CPU (AMD TSI)",
    "nct:SMBUSMASTER 0": "SMBus Master",
    "nct:PCH_CHIP_TEMP": "Chipset",
    "nct:PCH_CHIP_CPU_MAX_TEMP": "Chipset CPU Max",
    "nct:PCH_CPU_TEMP": "Chipset CPU",
    "nct:PCH_MCH_TEMP": "Chipset MCH",
    "nct:PCH_DIM0_TEMP": "Chipset DIMM0"
};

// Human-readable sensor name from chip, channel (temp1/fan2) and driver label.
function niceName(chip, base, label) {
    var key = (/^(nct|it8|w83)/.test(chip) ? "nct" : chip) + ":" + label;
    if (NAMES[key]) return NAMES[key];
    var m;
    if ((m = /^fan(\d+)$/.exec(base))) return "Fan " + m[1];
    if ((m = /^Tccd(\d+)$/.exec(label))) return "CPU Core Die " + m[1];
    if ((m = /^AUXTIN(\d+)$/.exec(label))) return "Aux Probe " + (parseInt(m[1]) + 1);
    if (chip === "nvme" && (m = /^Sensor (\d+)$/.exec(label))) return "NVMe SSD Sensor " + m[1];
    return friendly(chip) + " " + (label || base);
}

function friendly(chip) {
    if (chip === "k10temp" || chip === "coretemp") return "CPU";
    if (/^nvme/.test(chip)) return "NVMe";
    if (/^(nct|it8|w83)/.test(chip)) return "Board";
    if (chip === "amdgpu") return "AMD GPU";
    return chip;
}

var NV = {
    temp:  { kind: "temp", label: "GPU Temperature" },
    fan:   { kind: "pct",  label: "GPU Fan Speed" },
    util:  { kind: "pct",  label: "GPU Load" },
    power: { kind: "watt", label: "GPU Power" }
};

function kindOf(id) {
    if (id.indexOf("n:") === 0) return (NV[id.slice(2)] || { kind: "pct" }).kind;
    var parts = id.split(":");
    return (parts[2] || "").indexOf("fan") === 0 ? "fan" : "temp";
}

function defaultLabel(id) {
    if (id.indexOf("n:") === 0) return (NV[id.slice(2)] || { label: id }).label;
    var p = id.split(":");
    return niceName(p[1] || "?", p[2] || "", "");
}

// -> array of {id, kind, label, value}
function parse(out) {
    var res = [];
    var lines = out.split("\n");
    for (var i = 0; i < lines.length; ++i) {
        var f = lines[i].split("|");
        if (f[0] === "H" && f.length >= 5) {
            var raw = parseInt(f[4]);
            if (isNaN(raw)) continue;
            var isFan = f[2].indexOf("fan") === 0;
            res.push({
                id: "h:" + f[1] + ":" + f[2],
                kind: isFan ? "fan" : "temp",
                label: niceName(f[1], f[2], f[3]),
                raw: f[1] + " " + (f[3] || f[2]),
                value: isFan ? raw : raw / 1000
            });
        } else if (f[0] === "N" && f.length >= 2) {
            var v = f[1].split(",");
            var keys = ["temp", "fan", "util", "power"];
            for (var k = 0; k < keys.length && k < v.length; ++k) {
                var x = parseFloat(v[k]);
                if (isNaN(x)) continue;
                res.push({ id: "n:" + keys[k], kind: NV[keys[k]].kind, label: NV[keys[k]].label, value: x });
            }
        }
    }
    return res;
}

function lerp(a, b, t) {
    t = Math.max(0, Math.min(1, t));
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
}

// temps blend cool -> warm -> hot; everything else uses the accent color
function severityColor(kind, v, pal, warn, crit) {
    if (kind !== "temp" || isNaN(v)) return pal.accent;
    if (v < warn) return lerp(pal.cool, pal.warm, (v - (warn - 10)) / 10);
    return lerp(pal.warm, pal.hot, (v - warn) / Math.max(1, crit - warn));
}

// gauge range [lo, hi]
function range(kind, fanMax) {
    if (kind === "temp") return [20, 100];
    if (kind === "fan") return [0, fanMax];
    if (kind === "watt") return [0, 200];
    return [0, 100];
}

function unit(kind, fahrenheit) {
    return kind === "temp" ? (fahrenheit ? "°F" : "°C") : kind === "fan" ? "RPM" : kind === "watt" ? "W" : "%";
}

function format(kind, v, fahrenheit) {
    if (isNaN(v)) return "—";
    if (kind === "temp" && fahrenheit) v = v * 9 / 5 + 32;
    return String(Math.round(v));
}
