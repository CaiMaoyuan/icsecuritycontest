// Description: Access Control registers
//


module acct_wrapper #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 10,
    parameter NB_SLAVE = 1,
    parameter NB_PERIPHERALS = 9
)(
           clk_i,
           rst_ni,
           reglk_ctrl_i,
           acc_ctrl_o,
           axi_req_i, 
           axi_resp_o,
           fuse_acct_i
       );


    input  logic                   clk_i;
    input  logic                   rst_ni;
    input logic [7 :0]             reglk_ctrl_i; // register lock valuesA
    input  ariane_axi::req_t       axi_req_i;
    output ariane_axi::resp_t      axi_resp_o;
    output logic [4*NB_PERIPHERALS-1 :0]   acc_ctrl_o; // Access control values
    input logic [95:0] fuse_acct_i;

    localparam AcCt_MEM_SIZE = NB_SLAVE*3 ;  // 32*3 bytes of access control for each slave interface

// internal signals

reg [AcCt_MEM_SIZE-1:0][31:0] acct_mem ; 
logic [15:0] reglk_ctrl ;  

// signals from AXI 4 Lite
logic [AXI_ADDR_WIDTH-1:0] address;
logic                      en, en_acct;
logic                      we;
logic [63:0] wdata;
logic [63:0] rdata;

assign acc_ctrl_o = {acct_mem[3*0+2], acct_mem[3*0+1], acct_mem[3*0+0]}; 

assign reglk_ctrl = reglk_ctrl_i;

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
        .en_o       ( en_acct    ),
        .we_o       ( we         ),
        .data_i     ( rdata      ),
        .data_o     ( wdata      )
    );

    assign en = en_acct; 

///////////////////////////////////////////////////////////////////////////
// Implement APB I/O map to PKT interface
// Write side
integer j;
always @(posedge clk_i)
    begin
        if(~rst_ni)
            begin
                acct_mem[00]  <= fuse_acct_i[31:0];
                acct_mem[01]  <= fuse_acct_i[63:32];
                acct_mem[02]  <= fuse_acct_i[95:64];
            end
        else if(en && we)
            case(address[10:3])
                0:
                    begin
                    acct_mem[00]  <= reglk_ctrl[5] ? acct_mem[00] : wdata;
                    end
                1:   
                    begin                                          
                    acct_mem[01]  <= reglk_ctrl[5] ? acct_mem[01] : wdata; 
                    end
                2:                
                    begin                             
                    acct_mem[02]  <= reglk_ctrl[5] ? acct_mem[02] : wdata;
                    end
                default:
                    ;
            endcase
        else begin
            acct_mem[00]  <= acct_mem[00];
            acct_mem[01]  <= acct_mem[01];
            acct_mem[02]  <= acct_mem[02];
        end
    end // always @ (posedge wb_clk_i)

//// Read side
always @(*)
    begin
      rdata = 64'b0; 
      if (en) begin
        case(address[10:3])
            0:
                rdata = reglk_ctrl[4] ? 'b0 : acct_mem[0]; 
            1:                                    
                rdata = reglk_ctrl[4] ? 'b0 : acct_mem[1];
            2:                                    
                rdata = reglk_ctrl[4] ? 'b0 : acct_mem[2];
            default:
                rdata = 32'b0;
        endcase
      end // if
    end // always @ (*)
endmodule
