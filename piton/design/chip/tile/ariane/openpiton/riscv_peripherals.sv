// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 14.11.2018
// Description: Ariane chipset for OpenPiton that includes two bootroms
// (linux, baremetal, both with DTB), debug module, clint and plic.
//
// Note that direct system bus accesses are not yet possible due to a missing
// AXI-lite br_master <-> NOC converter module.
//
// The address bases for the individual peripherals are defined in the
// devices.xml file in OpenPiton, and should be set to
//
// Debug    0xfff1000000 <length 0x1000>
// Boot Rom 0xfff1010000 <length 0x10000>
// CLINT    0xfff1020000 <length 0xc0000>
// PLIC     0xfff1100000 <length 0x4000000>
//

module riscv_peripherals #(
    parameter int unsigned DataWidth       = 64,
    parameter int unsigned NumHarts        =  1,
    parameter int unsigned NumSources      =  1,
    parameter int unsigned PlicMaxPriority =  7,
    parameter bit          SwapEndianess   =  0,
    parameter logic [63:0] DmBase          = 64'hfff1000000,
    parameter logic [63:0] RomBase         = 64'hfff1010000,
    parameter logic [63:0] ClintBase       = 64'hfff1020000,
    parameter logic [63:0] PlicBase        = 64'hfff1100000,
    parameter logic [63:0] AES0Base        = 64'hfff5200000,
    parameter logic [63:0] SHA512Base      = 64'hfff5202000,
    parameter logic [63:0] DMABase         = 64'hfff5207000,
    parameter logic [63:0] RNGBase         = 64'hfff5208000,
    parameter logic [63:0] REGLKBase       = 64'hfff5206000,
    parameter logic [63:0] HMACBase        = 64'hfff5203000,
//    parameter logic [63:0] PKTBase         = 64'hfff5204000,
    parameter logic [63:0] ACCTBase         = 64'hfff5205000,
    parameter logic [63:0] RSTBase         = 64'hfff520A000
//    parameter logic [63:0] RSABase         = 64'hfff5211000
) (
    input                               clk_i,
    input                               rst_ni,
    input                               testmode_i,
    input wire [1:0]                    priv_lvl_i,
    // PMPs
    input riscv::pmpcfg_t [15:0]        pmpcfg_i,     // PMP configuration
    input [15:0][riscv::PLEN:0]         pmpaddr_i,    // PMP addresses
    // connections to OpenPiton NoC filters
    // Debug/JTAG
    input  [DataWidth-1:0]              buf_ariane_debug_noc2_data_i,
    input                               buf_ariane_debug_noc2_valid_i,
    output                              ariane_debug_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_debug_buf_noc3_data_o,
    output                              ariane_debug_buf_noc3_valid_o,
    input                               buf_ariane_debug_noc3_ready_i,
    // Bootrom
    input  [DataWidth-1:0]              buf_ariane_bootrom_noc2_data_i,
    input                               buf_ariane_bootrom_noc2_valid_i,
    output                              ariane_bootrom_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_bootrom_buf_noc3_data_o,
    output                              ariane_bootrom_buf_noc3_valid_o,
    input                               buf_ariane_bootrom_noc3_ready_i,
    // CLINT
    input  [DataWidth-1:0]              buf_ariane_clint_noc2_data_i,
    input                               buf_ariane_clint_noc2_valid_i,
    output                              ariane_clint_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_clint_buf_noc3_data_o,
    output                              ariane_clint_buf_noc3_valid_o,
    input                               buf_ariane_clint_noc3_ready_i,
    // PLIC
    input [DataWidth-1:0]               buf_ariane_plic_noc2_data_i,
    input                               buf_ariane_plic_noc2_valid_i,
    output                              ariane_plic_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_plic_buf_noc3_data_o,
    output                              ariane_plic_buf_noc3_valid_o,
    input                               buf_ariane_plic_noc3_ready_i,
    // This selects either the BM or linux bootrom
    input                               ariane_boot_sel_i,
    // Debug sigs to cores
    output                              ndmreset_o,    // non-debug module reset
    output                              dmactive_o,    // debug module is active
    output [NumHarts-1:0]               debug_req_o,   // async debug request
    input  [NumHarts-1:0]               unavailable_i, // communicate whether the hart is unavailable (e.g.: power down)
    // JTAG
    input                               tck_i,
    input                               tms_i,
    input                               trst_ni,
    input                               td_i,
    output                              td_o,
    output                              tdo_oe_o,
    // CLINT
    input                               rtc_i,        // Real-time clock in (usually 32.768 kHz)
    output [NumHarts-1:0]               timer_irq_o,  // Timer interrupts
    output [NumHarts-1:0]               ipi_o,        // software interrupt (a.k.a inter-process-interrupt)
    // PLIC
    input  [NumSources-1:0]             irq_sources_i,
    input  [NumSources-1:0]             irq_le_i,     // 0:level 1:edge
    output [NumHarts-1:0][1:0]          irq_o,         // level sensitive IR lines, mip & sip (async)
    // RNG
    input  [DataWidth-1:0]              buf_ariane_rng_noc2_data_i, 
    input                               buf_ariane_rng_noc2_valid_i,
    output                              ariane_rng_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_rng_buf_noc3_data_o,
    output                              ariane_rng_buf_noc3_valid_o,
    input                               buf_ariane_rng_noc3_ready_i,
    // RSA
//  input  [DataWidth-1:0]              buf_ariane_rsa_noc2_data_i,
//  input                               buf_ariane_rsa_noc2_valid_i,
//  output                              ariane_rsa_buf_noc2_ready_o,
//  output [DataWidth-1:0]              ariane_rsa_buf_noc3_data_o,
//  output                              ariane_rsa_buf_noc3_valid_o,
//  input                               buf_ariane_rsa_noc3_ready_i,
    // RST_CTRL
/*    input  [DataWidth-1:0]              buf_ariane_rst_noc2_data_i,
    input                               buf_ariane_rst_noc2_valid_i,
    output                              ariane_rst_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_rst_buf_noc3_data_o,
    output                              ariane_rst_buf_noc3_valid_o,
    input                               buf_ariane_rst_noc3_ready_i,*/
    // AES0
    input  [DataWidth-1:0]              buf_ariane_aes0_noc2_data_i,
    input                               buf_ariane_aes0_noc2_valid_i,
    output                              ariane_aes0_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_aes0_buf_noc3_data_o,
    output                              ariane_aes0_buf_noc3_valid_o,
    input                               buf_ariane_aes0_noc3_ready_i,
    // sha512
    input  [DataWidth-1:0]              buf_ariane_sha512_noc2_data_i,
    input                               buf_ariane_sha512_noc2_valid_i,
    output                              ariane_sha512_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_sha512_buf_noc3_data_o,
    output                              ariane_sha512_buf_noc3_valid_o,
    input                               buf_ariane_sha512_noc3_ready_i,
    // dma
    input  [DataWidth-1:0]              buf_ariane_dma_noc2_data_i,
    input                               buf_ariane_dma_noc2_valid_i,
    output                              ariane_dma_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_dma_buf_noc3_data_o,
    output                              ariane_dma_buf_noc3_valid_o,
    input                               buf_ariane_dma_noc3_ready_i,
    // REGLK
    input  [DataWidth-1:0]              buf_ariane_reglk_noc2_data_i,
    input                               buf_ariane_reglk_noc2_valid_i,
    output                              ariane_reglk_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_reglk_buf_noc3_data_o,
    output                              ariane_reglk_buf_noc3_valid_o,
    input                               buf_ariane_reglk_noc3_ready_i,
    // PKT
/*    input  [DataWidth-1:0]              buf_ariane_pkt_noc2_data_i,
    input                               buf_ariane_pkt_noc2_valid_i,
    output                              ariane_pkt_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_pkt_buf_noc3_data_o,
    output                              ariane_pkt_buf_noc3_valid_o,
    input                               buf_ariane_pkt_noc3_ready_i,*/
    // ACCT
    input  [DataWidth-1:0]              buf_ariane_acct_noc2_data_i,
    input                               buf_ariane_acct_noc2_valid_i,
    output                              ariane_acct_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_acct_buf_noc3_data_o,
    output                              ariane_acct_buf_noc3_valid_o,
    input                               buf_ariane_acct_noc3_ready_i,
    // HMAC
    input  [DataWidth-1:0]              buf_ariane_hmac_noc2_data_i,
    input                               buf_ariane_hmac_noc2_valid_i,
    output                              ariane_hmac_buf_noc2_ready_o,
    output [DataWidth-1:0]              ariane_hmac_buf_noc3_data_o,
    output                              ariane_hmac_buf_noc3_valid_o,
    input                               buf_ariane_hmac_noc3_ready_i,
    output                              hmac_warning    
);

  localparam int unsigned AxiIdWidth    =  1;
  localparam int unsigned AxiAddrWidth  = 64;
  localparam int unsigned AxiDataWidth  = 64;
  localparam int unsigned AxiUserWidth  =  1;

  parameter NB_PERIPHERALS = 14;
  parameter FUSE_MEM_SIZE  = 150;

  logic [8*NB_PERIPHERALS-1:0] reglk_ctrl;
  logic [4*NB_PERIPHERALS-1:0] acc_ctrl;
  logic [3:0][NB_PERIPHERALS-1:0] acc_ctrl_c;

  genvar i,j;
  generate
    for (i=0;i<4;i++)begin
      for (j=0;j<NB_PERIPHERALS;j++)begin
