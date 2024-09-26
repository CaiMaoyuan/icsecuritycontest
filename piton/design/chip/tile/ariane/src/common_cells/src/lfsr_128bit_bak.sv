// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Florian Zaruba, ETH Zurich
// Date: 5.11.2018
// Description: 16-bit LFSR

// --------------
// 128-bit LFSR
// --------------
//
// Description: Shift register
//
module lfsr_128bit #(
    parameter logic[127:0] SEED  = 128'b0,
    parameter int unsigned WIDTH = 128
)(
    input  logic                      clk_i,
    input  logic                      rst_ni,
    input  logic                      en_i,
    // input  logic [5:0][6:0]       shift_idx_i,
    // output logic [$clog2(WIDTH)-1:00]          refill_way_oh,
    output logic [WIDTH-1:0]                   refill_way_bin
);

    localparam int unsigned LOG_WIDTH = $clog2(WIDTH);

    // logic [5:0][6:0] shift_idx_i;
    logic [127:0] shift_d, shift_q;


    always_comb begin

        automatic logic shift_in;
        shift_in = !(shift_q[127] ^ shift_q[51] ^ shift_q[13] ^ shift_q[8] ^ shift_q[4] ^ shift_q[1]);
        // shift_in = !(shift_q[15] ^ shift_q[12] ^ shift_q[5] ^ shift_q[1]);

        shift_d = shift_q;

        if (en_i)
            shift_d = {shift_q[126:0], shift_in};

        // output assignment
//        refill_way_oh = 'b0;
//        refill_way_oh[shift_q[LOG_WIDTH-1:0]] = 1'b1;
        refill_way_bin = shift_q;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_
        if(~rst_ni) begin
            shift_q <= SEED;
        end else begin
            shift_q <= shift_d;
        end
    end

    //pragma translate_off
    initial begin
        assert (WIDTH <= 128) else $fatal(1, "WIDTH needs to be less than 128 because of the 128-bit LFSR");
    end
    //pragma translate_on

endmodule
