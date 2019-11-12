**[feature]**

    FULL sm4.0 support(little sm5.0)
    easy to use & easy to read

**[usage]**

    .\lua\lua.exe dxbc_reader.lua example/fragment.txt -o dxbc.out

    -o output [output filename]
    -d true   [enable debug info]

translate DXBC code like:

```c
    dp4 r0.x, cb2[8].xyzw, v0.xyzw               >>    r0.x = dot(CBUSE_UB_LOCAL_MATRIX_IDX.u_mtxLP[0].xyzw, in.POSITION.xyzw)
    mov o0.x, r0.x                               >>    out.SV_Position.x = r0.x
    dp4 r1.y, cb2[9].xyzw, v0.xyzw               >>    r1.y = dot(CBUSE_UB_LOCAL_MATRIX_IDX.u_mtxLP[1].xyzw, in.POSITION.xyzw)
    dp4 r1.z, cb2[10].xyzw, v0.xyzw              >>    r1.z = dot(CBUSE_UB_LOCAL_MATRIX_IDX.u_mtxLP[2].xyzw, in.POSITION.xyzw)
    dp4 r1.w, cb2[11].xyzw, v0.xyzw              >>    r1.w = dot(CBUSE_UB_LOCAL_MATRIX_IDX.u_mtxLP[3].xyzw, in.POSITION.xyzw)
    mov o0.yzw, r1.yyzw                          >>    out.SV_Position.yzw = r1.yzw
    mov r0.y, -r1.y                              >>    r0.y = -r1.y
    add r0.xy, r0.xyxx, r1.wwww                  >>    r0.xy = r0.xy + r1.ww
    mov o4.zw, r1.zzzw                           >>    out.TEXCOORD4.zw = r1.zw
    mul o4.xy, r0.xyxx, l(0.500000, 0.500000)    >>    out.TEXCOORD4.xy = r0.xy * float2(0.5, 0.5)
    add r0.x, l(1.000000), cb3[2].x              >>    r0.x = 1.0 + CBUSE_UB_MODEL_MATERIAL_IDX.u_ambient.x
    mul r1.xyzw, v1.xyzw, cb3[1].xyzw            >>    r1.xyzw = in.COLOR.xyzw * CBUSE_UB_MODEL_MATERIAL_IDX.u_diffuse.xyzw
    mul o1.xyz, r0.xxxx, r1.xyzx                 >>    out.TEXCOORD1.xyz = r0.xxx * r1.xyz
    mov o1.w, r1.w                               >>    out.TEXCOORD1.w = r1.w
    mov o2.zw, l(0,0,0,0)                        >>    out.TEXCOORD2.zw = float2(0, 0)
```
