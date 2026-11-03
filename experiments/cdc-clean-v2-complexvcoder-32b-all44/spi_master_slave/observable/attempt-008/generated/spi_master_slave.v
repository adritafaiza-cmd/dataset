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

    // Internal signals
    reg [N-1:0]        wren_sclk;
    reg [N-1:0]        di_sclk;
    reg [1:0]          spi_state;
    reg [3:0]          bit_cnt;
    reg [N-1:0]        shift_reg;
    reg [N-1:0]        do_reg;
    reg [3:0]          spi_clk_div;
    reg                spi_clk_toggle;
    reg                wr_ack_reg;
    reg                do_valid_reg;
    reg                di_req_reg;

    // State definitions
    localparam IDLE = 2'b00;
    localparam SEND = 2'b01;
    localparam DONE = 2'b10;

    // Clock domain crossing for wren_i
    sclk_domain_crossing #(.N(1)) cdc_wren (
        .clk_in   (pclk_i),
        .clk_out  (sclk_i),
        .rst      (rst_i),
        .data_in  (wren_i),
        .data_out (wren_sclk)
    );

    // Clock domain crossing for di_i
    sclk_domain_crossing #(.N(N)) cdc_di (
        .clk_in   (pclk_i),
        .clk_out  (sclk_i),
        .rst      (rst_i),
        .data_in  (di_i),
        .data_out (di_sclk)
    );

    // SPI master logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o  <= 1'b0;
            spi_clk_div <= 4'b0000;
            spi_clk_toggle <= 1'b0;
            spi_state <= IDLE;
            bit_cnt <= 4'b0000;
            shift_reg <= {N{1'b0}};
            do_reg <= {N{1'b0}};
            wr_ack_reg <= 1'b0;
            do_valid_reg <= 1'b0;
        end else begin
            // SPI clock division and toggle
            if (spi_clk_div == SPI_2X_CLK_DIV - 1) begin
                spi_clk_div <= 4'b0000;
                spi_clk_toggle <= ~spi_clk_toggle;
            end else begin
                spi_clk_div <= spi_clk_div + 1'b1;
            end

            // SPI clock output
            spi_sck_o <= spi_clk_toggle;

            case (spi_state)
                IDLE: begin
                    if (wren_sclk[0]) begin
                        shift_reg <= di_sclk;
                        wr_ack_reg <= 1'b1;
                        spi_ssel_o <= 1'b0;
                        spi_state <= SEND;
                    end else begin
                        wr_ack_reg <= 1'b0;
                    end
                    di_req_reg <= 1'b0;
                end

                SEND: begin
                    if (spi_clk_toggle) begin
                        spi_mosi_o <= shift_reg[N-1];
                        shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                        bit_cnt <= bit_cnt + 1'b1;
                        if (bit_cnt == N-1) begin
                            spi_state <= DONE;
                        end
                    end
                end

                DONE: begin
                    spi_ssel_o <= 1'b1;
                    do_reg <= shift_reg;
                    do_valid_reg <= 1'b1;
                    spi_state <= IDLE;
                    di_req_reg <= 1'b1;
                end

                default: begin
                    spi_state <= IDLE;
                end
            endcase
        end
    end

    // Parallel interface logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
            di_req_o <= 1'b1;
        end else begin
            wr_ack_o <= wr_ack_reg;
            do_valid_o <= do_valid_reg;
            do_o <= do_reg;
            di_req_o <= di_req_reg;
        end
    end

endmodule

// Clock domain crossing module
module sclk_domain_crossing #(
    parameter N = 8
)(
    input              clk_in,
    input              clk_out,
    input              rst,
    input  [N-1:0]     data_in,
    output reg [N-1:0] data_out
);

    reg [N-1:0] data_reg;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            data_reg <= {N{1'b0}};
        end else begin
            data_reg <= data_in;
        end
    end

    always @(posedge clk_out or posedge rst) begin
        if (rst) begin
            data_out <= {N{1'b0}};
        end else begin
            data_out <= data_reg;
        end
    end

endmodule
