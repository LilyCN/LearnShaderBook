using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Learn.ShaderBook;

public class AdditionalRenderFeature : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        const string m_CustomTag = "CustomRenderPass";
        Material m_Material;
        BSCVolume m_CustomVolume;
        RenderTargetIdentifier m_ColorAttachment;
        RenderTargetHandle m_ColorTexture;

        public CustomRenderPass()
        {
            m_ColorTexture.Init(m_CustomTag);
        }

        public void Setup(RenderTargetIdentifier colorAttachment, Material material)
        {
            m_ColorAttachment = colorAttachment;
            m_Material = material;
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (!m_CustomVolume.IsActive() || renderingData.cameraData.isSceneViewCamera)
            {
                return ;
            }
            m_Material.SetFloat("_Brightness", m_CustomVolume.brightness.value);
            m_Material.SetFloat("_Saturation", m_CustomVolume.saturation.value);
            m_Material.SetFloat("_Contrast", m_CustomVolume.contrast.value);

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;
            cmd.GetTemporaryRT(m_ColorTexture.id, opaqueDesc);
            cmd.Blit(m_ColorAttachment, m_ColorTexture.Identifier(), m_Material);
            cmd.Blit(m_ColorTexture.Identifier(), m_ColorAttachment);
        }
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            VolumeStack stack = VolumeManager.instance.stack;
            m_CustomVolume = stack.GetComponent<BSCVolume>();
            if (m_CustomVolume == null)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(m_CustomTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            cmd.ReleaseTemporaryRT(m_ColorTexture.id);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    public Shader m_CustomShader;
    Material m_Material;

    CustomRenderPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (m_CustomShader == null)
        {
            return;
        }
        if (m_Material == null)
        {
            m_Material = CoreUtils.CreateEngineMaterial(m_CustomShader);
        }
        m_ScriptablePass.Setup(renderer.cameraColorTarget, m_Material);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


