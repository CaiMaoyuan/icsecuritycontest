

module aes0_wrapper #(
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
           rand_key
       );

    input  logic                   clk_i;
    input  logic                   rst_ni;
    input logic [7 :0]             reglk_ctrl_i; // register lock values
    input logic                    acct_ctrl_i;
    input  ariane_axi::req_t       axi_req_i;
    output ariane_axi::resp_t      axi_resp_o;
    input logic [64:0]             rand_key;

// internal signals

logic start;
logic [63:0] text [0:1];
logic [63:0] key0 [0:1];  
logic key_update;

logic   [127:0] text_big   ;  
logic   [127:0] key_big ;  
logic   [127:0] ct;
logic           ct_valid;
logic   [5:0]   add_sel;
logic   [41:0]  shift_idx;
logic           write_once_reg;
logic   [31:0]   cycle;

// signals from AXI 4 Lite
logic [AXI_ADDR_WIDTH-1:0] address;
logic                     en;
logic                     we;
logic [63:0] wdata;
logic [63:0] rdata;

assign add_sel      = address[8:3];
assign text_big     = {text[0], text[1]};

logic ase_key_read_write_policy; //1:can be read and written; 0:can't be read and written
logic use_rand_key;

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

    logic en_acct;

// Implement APB I/O map to AES interface
// Write side
always @( posedge clk_i)
    begin
         if(~rst_ni)
             begin
                ase_key_read_write_policy <= 0;
                en <= 1; 
             end
         else 
        if(en && we)
            case(address[8:3])
                0:
                    start  <=  wdata[0];
                1:
                    text[1]  <= reglk_ctrl_i[2] ? 'b0 : wdata[63:0];
                2:
                    text[0]  <= reglk_ctrl_i[2] ? 'b0 : wdata[63:0]; 
                 3:
                    begin
                        key0[1]  = reglk_ctrl_i[3]  ? 'b0 : (ase_key_read_write_policy ? wdata[63:0] : key0[1]);
                        en = en_acct && acct_ctrl_i;
                    end
                 4:
                    key0[0]  = reglk_ctrl_i[5] ?  'b0 : (ase_key_read_write_policy ? wdata[63:0] : key0[0]);
                8:
                    key_update <= wdata[63:0];
                9: 
                    if(~write_once_reg) begin
                        shift_idx <= wdata[42:1];
                        write_once_reg <= wdata[0];
                    end
                    else begin
                        shift_idx <= shift_idx;
                        write_once_reg <= write_once_reg;
                    end
                11:
                    ase_key_read_write_policy <= reglk_ctrl_i[6] ? ase_key_read_write_policy : wdata[0];
                12: 
                    use_rand_key <= reglk_ctrl_i[6] ? use_rand_key : wdata[0];
                default:
                    ;
            endcase
    end // always @ (posedge wb_clk_i)

// Implement MD5 I/O memory map interface
// Read side
//always @(~write)
always @(*)
    begin
        if(~rst_ni) begin
                rdata = 64'b0;
            end
        else if (en) begin
        case(address[8:3])
            0:
                rdata = reglk_ctrl_i[0] ? 'b0 :  {63'b0, start};
            1:
                rdata = reglk_ctrl_i[2] ? 'b0 :  text[1];
            2:
                rdata = reglk_ctrl_i[2] ? 'b0 :  text[0];
            3:
                rdata = reglk_ctrl_i[3] ? 'b0 :  (ase_key_read_write_policy ? key_big[127:64] : 'b0);
            4:
                rdata = reglk_ctrl_i[3] ? 'b0 :  (ase_key_read_write_policy ? key_big[63:0] : 'b0);
            5:
                rdata = reglk_ctrl_i[4] ? 'b0 :  {63'b0, ct_valid};
            6:
                rdata = reglk_ctrl_i[5] ? 'b0 :  ct[63:0];
            7:                                                 
                rdata = reglk_ctrl_i[5] ? 'b0 :  ct[127:64];
            10:
                rdata = reglk_ctrl_i[5] ? 'b0 :  {32'b0, cycle};
            11: 
                rdata = reglk_ctrl_i[6] ? 'b0 :  {63'b0, ase_key_read_write_policy};
            12:
                rdata = reglk_ctrl_i[6] ? 'b0 :  use_rand_key;
        endcase
      end 
    end // always @ (*)


// select the proper key
logic   [127:0] key_big_lfsr ; 

always @(*)
    begin
        if (key_update) key_big = key_big_lfsr;
        else key_big = {key0[1], key0[0]}; 
    end

aes_counter aes_counter(
    .clk_i  (clk_i),
    .rst_n  (rst_ni),
    .start  (start),
    .done   (ct_valid),
    .cycle  (cycle)
    );

aes aes(
            .sys_clk    (clk_i      ),
            .sys_rst_n  (rst_ni     ),
            .text_in    (text_big   ),
            .key        (key_big    ),
            .ld         (start      ),
            .text_out   (ct         ),
            .done       (ct_valid   )
        );

lfsr_128bit #(
    .SEED   (128'b0 ),
    .WIDTH  (128    )
) lfsr_128bit(
    .clk_i          (clk_i      ),
    .rst_ni         (rst_ni     ),
    .shift_idx_i    (shift_idx  ),
    .en_i           (key_update ),
    .refill_way_bin (key_big_lfsr )
);


endmodule
