// Wrapper for sha_512

module sha512_wrapper #(
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 10
)(
           clk_i,
           rst_ni,
           reglk_ctrl_i,
           axi_req_i, 
           axi_resp_o
       );

    input  logic                   clk_i;
    input  logic                   rst_ni;
    input logic [7 :0]             reglk_ctrl_i; // register lock values
    input  ariane_axi::req_t       axi_req_i;
    output ariane_axi::resp_t      axi_resp_o;

logic [1:0] mode;


// Internal registers
reg newMessage_r, startHash_r;
logic startHash;
logic newMessage;
logic [63:0] data [0:15];

logic [1023:0] bigData; 
logic [511:0] hash;
logic ready;
logic hashValid;
logic [511 : 0]  h_block;
logic            h_block_update;
logic   [5:0] add_sel;

// signals from AXI 4 Lite
logic [AXI_ADDR_WIDTH-1:0] address;
logic                      en, en_acct;
logic                      we;
logic [63:0] wdata;
logic [63:0] rdata;


assign h_block_update = 0; 
assign h_block = 0;

assign add_sel = address[8:3];
assign bigData = {data[15], data[14], data[13], data[12], data[11], data[10], data[9], data[8], data[7], data[6], data[5], data[4], data[3], data[2], data[1], data[0]};

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

    assign en = en_acct ;

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


// Implement SHA512 I/O memory map interface
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
                data[8] <= 0;
                data[9] <= 0;
                data[10] <= 0;
                data[11] <= 0;
                data[12] <= 0;
                data[13] <= 0;
                data[14] <= 0;
                data[15] <= 0;
                mode <= 0;
            end
        else if(en && we)
            begin
                case(address[8:3])
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
                    9:                                        
                        data[8] <= reglk_ctrl_i[3] ? data[8] : wdata;
                    10:                                       
                        data[9] <= reglk_ctrl_i[3] ? data[9] : wdata;
                    11:                                       
                        data[10] <= reglk_ctrl_i[3] ? data[10] : wdata;
                    12:                                        
                        data[11] <= reglk_ctrl_i[3] ? data[11] : wdata;
                    13:
                        data[12] <= reglk_ctrl_i[3] ? data[12] : wdata;
                    14:                                        
                        data[13] <= reglk_ctrl_i[3] ? data[13] : wdata;
                    15:                                        
                        data[14] <= reglk_ctrl_i[3] ? data[14] : wdata;
                    16:                                         
                        data[15] <= reglk_ctrl_i[3] ? data[15] : wdata;
                    18:
                        mode <= reglk_ctrl_i[1] ? mode: wdata[1:0];
                    default:
                        ;
                endcase
            end
    end

// Implement SHA512 I/O memory map interface
// Read side
always @(*)
    begin
      rdata = 64'b0; 
      if (en) begin
        case(address[8:3])
            0:
                rdata = reglk_ctrl_i[0] ? 'b0 : {64'b0, ready};
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
             9:
                 rdata = reglk_ctrl_i[2] ? 'b0 : data[8];
             10:
                 rdata = reglk_ctrl_i[2] ? 'b0 : data[9];
             11:
                 rdata = reglk_ctrl_i[2] ? 'b0 : data[10];
             12:
                 rdata = reglk_ctrl_i[2] ? 'b0 : data[11];
             13:
                 rdata = reglk_ctrl_i[2] ? 'b0 : data[12];
             14:
                 rdata = reglk_ctrl_i[2] ? 'b0 : data[13];
             15:
                 rdata = reglk_ctrl_i[2] ? 'b0 : data[14];
             16:
                 rdata = reglk_ctrl_i[2] ? 'b0 : data[15];
            17:
                rdata = reglk_ctrl_i[0] ? 'b0 : {63'b0, hashValid};
            18:
                rdata = reglk_ctrl_i[1] ? 'b0: {62'b0, mode};
            19:
                rdata = reglk_ctrl_i[4] ? 'b0 : hash[63:0];
            20:                                                 
                rdata = reglk_ctrl_i[4] ? 'b0 : hash[127:64];
            21:                                                 
                rdata = reglk_ctrl_i[4] ? 'b0 : hash[191:128];
            22:                                                 
                rdata = reglk_ctrl_i[4] ? 'b0 : hash[255:192];
            23:                                                 
                rdata = reglk_ctrl_i[4] ? 'b0 : hash[319:256];
            24:                                                 
                rdata = reglk_ctrl_i[4] ? 'b0 : hash[383:320];
            25:                                                 
                rdata = reglk_ctrl_i[4] ? 'b0 : hash[447:384];
            26:                                                 
                rdata = reglk_ctrl_i[4] ? 'b0 : hash[511:448];
            default:
                rdata = 64'b0;
        endcase
      end // if
    end

sha512 sha512(
           .clk(clk_i),
           .reset_n(rst_ni),
           .init(startHash && ~startHash_r),
           .next(newMessage && ~newMessage_r),
           .mode(mode),
           .work_factor('b0),
           .work_factor_num(32'h0),
           .h_block(h_block),
           .h_block_update(h_block_update),
           .block(bigData),
           .ready(ready),
           .digest(hash),
           .digest_valid(hashValid)
       );

endmodule