//        assign acc_ctrl_c[i][j] = acc_ctrl[j*4+i] | (j==5 && acc_ctrl[4*4+i]);
         assign acc_ctrl_c[i][j] = acc_ctrl[j*4+i] ;
      end
    end
  endgenerate

  /////////////////////////////
  // Debug module and JTAG
  /////////////////////////////

  logic          debug_req_valid;
  logic          debug_req_ready;
  logic          debug_resp_valid;
  logic          debug_resp_ready;

  dm::dmi_req_t  debug_req;
  dm::dmi_resp_t debug_resp;

`ifdef RISCV_FESVR_SIM

  initial begin
    $display("[INFO] instantiating FESVR DTM in simulation.");
  end

  // SiFive's SimDTM Module
  // Converts to DPI calls
  logic [31:0] sim_exit; // TODO: wire this up in the testbench
  logic [1:0] debug_req_bits_op;
  assign dmi_req.op = dm::dtm_op_t'(debug_req_bits_op);

  SimDTM i_SimDTM (
    .clk                  ( clk_i                ),
    .reset                ( ~rst_ni              ),
    .debug_req_valid      ( debug_req_valid      ),
    .debug_req_ready      ( debug_req_ready      ),
    .debug_req_bits_addr  ( debug_req.addr       ),
    .debug_req_bits_op    ( debug_req_bits_op    ),
    .debug_req_bits_data  ( debug_req.data       ),
    .debug_resp_valid     ( debug_resp_valid     ),
    .debug_resp_ready     ( debug_resp_ready       ),
    .debug_resp_bits_resp ( debug_resp.resp      ),
    .debug_resp_bits_data ( debug_resp.data      ),
    .exit                 ( sim_exit             )
  );

`else // RISCV_FESVR_SIM

  logic        tck, tms, trst_n, tdi, tdo, tdo_oe;

  dmi_jtag i_dmi_jtag (
    .clk_i                                ,
    .rst_ni                               ,
    .testmode_i                           ,
    .dmi_req_o        ( debug_req        ),
    .dmi_req_valid_o  ( debug_req_valid  ),
    .dmi_req_ready_i  ( debug_req_ready  ),
    .dmi_resp_i       ( debug_resp       ),
    .dmi_resp_ready_o ( debug_resp_ready ),
    .dmi_resp_valid_i ( debug_resp_valid ),
    .dmi_rst_no       (                  ), // not connected
    .tck_i            ( tck              ),
    .tms_i            ( tms              ),
    .trst_ni          ( trst_n           ),
    .td_i             ( tdi              ),
    .td_o             ( tdo              ),
    .tdo_oe_o         ( tdo_oe           )
  );

`ifdef RISCV_JTAG_SIM

  initial begin
    $display("[INFO] instantiating JTAG DTM in simulation.");
  end

  // SiFive's SimJTAG Module
  // Converts to DPI calls
  logic [31:0] sim_exit; // TODO: wire this up in the testbench
  SimJTAG i_SimJTAG (
    .clock                ( clk_i                ),
    .reset                ( ~rst_ni              ),
    .enable               ( jtag_enable[0]       ),
    .init_done            ( init_done            ),
    .jtag_TCK             ( tck                  ),
    .jtag_TMS             ( tms                  ),
    .jtag_TDI             ( trst_n               ),
    .jtag_TRSTn           ( td                   ),
    .jtag_TDO_data        ( td                   ),
    .jtag_TDO_driven      ( tdo_oe               ),
    .exit                 ( sim_exit             )
  );

  assign td_o     = 1'b0  ;
  assign tdo_oe_o = 1'b0  ;

`else // RISCV_JTAG_SIM

  assign tck      = tck_i   ;
  assign tms      = tms_i   ;
  assign trst_n   = trst_ni ;
  assign tdi      = td_i    ;
  assign td_o     = tdo     ;
  assign tdo_oe_o = tdo_oe  ;

