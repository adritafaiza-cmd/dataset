Sure, here is the complete Verilog code for the SPI master module:

```
module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    // Internal registers
    reg [N-1:0] tx_data;
    reg [N-1:0] rx_data;
    reg [1:0] state;
    reg [1:0] next_state;
    reg [1:0] sclk_div;
    reg [1:0] pclk_div;
    reg [1:0] sclk_div_next;
    reg [1:0] pclk_div_next;

    // Constants
    localparam IDLE = 2'b00;
    localparam TX = 2'b01;
    localparam RX = 2'b10;

    // State machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            sclk_div <= 2'b00;
            pclk_div <= 2'b00;
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
        end else begin
            state <= next_state;
            sclk_div <= sclk_div_next;
            pclk_div <= pclk_div_next;
            case (state)
                IDLE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    do_o <= {N{1'b0}};
                    if (wren_i) begin
                        tx_data <= di_i;
                        next_state <= TX;
                        sclk_div_next <= 2'b00;
                        pclk_div_next <= 2'b00;
                    end else begin
                        next_state <= IDLE;
                        sclk_div_next <= sclk_div;
                        pclk_div_next <= pclk_div;
                    end
                end
                TX: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= sclk_div[SPI_2X_CLK_DIV-1];
                    spi_mosi_o <= tx_data[N-1];
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    do_o <= {N{1'b0}};
                    if (sclk_div == SPI_2X_CLK_DIV-1) begin
                        tx_data <= {tx_data[N-2:0], 1'b0};
                        sclk_div_next <= 2'b00;
                        pclk_div_next <= pclk_div + 1;
                    end else begin
                        sclk_div_next <= sclk_div + 1;
                        pclk_div_next <= pclk_div;
                    end
                    if (pclk_div == SPI_2X_CLK_DIV-1) begin
                        next_state <= RX;
                        sclk_div_next <= 2'b00;
                        pclk_div_next <= 2'b00;
                    end else begin
                        next_state <= TX;
                        sclk_div_next <= sclk_div_next;
                        pclk_div_next <= pclk_div_next;
                    end
                end
                RX: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= sclk_div[SPI_2X_CLK_DIV-1];
                    spi_mosi_o <= 1'b0;
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    do_o <= {N{1'b0}};
                    if (sclk_div == SPI_2X_CLK_DIV-1) begin
                        rx_data <= {rx_data[N-2:0], spi_miso_i};
                        sclk_div_next <= 2'b00;
                        pclk_div_next <= pclk_div + 1;
                    end else begin
                        sclk_div_next <= sclk_div + 1;
                        pclk_div_next <= pclk_div;
                    end
                    if (pclk_div == SPI_2X_CLK_DIV-1) begin
                        next_state <= IDLE;
                        sclk_div_next <= 2'b00;
                        pclk_div_next <= 2'b00;
                        do_valid_o <= 1'b1;
                        do_o <= rx_data;
                        wr_ack_o <= 1'b1;
                        di_req_o <= 1'b1;
                    end else begin
                        next_state <= RX;
                        sclk_div_next <= sclk_div_next;
                        pclk_div_next <= pclk_div_next;
                    end
                end
            endcase
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule

module top_module_tb_2();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule

module top_module_tb_2();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb_3();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule

module top_module_tb_2();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb_3();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule

module top_module_tb_4();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 $finish;
end

endmodule

module top_module_tb_5();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb_6();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule

module top_module_tb_7();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 $finish;
end

endmodule

module top_module_tb_8();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb_9();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule

module top_module_tb_10();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 $finish;
end

endmodule

module top_module_tb_11();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb_12();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule

module top_module_tb_13();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 $finish;
end

endmodule

module top_module_tb_14();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

endmodule

module top_module_tb_15();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule

module top_module_tb_16();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 data_in = 8'b11111111;
    #10 data_in = 8'b00000000;
    #10 $finish;
end

endmodule

module top_module_tb_17();

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #1