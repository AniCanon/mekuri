package app.mekuri

/**
 * The fold shader, a term-for-term transliteration of the Metal source.
 *
 * The axis and lead expressions are frozen text: the compiler reassociates the
 * product chains, so an arithmetically neutral term still changes rendered
 * pixels. New behaviour is a transformation of the uniforms, never a new term
 * here. The whole-mode statement sequence (sample, reach, shade, return) is
 * frozen for the same reason, and each face branch has its own helper rather
 * than sharing a converted value.
 */
internal const val MEKURI_FOLD_AGSL: String = """
uniform shader layer;
uniform float2 size;
uniform float progress;
uniform float heldRadius;
uniform float radiusSlope;
uniform float shear;
uniform float bow;
uniform float backFaceDim;
uniform float shadowWidth;
uniform float shadowOpacity;
uniform float face;

const float mekuriPi = 3.14159265;

// Unit light direction in the x/z plane, z toward the viewer.
const float2 mekuriLight = float2(0.45, 0.893);

const float mekuriFaceFront = 1.0;
const float mekuriFaceBack = 2.0;
const float mekuriFaceShadow = 3.0;
const half4 mekuriClear = half4(0.0);

// Diffuse shade of a back-face pixel whose surface normal is (nx, nz),
// between `dim` when turned fully from the light and 1 when facing it.
half mekuriBackShade(float nx, float nz, float dim) {
    float facing = saturate(nx * mekuriLight.x + nz * mekuriLight.y);
    return half(mix(dim, 1.0, facing * facing * facing));
}

// Shadow the lifted sheet casts on the page beneath, `d` past the crease.
// Darkest where the roll is tightest; reaches two radii past the rim.
half4 mekuriContactShadow(float d, float radius, float heldR, float opacity) {
    float reach = 1.0 - saturate((d - radius) / (2.0 * radius));
    float alpha = opacity * (heldR / radius) * reach * reach;
    return half4(0.0, 0.0, 0.0, half(alpha));
}

// Shadow the crease casts on the page beneath the leaf, `d` (negative) short
// of the crease. Same ramp as the whole-face dimming of the flat front.
half4 mekuriCreaseShadow(float d, float width, float opacity) {
    half reach = half(saturate(1.0 + d / width));
    return half4(0.0, 0.0, 0.0, half(opacity) * reach * reach);
}

half4 main(float2 position) {
    float held = 1.0 - position.y / size.y;
    float lead = bow * size.x * progress * (1.0 - progress);
    float axis = size.x * (1.0 - progress) + shear * (position.y - size.y * 0.5) - lead * held * held;
    float flap = size.x - axis;
    float d = position.x - axis;
    float radius = heldRadius + radiusSlope * (size.y - position.y);
    float halfTurn = mekuriPi * radius;

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
            half4 color = layer.eval(float2(axis + back, position.y));
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
            return layer.eval(float2(axis + front, position.y));
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
        half4 color = layer.eval(float2(axis + behind, position.y));
        return half4(color.rgb * mekuriBackShade(0.0, 1.0, backFaceDim), color.a);
    }

    if (face == mekuriFaceBack) {
        return mekuriClear;
    }
    if (face == mekuriFaceShadow) {
        return mekuriCreaseShadow(d, shadowWidth, shadowOpacity);
    }
    if (face == mekuriFaceFront) {
        return layer.eval(position);
    }

    half4 sheet = layer.eval(position);
    float reach = saturate(1.0 + d / shadowWidth);
    float shade = shadowOpacity * reach * reach;
    return half4(sheet.rgb * (1.0 - half(shade)), sheet.a);
}
"""
