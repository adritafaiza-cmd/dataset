module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input sclk_i,
    input pclk_i,
    input rst_i,
    output reg spi_ssel_o,
    output reg spi_sck_o,
    output spi_mosi_o,
    input spi_miso_i,
    output reg di_req_o,
    input [N-1:0] di_i,
    input wren_i,
    output reg wr_ack_o,
    output reg do_valid_o,
    output reg [N-1:0] do_o
);

    // Parallel interface (pclk domain)
    reg [N-1:0] data_p;
    reg data_available_p;
    reg di_req_p;

    // Synchronize data_available_p to sclk domain
    reg data_available_sync1, data_available_sync2;

    // SPI state machine (sclk domain)
    reg state;
    localparam IDLE = 0;
    localparam SHIFTING = 1;

    reg [N-1:0] shift_out;
    reg [N-1:0] shift_in;
    reg [$clog2(N)-1:0] bit_count;

    // SCK generation
    reg sck_reg;
    reg [15:0] clk_div_counter;

    // Assign MOSI
    assign spi_mosi_o = shift_out[N-1];

    // PCLK domain logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_p <= 1;
            data_available_p <= 0;
            data_p <= 0;
            wr_ack_o <= 0;
        end else begin
            wr_ack_o <= 0;
            if (di_req_p && wren_i) begin
                data_p <= di_i;
                data_available_p <= 1;
                di_req_p <= 0;
                wr_ack_o <= 1;
            end
        end
    end

    // Synchronize data_available_p to sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            data_available_sync1 <= 0;
            data_available_sync2 <= 0;
        end else begin
            data_available_sync1 <= data_available_p;
            data_available_sync2 <= data_available_sync1;
        end
    end

    // SCLK domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            shift_out <= 0;
            shift_in <= 0;
            bit_count <= 0;
            do_valid_o <= 0;
            do_o <= 0;
            sck_reg <= 0;
            clk_div_counter <= 0;
            di_req_o <= 1;
        end else begin
            do_valid_o <= 0;

            case (state)
                IDLE: begin
                    spi_ssel_o <= 1;
                    spi_sck_o <= 0;
                    if (data_available_sync2) begin
                        shift_out <= data_p;
                        spi_ssel_o <= 0;
                        state <= SHIFTING;
                        bit_count <= 0;
                        clk_div_counter <= 0;
                        sck_reg <= 0;
                        di_req_o <= 0;
                    end
                end

                SHIFTING: begin
                    spi_ssel_o <= 0;
                    // Generate SCK
                    if (clk_div_counter == SPI_2X_CLK_DIV -1) begin
                        sck_reg <= ~sck_reg;
                        clk_div_counter <= 0;
                    end else begin
                        clk_div_counter <= clk_div_counter + 1;
                    end

                    spi_sck_o <= sck_reg;

                    // On falling edge (sck_reg toggles to 0)
                    if (sck_reg && (clk_div_counter == SPI_2X_CLK_DIV -1)) begin
                        // Shift data out
                        shift_out <= shift_out << 1;
                        bit_count <= bit_count + 1;
                    end

                    // On rising edge (sck_reg toggles to 1)
                    if (!sck_reg && (clk_div_counter == SPI_2X_CLK_DIV -1)) begin
                        // Sample MISO
                        shift_in <= {shift_in[N-2:0], spi_miso_i};
                    end

                    if (bit_count == N) begin
                        // Transfer done
                        do_o <= shift_in;
                        do_valid_o <= 1;
                        di_req_o <= 1;
                        state <= IDLE;
                        spi_ssel_o <= 1;
                    end
                end
            endcase
        end
    end

endmodule
