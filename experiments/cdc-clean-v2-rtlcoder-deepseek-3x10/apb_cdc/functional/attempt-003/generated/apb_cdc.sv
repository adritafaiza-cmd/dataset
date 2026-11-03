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

    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg src_pslverr_reg;
    reg src_pready_reg;
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
    reg [1:0] state;

    always @(posedge src_pclk_i) begin
        if (!src_preset_ni) begin
            src_prdata_reg <= 0;
            src_pslverr_reg <= 0;
            src_pready_reg <= 0;
            state <= 0;
        end else begin
            case (state)
                0: begin
                    if (src_psel_i && src_penable_i) begin
                        dst_psel_reg <= src_psel_i;
                        dst_penable_reg <= src_penable_i;
                        dst_pwrite_reg <= src_pwrite_i;
                        dst_paddr_reg <= src_paddr_i;
                        dst_pwdata_reg <= src_pwdata_i;
                        dst_pstrb_reg <= src_pstrb_i;
                        dst_pprot_reg <= src_pprot_i;
                        state <= 1;
                    end
                end
                1: begin
                    if (dst_pready_i) begin
                        src_prdata_reg <= dst_prdata_i;
                        src_pslverr_reg <= dst_pslverr_i;
                        src_pready_reg <= 1;
                        state <= 0;
                    end
                end
            endcase
        end
    end

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
    assign dst_pready_reg = dst_pready_i;
    assign dst_prdata_reg = dst_prdata_i;
    assign dst_pslverr_reg = dst_pslverr_i;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the Unit Under Test (UUT)
    top_module uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        data_in = 8'b00000000;

        // Wait 100 ns for global reset to finish
        #100 reset = 0;

        // Add stimulus here
        #10 data_in = 8'b11111111;
        #10 data_in = 8'b00000000;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #10 data_in = 8'b01010101;
        #10 data_in = 8'b11001100;
        #10 data_in = 8'b00110011;
        #10 data_in = 8'b11110000;
        #10 data_in = 8'b00001111;
        #10 data_in = 8'b10101010;
        #