module aes_counter(
    clk_i,
    rst_n,
    start,
    done,
    cycle
    );
    input logic clk_i;
    input logic rst_n;
    input logic start;
    input logic done;
    output logic[31:0] cycle;

    logic start_r,done_r;
    logic count_start,count_end;
    logic count_state_r,count_state_n;

    always_ff @(posedge clk_i) begin: posedge_regs
        if(~rst_n) begin
            start_r <= 0;
            done_r  <= 0;
        end else begin
            start_r <= start;
            done_r  <= done;
        end
    end

    assign count_start  = ~start_r & start;
    assign count_end    = ~done_r  & done;

    always_comb begin: count_state
        unique case(count_state_r)
                1: begin
                    if(count_end) begin
                        count_state_n = 0;
                    end else count_state_n = count_state_r;
                end
                0: begin
                    if(count_start) begin
                        count_state_n = 1;
                    end else count_state_n = count_state_r;
                end
                default: count_state_n = count_state_r;
        endcase
    end

    always_ff @(posedge clk_i) begin: count_reg
        if(~rst_n) begin
            count_state_r <= 0;
        end else begin
            count_state_r <= count_state_n;
        end
    end

    always_ff @(posedge clk_i) begin: counter
        if(~rst_n) begin
            cycle <= 0;
        end else if(count_state_r) begin
            cycle <= cycle + 1;
        end else if(~count_state_r) begin
            cycle <= cycle;
        end
    end

endmodule
