class INPUT {
	SV_Position;
	TEXCOORD1;
	TEXCOORD2;
	TEXCOORD3;
	TEXCOORD4;
	TEXCOORD5;
	TEXCOORD6;
}
class OUT {
	SV_Target;
}
r0.xyzw = tex2D(tex0, in.TEXCOORD1.xy).xyzw //sample_state tex0Sampler;
r0.x = dot(r0.xywx, r0.xywx);
r0.x = 0.0 >= r0.x;
r0.x = r0.x & 0x3f800000 // 0x3f800000=1.0, maybe means: if (r0.x==0xFFFFFFFF) r0.x=1.0;
r1.x = r0.z >= 1.0;
r1.x = r1.x & 0x3f800000 // 0x3f800000=1.0, maybe means: if (r1.x==0xFFFFFFFF) r1.x=1.0;
r0.x = r0.x * r1.x;
r0.x = 0.0 != r0.x;
if (r0.x != 0) {
	out.SV_Target.xyzw = float4(0, 0, 0, 0);
	return;
}
r1.xyz = tex2D(tex0, in.TEXCOORD2.xy).yzw //sample_state tex0Sampler;
r2.xyz = tex2D(tex0, in.TEXCOORD2.zw).yzw //sample_state tex0Sampler;
r3.xyz = tex2D(tex0, in.TEXCOORD3.xy).yzw //sample_state tex0Sampler;
r4.yzw = tex2D(tex0, in.TEXCOORD3.zw).zwy //sample_state tex0Sampler;
r5.x = tex2D(tex0, in.TEXCOORD4.xy).z //sample_state tex0Sampler;
r5.y = tex2D(tex0, in.TEXCOORD4.zw).z //sample_state tex0Sampler;
r5.z = tex2D(tex0, in.TEXCOORD5.xy).z //sample_state tex0Sampler;
r5.w = tex2D(tex0, in.TEXCOORD5.zw).z //sample_state tex0Sampler;
r6.x = r1.y;
r6.y = r2.y;
r6.z = r3.y;
r6.w = r4.y;
r5.xyzw = r5.xyzw + r6.xyzw;
r0.x = dot(r5.xyzw, float4(0.1, 0.1, 0.1, 0.1));
r5.y = r0.z*0.2 + r0.x;
r0.x = r0.w * in.TEXCOORD1.z;
r0.x = r0.x*0.85 + r0.w;
r6.x = r1.z;
r6.y = r2.z;
r6.z = r3.z;
r6.w = r4.z;
r6.xyzw = -r0.xxxx + r6.xyzw;
r6.xyzw = saturate(r6.xyzw * float4(100000.0, 100000.0, 100000.0, 100000.0));
r0.x = dot(r6.xyzw, float4(1.0, 1.0, 1.0, 1.0));
r0.x = min(r0.x, 1.0);
r4.x = r1.x;
r4.y = r2.x;
r4.z = r3.x;
r1.xyzw = r4.xyzw * r6.xyzw;
r0.zw = max(r1.zw, r1.xy);
r0.z = max(r0.w, r0.z);
r0.x = -r0.x + 1.0;
r5.x = r0.y*r0.x + r0.z;
r0.xy = saturate(r5.xy);
r0.xy = tex2D(EdgeToneTex, r0.xy).xw //sample_state EdgeToneTexSampler;
r0.z = -r5.y + 1.0;
r0.z = saturate(r0.z + r0.z);
r0.y = r0.z * r0.y;
r0.x = -r0.x + 1.0;
out.SV_Target.xyz = r0.yyy * r0.xxx;
out.SV_Target.w = 1.0;
return;