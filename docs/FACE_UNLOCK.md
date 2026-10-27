# IR face unlock and NPU

Verified on 2026-10-27 on the Lenovo Yoga 7 2-in-1 14AKP10, running CachyOS with kernel `7.3.0-5-cachyos`.

Gaze is a system package setup. These dotfiles document it but do not install or configure it.

## IR face unlock

The integrated Chicony camera (USB ID `04f2:b83c`) exposes a color stream at `/dev/video0` and an IR grayscale stream at `/dev/video2` (`GREY`, 640×360, 15 fps). Gaze 0.4.1 is installed with its GUI and KDE integration.

The relevant settings in `/etc/gaze/config.toml` are:

```toml
[inference]
execution_provider = "cpu"
device = "cpu"

[cameras]
rgb = "primary"
ir = "/dev/video2"
```

The Gaze daemon is enabled at boot. A face profile is enrolled, and `gaze doctor` reported that it covers the configured camera spectra.

The KDE lock-screen integration is enabled through `gaze-kde-pam`. Check or restore it with:

```bash
sudo gaze-kde-pam status
sudo gaze-kde-pam enable
```

Use **Super+L** to test the lock screen. Login-greeter integration is separate and remains disabled. To enable it, run `sudo gaze-kde-pam enable-login`; face auth there starts when you submit the login form with an empty password. Keep password login available.

Useful checks:

```bash
gaze doctor
gaze auth --verbose
```

## AMD NPU

The CPU is an AMD Ryzen AI 7 350 with Radeon 860M. The NPU is PCI device `1022:17f0`; the in-kernel `amdxdna` driver loaded its firmware and created `/dev/accel/accel0`. Gaze currently uses the CPU.

The XRT userspace runtime, XDNA userspace plugin, and AMD Vitis ONNX Runtime provider are not installed. There is no `xrt-smi`, `/opt/xilinx`, `/opt/ryzen-ai`, or `/usr/lib/gaze/runtimes/vitis` on this system. The configured package repositories offer `xrt` and `xrt-plugin-amdxdna`, but those packages have not been installed or tested here.

Gaze needs AMD's Vitis-enabled `libonnxruntime.so` and the SDK library paths registered under `/usr/lib/gaze/runtimes/vitis` before its provider can be enabled. The first setup step, if resuming this work, is to install XRT and its userspace plugin. It does not replace the working kernel driver:

```bash
sudo pacman -S --needed xrt xrt-plugin-amdxdna
source /opt/xilinx/xrt/setup.sh
xrt-smi examine
```

Do not switch Gaze from CPU until the NPU is visible to XRT and the AMD Vitis runtime is installed and registered. AMD's [Linux installation guide](https://ryzenai.docs.amd.com/en/latest/linux.html) targets Ubuntu 24.04. The [CachyOS/Arch community guide](https://github.com/craigchandler/ryzen-ai-arch) is an experimental adaptation tested on a Ryzen AI 9 HX 470, not this Ryzen AI 7 350. The laptop's existing in-kernel `amdxdna` driver works; do not replace it with an Ubuntu DKMS package.

After registering the runtime, set `execution_provider = "vitis"` and `device = "npu"` in Gaze, restart `gazed`, and verify with `gaze doctor --benchmark` and the daemon journal. NPU acceleration is still unverified for Gaze's face models, so compare it with the current CPU setup.
