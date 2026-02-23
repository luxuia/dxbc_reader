# HLSL Shader Model 5 支持矩阵

本文档对照 [Microsoft Shader Model 5 Assembly](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/shader-model-5-assembly--directx-hlsl-) 规范，列出 dxbc_reader 工程对各 SM5 指令的支持情况。

## 图例

| 状态 | 说明 |
|------|------|
| ✅ 已支持 | 可正确反汇编为 HLSL |
| ⚠️ 部分支持 | 有实现但可能不完整（如仅注释、变体不全） |
| ❌ 未支持 | 输出为 `// op ...` 注释，并可能产生 unimplemented 警告 |

---

## 一、算术与逻辑运算

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| add | ✅ | `[di]?add` 匹配 |
| dadd | ✅ | 双精度加 |
| iadd | ✅ | 整型加 |
| sub | ❌ | 未单独实现（通常用 add+neg 表示） |
| mul, imul, umul | ✅ | `[uid]?mul` |
| dmul | ✅ | 双精度乘 |
| mad, imad, umad | ✅ | `[ui]?mad` |
| div, udiv, idiv | ✅ | `[du]?div`，udiv/idiv 四操作数第 4 个以注释输出 |
| ddiv | ❌ | 双精度除 |
| dfma | ❌ | 双精度 FMA |
| min, imin, umin, dmin | ✅ | `[uid]?min` |
| max, imax, umax, dmax | ✅ | `[uid]?max` |
| abs | ⚠️ | 通过 modifier 支持 `abs(x)`，非独立指令 |
| ineg | ❌ | 整型取负 |

---

## 二、位运算

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| and | ✅ | |
| or | ✅ | |
| xor | ✅ | |
| bfi | ✅ | bit field insert（表达式实现） |
| bfrev | ✅ | reversebits |
| countbits | ✅ | |
| ibfe | ❌ | 有符号位域提取 |
| ubfe | ❌ | 无符号位域提取 |
| firstbit_hi, firstbit_lo, firstbit_shi | ❌ | firstbithigh / firstbitlow |
| ishl, ishr, ushr | ✅ | `[ui]?shl`, `[ui]?shr` |

---

## 三、类型转换

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| ftoi, ftou | ✅ | |
| itof, utof | ✅ | `[uid]?tof` |
| f16tof32 | ❌ | 半精度转 float |
| f32tof16 | ❌ | float 转半精度 |
| ftod | ❌ | float 转 double |
| dtof | ❌ | double 转 float |

---

## 四、数学函数

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| rcp, drcp | ✅ | `[d]?rcp` |
| rsq | ✅ | |
| sqrt | ✅ | |
| exp | ✅ | exp2 |
| log | ✅ | log2 |
| sincos | ✅ | |
| frc | ✅ | frac |
| round_ni, round_pi, round_ne, round_z | ✅ | floor/ceil |

---

## 五、比较与分支

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| eq, ieq, deq | ✅ | `[di]?eq` |
| ne, ine, dne | ✅ | `[di]?ne` |
| lt, ilt, ult, dlt | ✅ | `[uid]?lt` |
| ge, ige, uge, dge | ✅ | `[uid]?ge` |
| not | ✅ | |
| movc, dmovc | ✅ | `[d]?movc` |
| swapc | ❌ | SM5 条件交换 |

---

## 六、控制流

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| if, endif, else | ✅ | |
| switch, case, default, endswitch | ✅ | |
| loop, endloop | ✅ | |
| break, breakc | ⚠️ | break 支持，breakc 仅支持 c_z/c_nz |
| continue, continuec | ⚠️ | 同上 |
| ret, retc | ⚠️ | ret 支持，retc 仅支持 c_z/c_nz |
| call | ❌ | 函数调用 |
| callc | ❌ | 条件函数调用 |
| fcall | ❌ | 间接函数调用 |
| label | ❌ | 标签 |

---

## 七、导数

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| deriv_rtx, deriv_rty | ✅ | `deriv_rt(.)(.*)` |
| deriv_rtx_coarse, deriv_rty_coarse | ✅ | dd*_coarse |
| deriv_rtx_fine, deriv_rty_fine | ⚠️ | 若 pattern 匹配则输出，与 coarse 形式相同 |

---

