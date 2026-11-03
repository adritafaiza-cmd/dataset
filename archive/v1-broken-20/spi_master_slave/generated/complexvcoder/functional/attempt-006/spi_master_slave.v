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
    reg [2:N]   bit_cnt;
    reg         shift_out_en;
    reg         shift_in_en;
    reg         ssel_reg;
    reg         sck_reg;
    reg         mosi_reg;
    reg         miso_reg;

    // Synchronization and state machines
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o  <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o   <= 1'b0;
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;
            shift_reg  <= 0;
            bit_cnt    <= 0;
            shift_out_en <= 0;
            shift_in_en  <= 0;
            ssel_reg   <= 1'b1;
            sck_reg    <= 1'b0;
            mosi_reg   <= 1'b0;
        end else begin
            if (wren_i) begin
                shift_reg <= di_i;
                wr_ack_o  <= 1'b1;
                di_req_o  <= 1'b1;
                shift_out_en <= 1'b1;
            end else begin
                wr_ack_o <= 1'b0;
                di_req_o <= 1'b0;
                shift_out_en <= 1'b0;
            end

            if (shift_out_en) begin
                if (bit_cnt == 0) begin
                    ssel_reg <= 1'b0;
                end

                if (bit_cnt < N) begin
                    bit_cnt <= bit_cnt + 1;
                    sck_reg <= ~sck_reg;
                    if (sck_reg) begin
                        spi_mosi_o <= shift_reg[N-1];
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                    end else begin
                        miso_reg <= spi_miso_i;
                    end
                end else begin
                    bit_cnt <= 0;
                    ssel_reg <= 1'b1;
                end
            end

            spi_ssel_o <= ssel_reg;
            spi_sck_o  <= sck_reg;
            spi_mosi_o <= mosi_reg;
            do_o       <= {miso_reg, do_o[N-2:0]};
            do_valid_o <= (bit_cnt == 0);
        end
    end

endmodule
