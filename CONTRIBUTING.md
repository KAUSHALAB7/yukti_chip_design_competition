# Contributing

Thanks for your interest in contributing! This project is a clean, synthesizable SystemVerilog design with a RISC-V integration. To keep quality high, please follow these guidelines:

1. Fork the repository and create a feature branch.
2. Run local tests before submitting a PR:
   - `bash KAB/scripts/run_tests.sh`
3. Keep RTL synthesizable: synchronous resets, no latches, single-clock domain unless justified.
4. Add/extend testbenches for any user-visible RTL change.
5. Use clear commit messages (imperative mood): `Add wrapper readback for C matrix`.
6. Open a PR with a brief description and test evidence (logs or wave screenshots if relevant).

## Style
- SystemVerilog `logic`, `always_ff`/`always_comb` preferred.
- Parameterize where practical, avoid magic numbers.
- Name testbenches `<module>_testbench.sv`.

## Code of Conduct
Please note that this project follows the Contributor Covenant. Be respectful and constructive.
