module prng_128bit(
    input clk,
    input rst_n,
    input en,
    input [128:0] seed,
    input [128:0] poly,
    output [128:0] rand_num,
    output rand_num_valid
);
 
integer i;

logic rand_num_valid_reg;
logic [128:0] rand_num_reg;
 
always @(posedge clk or negedge rst_n)begin:loop
 
    if (!rst_n) begin
        rand_num_reg <=  128'b0;
        rand_num_valid_reg <=0;
    end
    else if(en) begin
        rand_num_reg <=  seed;
    end
    else begin
        for(i=1;i<128;i=i+1) rand_num_reg[i] <=  rand_num_reg[i-1];
        rand_num_reg[0] <=  ^ (poly[127:0] & rand_num_reg [127:0]);
        rand_num_valid_reg<=1;
    end
end

assign rand_num_valid = rand_num_valid_reg;
assign rand_num = rand_num_reg;
 
endmodule