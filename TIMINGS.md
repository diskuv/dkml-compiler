# Timings

## Machines

### Windows-1

Specs:
```
C:\Windows\System32>wmic cpu get caption, deviceid, name, numberofcores, NumberOfLogicalProcessors, maxclockspeed
Caption                             DeviceID  MaxClockSpeed  Name                                 NumberOfCores  NumberOfLogicalProcessors
AMD64 Family 23 Model 8 Stepping 2  CPU0      3400           AMD Ryzen 5 2600 Six-Core Processor  6              12

C:\Windows\System32>systeminfo | find "Total Physical Memory"
Total Physical Memory:     32,701 MB

C:\Windows\System32>wmic MEMORYCHIP get BankLabel, DeviceLocator, Capacity, Speed
BankLabel     Capacity     DeviceLocator  Speed
P0 CHANNEL A  17179869184  DIMM 0         3200
P0 CHANNEL B  17179869184  DIMM 0         3200

C:\Windows\System32>winsat cpu -compression2
...
> CPU Vista Compression                        1890.09 MB/s

C:\Windows\System32>winsat disk -drive z
...
> Disk  Random 16.0 Read                       245.19 MB/s          8.0
> Disk  Sequential 64.0 Read                   1761.13 MB/s          8.9
> Disk  Sequential 64.0 Write                  2005.07 MB/s          9.0
> Average Read Time with Sequential Writes     0.076 ms          8.8
> Latency: 95th Percentile                     0.237 ms          8.8
> Latency: Maximum                             0.655 ms          8.9
> Average Read Time with Random Writes         0.109 ms          8.9
```

## Measurements

### 2023-01-20

* Machine: [Windows-1](#Windows-1)

Baseline before change:

```
$ rm -rf _build/prefix
$ git log -n1
commit 6bf809077fad4f1a53f51753bbaeed5f7ba08ece (HEAD -> main)
Author: Jonah Beckford <71855677+jonahbeckford@users.noreply.github.com>
Date:   Fri Jan 20 14:48:16 2023 -0800

    Copy-edit dev documentation

$ time env TOPDIR=dkmldir/vendor/drc/all/emptytop \
    DKML_REPRODUCIBLE_SYSTEM_BREWFILE=./Brewfile \
    src/r-c-ocaml-1-setup.sh \
    -d dkmldir \
    -t "$PWD/_build/prefix" \
    -f src-ocaml \
    -g "$PWD/_build/prefix/share/mlcross" \
    -v dl/ocaml \
    -z \
    -ewindows_x86_64 \
    -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh
real    0m40.013s

$ cd '_build/prefix' && time share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh
real    16m12.100s
user    0m23.481s
sys     7m3.153s
```

#### 2023-01-20 Change 1

> Place precompiled `ocamlc.opt.exe` in `boot/` of compiler before
> building the compiler.

```
$ rm -rf _build/prefix
$ time env TOPDIR=dkmldir/vendor/drc/all/emptytop \
    DKML_REPRODUCIBLE_SYSTEM_BREWFILE=./Brewfile \
    src/r-c-ocaml-1-setup.sh \
    -d dkmldir \
    -t "$PWD/_build/prefix" \
    -f src-ocaml \
    -g "$PWD/_build/prefix/share/mlcross" \
    -v dl/ocaml \
    -z \
    -ewindows_x86_64 \
    -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh
real    0m40.491s
user    0m0.940s
sys     0m6.736s

PS> & "$env:DiskuvOCamlHome\bin\dkml" version
1.2.0~prerel7
PS> Copy-Item $env:DiskuvOCamlHome\usr\bin\ocamlc.opt.exe .\_build\prefix\src-ocaml\boot\

$ (cd '_build/prefix' && time share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh 2>&1 | tee ../../change1.log)
real    15m39.047s
user    0m23.282s
sys     7m1.577s
```

#### 2023-01-20 Change 2

> Skip over cross-compiling support when no target ABIs specified

```
PS> git log -n1
commit 762fa5f10137f5c4f7e77cf6b56b2391900f06ae (HEAD -> main)
Author: Jonah Beckford <71855677+jonahbeckford@users.noreply.github.com>
Date:   Fri Jan 20 17:19:11 2023 -0800

    Skip over cross-compiling support when no target ABIs specified
$ install ./src/r-c-ocaml-*.sh ./dkmldir/vendor/dkml-compiler/src/

$ rm -rf _build/prefix
$ env TOPDIR=dkmldir/vendor/drc/all/emptytop \
    DKML_REPRODUCIBLE_SYSTEM_BREWFILE=./Brewfile \
    src/r-c-ocaml-1-setup.sh \
    -d dkmldir \
    -t "$PWD/_build/prefix" \
    -f src-ocaml \
    -g "$PWD/_build/prefix/share/mlcross" \
    -v dl/ocaml \
    -z \
    -ewindows_x86_64 \
    -k vendor/dkml-compiler/env/standard-compiler-env-to-ocaml-configure-env.sh

PS> & "$env:DiskuvOCamlHome\bin\dkml" version
1.2.0~prerel7
PS> Copy-Item $env:DiskuvOCamlHome\usr\bin\ocamlc.opt.exe .\_build\prefix\src-ocaml\boot\

$ (cd '_build/prefix' && time share/dkml/repro/100co/vendor/dkml-compiler/src/r-c-ocaml-2-build_host-noargs.sh 2>&1 | tee ../../change2.log)
real    11m51.490s
user    0m10.188s
sys     4m48.819s
```
