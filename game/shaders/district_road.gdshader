shader_type spatial;
uniform sampler2D asphalt_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D pavement_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool junction = false;
uniform bool crossing = false;
varying vec2 meters;
void vertex(){ meters=VERTEX.xz; }
void fragment(){
	float width=max(fwidth(meters.x),0.015);
	float road=1.0-smoothstep(3.98,4.02,abs(meters.x));
	if(junction) road=max(road,1.0-smoothstep(3.98,4.02,abs(meters.y)));
	vec3 asphalt=texture(asphalt_texture,meters/2.0).rgb*0.65;
	vec3 pavement=texture(pavement_texture,meters/1.2).rgb*0.58;
	ALBEDO=mix(pavement,asphalt,road);
	float edge=(1.0-smoothstep(0.035,0.035+width,abs(abs(meters.x)-3.65)))*road;
	float dash=1.0-smoothstep(0.055,0.055+width,abs(meters.x));
	dash*=step(1.7,mod(meters.y+6.0,5.0));
	if(!junction) ALBEDO=mix(ALBEDO,vec3(0.74,0.70,0.61),max(edge*0.7,dash*0.75));
	if(crossing){
		float stripe=step(0.2,mod(meters.x+4.0,0.9))*step(abs(meters.x),3.4)*step(abs(meters.y),1.4);
		ALBEDO=mix(ALBEDO,vec3(0.80,0.78,0.72),stripe);
	}
	ROUGHNESS=0.9; METALLIC=0.0;
}
