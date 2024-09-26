///////////////////////////////////////////
//
// File Name : dma_wrapper.sv
//
// Version info : 
//
// Assumptions : 
//      1) Max length == 255        
///////////////////////////////////////////



module dma_wrapper #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 10,
    parameter int unsigned NrPMPEntries    = 8
)
(
    clk_i,
    rst_ni,
    pmpcfg_i,   
    pmpaddr_i,  
    reglk_ctrl_i,


    axi_req_i, 
    axi_resp_o

);


    localparam DATA_WIDTH=32;


    input  logic                   clk_i;
    input  logic                   rst_ni;
    input [7:0][16-1:0] pmpcfg_i;   
    input logic [16-1:0][53:0]     pmpaddr_i;  
    input logic [7 :0]             reglk_ctrl_i; // register lock values

    input  ariane_axi::req_t       axi_req_i;
    output ariane_axi::resp_t      axi_resp_o;


    // internal signals
    logic [DATA_WIDTH-1:0] mm2s_dmacr; 
    logic [DATA_WIDTH-1:0] mm2s_dmasr;
    logic [DATA_WIDTH-1:0] mm2s_sa;
    logic [DATA_WIDTH-1:0] mm2s_sa_msb; 
    logic [DATA_WIDTH-1:0] mm2s_length; 

    logic [DATA_WIDTH-1:0] s2mm_dmacr; 
    logic [DATA_WIDTH-1:0] s2mm_dmasr; 
    logic [DATA_WIDTH-1:0] s2mm_da;
    logic [DATA_WIDTH-1:0] s2mm_da_msb;
    logic [DATA_WIDTH-1:0] s2mm_length;

    logic [31:0]axi_dma_0_M_AXIS_MM2S_TDATA;
    logic [3:0]axi_dma_0_M_AXIS_MM2S_TKEEP;
    logic axi_dma_0_M_AXIS_MM2S_TLAST;
    logic axi_dma_0_M_AXIS_MM2S_TVALID;

    logic [31:0] M_AXIS_MM2S_TDATA_o;
    logic [3:0] M_AXIS_MM2S_TKEEP_o;
    logic M_AXIS_MM2S_TLAST_o;
    logic M_AXIS_MM2S_TVALID_o;

    logic [31:0]axi_dma_0_M_AXI_MM2S_ARADDR;
    logic [1:0]axi_dma_0_M_AXI_MM2S_ARBURST;
    logic [3:0]axi_dma_0_M_AXI_MM2S_ARCACHE;
    logic [7:0]axi_dma_0_M_AXI_MM2S_ARLEN;
    logic [2:0]axi_dma_0_M_AXI_MM2S_ARPROT;
    logic axi_dma_0_M_AXI_MM2S_ARREADY;
    logic [2:0]axi_dma_0_M_AXI_MM2S_ARSIZE;
    logic axi_dma_0_M_AXI_MM2S_ARVALID;
    logic [31:0]axi_dma_0_M_AXI_MM2S_RDATA;
    logic axi_dma_0_M_AXI_MM2S_RLAST;
    logic axi_dma_0_M_AXI_MM2S_RREADY;
    logic [1:0]axi_dma_0_M_AXI_MM2S_RRESP;
    logic axi_dma_0_M_AXI_MM2S_RVALID;

    logic [31:0]axi_dma_0_M_AXI_S2MM_AWADDR;
    logic [1:0]axi_dma_0_M_AXI_S2MM_AWBURST;
    logic [3:0]axi_dma_0_M_AXI_S2MM_AWCACHE;
    logic [7:0]axi_dma_0_M_AXI_S2MM_AWLEN;
    logic [2:0]axi_dma_0_M_AXI_S2MM_AWPROT;
    logic axi_dma_0_M_AXI_S2MM_AWREADY;
    logic [2:0]axi_dma_0_M_AXI_S2MM_AWSIZE;
    logic axi_dma_0_M_AXI_S2MM_AWVALID;
    logic axi_dma_0_M_AXI_S2MM_BREADY;
    logic [1:0]axi_dma_0_M_AXI_S2MM_BRESP;
    logic axi_dma_0_M_AXI_S2MM_BVALID;
    logic [31:0]axi_dma_0_M_AXI_S2MM_WDATA;
    logic axi_dma_0_M_AXI_S2MM_WLAST;
    logic axi_dma_0_M_AXI_S2MM_WREADY;
    logic [3:0]axi_dma_0_M_AXI_S2MM_WSTRB;
    logic axi_dma_0_M_AXI_S2MM_WVALID;

    logic [31:0]axis_data_fifo_0_M_AXIS_TDATA;
    logic axis_data_fifo_0_M_AXIS_TLAST;
    logic axis_data_fifo_0_M_AXIS_TREADY;
    logic axis_data_fifo_0_M_AXIS_TVALID;

    logic axi_dma_0_mm2s_introut;
    logic axi_dma_0_s2mm_introut;
    logic axi_dma_0_s2mm_prmry_reset_out_n;

    logic        pmp_data_allow;

    logic [4:0] addr_sel;
    logic [63:0] address4pmp;

    
    // signals from AXI 4 Lite
    logic [AXI_ADDR_WIDTH-1:0] address;
    logic                      en;
    logic                      we;
    logic [63:0] wdata;
    logic [63:0] rdata;

	// signal from reset controllger
	// input logic rst_8;

