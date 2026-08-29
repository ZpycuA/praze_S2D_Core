shader_type canvas_item;
render_mode blend_mix;

// ============ 层 0（后层/脸） ============
uniform sampler2D layer_0_tex_0; // -90°（左侧脸）
uniform sampler2D layer_0_tex_1; // -45°（左半侧）
uniform sampler2D layer_0_tex_2; // 0°（正脸）
uniform sampler2D layer_0_tex_3; // 45°（右半侧）
uniform sampler2D layer_0_tex_4; // 90°（右侧脸）
uniform float layer_0_depth = 0.2;
uniform vec2 layer_0_anchor = vec2(0.5, 0.5);

// ============ 层 1（前层/前发） ============
uniform sampler2D layer_1_tex_0;
uniform sampler2D layer_1_tex_1;
uniform sampler2D layer_1_tex_2;
uniform sampler2D layer_1_tex_3;
uniform sampler2D layer_1_tex_4;
uniform float layer_1_depth = 0.8;
uniform vec2 layer_1_anchor = vec2(0.5, 0.5);

// ============ 全局参数 ============
uniform float view_angle = 0.0;     // 当前视角 -90 ~ 90
uniform float parallax_strength = 0.002;

// 对某一层的 5 个角度纹理进行采样并混合
vec4 sample_view_5(sampler2D tex0, sampler2D tex1, sampler2D tex2, 
                   sampler2D tex3, sampler2D tex4,
                   float angle, float depth, vec2 anchor, vec2 uv) {
    
    // 把角度从 [-90, 90] 映射到 [0, 4]
    float norm = (angle + 90.0) / 180.0;
    float float_index = norm * 4.0;
    
    // 视差偏移（基于锚点）
    vec2 centered_uv = uv - anchor;
    vec2 offset = vec2(angle * parallax_strength * depth, 0.0);
    vec2 final_uv = centered_uv + offset + anchor;
    
    // 防止越界采样（到边界处 clamp）
    final_uv = clamp(final_uv, vec2(0.0), vec2(1.0));
    
    // 用区间判断替代 floor/ceil，避免边界精度问题
    vec4 color;
    if (float_index < 1.0) {
        // 在 tex0 和 tex1 之间
        float t = smoothstep(0.0, 1.0, float_index);
        color = mix(texture(tex0, final_uv), texture(tex1, final_uv), t);
    } else if (float_index < 2.0) {
        float t = smoothstep(0.0, 1.0, float_index - 1.0);
        color = mix(texture(tex1, final_uv), texture(tex2, final_uv), t);
    } else if (float_index < 3.0) {
        float t = smoothstep(0.0, 1.0, float_index - 2.0);
        color = mix(texture(tex2, final_uv), texture(tex3, final_uv), t);
    } else if (float_index < 4.0) {
        float t = smoothstep(0.0, 1.0, float_index - 3.0);
        color = mix(texture(tex3, final_uv), texture(tex4, final_uv), t);
    } else {
        // float_index >= 4.0，直接采样 tex4
        color = texture(tex4, final_uv);
    }
    
    return color;
}

void fragment() {
    vec2 uv = UV;
    
    vec4 back_color = sample_view_5(
        layer_0_tex_0, layer_0_tex_1, layer_0_tex_2, layer_0_tex_3, layer_0_tex_4,
        view_angle, layer_0_depth, layer_0_anchor, uv
    );
    
    vec4 front_color = sample_view_5(
        layer_1_tex_0, layer_1_tex_1, layer_1_tex_2, layer_1_tex_3, layer_1_tex_4,
        view_angle, layer_1_depth, layer_1_anchor, uv
    );
    
    COLOR = mix(back_color, front_color, front_color.a);
}
