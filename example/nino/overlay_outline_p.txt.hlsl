class CBUSE_UB_CAMERA_IDX{
	float3	u_eyePos;
	float3	u_eyeDir;
	float3	u_eyeUpDir;
	float4	u_depthLinear;
	float4	u_eyeNearFarInvAspect;
	float3x4	u_mtxEyeSphere;
	float4	u_shadowSampleParams;
	float4	u_pointLightRWParam;
	float3	u_RayleighColorP20;
	float3	u_RayleighColorP10;
	float3	u_RayleighColorO00;
	float3	u_RayleighColorM10;
	float3	u_RayleighColorM20;
	float3	u_HeightRayleighColor;
	float3	u_MieColorP20;
	float3	u_MieColorO00;
	float3	u_MieColorM20;
	float4	u_fogWorldParam0;
	float4	u_fogWorldParam1;
	float4	u_fogHeightParam0;
	float4	u_fogHeightParam1;
}
class CB0{
	float4	u_edge_fade;
	float2	u_texelSize;
	float	u_fxaaSpanMax;
	float	u_fxaaReduceMul;
}
class INPUT {
	SV_Position;
	COLOR;
	TEXCOORD1;
	TEXCOORD2;
}
class OUT {
	SV_Target;
	SV_Depth;
}
r0.xy = -in.TEXCOORD2.zw + in.TEXCOORD2.xy;
r0.x = tex2D(in_edge_tex, r0.xy).x //sample_state in_edge_texSampler;
r1.xyzw = in.TEXCOORD2.zwzw*float4(1.0, -1.0, -1.0, 1.0) + in.TEXCOORD2.xyxy;
r0.z = tex2D(in_edge_tex, r1.xy).x //sample_state in_edge_texSampler;
r1.x = tex2D(in_edge_tex, r1.zw).x //sample_state in_edge_texSampler;
r1.zw = in.TEXCOORD2.zw + in.TEXCOORD2.xy;
r0.w = tex2D(in_edge_tex, r1.zw).x //sample_state in_edge_texSampler;
r1.z = tex2D(in_edge_tex, in.TEXCOORD2.xy).x //sample_state in_edge_texSampler;
r0.xy = r0.xz;
r1.y = r0.w;
r2.xy = min(r0.xy, r1.xy);
r1.w = min(r2.y, r2.x);
r1.w = min(r1.w, r1.z);
r2.xy = max(r0.xy, r1.xy);
r2.x = max(r2.y, r2.x);
r1.z = max(r1.z, r2.x);
r0.z = r0.z + r0.x;
r2.x = r0.w + r1.x;
r2.x = r0.z-r2.x;
r2.xz = -r2.xx;
r0.xy = r0.xy + r1.xy;
r2.yw = -r0.yy + r0.xx;
r0.x = r1.x + r0.z;
r0.x = r0.w + r0.x;
r0.x = r0.x * CB0.u_fxaaReduceMul.w;
r0.x = r0.x * 0.25;
r0.x = max(r0.x, 0.007813);
r0.y = min(abs(r2.w), abs(r2.z));
r0.x = r0.x + r0.y;
r0.x = rcp(r0.x);
r0.xyzw = r0.xxxx * r2.xyzw;
r0.xyzw = max(r0.xyzw, -CB0.u_fxaaSpanMax.zzzz);
r0.xyzw = min(r0.xyzw, CB0.u_fxaaSpanMax.zzzz);
r0.xyzw = r0.xyzw * CB0.u_texelSize.xyxy;
r2.xyzw = r0.zwzw*float4(-0.166667, -0.166667, 0.166667, 0.166667) + in.TEXCOORD2.xyxy;
r1.x = tex2D(in_edge_tex, r2.xy).x //sample_state in_edge_texSampler;
r1.y = tex2D(in_edge_tex, r2.zw).x //sample_state in_edge_texSampler;
r1.x = r1.y + r1.x;
r1.xy = r1.xx * float2(0.5, 0.25);
r0.xyzw = r0.xyzw*float4(-0.5, -0.5, 0.5, 0.5) + in.TEXCOORD2.xyxy;
r0.x = tex2D(in_edge_tex, r0.xy).x //sample_state in_edge_texSampler;
r0.y = tex2D(in_edge_tex, r0.zw).x //sample_state in_edge_texSampler;
r0.x = r0.y + r0.x;
r0.x = r0.x*0.25 + r1.y;
r0.y = r0.x < r1.w;
r0.z = r1.z < r0.x;
r0.y = r0.z | r0.y;
r0.x = r0.y;
r0.y = r0.x-0.003922;
r0.y = r0.y < 0.0;
if (r0.y != 0) discard;
r0.y = 0.1 < r0.x;
if (r0.y != 0) {
	r1.xy = in.TEXCOORD2.xy + CB0.u_edge_fade.zw;
	r1.zw = in.TEXCOORD2.yx;
	r0.y = tex2D(in_depth_tex, r1.xz).x //sample_state in_depth_texSampler;
	r2.xy = in.TEXCOORD2.xy-CB0.u_edge_fade.zw;
	r2.zw = in.TEXCOORD2.yx;
	r0.z = tex2D(in_depth_tex, r2.xz).x //sample_state in_depth_texSampler;
	r1.x = tex2D(in_depth_tex, r1.wy).x //sample_state in_depth_texSampler;
	r1.y = tex2D(in_depth_tex, r2.wy).x //sample_state in_depth_texSampler;
	r0.yz = min(r0.yz, r1.xy);
	r0.y = min(r0.z, r0.y);
} else {
	r0.y = tex2D(in_depth_tex, in.TEXCOORD2.xy).x //sample_state in_depth_texSampler;
}
r0.z = dot(CBUSE_UB_CAMERA_IDX.u_eyeNearFarInvAspect.yyyy, CBUSE_UB_CAMERA_IDX.u_eyeNearFarInvAspect.xxxx);
r0.w = -CBUSE_UB_CAMERA_IDX.u_eyeNearFarInvAspect.x + CBUSE_UB_CAMERA_IDX.u_eyeNearFarInvAspect.y;
r1.x = CBUSE_UB_CAMERA_IDX.u_eyeNearFarInvAspect.x + CBUSE_UB_CAMERA_IDX.u_eyeNearFarInvAspect.y;
r0.w = r0.y*r0.w-r1.x;
r0.z = r0.z/r0.w;
r0.z = -r0.z-CB0.u_edge_fade.x;
r0.z = saturate(r0.z * CB0.u_edge_fade.y);
r0.z = -r0.z + 1.0;
out.SV_Target.xyz = -r0.zzz*r0.xxx + float3(1.0, 1.0, 1.0);
out.SV_Target.w = 1.0;
oDepth = r0.y;
return;