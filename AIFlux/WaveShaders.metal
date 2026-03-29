#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 waterRipple(float2 position, float2 size, float time, float active) {
    if (active < 0.5) {
        return position;
    }

    float2 center = size * 0.5;
    float2 delta = position - center;
    float distance = length(delta);

    if (distance < 0.001) {
        return position;
    }

    float wave = sin(distance * 0.065 - time * 14.0) * exp(-distance * 0.008) * 14.0;
    float2 direction = normalize(delta);

    return position + direction * wave;
}

[[ stitchable ]] half4 loaderGlow(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size;
    float sweep = fract(time * 0.35);
    float band = smoothstep(sweep - 0.20, sweep, uv.x) * (1.0 - smoothstep(sweep, sweep + 0.20, uv.x));
    half boost = half(0.18 * band);
    return half4(color.rgb + boost, color.a);
}
