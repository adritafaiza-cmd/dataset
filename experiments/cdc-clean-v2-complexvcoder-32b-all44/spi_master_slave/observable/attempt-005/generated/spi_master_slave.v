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

reg [N-1:0] shift_reg;
reg [2:0] bit_cnt;
reg [2:0] state, next_state;
reg mosi_data, miso_data;
reg [N-1:0] do_reg;
reg wr_ack_reg, do_valid_reg, di_req_reg, ssel_reg, sck_reg;
reg spi_clk;
reg [31:0] div_cnt;

// State definitions
localparam IDLE = 3'b000;
localparam LOAD = 3'b001;
localparam SHIFT = 3'b010;
localparam DONE = 3'b011;

// Clock Divider
always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        div_cnt <= 32'd0;
        spi_clk <= 1'b0;
    end else begin
        if (div_cnt == SPI_2X_CLK_DIV - 1) begin
            div_cnt <= 32'd0;
            spi_clk <= ~spi_clk;
        end else begin
            div_cnt <= div_cnt + 1;
        end
    end
end

// SPI Master Control
always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        state <= IDLE;
        wr_ack_reg <= 1'b0;
        do_valid_reg <= 1'b0;
        di_req_reg <= 1'b0;
        ssel_reg <= 1'b1;
        sck_reg <= 1'b0;
        bit_cnt <= 3'd0;
        shift_reg <= 8'd0;
        do_reg <= 8'd0;
    end else begin
        state <= next_state;
        wr_ack_reg <= 1'b0;
        do_valid_reg <= 1'b0;
        case (state)
            IDLE: begin
                di_req_reg <= 1'b1;
                ssel_reg <= 1'b1;
                sck_reg <= 1'b0;
                if (wren_i) begin
                    next_state <= LOAD;
                    wr_ack_reg <= 1'b1;
                end else begin
                    next_state <= IDLE;
                end
            end
            LOAD: begin
                di_req_reg <= 1'b0;
                ssel_reg <= 1'b0;
                sck_reg <= 1'b0;
                shift_reg <= di_i;
                bit_cnt <= 3'd0;
                next_state <= SHIFT;
            end
            SHIFT: begin
                ssel_reg <= 1'b0;
                if (spi_clk) begin
                    sck_reg <= 1'b1;
                    miso_data <= spi_miso_i;
                end else begin
                    sck_reg <= 1'b0;
                    if (bit_cnt < N) begin
                        mosi_data <= shift_reg[7];
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        bit_cnt <= bit_cnt + 1;
                    end else begin
                        next_state <= DONE;
                    end
                end
            end
            DONE: begin
                ssel_reg <= 1'b1;
                sck_reg <= 1'b0;
                do_valid_reg <= 1'b1;
                do_reg <= {miso_data, shift_reg[6:0]};
                next_state <= IDLE;
            end
            default: begin
                next_state <= IDLE;
            end
        endcase
    end
end

// Output assignments
always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= 8'd0;
    end else begin
        spi_ssel_o <= ssel_reg;
        spi_sck_o <= sck_reg;
        di_req_o <= di_req_reg;
        wr_ack_o <= wr_ack_reg;
        do_valid_o <= do_valid_reg;
        do_o <= do_reg;
    end
end

assign spi_mosi_o = mosi_data;

endmodule
