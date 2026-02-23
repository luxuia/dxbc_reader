class GlobalPS{
	float4	CameraPosPS;
	float4	CameraInfoPS;
	float4	EnvInfo;
	float4	SunColor;
	float4	SunDirection;
	float4	AmbientColor;
	float4	FogColor;
	float4	ShadowColor;
	float4	ScreenColor;
	float4	ReflectionPos;
	float4	ScreenInfoPS;
	float4	Misc;
}
class Batch{
	float4x3	World;
	float4	cTintColor1;
	float4	cTintColor2;
	float4	cTintColor3;
	float4	cShadowBias;
	float4	cPointCloud;
	float4	cParamter;
	float4	cParamter2;
	float4	cVirtualLitDir;
	float4	cVirtualLitColor;
	float4x4	WorldViewProj;
	float4x4	LastWorldViewProjTex;
}
class Shader{
	float	cAliasingFactor;
	float	cEnvStrength;
	float	cRoughnessLow;
	float	cRoughnessHigh;
	float	cBloomScale;
	float	cMetallic;
	float	cSmoothness;
	float	cFlowPeriod;
	float	cBlendSharpness;
	float4	cBlockScale;
	float4	cBlockShrinkage;
	float4	cLightMapScale;
	float4	cLightMapUVTransform;
	float4	cOverlayMapUVTransform;
}
class INPUT {
	SV_Position;
	TEXCOORD1;
	TEXCOORD2;
	TEXCOORD3;
	TEXCOORD4;
	TEXCOORD5;
	TEXCOORD6;
	TEXCOORD7;
	TEXCOORD8;
}
class OUT {
	SV_Target;
}
void main(INPUT in) {
	// ps_5_0
	// dcl_globalFlags refactoringAllowed
	// dcl_constantbuffer CB3[12], immediateIndexed
	// dcl_constantbuffer CB0[14], immediateIndexed
	// dcl_constantbuffer CB1[8], immediateIndexed
	// dcl_sampler s1, mode_default
	// dcl_sampler s2, mode_default
	// dcl_sampler s4, mode_default
	// dcl_sampler s5, mode_default
	// dcl_sampler s7, mode_default
	// dcl_sampler s8, mode_default
	// dcl_sampler s9, mode_default
	// dcl_resource_texture2d (float,float,float,float) t1
	// dcl_resource_texture2d (float,float,float,float) t2
	// dcl_resource_texture2d (float,float,float,float) t4
	// dcl_resource_texture2d (float,float,float,float) t5
	// dcl_resource_texture2d (float,float,float,float) t7
	// dcl_resource_texture2d (float,float,float,float) t8
	// dcl_resource_texture2d (float,float,float,float) t9
	// dcl_input_ps linear centroid v1.xyzw
	// dcl_input_ps linear v2.w
	// dcl_input_ps linear v3.xyz
	// dcl_input_ps linear v4.xyz
	// dcl_input_ps linear v5.xyzw
	// dcl_input_ps linear v6.xyzw
	// dcl_input_ps linear v7.xyzw
	// dcl_input_ps linear v8.xyzw
	// dcl_output o0.xyzw
	// dcl_temps 9
	r0.y = Batch.cShadowBias.w;
	r0.x = 0;
	r1.xyz = in.TEXCOORD8.xyz/in.TEXCOORD8.www;
	r0.zw = r1.xy/Batch.cShadowBias.ww;
	r0.zw = r0.zw + float2(-0.5, -0.5);
	r0.zw = frac(r0.zw);
	r2.xy = r0.zw + float2(-0.5, -0.5);
	r2.xy = -r2.xy*Batch.cShadowBias.ww + r1.xy;
	r3.xyzw = r0.yxxy + r2.xyxy;
	r2.x = tShadowMap.Sample(sShadowMapSampler, r2.xy).x //sample sShadowMapSampler;
	r0.xy = r0.xy + r3.xy;
	r2.w = tShadowMap.Sample(sShadowMapSampler, r0.xy).x //sample sShadowMapSampler;
	r2.y = tShadowMap.Sample(sShadowMapSampler, r3.xy).x //sample sShadowMapSampler;
	r2.z = tShadowMap.Sample(sShadowMapSampler, r3.zw).x //sample sShadowMapSampler;
	r0.x = min(r1.z, 0.99999);
	r1.xy = r1.xy + float2(-0.5, -0.5);
	r1.xy = -abs(r1.xy) + float2(0.5, 0.5);
	r0.y = min(r1.y, r1.x);
	r1.xyzw = r2.xyzw < r0.xxxx;
	r2.xy = r1.xz;
	r1.xyzw = r1.xyzw & float4(0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000) // 0x3f800000=1.0, maybe means: if (r1.xyzw==0xFFFFFFFF) r1.xyzw=1.0;
	r1.yw = r2.xy + r1.yw;
	r0.xz = r0.zz*r1.yw + r1.xz;
	r0.z = -r0.x + r0.z;
	r0.x = r0.w*r0.z + r0.x;
	r0.z = in.TEXCOORD2.w + GlobalPS.Misc.y;
	r0.z = r0.z * 0.45;
	r0.w = dot(in.TEXCOORD4.xyzx, in.TEXCOORD4.xyzx);
	r0.w = sqrt(r0.w);
	r0.z = r0.w/r0.z;
	r0.w = r0.w/Batch.cParamter.w;
	r0.zw = -r0.zw + float2(3.0, 1.0);
	r0.yw = saturate(r0.yw * float2(10.0, 3.333333));
	r0.z = max(r0.z, 0.6);
	r0.z = min(r0.z, 1.0);
	r1.xyzw = tLightMap.Sample(sLightMapSampler, in.TEXCOORD1.zw).xyzw //sample sLightMapSampler;
	r1.w = max(r1.w, 0.0);
	r1.xyz = r1.xyz * r1.xyz;
	r1.xyz = r1.xyz * Shader.cLightMapScale.xyz;
	r1.xyz = r1.xyz*GlobalPS.AmbientColor.www + in.TEXCOORD5.xyz;
	r0.x = -r1.w*r0.z + r0.x;
	r0.z = r0.z * r1.w;
	r0.x = r0.y*r0.x + r0.z;
	r0.x = min(r0.x, 1.0);
	r0.x = -r0.x*GlobalPS.ShadowColor.w + 1.0;
	r0.yz = in.TEXCOORD1.xy*Shader.cOverlayMapUVTransform.xy + Shader.cOverlayMapUVTransform.zw;
	r2.xyz = tMixtureMap.Sample(sMixtureMapSampler, r0.yz).xyz //sample sMixtureMapSampler;
	r3.xyz = tOverlayMap.Sample(sOverlayMapSampler, r0.yz).xyz //sample sOverlayMapSampler;
	r0.y = r2.z + r2.z;
	r0.y = frac(r0.y);
	r0.y = r0.y >= 0.5;
	r0.y = r0.y & 0x3f000000 ;
	r4.x = in.TEXCOORD6.w;
	r4.y = in.TEXCOORD7.w;
	r4.xy = Shader.cBlockScale.xx*in.TEXCOORD4.xz + r4.xy;
	r4.zw = frac(r4.xy);
	r5.xy = Shader.cBlockShrinkage.yy*r4.zw + Shader.cBlockShrinkage.xx;
	r6.y = r0.y + r5.x;
	r7.xyz = r2.zxy >= float3(0.5, 0.5, 0.5);
	r0.yz = r2.xy + float2(-0.5, -0.5);
	r0.yz = abs(r0.yz)*float2(3.0, 3.0) + float2(-0.45, -0.45);
	r0.yz = max(r0.yz, float2(0.0, 0.0));
	r2.xyz = r7.xyz & float3(0x3f000000, 0x3f000000, 0x3f000000) ;
	r6.xzw = r2.zxy + r5.xyx;
	r2.xy = ddx_coarse(r4.xy);
	r2.zw = ddy_coarse(r4.xy);
	r2.xyzw = abs(r2.xyzw) * Shader.cBlockShrinkage.yyyy;
	r2.xyzw = min(r2.xyzw, Shader.cBlockShrinkage.wwww);
	r1.w = r0.w*-0.975 + 1.6;
	r2.xyzw = r1.wwww * r2.xyzw;
	r4.xyzw = tNormalMap.SampleGrad(sNormalMapSampler, r6.yz, r2.xyxx, r2.zwzz).xyzw //sample_d;
	r5.xw = -r0.yz*r0.ww + r4.ww;
	r5.xw = r5.xw + float2(1.0, 1.0);
	r5.z = r6.w;
	r7.xyz = tAuxiliaryMap.SampleGrad(sAuxiliaryMapSampler, r5.zy, r2.xyxx, r2.zwzz).xyz //sample_d;
	r8.xyz = tBlockMap.SampleGrad(sBlockMapSampler, r5.zy, r2.xyxx, r2.zwzz).xyz //sample_d;
	r6.y = r5.y + 0.5;
	r1.w = r0.y*r0.w + r7.z;
	r7.xyz = -r4.xyw + r7.xyz;
	r1.w = r1.w >= r5.x;
	r1.w = r1.w & 0x3f800000 // 0x3f800000=1.0, maybe means: if (r1.w==0xFFFFFFFF) r1.w=1.0;
	r1.w = -r0.y*r0.w + r1.w;
	r5.xy = r0.ww * r0.yz;
	r0.y = Shader.cBlendSharpness.x*r1.w + r5.x;
	r4.xyw = r0.yyy*r7.xyz + r4.xyw;
	r3.xyz = r3.xyz * r4.zzz;
	r7.xyz = tAuxiliaryMap.SampleGrad(sAuxiliaryMapSampler, r6.xy, r2.xyxx, r2.zwzz).xyz //sample_d;
	r2.xyz = tBlockMap.SampleGrad(sBlockMapSampler, r6.xy, r2.xyxx, r2.zwzz).xyz //sample_d;
	r6.xyz = -r4.xyw + r7.xyz;
	r1.w = r0.z*r0.w + r7.z;
	r1.w = r1.w >= r5.w;
	r1.w = r1.w & 0x3f800000 // 0x3f800000=1.0, maybe means: if (r1.w==0xFFFFFFFF) r1.w=1.0;
	r0.z = -r0.z*r0.w + r1.w;
	r0.z = Shader.cBlendSharpness.x*r0.z + r5.y;
	r4.xyz = r0.zzz*r6.xyz + r4.xyw;
	r4.xy = r4.xy*float2(2.0, 2.0) + float2(-1.0, -1.0);
	r1.w = r4.z-1.0;
	r1.w = r0.w*r1.w + 1.0;
	r1.w = max(r1.w, 0.08);
	r1.w = r1.w * r1.w;
	r1.w = r1.w * r1.w;
	r4.xzw = r4.xxx*in.TEXCOORD6.xyz + in.TEXCOORD3.xyz;
	r4.xyz = r4.yyy*in.TEXCOORD7.xyz + r4.xzw;
	r2.w = dot(r4.xyzx, r4.xyzx);
	r2.w = rsqrt(r2.w);
	r4.xyz = r2.www * r4.xyz;
	r2.w = saturate(dot(r4.xyzx, GlobalPS.SunDirection.xyzx));
	r5.xyz = r2.www * GlobalPS.SunColor.xyz;
	r5.xyz = r5.xyz*r0.xxx + GlobalPS.AmbientColor.xyz;
	r6.xyz = r0.www * r5.xyz;
	r1.xyz = r1.xyz + r5.xyz;
	r0.x = dot(-in.TEXCOORD4.xyzx, -in.TEXCOORD4.xyzx);
	r0.x = rsqrt(r0.x);
	r5.xyz = -in.TEXCOORD4.xyz*r0.xxx + GlobalPS.SunDirection.xyz;
	r0.x = dot(r5.xyzx, r5.xyzx);
	r0.x = rsqrt(r0.x);
	r5.xyz = r0.xxx * r5.xyz;
	r0.x = saturate(dot(r4.xyzx, r5.xyzx));
	r2.w = r0.x*r1.w-r0.x;
	r0.x = r2.w*r0.x + 1.0;
	r0.x = r0.x * r0.x;
	r0.x = r0.x * 3.141593;
	r0.x = r1.w/r0.x;
	r0.x = r0.x * 0.016;
	r4.xyz = r0.xxx * r6.xyz;
	r5.xyz = -r3.xyz*float3(1.8, 1.8, 1.8) + r8.xyz;
	r6.xyz = r3.xyz * float3(1.8, 1.8, 1.8);
	r5.xyz = r0.yyy*r5.xyz + r6.xyz;
	r2.xyz = r2.xyz-r5.xyz;
	r0.xyz = r0.zzz*r2.xyz + r5.xyz;
	r0.xyz = -r3.xyz*float3(1.8, 1.8, 1.8) + r0.xyz;
	r0.xyz = r0.www*r0.xyz + r6.xyz;
	r0.xyz = r0.xyz * r0.xyz;
	r0.xyz = r0.xyz * float3(0.31831, 0.31831, 0.31831);
	r0.xyz = r1.xyz*r0.xyz + r4.xyz;
	r0.w = dot(r4.xyzx, float4(0.6378, 2.1456, 1.0, 0.0));
	r0.w = r0.w * Shader.cBloomScale.x;
	r0.w = r0.w >= 1.0;
	out.SV_Target.w = r0.w & 0x3f800000 // 0x3f800000=1.0, maybe means: if (r0.w==0xFFFFFFFF) out.SV_Target.w=1.0;
	r0.xyz = r0.xyz*GlobalPS.EnvInfo.zzz-GlobalPS.FogColor.xyz;
	r0.xyz = in.TEXCOORD5.www*r0.xyz + GlobalPS.FogColor.xyz;
	r1.xyz = -r0.xyz + GlobalPS.ScreenColor.xyz;
	r0.xyz = GlobalPS.ScreenColor.www*r1.xyz + r0.xyz;
	out.SV_Target.xyz = min(r0.xyz, float3(8.0, 8.0, 8.0));
	return;
}