#!/usr/bin/env python3
"""Install pinned, checksum-verified official Rojo and Luau Linux binaries."""
import hashlib
import io
from pathlib import Path
import platform
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / ".tools"
RELEASES = [
    ("https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip",
     "00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4", {"rojo"}),
    ("https://github.com/luau-lang/luau/releases/download/0.727/luau-ubuntu.zip",
     "16b608cd05a9a402d879fa3a883ee86ce964114b798e4537bd7f71c83042015e", {"luau", "luau-analyze", "luau-compile"}),
]


def main():
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "amd64"):
        raise SystemExit("This bootstrap targets Linux x86_64. See README for local Studio/Rojo setup.")
    TOOLS.mkdir(exist_ok=True)
    for url, expected, executables in RELEASES:
        archive = TOOLS / url.rsplit("/", 1)[1]
        contents = archive.read_bytes() if archive.exists() else b""
        if hashlib.sha256(contents).hexdigest() != expected:
            request = urllib.request.Request(url, headers={"User-Agent": "Citymoney-setup"})
            with urllib.request.urlopen(request, timeout=60) as response:
                contents = response.read()
        if hashlib.sha256(contents).hexdigest() != expected:
            raise SystemExit(f"Checksum mismatch for {archive.name}; refusing to install.")
        archive.write_bytes(contents)
        with zipfile.ZipFile(io.BytesIO(contents)) as bundle:
            for executable in executables:
                matches = [name for name in bundle.namelist() if Path(name).name == executable]
                if len(matches) != 1:
                    raise SystemExit(f"Expected one {executable} in {archive.name}")
                destination = TOOLS / executable
                binary = bundle.read(matches[0])
                if not destination.exists() or destination.read_bytes() != binary:
                    temporary = TOOLS / (executable + ".pending")
                    temporary.write_bytes(binary)
                    temporary.chmod(0o755)
                    temporary.replace(destination)
                else:
                    destination.chmod(0o755)
        print(f"Verified and installed {archive.name}")


if __name__ == "__main__":
    main()
