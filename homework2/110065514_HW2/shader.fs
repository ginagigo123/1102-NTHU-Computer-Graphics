#version 330 core

out vec4 FragColor;
in vec4 vertex_color;
in vec3 vertex_normal;
in vec3 vertex_view;

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

uniform mat4 view_matrix;
uniform Material material;
uniform int light_type;
uniform Light light[3];
uniform int is_perpixel;

vec4 directionalLight(vec3 N, vec3 V){
	vec4 viewingLight = view_matrix * vec4(light[0].position, 1.0f);	
	vec3 S = normalize(viewingLight.xyz + V);
	vec3 H = normalize(S + V);						

	float diff = dot(S, N);	
	float spec = pow(max(dot(H, N), 0), material.shininess);

	vec3 color = light[0].Ambient * material.Ka;
	color += diff * light[0].Diffuse * material.Kd;
	color += spec * light[0].Specular * material.Ks;

	return vec4(color, 1.0f);
}

vec4 pointLight(vec3 N, vec3 V){
	vec4 viewingLight = view_matrix * vec4(light[1].position, 1.0f);	
	vec3 S = normalize(viewingLight.xyz + V);			
	vec3 H = normalize(S + V);						

	float diff = dot(S, N);	
	float spec = pow(max(dot(H, N), 0), material.shininess);

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
	vec4 viewingLight = view_matrix * vec4(light[2].position, 1.0f);
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

void main() {
	// [TODO]
	// FragColor = vec4(vertex_normal, 1.0f);
	vec3 N = normalize(vertex_normal);
	vec3 V = - vertex_view;
	vec4 color = vec4(0, 0, 0, 0);

	if(light_type == 0)
		color += directionalLight(N, V);
	else if(light_type == 1)
		color += pointLight(N, V);
	else if(light_type == 2) 
		color += spotLight(N, V);

	if(is_perpixel == 0)
		FragColor = vertex_color;
	else
		FragColor = color;
}
