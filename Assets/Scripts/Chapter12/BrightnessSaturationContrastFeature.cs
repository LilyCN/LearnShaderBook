using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BrightnessSaturationContrastFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class BSCSettings
    {
        [Range(0.0f, 3.0f)]
        public float brightness = 1.0f;
        [Range(0.0f, 3.0f)]
        public float saturation = 1.0f;
        [Range(0.0f, 3.0f)]
        public float contrast = 1.0f;
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material material = null;
    }

    public BSCSettings settings = new BSCSettings();

    class BrightnessSaturationContrastRenderPass : ScriptableRenderPass
    {
        public float brightness;
        public float saturation;
        public float contrast;
        public Material material;
        string tagId = "BSCRenderPass";
        RenderTargetHandle tempColorTexture;

        public BrightnessSaturationContrastRenderPass()
        {
            tempColorTexture.Init("_TempColorTexture");
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (material == null)
            {
                return;
            }
            
            material.SetFloat("_Brightness", brightness);
            material.SetFloat("_Saturation", saturation);
            material.SetFloat("_Contrast", contrast);
            
            CommandBuffer cmd = CommandBufferPool.Get(tagId);
            RenderTargetIdentifier cameraTexture = renderingData.cameraData.renderer.cameraColorTarget;
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;
            cmd.GetTemporaryRT(tempColorTexture.id, opaqueDesc);
            cmd.Blit(cameraTexture, tempColorTexture.Identifier(), material);
            cmd.Blit(tempColorTexture.Identifier(), cameraTexture);

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }

    BrightnessSaturationContrastRenderPass scriptablePass;

    public override void Create()
    {
        scriptablePass = new BrightnessSaturationContrastRenderPass();
        scriptablePass.brightness = settings.brightness;
        scriptablePass.saturation = settings.saturation;
        scriptablePass.contrast = settings.contrast;
        scriptablePass.material = settings.material;

        scriptablePass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(scriptablePass);
    }
}