///////////////////////////////////////////////////////////////////////////
    // -----------------------------
    // AXI Interface Logic
    // -----------------------------
    axi_lite_interface #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH    )
    ) axi_lite_interface_i (
        .clk_i      ( clk_i      ),
        .rst_ni     ( rst_ni     ),
        .axi_req_i  ( axi_req_i  ),
        .axi_resp_o ( axi_resp_o ),
        .address_o  ( address    ),
        .en_o       ( en         ),
        .we_o       ( we         ),
        .data_i     ( rdata      ),
        .data_o     ( wdata      )
    );

    assign addr_sel = address[7:0];


    ///////////////////////////////////////////////////////////////////////////
    // Implement APB I/O map to DMA interface
    // Write side
    always @(posedge clk_i)
        begin
            if(~rst_ni)
                begin
                    mm2s_dmacr <= 'b0; 
                    mm2s_dmasr <= 'b0; 
                    mm2s_sa <= 'b0; 
                    mm2s_sa_msb<= 'b0; 
                    mm2s_length<= 'b0; 
                    s2mm_dmacr  <= 'b0; 
                    s2mm_dmasr  <= 'b0; 
                    s2mm_da  <= 'b0; 
                    s2mm_da_msb  <= 'b0; 
                    s2mm_length <= 'b0;
                end
            else if(en && we)
                case(address[10:3])
                    8'h00:
                        mm2s_dmacr <= wdata;
                    8'h04:
                        mm2s_dmasr <= wdata;
                    8'h18:
                        mm2s_sa <= wdata;
                    8'h1C:
                        mm2s_sa_msb <= wdata;
                    8'h28:
                        mm2s_length <= wdata;
                    8'h30:
                        s2mm_dmacr <= wdata;
                    8'h34:
                        s2mm_dmasr <= wdata; 
                    8'h48:
                        s2mm_da <= wdata; 
                    8'h4C:
                        s2mm_da_msb <= wdata; 
                    8'H58:
                        s2mm_length <= wdata;
                    default:
                        ;
                endcase
        end // always @ (posedge wb_clk_i)

    // assign pmp_access_type_reg = (s2mm_dmacr[] == ) ? riscv::ACCESS_WRITE : riscv::ACCESS_READ;
    assign address4pmp = {mm2s_sa_msb, mm2s_sa};
    
    // Implement APB I/O memory map interface
    // Read side
    //always @(~external_bus_io.write)
    // assign rdata = 64'b0;
    always @(*)
        begin
            rdata = 64'b0; 
            if (en) begin
            case(address[15:3])
                8'h00:
                    rdata = mm2s_dmacr;
                8'h04:
                    rdata = mm2s_dmasr;
                8'h18:
                    rdata = mm2s_sa;
                8'h1C:
                    rdata = mm2s_sa_msb;
                8'h28:
                    rdata = mm2s_length;
                8'h30:
                    rdata = s2mm_dmacr;
                8'h34:
                    rdata = s2mm_dmasr; 
                8'h48:
                    rdata = s2mm_da; 
                8'h4C:
                    rdata = s2mm_da_msb; 
                8'H58:
                    rdata = s2mm_length;
                16'h1000:
                    rdata = mm2s_sa_msb; //testing memory overlap
                default:
                    rdata = 64'b0;
            endcase
            end // if
        end // always @ (*)
    
    
    ///////////////////////////////////////////////////////////////////////////
    // Instantiate the DMA module containing the DAM controller and the AXI master interf
    fake_dma u_fake_dma (
        .axi_resetn(rst_ni),
        .m_axi_mm2s_aclk(clk_i),
        .m_axi_mm2s_araddr(axi_dma_0_M_AXI_MM2S_ARADDR),
        .m_axi_mm2s_arburst(axi_dma_0_M_AXI_MM2S_ARBURST),
        .m_axi_mm2s_arcache(axi_dma_0_M_AXI_MM2S_ARCACHE),
        .m_axi_mm2s_arlen(axi_dma_0_M_AXI_MM2S_ARLEN),
        .m_axi_mm2s_arprot(axi_dma_0_M_AXI_MM2S_ARPROT),
        .m_axi_mm2s_arready(axi_dma_0_M_AXI_MM2S_ARREADY),
        .m_axi_mm2s_arsize(axi_dma_0_M_AXI_MM2S_ARSIZE),
        .m_axi_mm2s_arvalid(axi_dma_0_M_AXI_MM2S_ARVALID),
        .m_axi_mm2s_rdata(axi_dma_0_M_AXI_MM2S_RDATA),
        .m_axi_mm2s_rlast(axi_dma_0_M_AXI_MM2S_RLAST),
        .m_axi_mm2s_rready(axi_dma_0_M_AXI_MM2S_RREADY),
        .m_axi_mm2s_rresp(axi_dma_0_M_AXI_MM2S_RRESP),
        .m_axi_mm2s_rvalid(axi_dma_0_M_AXI_MM2S_RVALID),
        
        .m_axi_s2mm_aclk(clk_i),
        .m_axi_s2mm_awaddr(axi_dma_0_M_AXI_S2MM_AWADDR),
        .m_axi_s2mm_awburst(axi_dma_0_M_AXI_S2MM_AWBURST),
        .m_axi_s2mm_awcache(axi_dma_0_M_AXI_S2MM_AWCACHE),
        .m_axi_s2mm_awlen(axi_dma_0_M_AXI_S2MM_AWLEN),
        .m_axi_s2mm_awprot(axi_dma_0_M_AXI_S2MM_AWPROT),
        .m_axi_s2mm_awready(axi_dma_0_M_AXI_S2MM_AWREADY),
        .m_axi_s2mm_awsize(axi_dma_0_M_AXI_S2MM_AWSIZE),
        .m_axi_s2mm_awvalid(axi_dma_0_M_AXI_S2MM_AWVALID),
        .m_axi_s2mm_bready(axi_dma_0_M_AXI_S2MM_BREADY),
        .m_axi_s2mm_bresp(axi_dma_0_M_AXI_S2MM_BRESP),
        .m_axi_s2mm_bvalid(axi_dma_0_M_AXI_S2MM_BVALID),
        .m_axi_s2mm_wdata(axi_dma_0_M_AXI_S2MM_WDATA),
        .m_axi_s2mm_wlast(axi_dma_0_M_AXI_S2MM_WLAST),
        .m_axi_s2mm_wready(axi_dma_0_M_AXI_S2MM_WREADY),
        .m_axi_s2mm_wstrb(axi_dma_0_M_AXI_S2MM_WSTRB),
        .m_axi_s2mm_wvalid(axi_dma_0_M_AXI_S2MM_WVALID),

        .m_axis_mm2s_tdata(axi_dma_0_M_AXIS_MM2S_TDATA),
        .m_axis_mm2s_tkeep(axi_dma_0_M_AXIS_MM2S_TKEEP),
        .m_axis_mm2s_tlast(axi_dma_0_M_AXIS_MM2S_TLAST),
        .m_axis_mm2s_tready(1'b1),
        .m_axis_mm2s_tvalid(axi_dma_0_M_AXIS_MM2S_TVALID),

        .s_axis_s2mm_tdata(axis_data_fifo_0_M_AXIS_TDATA),
        .s_axis_s2mm_tkeep({1'b1,1'b1,1'b1,1'b1}),
        .s_axis_s2mm_tlast(axis_data_fifo_0_M_AXIS_TLAST),
        .s_axis_s2mm_tready(axis_data_fifo_0_M_AXIS_TREADY),
        .s_axis_s2mm_tvalid(axis_data_fifo_0_M_AXIS_TVALID),

        .mm2s_dmacr  (mm2s_dmacr),
        .mm2s_dmasr  (mm2s_dmasr),
        .mm2s_sa     (mm2s_sa),
        .mm2s_sa_msb (mm2s_sa_msb),
        .mm2s_length (mm2s_length),
        
        .s2mm_dmacr  (s2mm_dmacr),
        .s2mm_dmasr  (s2mm_dmasr),
        .s2mm_da     (s2mm_da),
        .s2mm_da_msb (s2mm_da_msb),
        .s2mm_length (s2mm_length)
    );


    // fake DDR controller
    axi_slv # (
        .AW   (32),
        .DW   (32) 
    ) u_fake_dma_axi_slv (
        .axi_arvalid   (axi_dma_0_M_AXI_MM2S_ARVALID),
        .axi_arready   (axi_dma_0_M_AXI_MM2S_ARREADY),
        .axi_araddr    (axi_dma_0_M_AXI_MM2S_ARADDR ),
        .axi_arcache   (axi_dma_0_M_AXI_MM2S_ARCACHE),
        .axi_arprot    (axi_dma_0_M_AXI_MM2S_ARPROT ),
        // .axi_arlock    (expl_axi_arlock ),
        .axi_arburst   (axi_dma_0_M_AXI_MM2S_ARBURST),
        .axi_arlen     (axi_dma_0_M_AXI_MM2S_ARLEN  ),
        .axi_arsize    (axi_dma_0_M_AXI_MM2S_ARSIZE ),
        
        .axi_awvalid   (axi_dma_0_M_AXI_S2MM_AWVALID),
        .axi_awready   (axi_dma_0_M_AXI_S2MM_AWREADY),
        .axi_awaddr    (axi_dma_0_M_AXI_S2MM_AWADDR ),
        .axi_awcache   (axi_dma_0_M_AXI_S2MM_AWCACHE),
        .axi_awprot    (axi_dma_0_M_AXI_S2MM_AWPROT ),
        // .axi_awlock    (expl_axi_awlock ),
        .axi_awburst   (axi_dma_0_M_AXI_S2MM_AWBURST),
        .axi_awlen     (axi_dma_0_M_AXI_S2MM_AWLEN  ),
        .axi_awsize    (axi_dma_0_M_AXI_S2MM_AWSIZE ),
        
        .axi_rvalid    (axi_dma_0_M_AXI_MM2S_RVALID ),
        .axi_rready    (axi_dma_0_M_AXI_MM2S_RREADY ),
        .axi_rdata     (axi_dma_0_M_AXI_MM2S_RDATA  ),
        .axi_rresp     (axi_dma_0_M_AXI_MM2S_RRESP  ),
        .axi_rlast     (axi_dma_0_M_AXI_MM2S_RLAST  ),
    
        .axi_wvalid    (axi_dma_0_M_AXI_S2MM_WVALID ),
        .axi_wready    (axi_dma_0_M_AXI_S2MM_WREADY ),
        .axi_wdata     (axi_dma_0_M_AXI_S2MM_WDATA  ),
        .axi_wstrb     (axi_dma_0_M_AXI_S2MM_WSTRB  ),
        .axi_wlast     (axi_dma_0_M_AXI_S2MM_WLAST  ),
    
        .axi_bvalid    (axi_dma_0_M_AXI_S2MM_BVALID ),
        .axi_bready    (axi_dma_0_M_AXI_S2MM_BREADY ),
        .axi_bresp     (axi_dma_0_M_AXI_S2MM_BRESP  ),

        .clk           (clk_i  ),
        .rst_n         (rst_ni) 
    );

    // fake axi stream source
    data_src dma_data_src (
        .M_AXIS_ACLK    (clk_i              ),
        .M_AXIS_ARESETN (rst_ni             ),
        .M_AXIS_TVALID  (axis_data_fifo_0_M_AXIS_TVALID ),
        .M_AXIS_TDATA   (axis_data_fifo_0_M_AXIS_TDATA  ),
        .M_AXIS_TSTRB   (),
        .M_AXIS_TLAST   (axis_data_fifo_0_M_AXIS_TLAST  ),
        .M_AXIS_TREADY  (axis_data_fifo_0_M_AXIS_TREADY )
    );

    // Load/store PMP check
    pmp #(
        .PLEN       ( 64                     ),
        .PMP_LEN    ( 54                     ),
        .NR_ENTRIES ( 16           )
    ) i_pmp_data (
        .addr_i        ( address4pmp         ),
        .priv_lvl_i    ( riscv::PRIV_LVL_U   ), //PRIV_LVL_U
        .access_type_i ( riscv::ACCESS_READ  ), // we only check the privilege in the reading mode (mm2s mode)
        // Configuration
        .conf_addr_i   ( pmpaddr_i           ),
        .conf_i        ( pmpcfg_i            ),
        .allow_o       ( pmp_data_allow      )
    );

    logic pmp_allow_o;


    always_ff @(posedge clk_i) begin : mm2s_axis_out
        if (~rst_ni) begin
            M_AXIS_MM2S_TDATA_o = 'b0;
            M_AXIS_MM2S_TKEEP_o = 'b0;
            M_AXIS_MM2S_TLAST_o = 0;
            M_AXIS_MM2S_TVALID_o = 0;
            pmp_allow_o = 1;
        end else begin
            M_AXIS_MM2S_TDATA_o = axi_dma_0_M_AXIS_MM2S_TDATA ;
            M_AXIS_MM2S_TKEEP_o = axi_dma_0_M_AXIS_MM2S_TKEEP ;
            M_AXIS_MM2S_TLAST_o = axi_dma_0_M_AXIS_MM2S_TLAST ;
            M_AXIS_MM2S_TVALID_o = axi_dma_0_M_AXIS_MM2S_TVALID ;
            pmp_allow_o = pmp_data_allow;
        end
    end


    
endmodule

