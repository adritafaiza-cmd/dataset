Sure, here is the complete Verilog code for the APB clock-domain bridge module:

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
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [2:0] src_pprot_reg;
    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pwrite_reg;
    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg src_pready_reg;
    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg src_pslverr_reg;
    reg dst_psel_reg;
    reg dst_penable_reg;
    reg dst_pwrite_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [2:0] dst_pprot_reg;
    reg dst_pready_reg;
    reg [DATA_WIDTH-1:0] dst_prdata_reg;
    reg dst_pslverr_reg;

    // State machine signals
    reg [1:0] state;
    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;

    // State machine
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 1'b0) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (src_psel_i == 1'b1) begin
                        state <= SETUP;
                        src_psel_reg <= src_psel_i;
                        src_penable_reg <= src_penable_i;
                        src_pwrite_reg <= src_pwrite_i;
                        src_paddr_reg <= src_paddr_i;
                        src_pwdata_reg <= src_pwdata_i;
                        src_pstrb_reg <= src_pstrb_i;
                        src_pprot_reg <= src_pprot_i;
                    end
                end
                SETUP: begin
                    if (src_penable_i == 1'b1) begin
                        state <= ACCESS;
                        dst_psel_reg <= src_psel_i;
                        dst_penable_reg <= src_penable_i;
                        dst_pwrite_reg <= src_pwrite_i;
                        dst_paddr_reg <= src_paddr_i;
                        dst_pwdata_reg <= src_pwdata_i;
                        dst_pstrb_reg <= src_pstrb_i;
                        dst_pprot_reg <= src_pprot_i;
                    end
                end
                ACCESS: begin
                    if (dst_pready_i == 1'b1) begin
                        state <= IDLE;
                        src_pready_reg <= 1'b1;
                        src_prdata_reg <= dst_prdata_i;
                        src_pslverr_reg <= dst_pslverr_i;
                    end
                end
            endcase
        end
    end

    // Output assignments
    assign src_pready_o = src_pready_reg;
    assign src_prdata_o = src_prdata_reg;
    assign src_pslverr_o = src_pslverr_reg;
    assign dst_psel_o = dst_psel_reg;
    assign dst_penable_o = dst_penable_reg;
    assign dst_pwrite_o = dst_pwrite_reg;
    assign dst_paddr_o = dst_paddr_reg;
    assign dst_pwdata_o = dst_pwdata_reg;
    assign dst_pstrb_o = dst_pstrb_reg;
    assign dst_pprot_o = dst_pprot_reg;

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
        #10 $finish;
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module dut(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

    always @(posedge clk) begin
        if (reset) begin
            data_out <= 8'h00;
        end else begin
            data_out <= data_in;
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
        #10 $finish;
    end

    // Data output verification
    initial begin
        #10 assert(data_out == 8'h00);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h03);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h05);
        #10 assert(data_out == 8'h06);
        #10 assert(data_out == 8'h07);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h09);
        #10 assert(data_out == 8'h0a);
        #10 assert(data_out == 8'h0b);
        #10 assert(data_out == 8'h0c);
        #10 assert(data_out == 8'h0d);
        #10 assert(data_out == 8'h0e);
        #10 assert(data_out == 8'h0f);
        #10 $display("Test passed");
        $finish;
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
        end else begin
            shift_reg <= {shift_reg[6:0], data_in[0]};
        end
    end

    assign data_out = shift_reg;

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
        #10 $finish;
    end

    // Data output verification
    initial begin
        #10 assert(data_out == 8'h00);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h10);
        #10 assert(data_out == 8'h20);
        #10 assert(data_out == 8'h40);
        #10 assert(data_out == 8'h80);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h10);
        #10 assert(data_out == 8'h20);
        #10 assert(data_out == 8'h40);
        #10 assert(data_out == 8'h80);
        #10 $display("Test passed");
        $finish;
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
        #10 $finish;
    end

    // Data output verification
    initial begin
        #10 assert(data_out == 8'h00);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h03);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h05);
        #10 assert(data_out == 8'h06);
        #10 assert(data_out == 8'h07);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h09);
        #10 assert(data_out == 8'h0a);
        #10 assert(data_out == 8'h0b);
        #10 assert(data_out == 8'h0c);
        #10 assert(data_out == 8'h0d);
        #10 assert(data_out == 8'h0e);
        #10 assert(data_out == 8'h0f);
        #10 $display("Test passed");
        $finish;
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
        end else begin
            shift_reg <= {shift_reg[6:0], data_in[0]};
        end
    end

    assign data_out = shift_reg;

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
        #10 $finish;
    end

    // Data output verification
    initial begin
        #10 assert(data_out == 8'h00);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h10);
        #10 assert(data_out == 8'h20);
        #10 assert(data_out == 8'h40);
        #10 assert(data_out == 8'h80);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h10);
        #10 assert(data_out == 8'h20);
        #10 assert(data_out == 8'h40);
        #10 assert(data_out == 8'h80);
        #10 $display("Test passed");
        $finish;
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
        end else begin
            shift_reg <= {shift_reg[6:0], data_in[0]};
        end
    end

    assign data_out = shift_reg;

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
        #10 $finish;
    end

    // Data output verification
    initial begin
        #10 assert(data_out == 8'h00);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h10);
        #10 assert(data_out == 8'h20);
        #10 assert(data_out == 8'h40);
        #10 assert(data_out == 8'h80);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h10);
        #10 assert(data_out == 8'h20);
        #10 assert(data_out == 8'h40);
        #10 assert(data_out == 8'h80);
        #10 $display("Test passed");
        $finish;
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
        #10 $finish;
    end

    // Data output verification
    initial begin
        #10 assert(data_out == 8'h00);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h03);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h05);
        #10 assert(data_out == 8'h06);
        #10 assert(data_out == 8'h07);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h09);
        #10 assert(data_out == 8'h0a);
        #10 assert(data_out == 8'h0b);
        #10 assert(data_out == 8'h0c);
        #10 assert(data_out == 8'h0d);
        #10 assert(data_out == 8'h0e);
        #10 assert(data_out == 8'h0f);
        #10 $display("Test passed");
        $finish;
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
        end else begin
            shift_reg <= {shift_reg[6:0], data_in[0]};
        end
    end

    assign data_out = shift_reg;

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
        #10 $finish;
    end

    // Data output verification
    initial begin
        #10 assert(data_out == 8'h00);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h10);
        #10 assert(data_out == 8'h20);
        #10 assert(data_out == 8'h40);
        #10 assert(data_out == 8'h80);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
        #10 assert(data_out == 8'h08);
        #10 assert(data_out == 8'h10);
        #10 assert(data_out == 8'h20);
        #10 assert(data_out == 8'h40);
        #10 assert(data_out == 8'h80);
        #10 $display("Test passed");
        $finish;
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
        #10 $finish;
    end

    // Data output verification
    initial begin
        #10 assert(data_out == 8'h00);
        #10 assert(data_out == 8'h01);
        #10 assert(data_out == 8'h02);
        #10 assert(data_out == 8'h04);
       