`endif // RISCV_JTAG_SIM
`endif // RISCV_FESVR_SIM

  logic                dm_slave_req;
  logic                dm_slave_we;
  logic [64-1:0]       dm_slave_addr;
  logic [64/8-1:0]     dm_slave_be;
  logic [64-1:0]       dm_slave_wdata;
  logic [64-1:0]       dm_slave_rdata;

  logic                dm_master_req;
  logic [64-1:0]       dm_master_add;
  logic                dm_master_we;
  logic [64-1:0]       dm_master_wdata;
  logic [64/8-1:0]     dm_master_be;
  logic                dm_master_gnt;
  logic                dm_master_r_valid;
  logic [64-1:0]       dm_master_r_rdata;

  // debug module
  dm_top #(
    .NrHarts              ( NumHarts             ),
    .BusWidth             ( AxiDataWidth         ),
    .SelectableHarts      ( {NumHarts{1'b1}}     )
  ) i_dm_top (
    .clk_i                                        ,
    .rst_ni                                       , // PoR
    .testmode_i                                   ,
    .ndmreset_o                                   ,
    .dmactive_o                                   , // active debug session
    .debug_req_o                                  ,
    .unavailable_i                                ,
    .hartinfo_i           ( {NumHarts{ariane_pkg::DebugHartInfo}} ),
    .slave_req_i          ( dm_slave_req         ),
    .slave_we_i           ( dm_slave_we          ),
    .slave_addr_i         ( dm_slave_addr        ),
    .slave_be_i           ( dm_slave_be          ),
    .slave_wdata_i        ( dm_slave_wdata       ),
    .slave_rdata_o        ( dm_slave_rdata       ),
    .master_req_o         ( dm_master_req        ),
    .master_add_o         ( dm_master_add        ),
    .master_we_o          ( dm_master_we         ),
    .master_wdata_o       ( dm_master_wdata      ),
    .master_be_o          ( dm_master_be         ),
    .master_gnt_i         ( dm_master_gnt        ),
    .master_r_valid_i     ( dm_master_r_valid    ),
    .master_r_rdata_i     ( dm_master_r_rdata    ),
    .dmi_rst_ni           ( rst_ni               ),
    .dmi_req_valid_i      ( debug_req_valid      ),
    .dmi_req_ready_o      ( debug_req_ready      ),
    .dmi_req_i            ( debug_req            ),
    .dmi_resp_valid_o     ( debug_resp_valid     ),
    .dmi_resp_ready_i     ( debug_resp_ready     ),
    .dmi_resp_o           ( debug_resp           )
  );

  AXI_BUS #(
      .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
      .AXI_DATA_WIDTH ( AxiDataWidth     ),
      .AXI_ID_WIDTH   ( AxiIdWidth       ),
      .AXI_USER_WIDTH ( AxiUserWidth     )
  ) dm_master();

  axi2mem #(
      .AXI_ID_WIDTH   ( AxiIdWidth   ),
      .AXI_ADDR_WIDTH ( AxiAddrWidth ),
      .AXI_DATA_WIDTH ( AxiDataWidth ),
      .AXI_USER_WIDTH ( AxiUserWidth )
  ) i_dm_axi2mem (
      .clk_i      ( clk_i                     ),
      .rst_ni     ( rst_ni                    ),
      .slave      ( dm_master                 ),
      .req_o      ( dm_slave_req              ),
      .we_o       ( dm_slave_we               ),
      .addr_o     ( dm_slave_addr             ),
      .be_o       ( dm_slave_be               ),
      .data_o     ( dm_slave_wdata            ),
      .data_i     ( dm_slave_rdata            )
  );

  logic debug_module_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_debug_axilite_bridge (
    .secure                 (debug_module_secure            ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_debug_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_debug_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_debug_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_debug_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_debug_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_debug_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( dm_master.aw_addr             ),
    .m_axi_awvalid          ( dm_master.aw_valid            ),
    .m_axi_awready          ( dm_master.aw_ready            ),
    //write data channel
    .m_axi_wdata            ( dm_master.w_data              ),
    .m_axi_wstrb            ( dm_master.w_strb              ),
    .m_axi_wvalid           ( dm_master.w_valid             ),
    .m_axi_wready           ( dm_master.w_ready             ),
    //read address channel
    .m_axi_araddr           ( dm_master.ar_addr             ),
    .m_axi_arvalid          ( dm_master.ar_valid            ),
    .m_axi_arready          ( dm_master.ar_ready            ),
    //read data channel
    .m_axi_rdata            ( dm_master.r_data              ),
    .m_axi_rresp            ( dm_master.r_resp              ),
    .m_axi_rvalid           ( dm_master.r_valid             ),
    .m_axi_rready           ( dm_master.r_ready             ),
    //write response channel
    .m_axi_bresp            ( dm_master.b_resp              ),
    .m_axi_bvalid           ( dm_master.b_valid             ),
    .m_axi_bready           ( dm_master.b_ready             ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );

  assign debug_module_secure = 0;
  // tie off system bus accesses (not supported yet due to
  // missing AXI-lite br_master <-> NOC converter)
  assign dm_master_gnt      = '0;
  assign dm_master_r_valid  = '0;
  assign dm_master_r_rdata  = '0;

  // tie off signals not used by AXI-lite
  assign dm_master.aw_id     = '0;
  assign dm_master.aw_len    = '0;
  assign dm_master.aw_size   = 3'b11;// 8byte
  assign dm_master.aw_burst  = '0;
  assign dm_master.aw_lock   = '0;
  assign dm_master.aw_cache  = '0;
  assign dm_master.aw_prot   = '0;
  assign dm_master.aw_qos    = '0;
  assign dm_master.aw_region = '0;
  assign dm_master.aw_atop   = '0;
  assign dm_master.w_last    = 1'b1;
  assign dm_master.ar_id     = '0;
  assign dm_master.ar_len    = '0;
  assign dm_master.ar_size   = 3'b11;// 8byte
  assign dm_master.ar_burst  = '0;
  assign dm_master.ar_lock   = '0;
  assign dm_master.ar_cache  = '0;
  assign dm_master.ar_prot   = '0;
  assign dm_master.ar_qos    = '0;
  assign dm_master.ar_region = '0;


  /////////////////////////////
  // Bootrom
  /////////////////////////////

  logic                    rom_req;
  logic [AxiAddrWidth-1:0] rom_addr;
  logic [AxiDataWidth-1:0] rom_rdata, rom_rdata_bm, rom_rdata_linux;

  AXI_BUS #(
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) br_master();

  axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidth    ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth  ),
    .AXI_DATA_WIDTH ( AxiDataWidth  ),
    .AXI_USER_WIDTH ( AxiUserWidth  )
  ) i_axi2rom (
    .clk_i                ,
    .rst_ni               ,
    .slave  ( br_master  ),
    .req_o  ( rom_req    ),
    .we_o   (            ),
    .addr_o ( rom_addr   ),
    .be_o   (            ),
    .data_o (            ),
    .data_i ( rom_rdata  )
  );

  bootrom i_bootrom_bm (
    .clk_i                   ,
    .req_i      ( rom_req   ),
    .addr_i     ( rom_addr  ),
    .rdata_o    ( rom_rdata_bm )
  );

  bootrom_linux i_bootrom_linux (
    .clk_i                   ,
    .req_i      ( rom_req   ),
    .addr_i     ( rom_addr  ),
    .rdata_o    ( rom_rdata_linux )
  );

  // we want to run in baremetal mode when using pitonstream
  assign rom_rdata = (ariane_boot_sel_i) ? rom_rdata_bm : rom_rdata_linux;

  logic bootrom_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_bootrom_axilite_bridge (
    .secure                 ( bootrom_secure                ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                           ),
    .rst                    ( ~rst_ni                         ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_bootrom_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_bootrom_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_bootrom_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_bootrom_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_bootrom_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_bootrom_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( br_master.aw_addr               ),
    .m_axi_awvalid          ( br_master.aw_valid              ),
    .m_axi_awready          ( br_master.aw_ready              ),
    //write data channel
    .m_axi_wdata            ( br_master.w_data                ),
    .m_axi_wstrb            ( br_master.w_strb                ),
    .m_axi_wvalid           ( br_master.w_valid               ),
    .m_axi_wready           ( br_master.w_ready               ),
    //read address channel
    .m_axi_araddr           ( br_master.ar_addr               ),
    .m_axi_arvalid          ( br_master.ar_valid              ),
    .m_axi_arready          ( br_master.ar_ready              ),
    //read data channel
    .m_axi_rdata            ( br_master.r_data                ),
    .m_axi_rresp            ( br_master.r_resp                ),
    .m_axi_rvalid           ( br_master.r_valid               ),
    .m_axi_rready           ( br_master.r_ready               ),
    //write response channel
    .m_axi_bresp            ( br_master.b_resp                ),
    .m_axi_bvalid           ( br_master.b_valid               ),
    .m_axi_bready           ( br_master.b_ready               ),
    // non-axi-lite signals
    .w_reqbuf_size          (                                 ),
    .r_reqbuf_size          (                                 )
  );

//added for monitor-------------------------------------
  logic [63:0] br_master_aw_addr = br_master.aw_addr;
  logic br_master_aw_valid = br_master.aw_valid;
  logic [63:0] br_master_ar_addr = br_master.ar_addr;
  logic br_master_ar_valid = br_master.ar_valid;
  logic [63:0] br_master_w_data = br_master.w_data;
  logic br_master_w_valid = br_master.w_valid;
  logic [63:0] br_master_r_data = br_master.r_data;
  logic br_master_r_ready = br_master.r_ready;
//----------------------------------------------
  assign bootrom_secure = 1;
  // tie off signals not used by AXI-lite
  assign br_master.aw_id     = '0;
  assign br_master.aw_len    = '0;
  assign br_master.aw_size   = 3'b11;// 8byte
  assign br_master.aw_burst  = '0;
  assign br_master.aw_lock   = '0;
  assign br_master.aw_cache  = '0;
  assign br_master.aw_prot   = '0;
  assign br_master.aw_qos    = '0;
  assign br_master.aw_region = '0;
  assign br_master.aw_atop   = '0;
  assign br_master.w_last    = 1'b1;
  assign br_master.ar_id     = '0;
  assign br_master.ar_len    = '0;
  assign br_master.ar_size   = 3'b11;// 8byte
  assign br_master.ar_burst  = '0;
  assign br_master.ar_lock   = '0;
  assign br_master.ar_cache  = '0;
  assign br_master.ar_prot   = '0;
  assign br_master.ar_qos    = '0;
  assign br_master.ar_region = '0;
  /////////////////////////////
  // CLINT
  /////////////////////////////

  ariane_axi::req_t    clint_axi_req;
  ariane_axi::resp_t   clint_axi_resp;

  clint #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .NR_CORES       ( NumHarts     )
  ) i_clint (
    .clk_i                         ,
    .rst_ni                        ,
    .testmode_i                    ,
    .axi_req_i   ( clint_axi_req  ),
    .axi_resp_o  ( clint_axi_resp ),
    .rtc_i                         ,
    .timer_irq_o                   ,
    .ipi_o
  );
  
  logic clint_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_clint_axilite_bridge (
    .secure                 (clint_secure                   ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_clint_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_clint_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_clint_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_clint_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_clint_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_clint_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( clint_axi_req.aw.addr         ),
    .m_axi_awvalid          ( clint_axi_req.aw_valid        ),
    .m_axi_awready          ( clint_axi_resp.aw_ready       ),
    //write data channel
    .m_axi_wdata            ( clint_axi_req.w.data          ),
    .m_axi_wstrb            ( clint_axi_req.w.strb          ),
    .m_axi_wvalid           ( clint_axi_req.w_valid         ),
    .m_axi_wready           ( clint_axi_resp.w_ready        ),
    //read address channel
    .m_axi_araddr           ( clint_axi_req.ar.addr         ),
    .m_axi_arvalid          ( clint_axi_req.ar_valid        ),
    .m_axi_arready          ( clint_axi_resp.ar_ready       ),
    //read data channel
    .m_axi_rdata            ( clint_axi_resp.r.data         ),
    .m_axi_rresp            ( clint_axi_resp.r.resp         ),
    .m_axi_rvalid           ( clint_axi_resp.r_valid        ),
    .m_axi_rready           ( clint_axi_req.r_ready         ),
    //write response channel
    .m_axi_bresp            ( clint_axi_resp.b.resp         ),
    .m_axi_bvalid           ( clint_axi_resp.b_valid        ),
    .m_axi_bready           ( clint_axi_req.b_ready         ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );
  assign clint_secure = 0;
  // tie off signals not used by AXI-lite
  assign clint_axi_req.aw.id     = '0;
  assign clint_axi_req.aw.len    = '0;
  assign clint_axi_req.aw.size   = 3'b11;// 8byte
  assign clint_axi_req.aw.burst  = '0;
  assign clint_axi_req.aw.lock   = '0;
  assign clint_axi_req.aw.cache  = '0;
  assign clint_axi_req.aw.prot   = '0;
  assign clint_axi_req.aw.qos    = '0;
  assign clint_axi_req.aw.region = '0;
  assign clint_axi_req.aw.atop   = '0;
  assign clint_axi_req.w.last    = 1'b1;
  assign clint_axi_req.ar.id     = '0;
  assign clint_axi_req.ar.len    = '0;
  assign clint_axi_req.ar.size   = 3'b11;// 8byte
  assign clint_axi_req.ar.burst  = '0;
  assign clint_axi_req.ar.lock   = '0;
  assign clint_axi_req.ar.cache  = '0;
  assign clint_axi_req.ar.prot   = '0;
  assign clint_axi_req.ar.qos    = '0;
  assign clint_axi_req.ar.region = '0;


  /////////////////////////////
  // PLIC
  /////////////////////////////

  AXI_BUS #(
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) plic_master();

  logic plic_secure;

  noc_axilite_bridge #(
    // this enables variable width accesses
    // note that the accesses are still 64bit, but the
    // write-enables are generated according to the access size
    .SLAVE_RESP_BYTEWIDTH   ( 0             ),
    .SWAP_ENDIANESS         ( SwapEndianess ),
    // this disables shifting of unaligned read data
    .ALIGN_RDATA            ( 0             )
  ) i_plic_axilite_bridge (
    .secure                 (plic_secure                    ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                        ),
    .rst                    ( ~rst_ni                      ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_plic_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_plic_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_plic_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_plic_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_plic_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_plic_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( plic_master.aw_addr               ),
    .m_axi_awvalid          ( plic_master.aw_valid              ),
    .m_axi_awready          ( plic_master.aw_ready              ),
    //write data channel
    .m_axi_wdata            ( plic_master.w_data                ),
    .m_axi_wstrb            ( plic_master.w_strb                ),
    .m_axi_wvalid           ( plic_master.w_valid               ),
    .m_axi_wready           ( plic_master.w_ready               ),
    //read address channel
    .m_axi_araddr           ( plic_master.ar_addr               ),
    .m_axi_arvalid          ( plic_master.ar_valid              ),
    .m_axi_arready          ( plic_master.ar_ready              ),
    //read data channel
    .m_axi_rdata            ( plic_master.r_data                ),
    .m_axi_rresp            ( plic_master.r_resp                ),
    .m_axi_rvalid           ( plic_master.r_valid               ),
    .m_axi_rready           ( plic_master.r_ready               ),
    //write response channel
    .m_axi_bresp            ( plic_master.b_resp                ),
    .m_axi_bvalid           ( plic_master.b_valid               ),
    .m_axi_bready           ( plic_master.b_ready               ),
    // non-axi-lite signals
    .w_reqbuf_size          ( plic_master.aw_size               ),
    .r_reqbuf_size          ( plic_master.ar_size               )
  );
  assign plic_secure = 0;
  // tie off signals not used by AXI-lite
  assign plic_master.aw_id     = '0;
  assign plic_master.aw_len    = '0;
  assign plic_master.aw_burst  = '0;
  assign plic_master.aw_lock   = '0;
  assign plic_master.aw_cache  = '0;
  assign plic_master.aw_prot   = '0;
  assign plic_master.aw_qos    = '0;
  assign plic_master.aw_region = '0;
  assign plic_master.aw_atop   = '0;
  assign plic_master.w_last    = 1'b1;
  assign plic_master.ar_id     = '0;
  assign plic_master.ar_len    = '0;
  assign plic_master.ar_burst  = '0;
  assign plic_master.ar_lock   = '0;
  assign plic_master.ar_cache  = '0;
  assign plic_master.ar_prot   = '0;
  assign plic_master.ar_qos    = '0;
  assign plic_master.ar_region = '0;


  reg_intf::reg_intf_resp_d32 plic_resp;
  reg_intf::reg_intf_req_a32_d32 plic_req;

  enum logic [2:0] {Idle, WriteSecond, ReadSecond, WriteResp, ReadResp} state_d, state_q;
  logic [31:0] rword_d, rword_q;

  // register read data
  assign rword_d = (plic_req.valid && !plic_req.write) ? plic_resp.rdata : rword_q;
  assign plic_master.r_data = {plic_resp.rdata, rword_q};

  always_ff @(posedge clk_i or negedge rst_ni) begin : p_plic_regs
    if (!rst_ni) begin
      state_q <= Idle;
      rword_q <= '0;
    end else begin
      state_q <= state_d;
      rword_q <= rword_d;
    end
  end

  // this is a simplified AXI statemachine, since the
  // W and AW requests always arrive at the same time here
  always_comb begin : p_plic_if
    automatic logic [31:0] waddr, raddr;
    // subtract the base offset (truncated to 32 bits)
    waddr = plic_master.aw_addr[31:0] - 32'(PlicBase) + 32'hc000000;
    raddr = plic_master.ar_addr[31:0] - 32'(PlicBase) + 32'hc000000;

    // AXI-lite
    plic_master.aw_ready = plic_resp.ready;
    plic_master.w_ready  = plic_resp.ready;
    plic_master.ar_ready = plic_resp.ready;

    plic_master.r_valid  = 1'b0;
    plic_master.r_resp   = '0;
    plic_master.b_valid  = 1'b0;
    plic_master.b_resp   = '0;

    // PLIC
    plic_req.valid       = 1'b0;
    plic_req.wstrb       = '0;
    plic_req.write       = 1'b0;
    plic_req.wdata       = plic_master.w_data[31:0];
    plic_req.addr        = waddr;

    // default
    state_d              = state_q;

    unique case (state_q)
      Idle: begin
        if (plic_master.w_valid && plic_master.aw_valid && plic_resp.ready) begin
          plic_req.valid = 1'b1;
          plic_req.write = plic_master.w_strb[3:0];
          plic_req.wstrb = '1;
          // this is a 64bit write, need to write second 32bit chunk in second cycle
          if (plic_master.aw_size == 3'b11) begin
            state_d = WriteSecond;
          end else begin
            state_d = WriteResp;
          end
        end else if (plic_master.ar_valid && plic_resp.ready) begin
          plic_req.valid = 1'b1;
          plic_req.addr  = raddr;
          // this is a 64bit read, need to read second 32bit chunk in second cycle
          if (plic_master.ar_size == 3'b11) begin
            state_d = ReadSecond;
          end else begin
            state_d = ReadResp;
          end
        end
      end
      // write high word
      WriteSecond: begin
        plic_master.aw_ready = 1'b0;
        plic_master.w_ready  = 1'b0;
        plic_master.ar_ready = 1'b0;
        plic_req.addr        = waddr + 32'h4;
        plic_req.wdata       = plic_master.w_data[63:32];
        if (plic_resp.ready && plic_master.b_ready) begin
          plic_req.valid       = 1'b1;
          plic_req.write       = 1'b1;
          plic_req.wstrb       = '1;
          plic_master.b_valid  = 1'b1;
          state_d              = Idle;
        end
      end
      // read high word
      ReadSecond: begin
        plic_master.aw_ready = 1'b0;
        plic_master.w_ready  = 1'b0;
        plic_master.ar_ready = 1'b0;
        plic_req.addr        = raddr + 32'h4;
        if (plic_resp.ready && plic_master.r_ready) begin
          plic_req.valid      = 1'b1;
          plic_master.r_valid = 1'b1;
          state_d             = Idle;
        end
      end
      WriteResp: begin
        plic_master.aw_ready = 1'b0;
        plic_master.w_ready  = 1'b0;
        plic_master.ar_ready = 1'b0;
        if (plic_master.b_ready) begin
          plic_master.b_valid  = 1'b1;
          state_d              = Idle;
        end
      end
      ReadResp: begin
        plic_master.aw_ready = 1'b0;
        plic_master.w_ready  = 1'b0;
        plic_master.ar_ready = 1'b0;
        if (plic_master.r_ready) begin
          plic_master.r_valid = 1'b1;
          state_d             = Idle;
        end
      end
      default: state_d = Idle;
    endcase
  end

  plic_top #(
    .N_SOURCE    ( NumSources      ),
    .N_TARGET    ( 2*NumHarts      ),
    .MAX_PRIO    ( PlicMaxPriority )
  ) i_plic (
    .clk_i,
    .rst_ni,
    .req_i         ( plic_req    ),
    .resp_o        ( plic_resp   ),
    .le_i          ( irq_le_i    ), // 0:level 1:edge
    .irq_sources_i,                 // already synchronized
    .eip_targets_o ( irq_o       )
  );


  /////////////////////////////
  // AES0
  /////////////////////////////

  ariane_axi::req_t    aes0_axi_req;
  ariane_axi::resp_t   aes0_axi_resp;

  logic [63:0] rng_rand_key;

  aes0_wrapper #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   )
  ) i_aes0_wrapper (
    .clk_i                         ,
    .rst_ni        ,
    .reglk_ctrl_i  ( reglk_ctrl[1*8+7:1*8] ),
    .acct_ctrl_i   ( acc_ctrl_c[priv_lvl_i][1]),
    .axi_req_i     ( aes0_axi_req  ),
    .axi_resp_o    ( aes0_axi_resp ),
    .rand_key      ( rng_rand_key  )
  );

  logic aes0_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_aes0_axilite_bridge (
    .secure                 ( aes0_secure                   ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_aes0_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_aes0_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_aes0_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_aes0_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_aes0_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_aes0_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( aes0_axi_req.aw.addr         ),
    .m_axi_awvalid          ( aes0_axi_req.aw_valid        ),
    .m_axi_awready          ( aes0_axi_resp.aw_ready       ),
    //write data channel
    .m_axi_wdata            ( aes0_axi_req.w.data          ),
    .m_axi_wstrb            ( aes0_axi_req.w.strb          ),
    .m_axi_wvalid           ( aes0_axi_req.w_valid         ),
    .m_axi_wready           ( aes0_axi_resp.w_ready        ),
    //read address channel
    .m_axi_araddr           ( aes0_axi_req.ar.addr         ),
    .m_axi_arvalid          ( aes0_axi_req.ar_valid        ),
    .m_axi_arready          ( aes0_axi_resp.ar_ready       ),
    //read data channel
    .m_axi_rdata            ( aes0_axi_resp.r.data         ),
    .m_axi_rresp            ( aes0_axi_resp.r.resp         ),
    .m_axi_rvalid           ( aes0_axi_resp.r_valid        ),
    .m_axi_rready           ( aes0_axi_req.r_ready         ),
    //write response channel
    .m_axi_bresp            ( aes0_axi_resp.b.resp         ),
    .m_axi_bvalid           ( aes0_axi_resp.b_valid        ),
    .m_axi_bready           ( aes0_axi_req.b_ready         ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );

  assign aes0_secure = 0;
  
  // tie off signals not used by AXI-lite
  assign aes0_axi_req.aw.id     = '0;
  assign aes0_axi_req.aw.len    = '0;
  assign aes0_axi_req.aw.size   = 3'b11;// 8byte
  assign aes0_axi_req.aw.burst  = '0;
  assign aes0_axi_req.aw.lock   = '0;
  assign aes0_axi_req.aw.cache  = '0;
  assign aes0_axi_req.aw.prot   = '0;
  assign aes0_axi_req.aw.qos    = '0;
  assign aes0_axi_req.aw.region = '0;
  assign aes0_axi_req.aw.atop   = '0;
  assign aes0_axi_req.w.last    = 1'b1;
  assign aes0_axi_req.ar.id     = '0;
  assign aes0_axi_req.ar.len    = '0;
  assign aes0_axi_req.ar.size   = 3'b11;// 8byte
  assign aes0_axi_req.ar.burst  = '0;
  assign aes0_axi_req.ar.lock   = '0;
  assign aes0_axi_req.ar.cache  = '0;
  assign aes0_axi_req.ar.prot   = '0;
  assign aes0_axi_req.ar.qos    = '0;
  assign aes0_axi_req.ar.region = '0;

  //////////////////////////////
  // RNG
  /////////////////////////////

  ariane_axi::req_t    rng_axi_req;
  ariane_axi::resp_t   rng_axi_resp;

  prng_wrapper #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   )
  ) i_prng_wrapper (
    .clk_i                         ,
    .rst_ni        ,
    .reglk_ctrl_i  ( reglk_ctrl[10*8+7:10*8] ),
    .acct_ctrl_i   ( acc_ctrl_c[priv_lvl_i][10]),
    .axi_req_i     ( rng_axi_req  ),
    .axi_resp_o    ( rng_axi_resp ),
    .rand_num_o    (rng_rand_key)
  );

  logic rng_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_rng_axilite_bridge (
    .secure                 ( rng_secure                    ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_rng_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_rng_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_rng_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_rng_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_rng_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_rng_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( rng_axi_req.aw.addr         ),
    .m_axi_awvalid          ( rng_axi_req.aw_valid        ),
    .m_axi_awready          ( rng_axi_resp.aw_ready       ),
    //write data channel
    .m_axi_wdata            ( rng_axi_req.w.data          ),
    .m_axi_wstrb            ( rng_axi_req.w.strb          ),
    .m_axi_wvalid           ( rng_axi_req.w_valid         ),
    .m_axi_wready           ( rng_axi_resp.w_ready        ),
    //read address channel
    .m_axi_araddr           ( rng_axi_req.ar.addr         ),
    .m_axi_arvalid          ( rng_axi_req.ar_valid        ),
    .m_axi_arready          ( rng_axi_resp.ar_ready       ),
    //read data channel
    .m_axi_rdata            ( rng_axi_resp.r.data         ),
    .m_axi_rresp            ( rng_axi_resp.r.resp         ),
    .m_axi_rvalid           ( rng_axi_resp.r_valid        ),
    .m_axi_rready           ( rng_axi_req.r_ready         ),
    //write response channel
    .m_axi_bresp            ( rng_axi_resp.b.resp         ),
    .m_axi_bvalid           ( rng_axi_resp.b_valid        ),
    .m_axi_bready           ( rng_axi_req.b_ready         ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );

  assign rng_secure = 0;
  
  // tie off signals not used by AXI-lite
  assign rng_axi_req.aw.id     = '0;
  assign rng_axi_req.aw.len    = '0;
  assign rng_axi_req.aw.size   = 3'b11;// 8byte
  assign rng_axi_req.aw.burst  = '0;
  assign rng_axi_req.aw.lock   = '0;
  assign rng_axi_req.aw.cache  = '0;
  assign rng_axi_req.aw.prot   = '0;
  assign rng_axi_req.aw.qos    = '0;
  assign rng_axi_req.aw.region = '0;
  assign rng_axi_req.aw.atop   = '0;
  assign rng_axi_req.w.last    = 1'b1;
  assign rng_axi_req.ar.id     = '0;
  assign rng_axi_req.ar.len    = '0;
  assign rng_axi_req.ar.size   = 3'b11;// 8byte
  assign rng_axi_req.ar.burst  = '0;
  assign rng_axi_req.ar.lock   = '0;
  assign rng_axi_req.ar.cache  = '0;
  assign rng_axi_req.ar.prot   = '0;
  assign rng_axi_req.ar.qos    = '0;
  assign rng_axi_req.ar.region = '0;

  /////////////////////////////
  // REGLK
  /////////////////////////////

  ariane_axi::req_t    reglk_axi_req;
  ariane_axi::resp_t   reglk_axi_resp;

  reglk_wrapper #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    // .NB_SLAVE       ( NB_SLAVE     ),
    .NB_PERIPHERALS ( NB_PERIPHERALS )
  ) i_reglk_wrapper (
    .clk_i                         ,
    .rst_ni                        ,
    .reglk_ctrl_o  ( reglk_ctrl     ),
    .reglk_ctrl_i  ( reglk_ctrl[2*8+7:2*8]),
    .axi_req_i     ( reglk_axi_req  ),
    .axi_resp_o    ( reglk_axi_resp )
  );

  logic reglk_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_reglk_axilite_bridge (
    .secure                 ( reglk_secure                  ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_reglk_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_reglk_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_reglk_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_reglk_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_reglk_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_reglk_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( reglk_axi_req.aw.addr         ),
    .m_axi_awvalid          ( reglk_axi_req.aw_valid        ),
    .m_axi_awready          ( reglk_axi_resp.aw_ready       ),
    //write data channel
    .m_axi_wdata            ( reglk_axi_req.w.data          ),
    .m_axi_wstrb            ( reglk_axi_req.w.strb          ),
    .m_axi_wvalid           ( reglk_axi_req.w_valid         ),
    .m_axi_wready           ( reglk_axi_resp.w_ready        ),
    //read address channel
    .m_axi_araddr           ( reglk_axi_req.ar.addr         ),
    .m_axi_arvalid          ( reglk_axi_req.ar_valid        ),
    .m_axi_arready          ( reglk_axi_resp.ar_ready       ),
    //read data channel
    .m_axi_rdata            ( reglk_axi_resp.r.data         ),
    .m_axi_rresp            ( reglk_axi_resp.r.resp         ),
    .m_axi_rvalid           ( reglk_axi_resp.r_valid        ),
    .m_axi_rready           ( reglk_axi_req.r_ready         ),
    //write response channel
    .m_axi_bresp            ( reglk_axi_resp.b.resp         ),
    .m_axi_bvalid           ( reglk_axi_resp.b_valid        ),
    .m_axi_bready           ( reglk_axi_req.b_ready         ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );

  assign reglk_secure = 1;

  // tie off signals not used by AXI-lite
  assign reglk_axi_req.aw.id     = '0;
  assign reglk_axi_req.aw.len    = '0;
  assign reglk_axi_req.aw.size   = 3'b11;// 8byte
  assign reglk_axi_req.aw.burst  = '0;
  assign reglk_axi_req.aw.lock   = '0;
  assign reglk_axi_req.aw.cache  = '0;
  assign reglk_axi_req.aw.prot   = '0;
  assign reglk_axi_req.aw.qos    = '0;
  assign reglk_axi_req.aw.region = '0;
  assign reglk_axi_req.aw.atop   = '0;
  assign reglk_axi_req.w.last    = 1'b1;
  assign reglk_axi_req.ar.id     = '0;
  assign reglk_axi_req.ar.len    = '0;
  assign reglk_axi_req.ar.size   = 3'b11;// 8byte
  assign reglk_axi_req.ar.burst  = '0;
  assign reglk_axi_req.ar.lock   = '0;
  assign reglk_axi_req.ar.cache  = '0;
  assign reglk_axi_req.ar.prot   = '0;
  assign reglk_axi_req.ar.qos    = '0;
  assign reglk_axi_req.ar.region = '0;

  /////////////////////////////
  // sha512
  /////////////////////////////

  ariane_axi::req_t    sha512_axi_req;
  ariane_axi::resp_t   sha512_axi_resp;

  sha512_wrapper #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   )
  ) i_sha512_wrapper (
    .clk_i                         ,
    .rst_ni                        ,
    .reglk_ctrl_i  ( reglk_ctrl[3*8+7:3*8]),
    .axi_req_i     ( sha512_axi_req  ),
    .axi_resp_o    ( sha512_axi_resp )
  );

  logic sha512_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_sha512_axilite_bridge (
    .secure                 ( sha512_secure                 ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_sha512_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_sha512_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_sha512_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_sha512_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_sha512_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_sha512_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( sha512_axi_req.aw.addr         ),
    .m_axi_awvalid          ( sha512_axi_req.aw_valid        ),
    .m_axi_awready          ( sha512_axi_resp.aw_ready       ),
    //write data channel
    .m_axi_wdata            ( sha512_axi_req.w.data          ),
    .m_axi_wstrb            ( sha512_axi_req.w.strb          ),
    .m_axi_wvalid           ( sha512_axi_req.w_valid         ),
    .m_axi_wready           ( sha512_axi_resp.w_ready        ),
    //read address channel
    .m_axi_araddr           ( sha512_axi_req.ar.addr         ),
    .m_axi_arvalid          ( sha512_axi_req.ar_valid        ),
    .m_axi_arready          ( sha512_axi_resp.ar_ready       ),
    //read data channel
    .m_axi_rdata            ( sha512_axi_resp.r.data         ),
    .m_axi_rresp            ( sha512_axi_resp.r.resp         ),
    .m_axi_rvalid           ( sha512_axi_resp.r_valid        ),
    .m_axi_rready           ( sha512_axi_req.r_ready         ),
    //write response channel
    .m_axi_bresp            ( sha512_axi_resp.b.resp         ),
    .m_axi_bvalid           ( sha512_axi_resp.b_valid        ),
    .m_axi_bready           ( sha512_axi_req.b_ready         ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );

  assign sha512_secure = 0;
  // tie off signals not used by AXI-lite
  assign sha512_axi_req.aw.id     = '0;
  assign sha512_axi_req.aw.len    = '0;
  assign sha512_axi_req.aw.size   = 3'b11;// 8byte
  assign sha512_axi_req.aw.burst  = '0;
  assign sha512_axi_req.aw.lock   = '0;
  assign sha512_axi_req.aw.cache  = '0;
  assign sha512_axi_req.aw.prot   = '0;
  assign sha512_axi_req.aw.qos    = '0;
  assign sha512_axi_req.aw.region = '0;
  assign sha512_axi_req.aw.atop   = '0;
  assign sha512_axi_req.w.last    = 1'b1;
  assign sha512_axi_req.ar.id     = '0;
  assign sha512_axi_req.ar.len    = '0;
  assign sha512_axi_req.ar.size   = 3'b11;// 8byte
  assign sha512_axi_req.ar.burst  = '0;
  assign sha512_axi_req.ar.lock   = '0;
  assign sha512_axi_req.ar.cache  = '0;
  assign sha512_axi_req.ar.prot   = '0;
  assign sha512_axi_req.ar.qos    = '0;
  assign sha512_axi_req.ar.region = '0;


  /////////////////////////////
  // DMA
  /////////////////////////////

  ariane_axi::req_t    dma_axi_req;
  ariane_axi::resp_t   dma_axi_resp;

  dma_wrapper #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   )
  ) i_dma_wrapper (
    .clk_i                         ,
    .rst_ni                        ,
    .reglk_ctrl_i  ( reglk_ctrl[4*8+7:4*8]),
    .pmpcfg_i      ( pmpcfg_i  ),
    .pmpaddr_i     ( pmpaddr_i  ),
    .axi_req_i     ( dma_axi_req  ),
    .axi_resp_o    ( dma_axi_resp )
  );

  logic dma_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_dma_axilite_bridge (
    .secure                 ( dma_secure                    ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_dma_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_dma_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_dma_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_dma_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_dma_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_dma_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( dma_axi_req.aw.addr         ),
    .m_axi_awvalid          ( dma_axi_req.aw_valid        ),
    .m_axi_awready          ( dma_axi_resp.aw_ready       ),
    //write data channel
    .m_axi_wdata            ( dma_axi_req.w.data          ),
    .m_axi_wstrb            ( dma_axi_req.w.strb          ),
    .m_axi_wvalid           ( dma_axi_req.w_valid         ),
    .m_axi_wready           ( dma_axi_resp.w_ready        ),
    //read address channel
    .m_axi_araddr           ( dma_axi_req.ar.addr         ),
    .m_axi_arvalid          ( dma_axi_req.ar_valid        ),
    .m_axi_arready          ( dma_axi_resp.ar_ready       ),
    //read data channel
    .m_axi_rdata            ( dma_axi_resp.r.data         ),
    .m_axi_rresp            ( dma_axi_resp.r.resp         ),
    .m_axi_rvalid           ( dma_axi_resp.r_valid        ),
    .m_axi_rready           ( dma_axi_req.r_ready         ),
    //write response channel
    .m_axi_bresp            ( dma_axi_resp.b.resp         ),
    .m_axi_bvalid           ( dma_axi_resp.b_valid        ),
    .m_axi_bready           ( dma_axi_req.b_ready         ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );

  assign dma_secure = 1;

  // tie off signals not used by AXI-lite
  assign dma_axi_req.aw.id     = '0;
  assign dma_axi_req.aw.len    = '0;
  assign dma_axi_req.aw.size   = 3'b11;// 8byte
  assign dma_axi_req.aw.burst  = '0;
  assign dma_axi_req.aw.lock   = '0;
  assign dma_axi_req.aw.cache  = '0;
  assign dma_axi_req.aw.prot   = '0;
  assign dma_axi_req.aw.qos    = '0;
  assign dma_axi_req.aw.region = '0;
  assign dma_axi_req.aw.atop   = '0;
  assign dma_axi_req.w.last    = 1'b1;
  assign dma_axi_req.ar.id     = '0;
  assign dma_axi_req.ar.len    = '0;
  assign dma_axi_req.ar.size   = 3'b11;// 8byte
  assign dma_axi_req.ar.burst  = '0;
  assign dma_axi_req.ar.lock   = '0;
  assign dma_axi_req.ar.cache  = '0;
  assign dma_axi_req.ar.prot   = '0;
  assign dma_axi_req.ar.qos    = '0;
  assign dma_axi_req.ar.region = '0;

  /////////////////////////////
  // HMAC
  /////////////////////////////

  ariane_axi::req_t    hmac_axi_req;
  ariane_axi::resp_t   hmac_axi_resp;

  hmac_wrapper #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   )
  ) i_hmac_wrapper (
    .clk_i                         ,
    .rst_ni        ,
    .reglk_ctrl_i  ( reglk_ctrl[5*8+7:5*8] ),
    .acct_ctrl_i   ( ),
    .expectedHash_i  (hmac_expectedHash),
    .axi_req_i     ( hmac_axi_req  ),
    .axi_resp_o    ( hmac_axi_resp ),
    .warning       (hmac_warning)
  );

  logic hmac_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_hmac_axilite_bridge (
    .secure                 ( hmac_secure                   ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_hmac_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_hmac_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_hmac_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_hmac_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_hmac_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_hmac_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( hmac_axi_req.aw.addr         ),
    .m_axi_awvalid          ( hmac_axi_req.aw_valid        ),
    .m_axi_awready          ( hmac_axi_resp.aw_ready       ),
    //write data channel
    .m_axi_wdata            ( hmac_axi_req.w.data          ),
    .m_axi_wstrb            ( hmac_axi_req.w.strb          ),
    .m_axi_wvalid           ( hmac_axi_req.w_valid         ),
    .m_axi_wready           ( hmac_axi_resp.w_ready        ),
    //read address channel
    .m_axi_araddr           ( hmac_axi_req.ar.addr         ),
    .m_axi_arvalid          ( hmac_axi_req.ar_valid        ),
    .m_axi_arready          ( hmac_axi_resp.ar_ready       ),
    //read data channel
    .m_axi_rdata            ( hmac_axi_resp.r.data         ),
    .m_axi_rresp            ( hmac_axi_resp.r.resp         ),
    .m_axi_rvalid           ( hmac_axi_resp.r_valid        ),
    .m_axi_rready           ( hmac_axi_req.r_ready         ),
    //write response channel
    .m_axi_bresp            ( hmac_axi_resp.b.resp         ),
    .m_axi_bvalid           ( hmac_axi_resp.b_valid        ),
    .m_axi_bready           ( hmac_axi_req.b_ready         ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );

  assign hmac_secure = 1;

  // tie off signals not used by AXI-lite
  assign hmac_axi_req.aw.id     = '0;
  assign hmac_axi_req.aw.len    = '0;
  assign hmac_axi_req.aw.size   = 3'b11;// 8byte
  assign hmac_axi_req.aw.burst  = '0;
  assign hmac_axi_req.aw.lock   = '0;
  assign hmac_axi_req.aw.cache  = '0;
  assign hmac_axi_req.aw.prot   = '0;
  assign hmac_axi_req.aw.qos    = '0;
  assign hmac_axi_req.aw.region = '0;
  assign hmac_axi_req.aw.atop   = '0;
  assign hmac_axi_req.w.last    = 1'b1;
  assign hmac_axi_req.ar.id     = '0;
  assign hmac_axi_req.ar.len    = '0;
  assign hmac_axi_req.ar.size   = 3'b11;// 8byte
  assign hmac_axi_req.ar.burst  = '0;
  assign hmac_axi_req.ar.lock   = '0;
  assign hmac_axi_req.ar.cache  = '0;
  assign hmac_axi_req.ar.prot   = '0;
  assign hmac_axi_req.ar.qos    = '0;
  assign hmac_axi_req.ar.region = '0;


  fuse_mem#(
    .MEM_SIZE(FUSE_MEM_SIZE)
  ) i_fuse_mem (
    .clk_i(clk_i),
    .acct_o(fuse_acct),
    .expectedHash_o (hmac_expectedHash)
  );

  logic [95:0] fuse_acct;
  logic [511:0] hmac_expectedHash; 

  ///////////////////////////////
  // ACCT
  /////////////////////////////

  ariane_axi::req_t    acct_axi_req;
  ariane_axi::resp_t   acct_axi_resp;

acct_wrapper #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   )
  ) i_acct_wrapper (
    .clk_i                         ,
    .rst_ni        ,
    .reglk_ctrl_i  ( reglk_ctrl[6*8+7:6*8] ),
    // .acct_ctrl_i   ( acc_ctrl_c[priv_lvl_i][1]),
    .acc_ctrl_o (acc_ctrl),
    .axi_req_i     ( acct_axi_req  ),
    .axi_resp_o    ( acct_axi_resp ),
    .fuse_acct_i   ( fuse_acct     )
  );

  logic acct_secure;

  noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SwapEndianess )
  ) i_acct_axilite_bridge (
    .secure                 ( acct_secure                   ),
    .priv_lvl_i             ( priv_lvl_i                    ),
    .clk                    ( clk_i                         ),
    .rst                    ( ~rst_ni                       ),
    // to/from NOC
    .splitter_bridge_val    ( buf_ariane_acct_noc2_valid_i ),
    .splitter_bridge_data   ( buf_ariane_acct_noc2_data_i  ),
    .bridge_splitter_rdy    ( ariane_acct_buf_noc2_ready_o ),
    .bridge_splitter_val    ( ariane_acct_buf_noc3_valid_o ),
    .bridge_splitter_data   ( ariane_acct_buf_noc3_data_o  ),
    .splitter_bridge_rdy    ( buf_ariane_acct_noc3_ready_i ),
    //axi lite signals
    //write address channel
    .m_axi_awaddr           ( acct_axi_req.aw.addr         ),
    .m_axi_awvalid          ( acct_axi_req.aw_valid        ),
    .m_axi_awready          ( acct_axi_resp.aw_ready       ),
    //write data channel
    .m_axi_wdata            ( acct_axi_req.w.data          ),
    .m_axi_wstrb            ( acct_axi_req.w.strb          ),
    .m_axi_wvalid           ( acct_axi_req.w_valid         ),
    .m_axi_wready           ( acct_axi_resp.w_ready        ),
    //read address channel
    .m_axi_araddr           ( acct_axi_req.ar.addr         ),
    .m_axi_arvalid          ( acct_axi_req.ar_valid        ),
    .m_axi_arready          ( acct_axi_resp.ar_ready       ),
    //read data channel
    .m_axi_rdata            ( acct_axi_resp.r.data         ),
    .m_axi_rresp            ( acct_axi_resp.r.resp         ),
    .m_axi_rvalid           ( acct_axi_resp.r_valid        ),
    .m_axi_rready           ( acct_axi_req.r_ready         ),
    //write response channel
    .m_axi_bresp            ( acct_axi_resp.b.resp         ),
    .m_axi_bvalid           ( acct_axi_resp.b_valid        ),
    .m_axi_bready           ( acct_axi_req.b_ready         ),
    // non-axi-lite signals
    .w_reqbuf_size          (                               ),
    .r_reqbuf_size          (                               )
  );
  
  assign acct_secure = 1;
  
  // tie off signals not used by AXI-lite
  assign acct_axi_req.aw.id     = '0;
  assign acct_axi_req.aw.len    = '0;
  assign acct_axi_req.aw.size   = 3'b11;// 8byte
  assign acct_axi_req.aw.burst  = '0;
  assign acct_axi_req.aw.lock   = '0;
  assign acct_axi_req.aw.cache  = '0;
  assign acct_axi_req.aw.prot   = '0;
  assign acct_axi_req.aw.qos    = '0;
  assign acct_axi_req.aw.region = '0;
  assign acct_axi_req.aw.atop   = '0;
  assign acct_axi_req.w.last    = 1'b1;
  assign acct_axi_req.ar.id     = '0;
  assign acct_axi_req.ar.len    = '0;
  assign acct_axi_req.ar.size   = 3'b11;// 8byte
  assign acct_axi_req.ar.burst  = '0;
  assign acct_axi_req.ar.lock   = '0;
  assign acct_axi_req.ar.cache  = '0;
  assign acct_axi_req.ar.prot   = '0;
  assign acct_axi_req.ar.qos    = '0;
  assign acct_axi_req.ar.region = '0;

endmodule // riscv_peripherals

