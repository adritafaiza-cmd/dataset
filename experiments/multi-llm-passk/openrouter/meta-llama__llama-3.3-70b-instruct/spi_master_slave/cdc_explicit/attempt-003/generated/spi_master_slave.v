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
reg [N-1:0] capture_reg;
reg [3:0]   state;
reg [3:0]   cnt;
reg         sclk_rst;
reg         pclk_rst;
reg         spi_sck_r;
reg         spi_sck_f;
reg         spi_miso_sync;
reg [1:0]   spi_miso_sync_reg;

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        sclk_rst <= 1'b1;
        spi_sck_r <= 1'b0;
        spi_sck_f <= 1'b0;
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
        shift_reg <= {N{1'b0}};
        cnt <= 4'b0;
        state <= 4'b0;
    end else begin
        sclk_rst <= 1'b0;
        case (state)
            4'b0000: begin
                spi_ssel_o <= 1'b1;
                spi_sck_o <= 1'b0;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b0001;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b0001: begin
                spi_ssel_o <= 1'b0;
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b0010;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b0010: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b0011;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b0011: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b0100;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b0100: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b0101;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b0101: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b0110;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b0110: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b0111;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b0111: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b1000;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b1000: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b1001;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b1001: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b1010;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b1010: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b1011;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b1011: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b1100;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b1100: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b1101;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b1101: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b1110;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b1110: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b1111;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            4'b1111: begin
                spi_sck_o <= spi_sck_f;
                if (spi_sck_r == 1'b1) begin
                    spi_sck_r <= 1'b0;
                    spi_sck_f <= 1'b1;
                end else if (spi_sck_r == 1'b0) begin
                    spi_sck_r <= 1'b1;
                    spi_sck_f <= 1'b0;
                end
                if (cnt == SPI_2X_CLK_DIV) begin
                    cnt <= 4'b0;
                    state <= 4'b0000;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        endcase
        if (state == 4'b0001) begin
            shift_reg <= {shift_reg[N-2:0], spi_miso_sync};
        end
        spi_mosi_o <= shift_reg[N-1];
        shift_reg <= {shift_reg[N-2:0], 1'b0};
    end
end

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        pclk_rst <= 1'b1;
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
    end else begin
        pclk_rst <= 1'b0;
        if (wren_i) begin
            wr_ack_o <= 1'b1;
            shift_reg <= di_i;
        end else begin
            wr_ack_o <= 1'b0;
        end
        if (state == 4'b1111) begin
            do_o <= shift_reg;
            do_valid_o <= 1'b1;
        end else begin
            do_valid_o <= 1'b0;
        end
        if (state == 4'b0000) begin
            di_req_o <= 1'b1;
        end else begin
            di_req_o <= 1'b0;
        end
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_miso_sync_reg <= 2'b00;
    end else begin
        spi_miso_sync_reg <= {spi_miso_sync_reg[0], spi_miso_i};
        spi_miso_sync <= spi_miso_sync_reg[1];
    end
end

endmodule
