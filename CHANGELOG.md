# Changelog

## [Unreleased]

### Changed
- File IO: add error handling and proper file close
- Parse validation: check parse_data and required fields before init
- Print: fix duplicate output; append no longer prints, only final print when -p
- args.print: normalize to boolean
- get_op: deterministic match order (longer patterns first)
- Main flow: encapsulated in run() for testability
- TEXCOORD: extracted format_io_vars() to reduce duplication
- Unimplemented ops: warn to stderr and output as comment instead of assert
- dxbc_def break/continue: unsupported args return placeholder instead of assert

### Added
- Golden regression tests (run_tests.lua)
- README: run directory, dependencies, options, testing
- CHANGELOG
