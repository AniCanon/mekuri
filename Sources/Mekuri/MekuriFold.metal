#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Unit light direction in the x/z plane, z toward the viewer.
constant float2 mekuriLight = float2(0.45, 0.893);

// Diffuse shade of a back-face pixel whose surface normal is (nx, nz),
// between `dim` when turned fully from the light and 1 when facing it.
static half mekuriBackShade(float nx, float nz, float dim) {
    float facing = saturate(nx * mekuriLight.x + nz * mekuriLight.y);
    return half(mix(dim, 1.0, facing * facing * facing));
}

// Shadow the lifted sheet casts on the page beneath, `d` past the crease.
// Darkest where the roll is tightest; reaches two radii past the rim.
static half4 mekuriContactShadow(float d, float radius, float heldRadius, float opacity) {
    float reach = 1.0 - saturate((d - radius) / (2.0 * radius));
    float alpha = opacity * (heldRadius / radius) * reach * reach;
    return half4(0.0h, 0.0h, 0.0h, half(alpha));
}

// Shadow the crease casts on the page beneath the leaf, `d` (negative) short
// of the crease. Same ramp as the whole-face dimming of the flat front.
static half4 mekuriCreaseShadow(float d, float width, float opacity) {
    half reach = half(saturate(1.0 + d / width));
    return half4(0.0h, 0.0h, 0.0h, half(opacity) * reach * reach);
}

// Which face of the leaf a pass draws. 0 samples one layer for both faces
// and carries both shadows. `front` and `back` each return transparent where
// their face is not visible, so two passes over different layers stack into
// one leaf; neither carries a shadow. `shadow` returns only the shadows, for
// a layer beneath the leaf, so each shadow composites exactly once.
constant float mekuriFaceFront = 1.0;
constant float mekuriFaceBack = 2.0;
constant float mekuriFaceShadow = 3.0;
constant half4 mekuriClear = half4(0.0h);

// Folds the layer around a cylinder whose axis sweeps from the trailing edge
// (progress 0) to the leading edge (progress 1). Distance is measured along
// x; `shear` is a ratio of horizontal travel per unit of vertical distance
// from the page centre, never an angle. The free corner is at y == 0 and the
// held end at y == size.y; `heldRadius` is the cylinder radius at the held
// end and `radiusSlope` its growth per point of fold distance. `bow` is the
// crease bow, 0...1. Formulas match MekuriFoldGeometry.
[[ stitchable ]] half4 mekuriFold(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float progress,
    float heldRadius,
    float radiusSlope,
    float shear,
    float bow,
    float backFaceDim,
    float shadowWidth,
    float shadowOpacity,
    float face
) {
    float held = 1.0 - position.y / size.y;
    float lead = bow * size.x * progress * (1.0 - progress);
    float axis = size.x * (1.0 - progress) + shear * (position.y - size.y * 0.5) - lead * held * held;
    float flap = size.x - axis;
    float d = position.x - axis;
    float radius = heldRadius + radiusSlope * (size.y - position.y);
    float halfTurn = M_PI_F * radius;

    if (d > radius) {
        if (face == mekuriFaceFront || face == mekuriFaceBack) {
            return mekuriClear;
        }
        return mekuriContactShadow(d, radius, heldRadius, shadowOpacity);
    }

    if (d >= 0.0) {
        float front = radius * asin(clamp(d / radius, -1.0, 1.0));
        float back = halfTurn - front;
        if (back <= flap) {
            if (face == mekuriFaceFront || face == mekuriFaceShadow) {
                return mekuriClear;
            }
            half4 color = layer.sample(float2(axis + back, position.y));
            float u = d / radius;
            half shade = mekuriBackShade(u, sqrt(saturate(1.0 - u * u)), backFaceDim);
            return half4(color.rgb * shade, color.a);
        }
        if (face == mekuriFaceBack) {
            return mekuriClear;
        }
        if (front <= flap) {
            if (face == mekuriFaceShadow) {
                return mekuriClear;
            }
            return layer.sample(float2(axis + front, position.y));
        }
        if (face == mekuriFaceFront) {
            return mekuriClear;
        }
        return mekuriContactShadow(d, radius, heldRadius, shadowOpacity);
    }

    float behind = halfTurn - d;
    if (behind <= flap) {
        if (face == mekuriFaceFront || face == mekuriFaceShadow) {
            return mekuriClear;
        }
        half4 color = layer.sample(float2(axis + behind, position.y));
        return half4(color.rgb * mekuriBackShade(0.0, 1.0, backFaceDim), color.a);
    }

    if (face == mekuriFaceBack) {
        return mekuriClear;
    }
    if (face == mekuriFaceShadow) {
        return mekuriCreaseShadow(d, shadowWidth, shadowOpacity);
    }
    if (face == mekuriFaceFront) {
        return layer.sample(position);
    }

    half4 flat = layer.sample(position);
    float reach = saturate(1.0 + d / shadowWidth);
    float shade = shadowOpacity * reach * reach;
    return half4(flat.rgb * (1.0h - half(shade)), flat.a);
}
