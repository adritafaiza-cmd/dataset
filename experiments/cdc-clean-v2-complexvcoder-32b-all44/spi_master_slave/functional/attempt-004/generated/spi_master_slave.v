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

    reg [N-1:0]        shift_reg;
    reg [N-1:0]        bit_cnt;
    reg [N-1:0]        data_in;
    reg [N-1:0]        data_out;
    reg [31:0]         sclk_div_cnt;
    reg                sclk_edge;
    reg                write_req;
    reg                read_ack;
    reg                tx_done;
    reg                rx_done;
    reg [1:0]          state;

    // Reset logic
    always @(posedge rst_i) begin
        spi_ssel_o   <= 0;
        spi_sck_o    <= 0;
        spi_mosi_o   <= 0;
        di_req_o     <= 1;
        wr_ack_o     <= 0;
        do_valid_o   <= 0;
        do_o         <= 0;
        shift_reg    <= 0;
        bit_cnt      <= 0;
        data_in      <= 0;
        data_out     <= 0;
        sclk_div_cnt <= 0;
        sclk_edge    <= 0;
        write_req    <= 0;
        read_ack     <= 0;
        tx_done      <= 0;
        rx_done      <= 0;
        state        <= 0;
    end

    // SCLK domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 0;
            sclk_edge    <= 0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 0;
                sclk_edge    <= ~sclk_edge;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // SPI transaction logic
    always @(posedge sclk_edge or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 0;
            spi_sck_o  <= 0;
            spi_mosi_o <= 0;
            shift_reg  <= 0;
            bit_cnt    <= 0;
            tx_done    <= 0;
            rx_done    <= 0;
        end else begin
            if (write_req) begin
                spi_ssel_o <= 1;
                spi_sck_o  <= 1;
                spi_mosi_o <= shift_reg[N-1];
                shift_reg  <= {shift_reg[N-2:0], spi_miso_i};
                bit_cnt    <= bit_cnt + 1;

                if (bit_cnt == N - 1) begin
                    tx_done <= 1;
                    rx_done <= 1;
                    bit_cnt <= 0;
                    shift_reg <= 0;
                end
            end else begin
                spi_ssel_o <= 0;
                spi_sck_o  <= 0;
                spi_mosi_o <= 0;
            end
        end
    end

    // Parallel interface logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o   <= 1;
            wr_ack_o   <= 0;
            do_valid_o <= 0;
            do_o       <= 0;
            write_req  <= 0;
            read_ack   <= 0;
        end else begin
            if (wren_i && !write_req) begin
                data_in  <= di_i;
                wr_ack_o <= 1;
                write_req <= 1;
                di_req_o <= 0;
            end else begin
                wr_ack_o <= 0;
            end

            if (tx_done) begin
                write_req <= 0;
                di_req_o  <= 1;
            end

            if (tx_done) begin
                data_out   <= shift_reg;
                do_o       <= data_out;
                do_valid_o <= 1;
                rx_done    <= 0;
            end else begin
                do_valid_o <= 0;
            end

            if (rx_done) begin
                tx_done <= 0;
            end
        end
    end

endmodule
