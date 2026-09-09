package app.mekuri

import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.asComposeRenderEffect
import androidx.compose.ui.graphics.graphicsLayer

/** One shader object per pass; only its argument block is rebuilt per frame. */
@Composable
internal fun rememberMekuriFoldShader(): RuntimeShader = remember { RuntimeShader(MEKURI_FOLD_AGSL) }

/**
 * Folds the content this modifier is applied to. The shader folds a flap
 * entering from the right only, so a right-to-left pass mirrors the content
 * into the effect and mirrors the result back out; the mirror is spatial, never
 * a negated progress. The effect layer is a single render node, so translucent
 * output composites exactly once whatever the content is made of.
 *
 * [progress] is read inside the layer block, which is the per-frame path;
 * reading it in composition would rebuild the subtree every animation frame.
 */
internal fun Modifier.mekuriFold(
    shader: RuntimeShader,
    mirrorScale: Float,
    face: MekuriFace,
    isHinged: Boolean,
    configuration: MekuriConfiguration,
    progress: () -> Float,
): Modifier = this
    .graphicsLayer { scaleX = mirrorScale }
    .graphicsLayer {
        val uniforms = MekuriFoldUniforms.of(
            size = size,
            progress = progress(),
            configuration = configuration,
            face = face,
            hinge = if (isHinged) MekuriFoldUniforms.hinge(size) else null,
        )
        shader.setUniforms(uniforms)
        renderEffect = RenderEffect.createRuntimeShaderEffect(shader, LAYER_UNIFORM).asComposeRenderEffect()
        compositingStrategy = CompositingStrategy.Offscreen
        clip = true
    }
    .graphicsLayer { scaleX = mirrorScale }

private const val LAYER_UNIFORM = "layer"

private fun RuntimeShader.setUniforms(uniforms: MekuriFoldUniforms) {
    setFloatUniform("size", uniforms.size.width, uniforms.size.height)
    setFloatUniform("progress", uniforms.progress)
    setFloatUniform("heldRadius", uniforms.heldRadius)
    setFloatUniform("radiusSlope", uniforms.radiusSlope)
    setFloatUniform("shear", uniforms.shear)
    setFloatUniform("bow", uniforms.bow)
    setFloatUniform("backFaceDim", uniforms.backFaceDim)
    setFloatUniform("shadowWidth", uniforms.shadowWidth)
    setFloatUniform("shadowOpacity", uniforms.shadowOpacity)
    setFloatUniform("face", uniforms.face)
}
