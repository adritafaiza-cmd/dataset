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

    // Parallel domain registers
    reg [N-1:0] data_p;
    reg data_available_p;
    reg di_req_reg;

    // SCLK domain registers
    reg data_available_s1, data_available_s2;
    reg [N-1:0] data_s;
    reg transfer_active_s;
    reg [N-1:0] shift_out;
    reg [N-1:0] shift_in;
    reg [3:0] bit_count;
    reg sck_div_counter;
    reg sck_reg;

    // CDC for done signal
    reg done_p1, done_p2;
    reg [N-1:0] recv_data_s;

    // Assign MOSI
    assign spi_mosi_o = shift_out[N-1];

    // CDC for data_available_p to SCLK domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            data_available_s1 <= 0;
            data_available_s2 <= 0;
        end else begin
            data_available_s1 <= data_available_p;
            data_available_s2 <= data_available_s1;
        end
    end

    // CDC for done_s to PCLK domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            done_p1 <= 0;
            done_p2 <= 0;
        end else begin
            done_p1 <= done_s;
            done_p2 <= done_p1;
        end
    end

    // CDC for received data
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            recv_data_s <= 0;
        end else if (done_p2) begin
            recv_data_s <= shift_in;
        end
    end

    // Parallel domain logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_reg <= 1;
            data_available_p <= 0;
            data_p <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
        end else begin
            wr_ack_o <= 0;
            do_valid_o <= 0;

            if (done_p2) begin
                do_o <= recv_data_s;
                wr_ack_o <= 1;
                do_valid_o <= 1;
            end

            if (di_req_reg && wren_i) begin
                data_p <= di_i;
                data_available_p <= 1;
                di_req_reg <= 0;
            end

            if (transfer_start_s) begin
                data_available_p <= 0;
            end

            if (data_available_p && !transfer_active_s) begin
                di_req_reg <= 0;
            end

            if (done_p2) begin
                di_req_reg <= 1;
            end
        end
    end

    // Transfer start signal
    wire transfer_start_s = data_available_s2 && !transfer_active_s;

    // SCLK domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            sck_reg <= 0;
            sck_div_counter <= 0;
            transfer_active_s <= 0;
            shift_out <= 0;
            shift_in <= 0;
            bit_count <= 0;
            done_s <= 0;
            data_s <= 0;
        end else begin
            done_s <= 0;

            if (transfer_active_s) begin
                // SCK generation
                if (sck_div_counter == SPI_2X_CLK_DIV) begin
                    sck_reg <= ~sck_reg;
                    sck_div_counter <= 0;
                end else begin
                    sck_div_counter <= sck_div_counter + 1;
                end

                // Data shifting on falling edge (sck_reg toggling)
                if (sck_div_counter == SPI_2X_CLK_DIV && sck_reg) begin
                    shift_out <= {shift_out[N-2:0], 1'b0};
                    bit_count <= bit_count + 1;
                    shift_in <= {shift_in[N-2:0], spi_miso_i};
                end

                if (bit_count == N) begin
                    transfer_active_s <= 0;
                    spi_ssel_o <= 1;
                    done_s <= 1;
                    bit_count <= 0;
                    sck_div_counter <= 0;
                    sck_reg <= 0;
                end
            end else begin
                if (transfer_start_s) begin
                    transfer_active_s <= 1;
                    spi_ssel_o <= 0;
                    data_s <= data_p;
                    shift_out <= data_p;
                    bit_count <= 0;
                    sck_div_counter <= 0;
                    sck_reg <= 0;
                end
            end

            spi_sck_o <= sck_reg;
        end
    end

    // Assign di_req_o
    always @* di_req_o = di_req_reg;

endmodule
