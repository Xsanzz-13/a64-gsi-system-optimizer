XSANZZ OS device scripts

Included in the optional KernelSU/SukiSU module:
- auto.sh: bounded boot wait and a mild best-effort HWC niceness adjustment.
- refactor.sh: aligns VM swappiness to the value observed in the stock A03 audit (170) and reports the existing zRAM setup.

The scripts run only after the user installs the generated module in KernelSU/SukiSU Manager.

99-fastcharge.sh is intentionally excluded from the module and system image. It forces charging-current sysfs values without validating the charger, battery, thermal limits, or board configuration. Keep OEM charging and JEITA protections in control.
