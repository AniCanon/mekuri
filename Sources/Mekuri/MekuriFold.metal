#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Folds the layer around a cylinder of `radius` whose axis sweeps from the
// trailing edge (progress 0) to the leading edge (progress 1). Distance is
// measured along x; `shear` is a ratio of horizontal travel per unit of
// vertical distance from the page centre, never an angle.
[[ stitchable ]] half4 mekuriFold(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float progress,
    float radius,
    float shear,
    float backFaceDim,
    float shadowWidth,
    float shadowOpacity
) {
    float axis = size.x * (1.0 - progress) + shear * (position.y - size.y * 0.5);
    float flap = size.x - axis;
    float d = position.x - axis;
    float halfTurn = M_PI_F * radius;

    if (d > radius) {
        return half4(0.0h);
    }

    if (d >= 0.0) {
        float front = radius * asin(clamp(d / radius, -1.0, 1.0));
        float back = halfTurn - front;
        if (back <= flap) {
            half4 color = layer.sample(float2(axis + back, position.y));
            return half4(color.rgb * backFaceDim, color.a);
        }
        if (front <= flap) {
            return layer.sample(float2(axis + front, position.y));
        }
        return half4(0.0h);
    }

    float behind = halfTurn - d;
    if (behind <= flap) {
        half4 color = layer.sample(float2(axis + behind, position.y));
        return half4(color.rgb * backFaceDim, color.a);
    }

    half4 flat = layer.sample(position);
    float shade = shadowOpacity * saturate(1.0 + d / shadowWidth);
    return half4(flat.rgb * (1.0h - half(shade)), flat.a);
}
