// Wrapper for sha_256

module hmac_wrapper #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 10
)(
           clk_i,
           rst_ni,
           reglk_ctrl_i,
           acct_ctrl_i,
           expectedHash_i,
           axi_req_i, 
           axi_resp_o
           ,warning
       );

    input  logic                   clk_i;
    input  logic                   rst_ni;
    input logic [7 :0]             reglk_ctrl_i; // register lock values
    input logic                    acct_ctrl_i;
    input logic [255:0]            expectedHash_i;
    input  ariane_axi::req_t       axi_req_i;
    output ariane_axi::resp_t      axi_resp_o;

output warning;

// internal signals


// Internal registers
reg newMessage_r, startHash_r;
logic startHash;
logic newMessage;
logic [63:0] data [0:7];
logic [63:0] key0 [0:7];

logic [511:0] bigData; 
logic [255:0] hash;
logic ready;
logic hashValid;
logic [511:0] key;

// signals from AXI 4 Lite
logic [AXI_ADDR_WIDTH-1:0] address;
logic                      en, en_acct;
logic                      we;
logic [63:0] wdata;
logic [63:0] rdata;
logic [63:0] expectedHash [3:0];

assign key    = {key0[0], key0[1], key0[2], key0[3],key0[4],key0[5],key0[6],key0[7]}; 

assign bigData = {data[7], data[6], data[5], data[4], data[3], data[2], data[1], data[0]};


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
        .en_o       ( en    ),
        .we_o       ( we         ),
        .data_i     ( rdata      ),
        .data_o     ( wdata      )
    );

always @(posedge clk_i)
  begin
    if(~rst_ni)
      begin
        startHash_r <= 1'b0;
        newMessage_r <= 1'b0;
      end
    else
      begin
        // Generate a registered versions of startHash and newMessage
        startHash_r         <= startHash;
        newMessage_r        <= newMessage;
      end
  end

logic warning;

// Implement SHA256 I/O memory map interface
// Write side
always @(posedge clk_i)
    begin
        if(~rst_ni)
            begin
                startHash <= 0;
                newMessage <= 0;
                data[0] <= 0;
                data[1] <= 0;
                data[2] <= 0;
                data[3] <= 0;
                data[4] <= 0;
                data[5] <= 0;
                data[6] <= 0;
                data[7] <= 0;
                key0[3] <= 0;
                key0[2] <= 0;        
                key0[1] <= 0;
                key0[0] <= 0;
                expectedHash[0] <= expectedHash_i[63:0];
                expectedHash[1] <= expectedHash_i[127:64];
                expectedHash[2] <= expectedHash_i[191:128];
                expectedHash[3] <= expectedHash_i[255:192];
            end
        else if(en && we)
            begin
                case(address[9:3])
                    0:
                        begin
                            startHash <= reglk_ctrl_i[1] ? startHash : wdata[0];
                            newMessage <= reglk_ctrl_i[1] ? newMessage : wdata[1];
                        end
                    1:
                        data[0] <= reglk_ctrl_i[3] ? data[0] : wdata;
                    2:                                        
                        data[1] <= reglk_ctrl_i[3] ? data[1] : wdata;
                    3:                                        
                        data[2] <= reglk_ctrl_i[3] ? data[2] : wdata;
                    4:                                        
                        data[3] <= reglk_ctrl_i[3] ? data[3] : wdata;
                    5:                                        
                        data[4] <= reglk_ctrl_i[3] ? data[4] : wdata;
                    6:                                         
                        data[5] <= reglk_ctrl_i[3] ? data[5] : wdata;
                    7:
                        data[6] <= reglk_ctrl_i[3] ? data[6] : wdata;
                    8:                                        
                        data[7] <= reglk_ctrl_i[3] ? data[7] : wdata;
                    34:   
                        key0[7] <= reglk_ctrl_i[5] ? key0[7] : wdata;
                    35:                                        
                        key0[6] <= reglk_ctrl_i[5] ? key0[6] : wdata;
                    36:   
                        key0[5] <= reglk_ctrl_i[5] ? key0[5] : wdata;
                    37:                                        
                        key0[4] <= reglk_ctrl_i[5] ? key0[4] : wdata;
                    38:                                        
                        key0[3] <= reglk_ctrl_i[5] ? key0[3] : wdata;
                    39:                                        
                        key0[2] <= reglk_ctrl_i[5] ? key0[2] : wdata;
                    40:                                        
                        key0[1] <= reglk_ctrl_i[5] ? key0[1] : wdata;
                    41:
                        key0[0] <= reglk_ctrl_i[5] ? key0[0] : wdata;
                    46:                                        
                        expectedHash[0] <= reglk_ctrl_i[5] ? expectedHash[0] : wdata;
                    47:                                        
                        expectedHash[1] <= reglk_ctrl_i[5] ? expectedHash[1] : wdata;
                    48:                                        
                        expectedHash[2] <= reglk_ctrl_i[5] ? expectedHash[2] : wdata;
                    49:
                        expectedHash[3] <= reglk_ctrl_i[5] ? expectedHash[3] : wdata;
                    50:
                        warning <= 1;       
                    default:
                        ;
                endcase
            end
    end

// Implement SHA256 I/O memory map interface
// Read side
always @(*)
    begin
      rdata = 64'b0; 
      if (en) begin
        case(address[9:3])
            0:
                rdata = reglk_ctrl_i[0] ? 'b0 : {63'b0, ready};
            1:
                rdata = reglk_ctrl_i[2] ? 'b0 : data[0];
            2:
                rdata = reglk_ctrl_i[2] ? 'b0 : data[1];
            3:
                rdata = reglk_ctrl_i[2] ? 'b0 : data[2];
            4:
                rdata = reglk_ctrl_i[2] ? 'b0 : data[3];
            5:
                rdata = reglk_ctrl_i[2] ? 'b0 : data[4];
            6:
                rdata = reglk_ctrl_i[2] ? 'b0 : data[5];
            7:
                rdata = reglk_ctrl_i[2] ? 'b0 : data[6];
            8:
                rdata = reglk_ctrl_i[2] ? 'b0 : data[7];
            17:
                rdata = reglk_ctrl_i[0] ? 'b0 : {63'b0, hashValid};
            18:
                rdata = reglk_ctrl_i[6] ? 'b0 : hash[63:0];
            19:                                                 
                rdata = reglk_ctrl_i[6] ? 'b0 : hash[127:64];
            20:                                                 
                rdata = reglk_ctrl_i[6] ? 'b0 : hash[191:128];
            21:                                                 
                rdata = reglk_ctrl_i[6] ? 'b0 : hash[255:192];
            42:
                rdata = reglk_ctrl_i[5] ? 'b0 : expectedHash[0];
            43:
                rdata = reglk_ctrl_i[5] ? 'b0 : expectedHash[1];
            44:
                rdata = reglk_ctrl_i[5] ? 'b0 : expectedHash[2];
            45:
                rdata = reglk_ctrl_i[5] ? 'b0 : expectedHash[3];
            default:
                rdata = 64'b0;
        endcase
      end // if
    end


top_hmac hmac_inst(
    .CLK(clk_i),
    .RST(rst_ni),
    .init(startHash),
    .key_i(key),
    .data_i(bigData),
    .hmac_o(hash),
    .data_available_o(hashValid) 
);

endmodule

