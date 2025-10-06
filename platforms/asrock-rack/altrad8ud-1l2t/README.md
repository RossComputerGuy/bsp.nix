# ALTRAD8UD-1L2T

Ampere Altra series compatible server motherboard from ASRock Rack.

## Requirements

- `altra_atf_signed_2.10.20230517.slim` (**Required to go through Ampere Customer Connect**)

## Steps

1. `nix build .#asrock-rack/altrad8ud-1l2t`
2. Build the SPI-NOR image
    1. `dd bs=1024 count=2048 if=/dev/zero | tr "\000" "\377" >altra1l2t_tfa_uefi.bin`
    2. `dd bs=1024 conv=notrunc if=altra_atf_signed_2.10.20230517.slim of=altra1l2t_tfa_uefi.bin`
    3. `dd bs=1 seek=2031616 conv=notrunc if=result/board_cfg.bin of=altra1l2t_tfa_uefi.bin`
    4. `dd bs=1024 seek=2048 if=result/FV/BL33_ALTRA1L2T_UEFI.fd of=altra1l2t_tfa_uefi.bin`
    5. `dd bs=1M count= if=/dev/zero | tr "\000" "\377" > altra1l2t_rom.bin`
    6. `dd bs=1M seek=4 conv=notrunc if=altra1l2t_tfa_uefi.bin of=altra1l2t_rom.bin`

The resulting file will be the `altra1l2t_rom.bin`, it requires the signed ATF from Ampere Custom Connect.
