class INPUT {
	SV_POSITION;
	TEXCOORD1;
}
class OUT {
	SV_Target;
}
void main(INPUT in) {
	r0.xy = saturate(in.TEXCOORD1.yx);
	r0.xy = r0.xy-cb0[14].yx;
	r0.xy = saturate(r0.xy/cb0[14].wz);
	r0.zw = r0.xy * cb0[3].yy;
	r1.x = -cb0[3].y + 1.0;
	r0.xy = r0.yx*r1.xx + r0.zw;
	r0.xy = r0.xy*cb0[13].zw + cb0[13].xy;
	r0.xyzw = tex2D(t0, r0.xy).yxzw //sample_state s0;
	r1.x = r0.y*cb0[3].w + r0.x;
	r1.x = saturate(r0.z*cb0[3].w + r1.x);
	r0.xw = r0.xw-r1.xx;
	r0.xyz = r0.yxz/r0.www;
	r0.xyzw = r0.xyzw * cb0[15].xyzw;
	out.SV_Target.xyzw = r0.xyzw + r0.xyzw;
	return;
}