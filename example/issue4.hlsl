//
// Generated by Microsoft (R) D3D Shader Disassembler
//
//
// Input signature:
//
// Name Index Mask Register SysValue Format Used
// -------------------- ----- ------ -------- -------- ------- ------
// SV_POSITION 0 xyzw 0 POS float
// TEXCOORD 0 xyzw 1 NONE float zw
//
//
// Output signature:
//
// Name Index Mask Register SysValue Format Used
// -------------------- ----- ------ -------- -------- ------- ------
// SV_Target 0 xyzw 0 TARGET float xyzw
//
ps_4_0
dcl_constantbuffer CB0[88], immediateIndexed
dcl_constantbuffer CB1[8], immediateIndexed
dcl_sampler s0, mode_default
dcl_sampler s1, mode_default
dcl_sampler s2, mode_default
dcl_sampler s3, mode_default
dcl_sampler s4, mode_default
dcl_sampler s5, mode_default
dcl_resource_texture2d(float, float, float, float) t0
dcl_resource_texture2d(float, float, float, float) t1
dcl_resource_texture2d(float, float, float, float) t2
dcl_resource_texture2d(float, float, float, float) t3
dcl_resource_texture2d(float, float, float, float) t4
dcl_resource_texture2d(float, float, float, float) t5
dcl_input_ps linear v1.zw
dcl_output o0.xyzw
dcl_temps 4
sample r0.xyzw, v1.zwzz, t0.xyzw, s5
add r0.xy, -r0.zzzz, r0.xyxx
add r0.xy, r0.xyxx, v1.zwzz
sample r1.xyzw, r0.xyxx, t4.xyzw, s0
mad r0.z, cb1[7].z, | r1.x | , cb1[7].w
div r0.z, l(1.000000, 1.000000, 1.000000, 1.000000), r0.z
div r0.z, cb0[69].x, r0.z
add r0.z, -r0.z, l(1.000000)
lt r0.w, l(0.000000), r0.z
movc r0.w, r0.w, cb0[69].w, cb0[69].z
mul r0.z, r0.w, | r0.z |
log r0.z, r0.z
mul r0.z, r0.z, cb0[69].y
exp r0.z, r0.z
max r0.z, r0.z, l(0.001000)
min r0.z, r0.z, l(1.000000)
add r0.w, -r0.z, l(1.000000)
sample r1.xyzw, r0.xyxx, t2.xyzw, s3
sample r2.xyzw, r0.xyxx, t1.xyzw, s1
add r1.xyz, r1.xyzx, r2.xyzx
mov o0.w, r2.w
sample r2.xyzw, r0.xyxx, t3.xyzw, s2
add r0.xy, r0.xyxx, l(-0.500000, -0.500000, 0.000000, 0.000000)
mul_sat r0.xy, | r0.xyxx | , cb0[87].xxxx
mad r2.xyz, r1.xyzx, r0.wwww, r2.xyzx
mad r1.xyz, -r1.xyzx, r0.zzzz, r1.xyzx
mad r1.xyz, r2.xyzx, r0.zzzz, r1.xyzx
dp3 r2.x, l(0.390405, 0.549941, 0.008926, 0.000000), r1.xyzx
dp3 r2.y, l(0.070842, 0.963172, 0.001358, 0.000000), r1.xyzx
dp3 r2.z, l(0.023108, 0.128021, 0.936245, 0.000000), r1.xyzx
mul r1.xyz, r2.xyzx, cb0[84].xyzx
dp3 r2.x, l(2.858470, -1.628790, -0.024891, 0.000000), r1.xyzx
dp3 r2.y, l(-0.210182, 1.158200, 0.000324, 0.000000), r1.xyzx
dp3 r2.z, l(-0.041812, -0.118169, 1.068670, 0.000000), r1.xyzx
max r1.xyz, r2.xyzx, l(0.000000, 0.000000, 0.000000, 0.000000)
mul r1.xyz, r1.xyzx, cb0[79].zzzz
mul r2.xyz, r1.xyzx, r1.xyzx
mul r2.xyz, r2.xyzx, cb0[78].xxxx
mul r0.z, cb0[78].y, cb0[78].z
mad r3.xyz, r0.zzzz, r1.xyzx, r2.xyzx
mad r1.xyz, cb0[78].yyyy, r1.xyzx, r2.xyzx
mad r1.xyz, cb0[78].wwww, cb0[79].yyyy, r1.xyzx
mad r2.xyz, cb0[78].wwww, cb0[79].xxxx, r3.xyzx
div r1.xyz, r2.xyzx, r1.xyzx
div r0.z, cb0[79].x, cb0[79].y
add r1.xyz, -r0.zzzz, r1.xyzx
mul r0.z, cb0[79].w, cb0[79].z
mul r1.xyz, r0.zzzz, r1.xyzx
dp3 r0.z, r1.xyzx, l(0.212500, 0.715400, 0.072100, 0.000000)
mul r0.z, r0.z, r0.z
mad_sat r2.xyz, r0.zzzz, cb0[87].yyyy, cb0[86].xyzx
dp2 r0.z, r0.xyxx, r0.xyxx
mad r0.xy, -r0.yxyy, r0.yxyy, l(1.000000, 1.000000, 0.000000, 0.000000)
add r0.z, -r0.z, l(1.000000)
max r0.z, r0.z, l(0.000000)
ilt r3.xy, l(0, 0, 0, 0), cb0[87].zwzz
movc r0.y, r3.x, r0.y, r0.z
movc r0.x, cb0[87].z, r0.y, r0.x
mul r0.y, r0.x, r0.x
mul r0.z, r0.y, r0.y
mul r0.z, r0.x, r0.z
mul r0.x, r0.x, r0.y
movc r0.x, r3.y, r0.x, r0.z
movc r0.x, cb0[87].w, r0.x, r0.y
add r0.y, -r0.x, l(1.000000)
mad r0.xyz, r2.xyzx, r0.yyyy, r0.xxxx
mul r0.xyz, r0.xyzx, r1.xyzx
max r0.xyz, r0.xyzx, l(0.000000, 0.000000, 0.000000, 0.000000)
log r0.xyz, r0.xyzx
mul r0.xyz, r0.xyzx, l(0.416667, 0.416667, 0.416667, 0.000000)
exp r0.xyz, r0.xyzx
mad_sat r0.xyz, r0.xyzx, l(1.055000, 1.055000, 1.055000, 0.000000), l(-0.055000, -0.055000, -0.055000, 0.000000)
mul r0.xyw, r0.xyxz, cb0[82].zzzz
round_ni r0.w, r0.w
mad r0.z, r0.z, cb0[82].z, -r0.w
mul r1.xy, cb0[82].xyxx, l(0.500000, 0.500000, 0.000000, 0.000000)
mad r1.zw, r0.xxxy, cb0[82].xxxy, r1.xxxy
mad r1.y, r0.w, cb0[82].y, r1.z
add r1.x, r1.y, cb0[82].y
sample r2.xyzw, r1.ywyy, t5.xyzw, s4
sample r1.xyzw, r1.xwxx, t5.xyzw, s4
add r0.xyw, -r2.xyxz, r1.xyxz
mad o0.xyz, r0.zzzz, r0.xywx, r2.xyzx
ret