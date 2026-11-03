// Verilog-2001 rewrite of OpenCores spi_master (Jonny Doin).
// Parallel I/O is clocked by pclk_i; the serial shifter is clocked by sclk_i.

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

    localparam DIVW = 4;
    reg [DIVW-1:0] div_cnt;
    reg spi_ce;
    (* ASYNC_REG = "TRUE" *) reg [1:0] start_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] done_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] p_rst_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] s_rst_sync;
    wire p_rst = p_rst_sync[1];
    wire s_rst = s_rst_sync[1];
    reg start_req, done_pulse, busy;
    reg [N-1:0] tx_shift, rx_shift, tx_hold;
    reg [4:0] bit_cnt;

    assign spi_mosi_o = tx_shift[N-1];

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            p_rst_sync <= 2'b11;
        else
            p_rst_sync <= {p_rst_sync[0], 1'b0};
    end

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            s_rst_sync <= 2'b11;
        else
            s_rst_sync <= {s_rst_sync[0], 1'b0};
    end

    always @(posedge pclk_i or posedge p_rst) begin
        if (p_rst) begin
            start_req <= 1'b0;
            wr_ack_o <= 1'b0;
            di_req_o <= 1'b1;
            tx_hold <= {N{1'b0}};
            do_o <= {N{1'b0}};
            do_valid_o <= 1'b0;
            done_sync <= 2'b00;
        end else begin
            done_sync <= {done_sync[0], done_pulse};
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            if (wren_i && !start_req) begin
                tx_hold <= di_i;
                start_req <= 1'b1;
                wr_ack_o <= 1'b1;
                di_req_o <= 1'b0;
            end
            if (done_sync == 2'b01) begin
                start_req <= 1'b0;
                do_o <= rx_shift;
                do_valid_o <= 1'b1;
                di_req_o <= 1'b1;
            end
        end
    end

    always @(posedge sclk_i or posedge s_rst) begin
        if (s_rst) begin
            div_cnt <= {DIVW{1'b0}};
            spi_ce <= 1'b0;
            start_sync <= 2'b00;
            busy <= 1'b0;
            done_pulse <= 1'b0;
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            tx_shift <= {N{1'b0}};
            rx_shift <= {N{1'b0}};
            bit_cnt <= 5'd0;
        end else begin
            start_sync <= {start_sync[0], start_req};
            if (div_cnt == (SPI_2X_CLK_DIV-1)) begin
                div_cnt <= {DIVW{1'b0}};
                spi_ce <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 1'b1;
                spi_ce <= 1'b0;
            end

            if (spi_ce) begin
                if (!busy && start_sync[1]) begin
                    busy <= 1'b1;
                    done_pulse <= 1'b0;
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= 1'b0;
                    tx_shift <= tx_hold;
                    bit_cnt <= N;
                end else if (busy) begin
                    if (spi_sck_o == 1'b0) begin
                        spi_sck_o <= 1'b1;
                        rx_shift <= {rx_shift[N-2:0], spi_miso_i};
                    end else begin
                        spi_sck_o <= 1'b0;
                        tx_shift <= {tx_shift[N-2:0], 1'b0};
                        if (bit_cnt == 5'd1) begin
                            busy <= 1'b0;
                            spi_ssel_o <= 1'b1;
                            done_pulse <= 1'b1;
                        end else
                            bit_cnt <= bit_cnt - 5'd1;
                    end
                end
            end
        end
    end

endmodule
