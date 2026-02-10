shader_type canvas_item;

uniform float wobble_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wobble_amount : hint_range(0.0, 1.0) = 0.1;
uniform float distortion_strength : hint_range(0.0, 2.0) = 1.0;

// Simple random function
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// 2D noise
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(random(i), random(i + vec2(1.0, 0.0)), f.x),
        mix(random(i + vec2(0.0, 1.0)), random(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void fragment() {
    float time = TIME * wobble_speed;
    vec2 pos = UV - 0.5;
    float dist = length(pos);
    float angle = atan(pos.y, pos.x);
    
    // Create organic, shifting noise
    float n = noise(vec2(angle * 2.5 + time, dist * 5.0 - time));
    n += noise(vec2(angle * 4.0 - time * 0.5, dist * 8.0 + time * 0.2)) * 0.5;
    n *= 0.5;
    
    // Distort the radius based on noise
    float radius = 0.3 + n * wobble_amount;
    
    // Smoothstep
    float mask = smoothstep(radius, radius - 0.05, dist);
    
    // Add inner turbulence
    float inner_noise = noise(UV * 5.0 + vec2(time * 0.5, -time));
    float alpha = mask * (0.8 + 0.2 * inner_noise); 
    
    // INVERTED: Black blob
    COLOR = vec4(0.0, 0.0, 0.0, alpha); 
}
