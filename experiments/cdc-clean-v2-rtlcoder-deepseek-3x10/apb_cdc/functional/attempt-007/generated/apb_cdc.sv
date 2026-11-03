Sure, here is the complete Verilog code for the APB clock-domain bridge:

```
module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals
    reg [ADDR_WIDTH-1:0]    src_paddr_r;
    reg [DATA_WIDTH-1:0]    src_pwdata_r;
    reg [DATA_WIDTH/8-1:0]  src_pstrb_r;
    reg [2:0]               src_pprot_r;
    reg                     src_psel_r;
    reg                     src_penable_r;
    reg                     src_pwrite_r;
    reg                     src_pready_r;
    reg [DATA_WIDTH-1:0]    src_prdata_r;
    reg                     src_pslverr_r;
    reg                     dst_psel_r;
    reg                     dst_penable_r;
    reg                     dst_pwrite_r;
    reg [ADDR_WIDTH-1:0]    dst_paddr_r;
    reg [DATA_WIDTH-1:0]    dst_pwdata_r;
    reg [DATA_WIDTH/8-1:0]  dst_pstrb_r;
    reg [2:0]               dst_pprot_r;
    reg                     dst_pready_r;
    reg [DATA_WIDTH-1:0]    dst_prdata_r;
    reg                     dst_pslverr_r;

    // Synchronous reset
    always @(posedge src_pclk_i) begin
        if (~src_preset_ni) begin
            src_paddr_r <= 0;
            src_pwdata_r <= 0;
            src_pstrb_r <= 0;
            src_pprot_r <= 0;
            src_psel_r <= 0;
            src_penable_r <= 0;
            src_pwrite_r <= 0;
            src_pready_r <= 0;
            src_prdata_r <= 0;
            src_pslverr_r <= 0;
        end else begin
            src_paddr_r <= src_paddr_i;
            src_pwdata_r <= src_pwdata_i;
            src_pstrb_r <= src_pstrb_i;
            src_pprot_r <= src_pprot_i;
            src_psel_r <= src_psel_i;
            src_penable_r <= src_penable_i;
            src_pwrite_r <= src_pwrite_i;
            src_pready_r <= dst_pready_i;
            src_prdata_r <= dst_prdata_i;
            src_pslverr_r <= dst_pslverr_i;
        end
    end

    // Asynchronous reset
    always @(posedge dst_pclk_i) begin
        if (~dst_preset_ni) begin
            dst_paddr_r <= 0;
            dst_pwdata_r <= 0;
            dst_pstrb_r <= 0;
            dst_pprot_r <= 0;
            dst_psel_r <= 0;
            dst_penable_r <= 0;
            dst_pwrite_r <= 0;
            dst_pready_r <= 0;
            dst_prdata_r <= 0;
            dst_pslverr_r <= 0;
        end else begin
            dst_paddr_r <= src_paddr_r;
            dst_pwdata_r <= src_pwdata_r;
            dst_pstrb_r <= src_pstrb_r;
            dst_pprot_r <= src_pprot_r;
            dst_psel_r <= src_psel_r;
            dst_penable_r <= src_penable_r;
            dst_pwrite_r <= src_pwrite_r;
            dst_pready_r <= src_pready_r;
            dst_prdata_r <= src_prdata_r;
            dst_pslverr_r <= src_pslverr_r;
        end
    end

    // Output assignments
    assign src_pready_o = dst_pready_i;
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;
    assign dst_psel_o = src_psel_r;
    assign dst_penable_o = src_penable_r;
    assign dst_pwrite_o = src_pwrite_r;
    assign dst_paddr_o = src_paddr_r;
    assign dst_pwdata_o = src_pwdata_r;
    assign dst_pstrb_o = src_pstrb_r;
    assign dst_pprot_o = src_pprot_r;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 data_in = 8'h10;
        #10 data_in = 8'h11;
        #10 data_in = 8'h12;
        #10 data_in = 8'h13;
        #10 data_in = 8'h14;
        #10 data_in = 8'h15;
        #10 data_in = 8'h16;
        #10 data_in = 8'h17;
        #10 data_in = 8'h18;
        #10 data_in = 8'h19;
        #10 data_in = 8'h1a;
        #10 data_in = 8'h1b;
        #10 data_in = 8'h1c;
        #10 data_in = 8'h1d;
        #10 data_in = 8'h1e;
        #10 data_in = 8'h1f;
        #10 data_in = 8'h20;
        #10 data_in = 8'h21;
        #10 data_in = 8'h22;
        #10 data_in = 8'h23;
        #10 data_in = 8'h24;
        #10 data_in = 8'h25;
        #10 data_in = 8'h26;
        #10 data_in = 8'h27;
        #10 data_in = 8'h28;
        #10 data_in = 8'h29;
        #10 data_in = 8'h2a;
        #10 data_in = 8'h2b;
        #10 data_in = 8'h2c;
        #10 data_in = 8'h2d;
        #10 data_in = 8'h2e;
        #10 data_in = 8'h2f;
        #10 data_in = 8'h30;
        #10 data_in = 8'h31;
        #10 data_in = 8'h32;
        #10 data_in = 8'h33;
        #10 data_in = 8'h34;
        #10 data_in = 8'h35;
        #10 data_in = 8'h36;
        #10 data_in = 8'h37;
        #10 data_in = 8'h38;
        #10 data_in = 8'h39;
        #10 data_in = 8'h3a;
        #10 data_in = 8'h3b;
        #10 data_in = 8'h3c;
        #10 data_in = 8'h3d;
        #10 data_in = 8'h3e;
        #10 data_in = 8'h3f;
        #10 data_in = 8'h40;
        #10 data_in = 8'h41;
        #10 data_in = 8'h42;
        #10 data_in = 8'h43;
        #10 data_in = 8'h44;
        #10 data_in = 8'h45;
        #10 data_in = 8'h46;
        #10 data_in = 8'h47;
        #10 data_in = 8'h48;
        #10 data_in = 8'h49;
        #10 data_in = 8'h4a;
        #10 data_in = 8'h4b;
        #10 data_in = 8'h4c;
        #10 data_in = 8'h4d;
        #10 data_in = 8'h4e;
        #10 data_in = 8'h4f;
        #10 data_in = 8'h50;
        #10 data_in = 8'h51;
        #10 data_in = 8'h52;
        #10 data_in = 8'h53;
        #10 data_in = 8'h54;
        #10 data_in = 8'h55;
        #10 data_in = 8'h56;
        #10 data_in = 8'h57;
        #10 data_in = 8'h58;
        #10 data_in = 8'h59;
        #10 data_in = 8'h5a;
        #10 data_in = 8'h5b;
        #10 data_in = 8'h5c;
        #10 data_in = 8'h5d;
        #10 data_in = 8'h5e;
        #10 data_in = 8'h5f;
        #10 data_in = 8'h60;
        #10 data_in = 8'h61;
        #10 data_in = 8'h62;
        #10 data_in = 8'h63;
        #10 data_in = 8'h64;
        #10 data_in = 8'h65;
        #10 data_in = 8'h66;
        #10 data_in = 8'h67;
        #10 data_in = 8'h68;
        #10 data_in = 8'h69;
        #10 data_in = 8'h6a;
        #10 data_in = 8'h6b;
        #10 data_in = 8'h6c;
        #10 data_in = 8'h6d;
        #10 data_in = 8'h6e;
        #10 data_in = 8'h6f;
        #10 data_in = 8'h70;
        #10 data_in = 8'h71;
        #10 data_in = 8'h72;
        #10 data_in = 8'h73;
        #10 data_in = 8'h74;
        #10 data_in = 8'h75;
        #10 data_in = 8'h76;
        #10 data_in = 8'h77;
        #10 data_in = 8'h78;
        #10 data_in = 8'h79;
        #10 data_in = 8'h7a;
        #10 data_in = 8'h7b;
        #10 data_in = 8'h7c;
        #10 data_in = 8'h7d;
        #10 data_in = 8'h7e;
        #10 data_in = 8'h7f;
        #10 data_in = 8'h80;
        #10 data_in = 8'h81;
        #10 data_in = 8'h82;
        #10 data_in = 8'h83;
        #10 data_in = 8'h84;
        #10 data_in = 8'h85;
        #10 data_in = 8'h86;
        #10 data_in = 8'h87;
        #10 data_in = 8'h88;
        #10 data_in = 8'h89;
        #10 data_in = 8'h8a;
        #10 data_in = 8'h8b;
        #10 data_in = 8'h8c;
        #10 data_in = 8'h8d;
        #10 data_in = 8'h8e;
        #10 data_in = 8'h8f;
        #10 data_in = 8'h90;
        #10 data_in = 8'h91;
        #10 data_in = 8'h92;
        #10 data_in = 8'h93;
        #10 data_in = 8'h94;
        #10 data_in = 8'h95;
        #10 data_in = 8'h96;
        #10 data_in = 8'h97;
        #10 data_in = 8'h98;
        #10 data_in = 8'h99;
        #10 data_in = 8'h9a;
        #10 data_in = 8'h9b;
        #10 data_in = 8'h9c;
        #10 data_in = 8'h9d;
        #10 data_in = 8'h9e;
        #10 data_in = 8'h9f;
        #10 data_in = 8'ha0;
        #10 data_in = 8'ha1;
        #10 data_in = 8'ha2;
        #10 data_in = 8'ha3;
        #10 data_in = 8'ha4;
        #10 data_in = 8'ha5;
        #10 data_in = 8'ha6;
        #10 data_in = 8'ha7;
        #10 data_in = 8'ha8;
        #10 data_in = 8'ha9;
        #10 data_in = 8'haa;
        #10 data_in = 8'hab;
        #10 data_in = 8'hac;
        #10 data_in = 8'had;
        #10 data_in = 8'hae;
        #10 data_in = 8'haf;
        #10 data_in = 8'hb0;
        #10 data_in = 8'hb1;
        #10 data_in = 8'hb2;
        #10 data_in = 8'hb3;
        #10 data_in = 8'hb4;
        #10 data_in = 8'hb5;
        #10 data_in = 8'hb6;
        #10 data_in = 8'hb7;
        #10 data_in = 8'hb8;
        #10 data_in = 8'hb9;
        #10 data_in = 8'hba;
        #10 data_in = 8'hbb;
        #10 data_in = 8'hbc;
        #10 data_in = 8'hbd;
        #10 data_in = 8'hbe;
        #10 data_in = 8'hbf;
        #10 data_in = 8'hc0;
        #10 data_in = 8'hc1;
        #10 data_in = 8'hc2;
        #10 data_in = 8'hc3;
        #10 data_in = 8'hc4;
        #10 data_in = 8'hc5;
        #10 data_in = 8'hc6;
        #10 data_in = 8'hc7;
        #10 data_in = 8'hc8;
        #10 data_in = 8'hc9;
        #10 data_in = 8'hca;
        #10 data_in = 8'hcb;
        #10 data_in = 8'hcc;
        #10 data_in = 8'hcd;
        #10 data_in = 8'hce;
        #10 data_in = 8'hcf;
        #10 data_in = 8'hd0;
        #10 data_in = 8'hd1;
        #10 data_in = 8'hd2;
        #10 data_in = 8'hd3;
        #10 data_in = 8'hd4;
        #10 data_in = 8'hd5;
        #10 data_in = 8'hd6;
        #10 data_in = 8'hd7;
        #10 data_in = 8'hd8;
        #10 data_in = 8'hd9;
        #10 data_in = 8'hda;
        #10 data_in = 8'hdb;
        #10 data_in = 8'hdc;
        #10 data_in = 8'hdd;
        #10 data_in = 8'hde;
        #10 data_in = 8'hdf;
        #10 data_in = 8'he0;
        #10 data_in = 8'he1;
        #10 data_in = 8'he2;
        #10 data_in = 8'he3;
        #10 data_in = 8'he4;
        #10 data_in = 8'he5;
        #10 data_in = 8'he6;
        #10 data_in = 8'he7;
        #10 data_in = 8'he8;
        #10 data_in = 8'he9;
        #10 data_in = 8'hea;
        #10 data_in = 8'heb;
        #10 data_in = 8'hec;
        #10 data_in = 8'hed;
        #10 data_in = 8'hee;
        #10 data_in = 8'hef;
        #10 data_in = 8'hf0;
        #10 data_in = 8'hf1;
        #10 data_in = 8'hf2;
        #10 data_in = 8'hf3;
        #10 data_in = 8'hf4;
        #10 data_in = 8'hf5;
        #10 data_in = 8'hf6;
        #10 data_in = 8'hf7;
        #10 data_in = 8'hf8;
        #10 data_in = 8'hf9;
        #10 data_in = 8'hfa;
        #10 data_in = 8'hfb;
        #10 data_in = 8'hfc;
        #10 data_in = 8'hfd;
        #10 data_in = 8'hfe;
        #10 data_in = 8'hff;
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'h00;
            data_out <= 8'h00;
        end else begin
            shift_reg <= {shift_reg[6:0], data_in};
            data_out <= shift_reg[7];
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    dut dut_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 data_in = 8'h10;
        #10 data_in = 8'h11;
        #10 data_in = 8'h12;
        #10 data_in = 8'h13;
        #10 data_in = 8'h14;
        #10 data_in = 8'h15;
        #10 data_in = 8'h16;
        #10 data_in = 8'h17;
        #10 data_in = 8'h18;
        #10 data_in = 8'h19;
        #10 data_in = 8'h1a;
        #10 data_in = 8'h1b;
        #10 data_in = 8'h1c;
        #10 data_in = 8'h1d;
        #10 data_in = 8'h1e;
        #10 data_in = 8'h1f;
        #10 data_in = 8'h20;
        #10 data_in = 8'h21;
        #10 data_in = 8'h22;
        #10 data_in = 8'h23;
        #10 data_in = 8'h24;
        #10 data_in = 8'h25;
        #10 data_in = 8'h26;
        #10 data_in = 8'h27;
        #10 data_in = 8'h28;
        #10 data_in = 8'h29;
        #10 data_in = 8'h2a;
        #10 data_in = 8'h2b;
        #10 data_in = 8'h2c;
        #10 data_in = 8'h2d;
        #10 data_in = 8'h2e;
        #10 data_in = 8'h2f;
        #10 data_in = 8'h30;
        #10 data_in = 8'h31;
        #10 data_in = 8'h32;
        #10 data_in = 8'h33;
        #10 data_in = 8'h34;
        #10 data_in = 8'h35;
        #10 data_in = 8'h36;
        #10 data_in = 8'h37;
        #10 data_in = 8'h38;
        #10 data_in = 8'h39;
        #10 data_in = 8'h3a;
        #10 data_in = 8'h3b;
        #10 data_in = 8'h3c;
        #10 data_in = 8'h3d;
        #10 data_in = 8'h3e;
        #10 data_in = 8'h3f;
        #10 data_in = 8'h40;
        #10 data_in = 8'h41;
        #10 data_in = 8'h42;
        #10 data_in = 8'h43;
        #10 data_in = 8'h44;
        #10 data_in = 8'h45;
        #10 data_in = 8'h46;
        #10 data_in = 8'h47;
        #10 data_in = 8'h48;
        #10 data_in = 8'h49;
        #10 data_in = 8'h4a;
        #10 data_in = 8'h4b;
        #10 data_in = 8'h4c;
        #10 data_in = 8'h4d;
        #10 data_in = 8'h4e;
        #10 data_in = 8'h4f;
        #10 data_in = 8'h50;
        #10 data_in = 8'h51;
        #10 data_in = 8'h52;
        #10 data_in = 8'h53;
        #10 data_in = 8'h54;
        #10 data_in = 8'h55;
        #10 data_in = 8'h56;
        #10 data_in = 8'h57;
        #10 data_in = 8'h58;
        #10 data_in = 8'h59;
        #10 data_in = 8'h5a;
        #10 data_in = 8'h5b;
        #10 data_in = 8'h5c;
        #10 data_in = 8'h5d;
        #10 data_in = 8'h5e;
        #10 data_in = 8'h5f;
        #10 data_in = 8'h60;
        #10 data_in = 8'h61;
        #10 data_in = 8'h62;
        #10 data_in = 8'h63;
        #10 data_in = 8'h64;
        #10 data_in = 8'h65;
        #10 data_in = 8'h66;
        #10 data_in = 8'h67;
        #10 data_in = 8'h68;
        #10 data_in = 8'h69;
        #10 data_in = 8'h6a;
        #10 data_in = 8'h6b;
        #10 data_in = 8'h6c;
        #10 data_in = 8'h6d;
        #10 data_in = 8'h6e;
        #10 data_in = 8'h6f;
        #10 data_in = 8'h70;
        #10 data_in = 8'h71;
        #10 data_in = 8'h72;
        #10 data_in = 8'h73;
        #10 data_in = 8'h74;
        #10 data_in = 8'h75;
        #10 data_in = 8'h76;
        #10 data_in = 8'h77;
        #10 data_in = 8'h78;
        #10 data_in = 8'h79;
        #10 data_in = 8'h7a;
        #10 data_in = 8'h7b;
        #10 data_in = 8'h7c;
        #10 data_in = 8'h7d;
        #10 data_in = 8'h7e;
        #10 data_in = 8'h7f;
        #10 data_in = 8'h80;
        #10 data_in = 8'h81;
        #10 data_in = 8'h82;
        #10 data_in = 8'h83;
        #10 data_in = 8'h84;
        #10 data_in = 8'h85;
        #10 data_in = 8'h86;
        #10 data_in = 8'h87;
        #10 data_in = 8'h88;
        #10 data_in = 8'h89;
        #10 data_in = 8'h8a;
        #10 data_in = 8'h8b;
        #10 data_in = 8'h8c;
        #10 data_in = 8'h8d;
        #10 data_in = 8'h8e;
        #10 data_in = 8'h8f;
        #10 data_in = 8'h90;
        #10 data_in = 8'h91;
        #10 data_in = 8'h92;
        #10 data_in = 8'h93;
        #10 data_in = 8'h94;
        #10 data_in = 8'h95;
        #10 data_in = 8'h96