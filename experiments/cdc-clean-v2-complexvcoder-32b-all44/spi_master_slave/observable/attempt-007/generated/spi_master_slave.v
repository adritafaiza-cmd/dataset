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

    reg [N-1:0] parallel_data;
    reg [N-1:0] serial_data;
    reg         shift_start;
    reg         shift_done;
    reg         shift_start_synced;
    reg         shift_done_synced;

    // Clock-domain crossing for shift_start
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_start_synced <= 0;
        end else begin
            shift_start_synced <= shift_start;
        end
    end

    // Clock-domain crossing for shift_done
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_done_synced <= 0;
        end else begin
            shift_done_synced <= shift_done;
        end
    end

    spi_master_control spi_master_ctrl_inst (
        .pclk_i        (pclk_i),
        .rst_i         (rst_i),
        .wren_i        (wren_i),
        .di_req_o      (di_req_o),
        .wr_ack_o      (wr_ack_o),
        .do_valid_o    (do_valid_o),
        .shift_start   (shift_start),
        .shift_done    (shift_done_synced),
        .parallel_data (parallel_data),
        .serial_data   (serial_data)
    );

    spi_master_shift spi_master_shift_inst (
        .sclk_i        (sclk_i),
        .rst_i         (rst_i),
        .shift_start   (shift_start_synced),
        .shift_done    (shift_done),
        .parallel_data (parallel_data),
        .spi_ssel_o    (spi_ssel_o),
        .spi_sck_o     (spi_sck_o),
        .spi_mosi_o    (spi_mosi_o),
        .spi_miso_i    (spi_miso_i),
        .serial_data   (serial_data)
    );

endmodule

module spi_master_control #(
    parameter N = 8
)(
    input              pclk_i,
    input              rst_i,
    input              wren_i,
    output reg         di_req_o,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg         shift_start,
    input              shift_done,
    output reg [N-1:0] parallel_data,
    input  [N-1:0]     serial_data
);

    typedef enum reg [1:0] {
        IDLE,
        REQUEST,
        SHIFT,
        RESPONSE
    } state_t;

    state_t state, next_state;
    reg [N-1:0] wr_ack_pulse, do_valid_pulse;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        di_req_o = 0;
        wr_ack_o = 0;
        do_valid_o = 0;
        shift_start = 0;

        case (state)
            IDLE: begin
                di_req_o = 1;
                if (wren_i) begin
                    next_state = REQUEST;
                end
            end
            REQUEST: begin
                wr_ack_o = 1;
                parallel_data = di_i;
                next_state = SHIFT;
                shift_start = 1;
            end
            SHIFT: begin
                if (shift_done) begin
                    next_state = RESPONSE;
                end
            end
            RESPONSE: begin
                do_valid_o = 1;
                do_o = serial_data;
                next_state = IDLE;
            end
        endcase
    end

endmodule

module spi_master_shift #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              rst_i,
    input              shift_start,
    output reg         shift_done,
    input  [N-1:0]     parallel_data,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output reg         spi_mosi_o,
    input              spi_miso_i,
    output reg [N-1:0] serial_data
);

    reg [2:0] bit_counter;
    reg [N-1:0] shift_reg;
    reg [N-1:0] miso_reg;
    reg         sck_reg;
    reg         ssel_reg;
    reg         sclk_div_counter;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            bit_counter <= 0;
            shift_reg <= 0;
            miso_reg <= 0;
            sck_reg <= 0;
            ssel_reg <= 0;
            sclk_div_counter <= 0;
            shift_done <= 0;
        end else begin
            if (shift_start) begin
                bit_counter <= N-1;
                shift_reg <= parallel_data;
                miso_reg <= 0;
                sclk_div_counter <= 0;
                sck_reg <= 0;
                ssel_reg <= 1;
                shift_done <= 0;
            end else if (ssel_reg) begin
                if (sclk_div_counter == SPI_2X_CLK_DIV-1) begin
                    sclk_div_counter <= 0;
                    sck_reg <= ~sck_reg;
                    if (sck_reg) begin
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                        miso_reg <= {miso_reg[N-2:0], spi_miso_i};
                        if (bit_counter == 0) begin
                            ssel_reg <= 0;
                            shift_done <= 1;
                            serial_data <= miso_reg;
                        end else begin
                            bit_counter <= bit_counter - 1;
                        end
                    end
                end else begin
                    sclk_div_counter <= sclk_div_counter + 1;
                end
            end
        end
    end

    assign spi_ssel_o = ssel_reg;
    assign spi_sck_o = sck_reg;
    assign spi_mosi_o = shift_reg[N-1];

endmodule
