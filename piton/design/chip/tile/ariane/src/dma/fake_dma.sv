
module fake_dma 
(   
    input logic         axi_resetn,
    input logic         m_axi_mm2s_aclk,
    output logic[31:0]  m_axi_mm2s_araddr,
    output logic[1:0]   m_axi_mm2s_arburst,
    output logic[3:0]   m_axi_mm2s_arcache,
    output logic[7:0]   m_axi_mm2s_arlen,
    output logic[2:0]   m_axi_mm2s_arprot,
    input logic         m_axi_mm2s_arready,
    output logic[2:0]   m_axi_mm2s_arsize,
    output logic        m_axi_mm2s_arvalid,

    input logic[31:0]   m_axi_mm2s_rdata,
    input logic         m_axi_mm2s_rlast,
    output logic        m_axi_mm2s_rready,
    input logic[1:0]    m_axi_mm2s_rresp,
    input logic         m_axi_mm2s_rvalid,
    
    input logic         m_axi_s2mm_aclk,
    output logic[31:0]  m_axi_s2mm_awaddr,
    output logic[1:0]   m_axi_s2mm_awburst,
    output logic[3:0]   m_axi_s2mm_awcache,
    output logic[7:0]   m_axi_s2mm_awlen,
    output logic[2:0]   m_axi_s2mm_awprot,
    input logic         m_axi_s2mm_awready,
    output logic[2:0]   m_axi_s2mm_awsize,
    output logic        m_axi_s2mm_awvalid,

    output logic        m_axi_s2mm_bready,
    input logic[1:0]    m_axi_s2mm_bresp,
    input logic         m_axi_s2mm_bvalid,

    output logic[31:0]  m_axi_s2mm_wdata,
    output logic        m_axi_s2mm_wlast,
    input logic         m_axi_s2mm_wready,
    output logic[3:0]   m_axi_s2mm_wstrb,
    output logic        m_axi_s2mm_wvalid,

    output logic[31:0]  m_axis_mm2s_tdata,
    output logic[3:0]   m_axis_mm2s_tkeep,
    output logic        m_axis_mm2s_tlast,
    input logic         m_axis_mm2s_tready,
    output logic        m_axis_mm2s_tvalid,

    input logic[31:0]   s_axis_s2mm_tdata,
    input logic[31:0]   s_axis_s2mm_tkeep,
    input logic         s_axis_s2mm_tlast,
    output logic        s_axis_s2mm_tready,
    input logic         s_axis_s2mm_tvalid,

    input logic[31:0]   mm2s_dmacr  ,
    input logic[31:0]   mm2s_dmasr  ,
    input logic[31:0]   mm2s_sa     ,
    input logic[31:0]   mm2s_sa_msb ,
    input logic[31:0]   mm2s_length ,
    input logic[31:0]   s2mm_dmacr  ,
    input logic[31:0]   s2mm_dmasr  ,
    input logic[31:0]   s2mm_da     ,
    input logic[31:0]   s2mm_da_msb ,
    input logic[31:0]   s2mm_length 
     
); 
    assign s_axis_s2mm_tready = 1'b1;


    data_src data_src (
        .M_AXIS_ACLK    (m_axi_mm2s_aclk    ),
        .M_AXIS_ARESETN (axi_resetn         ),
        .M_AXIS_TVALID  (m_axis_mm2s_tvalid ),
        .M_AXIS_TDATA   (m_axis_mm2s_tdata  ),
        .M_AXIS_TSTRB   (),
        .M_AXIS_TLAST   (m_axis_mm2s_tlast  ),
        .M_AXIS_TREADY  (m_axis_mm2s_tready )
    );



endmodule
