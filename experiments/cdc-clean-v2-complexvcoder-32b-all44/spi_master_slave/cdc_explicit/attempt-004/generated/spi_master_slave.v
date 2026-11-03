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
    reg [N-1:0]        shift_reg;
    reg [3:0]          bit_cnt;
    reg [N-1:0]        tx_data;
    reg [N-1:0]        rx_data;
    reg                wren_sync;
    reg                wren_reg;
    reg                wren_ff;
    reg [$clog2(SPI_2X_CLK_DIV):0] clk_div_cnt;
    reg                sck_toggle;
    reg                miso_synced;
    reg                di_req_synced;

    // CDC synchronization for spi_miso_i
    cdc_sync cdc_sync_miso (
        .local(spi_miso_i),
        .remote(miso_synced)
    );

    // CDC synchronization for di_req_o
    cdc_sync cdc_sync_di_req (
        .local(di_req_o),
        .remote(di_req_synced)
    );

    // Synchronize wren_i to pclk_i using double FFs
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_sync <= 0;
            wren_reg <= 0;
        end else begin
            wren_sync <= wren_i;
            wren_reg <= wren_sync;
        end
    end

    // Detect edge of wren_i and set wr_ack_o to high for one cycle
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_o <= 0;
        end else if (wren_i & ~wren_reg) begin
            wr_ack_o <= 1;
        end else begin
            wr_ack_o <= 0;
        end
    end

    // Load di_i into tx_data and set di_req_o to high when wren_i is high
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 0;
            tx_data <= 0;
        end else if (wren_i) begin
            di_req_o <= 1;
            tx_data <= di_i;
        end else if (!di_req_synced) begin
            di_req_o <= 0;
        end
    end

    // Divide sclk_i by SPI_2X_CLK_DIV to generate sck
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_div_cnt <= 0;
            sck_toggle <= 0;
        end else begin
            if (clk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                clk_div_cnt <= 0;
                sck_toggle <= ~sck_toggle;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1;
            end
        end
    end

    assign spi_sck_o = sck_toggle;

    // Shift tx_data out on mosi and capture miso_synced into rx_data
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg <= 0;
            bit_cnt <= 0;
            rx_data <= 0;
            spi_ssel_o <= 0;
            do_valid_o <= 0;
        end else begin
            if (bit_cnt == 0) begin
                shift_reg <= tx_data;
                spi_ssel_o <= 1;
                do_valid_o <= 0;
            end else if (bit_cnt < N) begin
                shift_reg <= {shift_reg[N-2:0], miso_synced};
            end else begin
                rx_data <= {shift_reg[N-2:0], miso_synced};
                spi_ssel_o <= 0;
                do_valid_o <= 1;
            end
            if (bit_cnt < N) begin
                bit_cnt <= bit_cnt + 1;
            end else begin
                bit_cnt <= 0;
            end
        end
    end

    // Register rx_data into do_o on pclk_i
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_o <= 0;
        end else begin
            do_o <= rx_data;
        end
    end

    // Clear do_valid_o after one cycle
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_o <= 0;
        end else if (do_valid_o) begin
            do_valid_o <= 0;
        end
    end

endmodule

module cdc_sync (
    input  local,
    output reg remote
);

    // Internal signals
    reg sync_ff1;
    reg sync_ff2;

    // Synchronize local input to sync_ff1
    always @(posedge local or posedge local) begin
        sync_ff1 <= local;
    end

    // Register sync_ff1 to sync_ff2
    always @(posedge remote or posedge remote) begin
        sync_ff2 <= sync_ff1;
    end

    // Assign sync_ff2 to remote output
    always @(posedge remote or posedge remote) begin
        remote <= sync_ff2;
    end

endmodule
