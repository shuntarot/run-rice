# Building the mruby/c firmware (`picoruby/`)

`make -C picoruby` builds `picoruby.elf`, a Ruby script run by mruby/c on the
core. It needs three things on the build machine. If you only want to run it,
build the ELF on any machine that has them and copy the file.

The commands below are for Ubuntu (they were run on AlmaLinux; the package
names are the Ubuntu ones).

```bash
sudo apt install git make gcc ruby rake
```

## What you need

| Need | Why |
|---|---|
| A PicoRuby checkout with three submodules | the mruby/c source, and the compiler that turns a script into bytecode |
| Ruby and `rake` | mruby/c generates its `_autogen_*.h` tables with Ruby, and `rake` builds the compiler |
| A RISC-V GCC with RV32 libraries | the firmware is `-march=rv32im_zicsr_zifencei -mabi=ilp32` |

## 1. PicoRuby

Put the checkout beside this repository (`../picoruby`), or pass
`PICORUBY=<dir>` to `make`.

```bash
cd ..
git clone https://github.com/picoruby/picoruby
cd picoruby
git submodule update --init mrbgems/picoruby-mrubyc/lib/mrubyc \
    mrbgems/mruby-compiler mrbgems/mruby-bin-mrbc \
    mrbgems/picoruby-mruby/lib/mruby
MRUBY_CONFIG=build_config/picorbc.rb rake      # writes bin/mrbc
```

Without the submodule `make` stops at `cp: cannot stat .../mrubyc/src`.
Without Ruby it stops at `No rule to make target '_autogen_builtin_class.h'`.
Without `bin/mrbc` it stops at `bin/mrbc: No such file or directory`.
`bin/mrbc` is a plain x86-64 Linux program, so copying it from another
machine also works.

## 2. The toolchain

GCC must pick RV32 libraries for `-march=rv32im_zicsr_zifencei -mabi=ilp32`.
Check that the linker is happy before a long build:

```bash
<prefix>riscv64-unknown-elf-gcc -march=rv32im_zicsr_zifencei -mabi=ilp32 \
    -print-multi-directory
```

A RISC-V GCC built with the defaults is RV64 only. The symptom is the link
step failing with `file class ELFCLASS64 incompatible with ELFCLASS32`. Build
riscv-gnu-toolchain for RV32 (no simulators are needed):

```bash
sudo apt install autoconf automake autotools-dev curl python3 libmpc-dev \
    libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
    libtool patchutils bc zlib1g-dev libexpat-dev
git clone --filter=blob:none https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
git submodule update --init --depth=1 binutils gcc newlib
./configure --prefix=$HOME/riscv-rv32 \
    --with-arch=rv32im_zicsr_zifencei --with-abi=ilp32
make -j16
```

For one compiler that also builds RV64, replace the last two options with
`--with-multilib-generator="rv32im_zicsr_zifencei-ilp32--;rv64gc-lp64d--"`
and list every RV64 combination you use.

## 3. Build and run

`CROSS` is the tool prefix, ending in a dash. It is `riscv64-unknown-elf-`
for a standard riscv-gnu-toolchain build, whatever the target width.

```bash
make -C picoruby CROSS=$HOME/riscv-rv32/bin/riscv64-unknown-elf-
HIO_REGS=hns_mem/regs.json hio cpu boot picoruby/picoruby.elf
```

Other settings are at the top of `picoruby/Makefile`: `SCRIPTS` (up to four
scripts, one task each), `OPT`, `CPU_HZ` and `PICORUBY`. After changing the
toolchain, run `make -C picoruby clean`.