## 八、纹理采样与加载

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| sample | ✅ | Sample |
| sample_b | ✅ | SampleBias |
| sample_c | ✅ | SampleCmp |
| sample_c_lz | ✅ | SampleCmpLevelZero |
| sample_d | ✅ | SampleGrad |
| sample_l | ✅ | SampleLevel |
| ld_indexable | ✅ | Texture2D/2DArray/3D/StructuredBuffer.Load |
| ld_raw | ✅ | ByteAddressBuffer.Load |
| ld_structured | ✅ | StructuredBuffer 结构化加载 |
| ld_uav_typed | ✅ | UAV typed 加载 |
| ld | ❌ | 通用 ld（与 ld_indexable 可能不同格式） |
| ld2dms | ❌ | 2D 多重采样 |
| lod | ❌ | 计算 mip level |
| resinfo | ❌ | 资源尺寸 GetDimensions |
| sampleinfo | ❌ | 采样数量 |
| samplepos | ❌ | 采样位置 |
| gather4, gather4_c, gather4_po, gather4_po_c | ❌ | Gather 系列 |

---

## 九、存储与 UAV

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| store_structured | ✅ | |
| store_uav_typed | ✅ | |
| store_raw | ✅ | ByteAddressBuffer.Store |

---

## 十、原子操作 (Atomic)

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| atomic_iadd | ✅ | InterlockedAdd |
| atomic_and | ✅ | InterlockedAnd |
| atomic_or | ✅ | InterlockedOr |
| atomic_xor | ✅ | InterlockedXor |
| atomic_imax, atomic_imin | ✅ | InterlockedMax/Min |
| atomic_umax, atomic_umin | ✅ | InterlockedMax/Min (uint) |
| atomic_cmp_store | ✅ | InterlockedCompareStore |
| imm_atomic_iadd | ✅ | 先读原值再 InterlockedAdd |
| imm_atomic_and, imm_atomic_or, imm_atomic_xor | ✅ | 同上 |
| imm_atomic_exch | ✅ | 先读原值再 InterlockedExchange |
| imm_atomic_cmp_exch | ✅ | 先读原值再 InterlockedCompareExchange |
| imm_atomic_alloc | ❌ | |
| imm_atomic_consume | ❌ | |

---

## 十一、几何与流输出 (GS)

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| emit | ❌ | |
| emit_stream | ❌ | |
| emitThenCut | ❌ | |
| emitThenCut_stream | ❌ | |
| cut | ❌ | |
| cut_stream | ❌ | |

---

## 十二、曲面细分 (HS/DS)

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| hs_decls | ❌ | |
| hs_control_point_phase | ❌ | |
| hs_fork_phase | ❌ | |
| hs_join_phase | ❌ | |

---

## 十三、Compute Shader

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| sync | ✅ | 输出 `sync`（对应 GroupMemoryBarrierWithGroupSync） |
| dcl_thread_group | ⚠️ | 以 `[numthreads(x,y,z)]` 形式在入口注释中输出 |
| dcl_tgsm_* | ⚠️ | groupshared 声明以注释输出 |
| dcl_indexableTemp | ⚠️ | 以注释输出 |

---

## 十四、其他

| SM5 指令 | 工程支持 | 说明 |
|----------|----------|------|
| dp2, dp3, dp4 | ✅ | dot |
| mov, dmov | ✅ | |
| discard | ✅ | |
| nop | ❌ | 空操作 |
| bufinfo | ❌ | 缓冲区元信息 GetDimensions |
| uaddc | ❌ | 无符号加带进位 |
| usubb | ❌ | 无符号减带借位 |

---

## 十五、声明 (dcl_*)

所有 `dcl_*`、`vs_*`、`ps_*`、`cs_*` 均以注释形式输出，不触发 unimplemented 警告。包括但不限于：

- dcl_constantBuffer, dcl_immediateConstantBuffer  
- dcl_input, dcl_output, dcl_input_sv, dcl_output_siv 等  
- dcl_resource, dcl_resource raw, dcl_resource structured  
- dcl_sampler, dcl_temps, dcl_indexableTemp  
- dcl_tessellator_*, dcl_hs_*, dcl_inputPrimitive, dcl_outputTopology  
- dcl_uav_typed, dcl_uav_raw, dcl_uav_structured  
- dcl_function_body, dcl_function_table, dcl_interface*  
- vs_4_0, vs_5_0, ps_4_0, ps_5_0, cs_5_0 等  

---

## 十六、实现位置

- 指令映射：`dxbc_def.lua` 中 `shader_def`、`shader_def5`、`shader_def_cs`
- 未匹配指令处理：`dxbc_reader.lua` 中约 273–284 行
- 声明类指令：`shader_def` 中 `dcl_.*`、`vs_%d_%d`、`ps_%d_%d`、`cs_%d_%d` 设为 `false`，以注释输出
