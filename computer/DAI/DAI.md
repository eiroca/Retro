# DAI

## DAI technical information

CPU: Intel 8080 2MHz

| Memory map | Description |
|------------|-------------|
| `0000-BFFF` | RAM |
| `C000-DFFF` | ROM (non-switchable) |
| `E000-EFFF` | ROM (4 switchable banks) |
| `F000-F7FF` | ROM extension (optional) |
| `F800-F8FF` | DAI stack |
| `F900-FFFF` | I/O |
| `---------` | **I/O Area**|
| `F900-FAFF` | spare |
| `FB00-FBFF` | AMD9511 math chip (optional) |
| `FC00-FCFF` | 8253 programmable interval timer |
| `FD00-FDFF` | discrete devices |
| `FE00-FEFF` | 8255 PIO (DCE bus) |
| `FF00-FFFF` | timer + 5501 interrupt controller |
| `---------` | **Discrete Devices IO** |
| `FD00` | POR1 IN |
| `|-bit 0` | none |
| `|-bit 1` | none |
| `|-bit 2` | PIPGE: Page signal |
| `|-bit 3` | PIDTR: Serial output ready|
| `|-bit 4` | PIBU1: Button on paddle 1 (1 = closed) |
| `|-bit 5` | PIBU2: Button on paddle 2 (1 = closed) |
| `|-bit 6` | PIRPI: Random data |
| `|-bit 7` | PICAI: Cassette input data |
| `FD01` | PDLST:  IN  Single pulse used to trigger paddle timer circuit |
| `FD04` | POR1:   OUT  |
| `|-bit 0-3` | Volume oscillator channel 0 |
| `|-bit 4-7` | Volume oscillator channel 1 |
| `FD05` | POR1:   OUT  |
| `|-bit 0-3` | Volume oscillator channel 2 |
| `|-bit 4-7` | Volume random noise generator |
| `FD06` | POR0:   OUT |
| `|-bit 0` | POCAS: Cassette data output |
| `|-bit 1` | PDLMSK: Paddle select |
| `|-bit 2` | PDPNA:  Paddle enable |
| `|-bit 3` | PIDTR: Serial output ready|
| `|-bit 4` | POCM1:  Cassette 1 motor control (0 = run) |
| `|-bit 5` | POCM2:  Cassette 2 motor control (0 = run)) |
| `|-bit 6-7` | ROM bank switching |
| `---------` | **RAM** |
| `0000-02EB` | DAI system-heap |
| `02EC-B350` | free RAM (mode-0) |
| `B350-BFFF` | video memory (mode-0) |
| `---------` | **ROM** |
| `C000-DFFF` | ROM (non-switchable) - BASIC ROM|
| `E000-EFFF` | ROM (4 switchable banks) |
| `F000-F7FF` | ROM extension (optional) |
| `---------` | **KEN-DOS** |
| `F000-F8FF` | KEN-DOS ROM |
| `F900-FAFF` | KEN-DOS heap/bank select address |
| `AD50` | KEN-DOS start of FAM (mode-0) |
| `AF50` | KEN-DOS start of directory (mode-0) |
| `F000` | Pointer to initializing-routine which enables KEN-DOS commands to be used in Basic programs |
| `FA50` | KEN-DOS start of bank-switch routine |
| `01B0` | Buffer for drive select byte |
| `0296` | Inswitch vector; 0 = RS232, 2 = pointer op #02E0 |
| `0297-0298` | Pointer to KEN-DOS command-table |
| `02C5-02EB` | Pointer for disk and/or cassette. Do not change these addresses! |
| `F98C-F98D` | On this address "10" is written during start-up. Second byte for motor-on time after finishing disk-access. Is used together with `#F9BC` as count-down buffer. |
| `FAFE-FAFF` | Offset pointers to relocate the 1.5Kbyte needed by the KEN-DOS system as buffer for FAM and directory |
