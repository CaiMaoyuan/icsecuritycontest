 /*
 * FUSE mem: Which have all the secure data
 */

module fuse_mem 
(
   input  logic         clk_i,
   output logic [95:0] acct_o,
   output logic [511:0] expectedHash_o
);
    parameter  MEM_SIZE = 108;
    localparam ACCT_OFFSET = 108; 
    localparam EXPECTED_HASH_OFFSET = 108; 

// Store key values here. // Replication of fuse. 
    const logic [MEM_SIZE-1:0][31:0] mem = {
        // expected hamc hash
        32'h1efe832e, 32'h03f7255b, 32'h2b9bb33f, 32'h32f60445,  // 100
        32'hf9d607f5, 32'h2ec5b0a3, 32'h11afe348, 32'h1f43b83d,  // 91

        32'h6AB541B4, 32'h869DCA71, 32'hC4CA11D8, 32'hBB1B0253, //100 99 98 97
        
        32'h3B789A55, 32'h75831614, //86
        32'h29292C74, //85

        32'h04BC21F6, //93
        //RNG POLY END
        //HMAC okey hash
        32'hd5de2a45, 32'ha2a90626, 32'h595bee9e, 32'h537f47da,
        32'h747616fd, 32'hb878b776, 32'hf787e54b, 32'hb9418290, 
        //HMAC ikey hash
        32'h1c9d0b34, 32'h8683fd98, 32'h736ab688, 32'h81c2c0da,
        32'h99b1d298, 32'h33d2b38d, 32'h07e12a57, 32'hfbc8cd46, 
        //HMAC key
        "$$|-", "|/-\\", "[|<@", "|]/_", 
        "\\{<=", "=>H@", "ckAd", "aC$$", 
        // Access control for master 2. First 4 bits for peripheral 0, next 4 for p1 and so on.
        32'hff8f8f8f,
        32'hfffccff8,
        32'hfff0f888,
        // Access control for master 1. First 4 bits for peripheral 0, next 4 for p1 and so on.
        32'hf8ff8fff,
        32'hf8fc88c8,
        32'hfc8f8ff8, 
        // Access control for master 0. First 4 bits for peripheral 0, next 4 for p1 and so on.
        32'hffffffff,
        32'hfffff888,
        32'h888f888f, 
        // SHA Key
        32'h28aed2a6,
        32'h28aed2a6,
        32'habf71588,
        32'h09cf4f3c,
        32'h2b7e1516,
        32'h28aed2a6, 
        // AES2 Key 2
        32'h23304b7a, //53
        32'h39f9f3ff, //52
        32'h067d8d9f, //51
        32'h9e24ecc7,
        // AES2 Key 1
        32'hf3eed1bd,
        32'hb5d2a03c,
        32'h064b5a7e,
        32'h3db181f8,
        // AES2 Key 0
        32'h00000001,
        32'h00000010,
        32'h00010000,
        32'h04200000,
        // AES1 Key 2
        32'h23304b7a,
        32'h39f9f3ff,
        32'h067d8d8f,
        32'h9e24ecc7,
        32'h00000000,
        32'h00000000,
        32'h00000000,
        32'h00000000,    // LSB 32 bits
        // AES1 Key 1
        32'h00000000,
        32'h00000000,
        32'h00000000,
        32'h00000000,
        32'h00000000,
        32'h00000000,    // LSB 32 bits
        // AES1 Key 0
        32'h2b7e1516,
        32'h28aed2a6,
        32'habf71588,
        32'h09cf4f3c,
        32'h00000000,
        32'h00000000,
        32'h00000000,
        32'h00000000,  // LSB 32 bits
        // AES0 Key 2
        32'h28aed9a6,
        32'h207e1516,
        32'h09c94f3c,
        32'ha6f71558,
        32'h2b7e1516,    
        32'h28aed2a6, // LSB 32 bits
        // AES0 Key 1
        32'hf3eed1bd,
        32'hb5d2a03c,
        32'h064b5a7e,
        32'h3db181f8,
        32'hf3eed1bd,
        32'hb5d2a03c,
        32'h064b5a7e,
        32'h3db181f8,   // LSB 32 bits
        // AES0 Key 0
        32'h28aef2a6,
        32'h2b3e1216,    
        32'habf71588,
        32'h09cf4f3c,
        32'h2b7e1516,
        32'h28aed2a6    // LSB 32 bits  // mem[0]
    };

    logic [$clog2(MEM_SIZE)-1:0] addr_q;


    // this prevents spurious Xes from propagating into
    // the speculative fetch stage of the core
    assign acct_o = {mem[ACCT_OFFSET],mem[ACCT_OFFSET-1],mem[ACCT_OFFSET-2],mem[ACCT_OFFSET-3],mem[ACCT_OFFSET-4],mem[ACCT_OFFSET-5],mem[ACCT_OFFSET-6],mem[ACCT_OFFSET-7]}; // default values for  the acct module 
    assign expectedHash_o = {mem[EXPECTED_HASH_OFFSET],mem[EXPECTED_HASH_OFFSET-1],mem[EXPECTED_HASH_OFFSET-2],mem[EXPECTED_HASH_OFFSET-3],mem[EXPECTED_HASH_OFFSET-4],mem[EXPECTED_HASH_OFFSET-5],mem[EXPECTED_HASH_OFFSET-6],mem[EXPECTED_HASH_OFFSET-7],mem[EXPECTED_HASH_OFFSET-8],mem[EXPECTED_HASH_OFFSET-9],mem[EXPECTED_HASH_OFFSET-10],mem[EXPECTED_HASH_OFFSET-11],mem[EXPECTED_HASH_OFFSET-12],mem[EXPECTED_HASH_OFFSET-13],mem[EXPECTED_HASH_OFFSET-14],mem[EXPECTED_HASH_OFFSET-15]};


// added for monitoring
    logic [31:0] mem0 = mem[0];
    logic [31:0] mem99 = mem[99];



endmodule
