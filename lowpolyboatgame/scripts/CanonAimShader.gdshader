shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_always, blend_mix;

uniform float glow_strength : hint_range(0.0, 5.0) = 2.5;
uniform float fade_length : hint_range(0.0, 1.0) = 0.8;
uniform float outline_thickness = 0.25;
uniform vec3 inside_color : source_color = vec3(1.0, 0.5, 0.0); // bright orange
uniform vec3 outline_color : source_color = vec3(1.0, 0.9, 0.4); // bright yellowish outline

uniform float wave_speed = 3.5;
uniform float wave_frequency = 2.0;
uniform float wave_amplitude = 0.7; // how much brightness oscillates
uniform float transparency : hint_range(0.0, 1.0) = 0.3; // lower = more see-through

void fragment() {
    float fade = 1.0 - UV.y * fade_length;
    fade = clamp(fade, 0.0, 1.0);

    float edge = min(UV.x, 1.0 - UV.x);
    float outline = smoothstep(0.0, outline_thickness, edge);
    vec3 base_color = mix(outline_color, inside_color, outline);

    float wave = sin(UV.y * wave_frequency * 6.283 - TIME * wave_speed);
    float brightness = 2.50 + wave * wave_amplitude;

    vec3 final_color = base_color * brightness;

    ALBEDO = final_color;
    EMISSION = final_color * glow_strength;

    // Only opacity affected by transparency
    ALPHA = fade * transparency;
}
