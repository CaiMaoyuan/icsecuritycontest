module prng_wrapper #(
	parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ID_WIDTH   = 10
)(
	clk_i,
    rst_ni,
    reglk_ctrl_i,
    acct_ctrl_i,
    axi_req_i, 
    axi_resp_o,
    rand_num_o
	);


	input  logic                   clk_i;
    input  logic                   rst_ni;
    input logic [7 :0]             reglk_ctrl_i; // register lock values
    input logic                    acct_ctrl_i;
    input  ariane_axi::req_t       axi_req_i;
    output ariane_axi::resp_t      axi_resp_o;

output logic [63:0] rand_num_o = rand_num_64;

logic mode; // 1:128bit;0:64bit

logic [63:0] seed [0:1];
logic [127:0] seed_big;

logic [63:0] poly128 [0:1];
logic [127:0] poly128_big;

logic [63:0] poly64;
logic rand_num_valid, rand_num_valid_64, rand_num_valid_128;

assign rand_num_valid = rand_num_valid_64 || rand_num_valid_128;

logic seed_input_done;
logic seed_input_done_r;


//signals from AXI 4 Lite
logic [AXI_ADDR_WIDTH-1:0] address;
logic                      en, en_acct;
logic                      we;
logic [63:0]               wdata;
logic [63:0]               rdata;
//rand generate seed here
assign seed_big = {seed[0], seed[1]};
assign poly128_big = {poly128[0], poly128[1]};
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

    assign en = en_acct && acct_ctrl_i; 

// Implement APB I/O map to AES interface
// Write side
always @(posedge clk_i)
    begin
        if(~rst_ni)
            begin
			end
        else if(en && we)
        begin
            case(address[8:3])
                2:
                    poly128[1] <= reglk_ctrl_i[5] ? poly128[1] : wdata;
                3:
                    poly128[0] <= reglk_ctrl_i[5] ? poly128[0] : wdata;
                4:
                    mode <= reglk_ctrl_i[5] ? mode : wdata[0];
                8:
                    poly64 <= reglk_ctrl_i[5] ? poly64 : wdata;
                26:
                    seed_input_done <= reglk_ctrl_i[6] ? seed_input_done : wdata[0];
                default:
                    ;
            endcase // address[8:3]
        end
    end 

// Implement MD5 I/O memory map interface
// Read side
always @(*)
    begin
        rdata = 64'b0;
        if(en) begin
            case(address[8:3]) 
                0:
                    rdata = reglk_ctrl_i[3] ? 0 : seed[1];
                1:
                    rdata = reglk_ctrl_i[3] ? 0 : seed[0];
                2:
                    rdata = reglk_ctrl_i[5] ? 0 : poly128_big[63:0];
                3:
                    rdata = reglk_ctrl_i[5] ? 0 : poly128_big[127:64];
                8:
                    rdata = reglk_ctrl_i[5] ? 0 : poly64;
                9:
                    rdata = reglk_ctrl_i[4] ? 0 : rand_num_64;
                10:
                    rdata = reglk_ctrl_i[4] ? 0 : rand_num_128[63:0];
                11:
                    rdata = reglk_ctrl_i[4] ? 0 : rand_num_128[128:64];
                14:
                    rdata = reglk_ctrl_i[6] ? 0 : {63'b0, rand_num_valid};
                default:
                    if (rand_num_valid)
                        rdata = 64'b0;
            endcase // address[8:3]
        end 
    end

always @(posedge clk_i)
  begin
    if(~rst_ni)
      begin
        seed_input_done_r <= 1'b0;
      end
    else
      begin
        // Generate a registered versions of startHash and newMessage
        seed_input_done_r         <= seed_input_done;
      end
  end

logic [63:0] rand_num_64;
logic [128:0] rand_num_128;

prng_64bit prng_64bit(
    .clk(clk_i),
    .rst_n(rst_ni),
    .en(seed_input_done && ~seed_input_done_r && (mode == 0)),
    .seed(seed_big),
    .poly(poly64),
    .rand_num(rand_num_64),
    .rand_num_valid(rand_num_valid_64)
);

prng_128bit prng_128bit(
    .clk(clk_i),
    .rst_n(rst_ni),
    .en(seed_input_done && ~seed_input_done_r && (mode == 1)),
    .seed(seed_big),
    .poly(poly128_big),
    .rand_num(rand_num_128),
    .rand_num_valid(rand_num_valid_128)
);


endmodule
