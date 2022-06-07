#version 330

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec3 aNormal;
layout (location = 3) in vec2 aTexCoord;

out vec2 texCoord;
out vec4 vertex_color;
out vec3 vertex_normal;
out vec3 vertex_view;

// Light
struct Material{
	vec3 Ka;
	vec3 Kd;
	vec3 Ks;
	float shininess;
};

struct Light{
	vec3 position;
	vec3 direction;
	vec3 spotDirection;
	vec3 Ambient;
	vec3 Diffuse;
	vec3 Specular;
	float spotExponent;
	float spotCutoff;
	float constant;
	float linear;
	float quadratic;
};



uniform mat4 um4p;	
uniform mat4 um4v;
uniform mat4 um4m;
uniform int light_type;
uniform Material material;
uniform Light light[3];

// [TODO] passing uniform variable for texture coordinate offset
uniform vec2 eyeOffset;
uniform int isEye;

// Calculate Light
vec4 directionalLight(vec3 normal, vec3 V){
	vec4 viewingLight = um4v * vec4(light[0].position, 1.0f);
	vec3 lightDir = normalize(viewingLight.xyz + V);
	vec3 H = normalize(lightDir + V);

	float diff = dot(lightDir, normal);
	float spec = pow(max(dot(H, normal), 0), material.shininess);

	vec3 color = light[0].Ambient * material.Ka;
	color += diff * light[0].Diffuse * material.Kd;
	color += spec * light[0].Specular * material.Ks;

	return vec4(color, 1.0f);
}

vec4 pointLight(vec3 normal, vec3 V){
	vec4 viewingLight = um4v * vec4(light[1].position, 1.0f);
	vec3 lightDir = normalize(viewingLight.xyz + V);
	vec3 H = normalize(lightDir + V);

	float diff = dot(lightDir, normal);
	float spec = pow(max(dot(H, normal), 0), material.shininess);

	// Attenuation
	float dist = length(viewingLight.xyz + V);
	float attenuation = 1.0 / (light[1].constant + light[1].linear * dist + pow(dist, 2) * light[1].quadratic);

	vec3 color = light[1].Ambient * material.Ka;
	color += diff * light[1].Diffuse * material.Kd;
	color += spec * light[1].Specular * material.Ks;
	color *= attenuation;

	return vec4(color, 1.0f);
}

vec4 spotLight(vec3 normal, vec3 V){
	vec4 viewingLight = um4v * vec4(light[2].position, 1.0f);
	vec3 lightDir = normalize(viewingLight.xyz + V);
	vec3 H = normalize(lightDir + V);

	float diff = dot(lightDir, normal);
	float spec = pow(max(dot(H, normal), 0), material.shininess);

	// Attenuation
	float dist = length(viewingLight.xyz + V);
	float attenuation = 1.0f / (light[2].constant + light[2].linear * dist + pow(dist, 2) * light[2].quadratic);

	// Spotlight intensity
	float theta = dot(-lightDir, normalize(light[2].spotDirection.xyz));
	float intensity = pow(max(theta, 0), light[2].spotExponent);

	vec3 color;
	
	if(theta > cos(light[2].spotCutoff / 180.0 * 3.1415926)) {
		color =  attenuation * intensity * (diff * light[2].Diffuse * material.Kd + spec * light[2].Specular * material.Ks);
		color += light[2].Ambient * material.Ka;
	}
	else
		color = light[2].Ambient * material.Ka;

	return vec4(color, 1.0f);
}



void main() 
{
	vec4 vertex = um4v * um4m * vec4(aPos.x, aPos.y, aPos.z, 1.0);
	vec4 normal = transpose(inverse(um4v * um4m)) * vec4(aNormal, 0.0);

	vertex_view = vertex.xyz;
	vertex_normal = normal.xyz;

	vec3 N = normalize(vertex_normal);
	vec3 V = -vertex_view;

	vertex_color = vec4(0, 0, 0, 0);

	if(light_type == 0)
		vertex_color += directionalLight(N, V);
	else if(light_type == 1)
		vertex_color += pointLight(N, V);
	else if(light_type == 2)
		vertex_color += spotLight(N, V);

	// [TODO]
	texCoord = aTexCoord;
	if (isEye == 1)
		texCoord = aTexCoord + eyeOffset;
	else
		texCoord = aTexCoord;
	gl_Position = um4p * um4v * um4m * vec4(aPos, 1.0);
}
