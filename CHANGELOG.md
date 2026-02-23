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
- Declaration ops (dcl_*, vs_*, ps_*, cs_*): output as comments, suppress unimplemented warning
- Sample variants: sample_l→SampleLevel, sample_c_lz→SampleCmpLevelZero, sample_c→SampleCmp, sample_b→SampleBias, sample_d→SampleGrad
- ld_indexable: add texture type comment (Texture2DArray/Texture3D/StructuredBuffer)
- SM5 bfi/bfrev/countbits: fix handler signatures, use HLSL reversebits/countbits
- udiv/idiv: support 4th operand (output as comment)
- Integer literals: use uint4 in ishl/ishr/iadd/imad context

### Added
- Golden regression tests (run_tests.lua)
- README: run directory, dependencies, options, testing
- CHANGELOG
- switch/case/default/endswitch control flow
- op_param._op passed to handlers for variant detection
- Texture type hints in sample/ld output (Texture2DArray, Texture3D)
- Compute shader: [numthreads(x,y,z)] entry, groupshared TGSM, dcl_indexableTemp declarations
