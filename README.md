[feature]
    FULL sm4.0 support(little sm5.0)
    easy to use & easy to read

[usage]
    .\lua\lua.exe fragment.txt -o dxbc.out

    -o output [output filename]
    -d true   [enable debug info]

translate DXBC code like:

    dp4 r0.x, cb2[8].xyzw, v0.xyzw
    mov o0.x, r0.x
    dp4 r1.y, cb2[9].xyzw, v0.xyzw
    dp4 r1.z, cb2[10].xyzw, v0.xyzw
    dp4 r1.w, cb2[11].xyzw, v0.xyzw
    mov o0.yzw, r1.yyzw
    mov r0.y, -r1.y
    add r0.xy, r0.xyxx, r1.wwww
    mov o4.zw, r1.zzzw
    mul o4.xy, r0.xyxx, l(0.500000, 0.500000, 0.000000, 0.000000)
    add r0.x, l(1.000000), cb3[2].x
    mul r1.xyzw, v1.xyzw, cb3[1].xyzw
    mul o1.xyz, r0.xxxx, r1.xyzx
    mov o1.w, r1.w
    mov o2.zw, l(0,0,0,0)


to:

    r0.x = dot(CBUSE_UB_LOCAL_MATRIX_IDX.u_mtxLP[0].x, in.POSITION.x)
    out.SV_Position.x = r0.x
    r1.y = dot(CBUSE_UB_LOCAL_MATRIX_IDX.u_mtxLP[1].y, in.POSITION.y)
    r1.z = dot(CBUSE_UB_LOCAL_MATRIX_IDX.u_mtxLP[2].z, in.POSITION.z)
    r1.w = dot(CBUSE_UB_LOCAL_MATRIX_IDX.u_mtxLP[3].w, in.POSITION.w)
    out.SV_Position.yzw = r1.yzw
    r0.y = -r1.y
    r0.xy = r0.xy+r1.ww
    out.TEXCOORD4.zw = r1.zw
    out.TEXCOORD4.xy = r0.xy*float4(0.5,0.5,0.0,0.0)
    r0.x = 1.0+CBUSE_UB_MODEL_MATERIAL_IDX.u_ambient.x
    r1.xyzw = in.COLOR.xyzw*CBUSE_UB_MODEL_MATERIAL_IDX.u_diffuse.xyzw
    out.TEXCOORD1.xyz = r0.xxx*r1.xyz
    out.TEXCOORD1.w = r1.w
    out.TEXCOORD2.zw = float4(0,0,0,0)
