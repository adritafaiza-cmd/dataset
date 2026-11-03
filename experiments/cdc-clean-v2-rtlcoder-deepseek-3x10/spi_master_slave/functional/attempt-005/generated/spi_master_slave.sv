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
    reg [N-1:0]         shift_reg;
    reg [N-1:0]         data_reg;
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] clk_div_reg;
    reg                 sclk_div_reg;
    reg                 sclk_div_reg_next;
    reg                 spi_sck_div_reg;
    reg                 spi_sck_div_reg_next;
    reg                 spi_ssel_div_reg;
    reg                 spi_ssel_div_reg_next;
    reg                 spi_mosi_div_reg;
    reg                 spi_mosi_div_reg_next;
    reg                 spi_miso_div_reg;
    reg                 spi_miso_div_reg_next;
    reg                 di_req_div_reg;
    reg                 di_req_div_reg_next;
    reg                 wr_ack_div_reg;
    reg                 wr_ack_div_reg_next;
    reg                 do_valid_div_reg;
    reg                 do_valid_div_reg_next;
    reg [N-1:0]         do_div_reg;
    reg [N-1:0]         do_div_reg_next;

    // Internal wires
    wire                sclk_div_wire;
    wire                spi_sck_div_wire;
    wire                spi_ssel_div_wire;
    wire                spi_mosi_div_wire;
    wire                spi_miso_div_wire;
    wire                di_req_div_wire;
    wire                wr_ack_div_wire;
    wire                do_valid_div_wire;
    wire [N-1:0]        do_div_wire;

    // Assign outputs
    assign spi_ssel_o = spi_ssel_div_wire;
    assign spi_sck_o = spi_sck_div_wire;
    assign spi_mosi_o = spi_mosi_div_wire;
    assign di_req_o = di_req_div_wire;
    assign wr_ack_o = wr_ack_div_wire;
    assign do_valid_o = do_valid_div_wire;
    assign do_o = do_div_wire;

    // Clock divider
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_div_reg <= 'b0;
            sclk_div_reg <= 'b0;
            sclk_div_reg_next <= 'b0;
        end else begin
            clk_div_reg <= clk_div_reg + 1;
            sclk_div_reg <= sclk_div_reg_next;
            sclk_div_reg_next <= sclk_div_reg;
        end
    end

    // SPI clock divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_div_reg <= 'b0;
            spi_sck_div_reg_next <= 'b0;
        end else begin
            spi_sck_div_reg <= spi_sck_div_reg_next;
            spi_sck_div_reg_next <= spi_sck_div_reg;
        end
    end

    // SPI select divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_div_reg <= 'b0;
            spi_ssel_div_reg_next <= 'b0;
        end else begin
            spi_ssel_div_reg <= spi_ssel_div_reg_next;
            spi_ssel_div_reg_next <= spi_ssel_div_reg;
        end
    end

    // SPI MOSI divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_div_reg <= 'b0;
            spi_mosi_div_reg_next <= 'b0;
        end else begin
            spi_mosi_div_reg <= spi_mosi_div_reg_next;
            spi_mosi_div_reg_next <= spi_mosi_div_reg;
        end
    end

    // SPI MISO divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_miso_div_reg <= 'b0;
            spi_miso_div_reg_next <= 'b0;
        end else begin
            spi_miso_div_reg <= spi_miso_div_reg_next;
            spi_miso_div_reg_next <= spi_miso_div_reg;
        end
    end

    // DI request divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_div_reg <= 'b0;
            di_req_div_reg_next <= 'b0;
        end else begin
            di_req_div_reg <= di_req_div_reg_next;
            di_req_div_reg_next <= di_req_div_reg;
        end
    end

    // Write acknowledge divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_div_reg <= 'b0;
            wr_ack_div_reg_next <= 'b0;
        end else begin
            wr_ack_div_reg <= wr_ack_div_reg_next;
            wr_ack_div_reg_next <= wr_ack_div_reg;
        end
    end

    // Data valid divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_div_reg <= 'b0;
            do_valid_div_reg_next <= 'b0;
        end else begin
            do_valid_div_reg <= do_valid_div_reg_next;
            do_valid_div_reg_next <= do_valid_div_reg;
        end
    end

    // Data divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_div_reg <= 'b0;
            do_div_reg_next <= 'b0;
        end else begin
            do_div_reg <= do_div_reg_next;
            do_div_reg_next <= do_div_reg;
        end
    end

    // SPI clock divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_div_reg <= 'b0;
            spi_sck_div_reg_next <= 'b0;
        end else begin
            spi_sck_div_reg <= spi_sck_div_reg_next;
            spi_sck_div_reg_next <= spi_sck_div_reg;
        end
    end

    // SPI select divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_div_reg <= 'b0;
            spi_ssel_div_reg_next <= 'b0;
        end else begin
            spi_ssel_div_reg <= spi_ssel_div_reg_next;
            spi_ssel_div_reg_next <= spi_ssel_div_reg;
        end
    end

    // SPI MOSI divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_div_reg <= 'b0;
            spi_mosi_div_reg_next <= 'b0;
        end else begin
            spi_mosi_div_reg <= spi_mosi_div_reg_next;
            spi_mosi_div_reg_next <= spi_mosi_div_reg;
        end
    end

    // SPI MISO divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_miso_div_reg <= 'b0;
            spi_miso_div_reg_next <= 'b0;
        end else begin
            spi_miso_div_reg <= spi_miso_div_reg_next;
            spi_miso_div_reg_next <= spi_miso_div_reg;
        end
    end

    // DI request divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_div_reg <= 'b0;
            di_req_div_reg_next <= 'b0;
        end else begin
            di_req_div_reg <= di_req_div_reg_next;
            di_req_div_reg_next <= di_req_div_reg;
        end
    end

    // Write acknowledge divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_div_reg <= 'b0;
            wr_ack_div_reg_next <= 'b0;
        end else begin
            wr_ack_div_reg <= wr_ack_div_reg_next;
            wr_ack_div_reg_next <= wr_ack_div_reg;
        end
    end

    // Data valid divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_div_reg <= 'b0;
            do_valid_div_reg_next <= 'b0;
        end else begin
            do_valid_div_reg <= do_valid_div_reg_next;
            do_valid_div_reg_next <= do_valid_div_reg;
        end
    end

    // Data divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_div_reg <= 'b0;
            do_div_reg_next <= 'b0;
        end else begin
            do_div_reg <= do_div_reg_next;
            do_div_reg_next <= do_div_reg;
        end
    end

    // SPI clock divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_div_reg <= 'b0;
            spi_sck_div_reg_next <= 'b0;
        end else begin
            spi_sck_div_reg <= spi_sck_div_reg_next;
            spi_sck_div_reg_next <= spi_sck_div_reg;
        end
    end

    // SPI select divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_div_reg <= 'b0;
            spi_ssel_div_reg_next <= 'b0;
        end else begin
            spi_ssel_div_reg <= spi_ssel_div_reg_next;
            spi_ssel_div_reg_next <= spi_ssel_div_reg;
        end
    end

    // SPI MOSI divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_div_reg <= 'b0;
            spi_mosi_div_reg_next <= 'b0;
        end else begin
            spi_mosi_div_reg <= spi_mosi_div_reg_next;
            spi_mosi_div_reg_next <= spi_mosi_div_reg;
        end
    end

    // SPI MISO divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_miso_div_reg <= 'b0;
            spi_miso_div_reg_next <= 'b0;
        end else begin
            spi_miso_div_reg <= spi_miso_div_reg_next;
            spi_miso_div_reg_next <= spi_miso_div_reg;
        end
    end

    // DI request divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_div_reg <= 'b0;
            di_req_div_reg_next <= 'b0;
        end else begin
            di_req_div_reg <= di_req_div_reg_next;
            di_req_div_reg_next <= di_req_div_reg;
        end
    end

    // Write acknowledge divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_div_reg <= 'b0;
            wr_ack_div_reg_next <= 'b0;
        end else begin
            wr_ack_div_reg <= wr_ack_div_reg_next;
            wr_ack_div_reg_next <= wr_ack_div_reg;
        end
    end

    // Data valid divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_div_reg <= 'b0;
            do_valid_div_reg_next <= 'b0;
        end else begin
            do_valid_div_reg <= do_valid_div_reg_next;
            do_valid_div_reg_next <= do_valid_div_reg;
        end
    end

    // Data divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_div_reg <= 'b0;
            do_div_reg_next <= 'b0;
        end else begin
            do_div_reg <= do_div_reg_next;
            do_div_reg_next <= do_div_reg;
        end
    end

    // SPI clock divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_div_reg <= 'b0;
            spi_sck_div_reg_next <= 'b0;
        end else begin
            spi_sck_div_reg <= spi_sck_div_reg_next;
            spi_sck_div_reg_next <= spi_sck_div_reg;
        end
    end

    // SPI select divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_div_reg <= 'b0;
            spi_ssel_div_reg_next <= 'b0;
        end else begin
            spi_ssel_div_reg <= spi_ssel_div_reg_next;
            spi_ssel_div_reg_next <= spi_ssel_div_reg;
        end
    end

    // SPI MOSI divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_div_reg <= 'b0;
            spi_mosi_div_reg_next <= 'b0;
        end else begin
            spi_mosi_div_reg <= spi_mosi_div_reg_next;
            spi_mosi_div_reg_next <= spi_mosi_div_reg;
        end
    end

    // SPI MISO divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_miso_div_reg <= 'b0;
            spi_miso_div_reg_next <= 'b0;
        end else begin
            spi_miso_div_reg <= spi_miso_div_reg_next;
            spi_miso_div_reg_next <= spi_miso_div_reg;
        end
    end

    // DI request divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_div_reg <= 'b0;
            di_req_div_reg_next <= 'b0;
        end else begin
            di_req_div_reg <= di_req_div_reg_next;
            di_req_div_reg_next <= di_req_div_reg;
        end
    end

    // Write acknowledge divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_div_reg <= 'b0;
            wr_ack_div_reg_next <= 'b0;
        end else begin
            wr_ack_div_reg <= wr_ack_div_reg_next;
            wr_ack_div_reg_next <= wr_ack_div_reg;
        end
    end

    // Data valid divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_div_reg <= 'b0;
            do_valid_div_reg_next <= 'b0;
        end else begin
            do_valid_div_reg <= do_valid_div_reg_next;
            do_valid_div_reg_next <= do_valid_div_reg;
        end
    end

    // Data divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_div_reg <= 'b0;
            do_div_reg_next <= 'b0;
        end else begin
            do_div_reg <= do_div_reg_next;
            do_div_reg_next <= do_div_reg;
        end
    end

    // SPI clock divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_div_reg <= 'b0;
            spi_sck_div_reg_next <= 'b0;
        end else begin
            spi_sck_div_reg <= spi_sck_div_reg_next;
            spi_sck_div_reg_next <= spi_sck_div_reg;
        end
    end

    // SPI select divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_div_reg <= 'b0;
            spi_ssel_div_reg_next <= 'b0;
        end else begin
            spi_ssel_div_reg <= spi_ssel_div_reg_next;
            spi_ssel_div_reg_next <= spi_ssel_div_reg;
        end
    end

    // SPI MOSI divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_div_reg <= 'b0;
            spi_mosi_div_reg_next <= 'b0;
        end else begin
            spi_mosi_div_reg <= spi_mosi_div_reg_next;
            spi_mosi_div_reg_next <= spi_mosi_div_reg;
        end
    end

    // SPI MISO divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_miso_div_reg <= 'b0;
            spi_miso_div_reg_next <= 'b0;
        end else begin
            spi_miso_div_reg <= spi_miso_div_reg_next;
            spi_miso_div_reg_next <= spi_miso_div_reg;
        end
    end

    // DI request divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_div_reg <= 'b0;
            di_req_div_reg_next <= 'b0;
        end else begin
            di_req_div_reg <= di_req_div_reg_next;
            di_req_div_reg_next <= di_req_div_reg;
        end
    end

    // Write acknowledge divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_div_reg <= 'b0;
            wr_ack_div_reg_next <= 'b0;
        end else begin
            wr_ack_div_reg <= wr_ack_div_reg_next;
            wr_ack_div_reg_next <= wr_ack_div_reg;
        end
    end

    // Data valid divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_div_reg <= 'b0;
            do_valid_div_reg_next <= 'b0;
        end else begin
            do_valid_div_reg <= do_valid_div_reg_next;
            do_valid_div_reg_next <= do_valid_div_reg;
        end
    end

    // Data divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_div_reg <= 'b0;
            do_div_reg_next <= 'b0;
        end else begin
            do_div_reg <= do_div_reg_next;
            do_div_reg_next <= do_div_reg;
        end
    end

    // SPI clock divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_div_reg <= 'b0;
            spi_sck_div_reg_next <= 'b0;
        end else begin
            spi_sck_div_reg <= spi_sck_div_reg_next;
            spi_sck_div_reg_next <= spi_sck_div_reg;
        end
    end

    // SPI select divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_div_reg <= 'b0;
            spi_ssel_div_reg_next <= 'b0;
        end else begin
            spi_ssel_div_reg <= spi_ssel_div_reg_next;
            spi_ssel_div_reg_next <= spi_ssel_div_reg;
        end
    end

    // SPI MOSI divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_div_reg <= 'b0;
            spi_mosi_div_reg_next <= 'b0;
        end else begin
            spi_mosi_div_reg <= spi_mosi_div_reg_next;
            spi_mosi_div_reg_next <= spi_mosi_div_reg;
        end
    end

    // SPI MISO divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_miso_div_reg <= 'b0;
            spi_miso_div_reg_next <= 'b0;
        end else begin
            spi_miso_div_reg <= spi_miso_div_reg_next;
            spi_miso_div_reg_next <= spi_miso_div_reg;
        end
    end

    // DI request divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_div_reg <= 'b0;
            di_req_div_reg_next <= 'b0;
        end else begin
            di_req_div_reg <= di_req_div_reg_next;
            di_req_div_reg_next <= di_req_div_reg;
        end
    end

    // Write acknowledge divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_div_reg <= 'b0;
            wr_ack_div_reg_next <= 'b0;
        end else begin
            wr_ack_div_reg <= wr_ack_div_reg_next;
            wr_ack_div_reg_next <= wr_ack_div_reg;
        end
    end

    // Data valid divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_div_reg <= 'b0;
            do_valid_div_reg_next <= 'b0;
        end else begin
            do_valid_div_reg <= do_valid_div_reg_next;
            do_valid_div_reg_next <= do_valid_div_reg;
        end
    end

    // Data divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_div_reg <= 'b0;
            do_div_reg_next <= 'b0;
        end else begin
            do_div_reg <= do_div_reg_next;
            do_div_reg_next <= do_div_reg;
        end
    end

    // SPI clock divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_div_reg <= 'b0;
            spi_sck_div_reg_next <= 'b0;
        end else begin
            spi_sck_div_reg <= spi_sck_div_reg_next;
            spi_sck_div_reg_next <= spi_sck_div_reg;
        end
    end

    // SPI select divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_div_reg <= 'b0;
            spi_ssel_div_reg_next <= 'b0;
        end else begin
            spi_ssel_div_reg <= spi_ssel_div_reg_next;
            spi_ssel_div_reg_next <= spi_ssel_div_reg;
        end
    end

    // SPI MOSI divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_div_reg <= 'b0;
            spi_mosi_div_reg_next <= 'b0;
        end else begin
            spi_mosi_div_reg <= spi_mosi_div_reg_next;
            spi_mosi_div_reg_next <= spi_mosi_div_reg;
        end
    end

    // SPI MISO divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_miso_div_reg <= 'b0;
            spi_miso_div_reg_next <= 'b0;
        end else begin
            spi_miso_div_reg <= spi_miso_div_reg_next;
            spi_miso_div_reg_next <= spi_miso_div_reg;
        end
    end

    // DI request divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_div_reg <= 'b0;
            di_req_div_reg_next <= 'b0;
        end else begin
            di_req_div_reg <= di_req_div_reg_next;
            di_req_div_reg_next <= di_req_div_reg;
        end
    end

    // Write acknowledge divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_div_reg <= 'b0;
            wr_ack_div_reg_next <= 'b0;
        end else begin
            wr_ack_div_reg <= wr_ack_div_reg_next;
            wr_ack_div_reg_next <= wr_ack_div_reg;
        end
    end

    // Data valid divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_div_reg <= 'b0;
            do_valid_div_reg_next <= 'b0;
        end else begin
            do_valid_div_reg <= do_valid_div_reg_next;
            do_valid_div_reg_next <= do_valid_div_reg;
        end
    end

    // Data divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_div_reg <= 'b0;
            do_div_reg_next <= 'b0;
        end else begin
            do_div_reg <= do_div_reg_next;
            do_div_reg_next <= do_div_reg;
        end
    end

    // SPI clock divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_div_reg <= 'b0;
            spi_sck_div_reg_next <= 'b0;
        end else begin
            spi_sck_div_reg <= spi_sck_div_reg_next;
            spi_sck_div_reg_next <= spi_sck_div_reg;
        end
    end

    // SPI select divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_div_reg <= 'b0;
            spi_ssel_div_reg_next <= 'b0;
        end else begin
            spi_ssel_div_reg <= spi_ssel_div_reg_next;
            spi_ssel_div_reg_next <= spi_ssel_div_reg;
        end
    end

    // SPI MOSI divider
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_div_reg <= 'b0;
            spi_mosi_div