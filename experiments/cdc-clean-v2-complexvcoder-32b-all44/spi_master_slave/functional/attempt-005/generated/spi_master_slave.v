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
    reg [N-1:0] rx_reg;
    reg [3:0]   bit_cnt;
    reg [3:0]   sclk_div_cnt;
    reg         spi_sck;
    reg         spi_ssel;
    reg         spi_mosi;
    reg         di_req;
    reg         wr_ack;
    reg         do_valid;
    reg [N-1:0] do_reg;
    reg [3:0]   sclk_div_max;
    reg [3:0]   sclk_div_max_val;
    reg         sclk_rising_edge;
    reg         sclk_falling_edge;
    reg         sclk_div_cnt_rst;
    reg         sclk_div_cnt_en;
    reg         bit_cnt_rst;
    reg         bit_cnt_en;
    reg         shift_reg_load;
    reg         shift_reg_shift;
    reg         rx_reg_load;
    reg         spi_sck_load;
    reg         spi_ssel_load;
    reg         spi_mosi_load;
    reg         di_req_load;
    reg         wr_ack_load;
    reg         do_valid_load;
    reg         do_load;

    // SCLK Divider
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 0;
            sclk_div_cnt_rst <= 1;
            sclk_div_cnt_en <= 0;
        end else begin
            if (sclk_div_cnt_rst) begin
                sclk_div_cnt <= 0;
                sclk_div_cnt_rst <= 0;
            end else if (sclk_div_cnt_en) begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // Bit Counter
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            bit_cnt <= 0;
            bit_cnt_rst <= 1;
            bit_cnt_en <= 0;
        end else begin
            if (bit_cnt_rst) begin
                bit_cnt <= 0;
                bit_cnt_rst <= 0;
            end else if (bit_cnt_en) begin
                bit_cnt <= bit_cnt + 1;
            end
        end
    end

    // SPI SCK
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck <= 0;
            spi_sck_load <= 0;
        end else begin
            if (spi_sck_load) begin
                spi_sck <= ~spi_sck;
            end
        end
    end

    // SPI SSEL
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel <= 1;
            spi_ssel_load <= 0;
        end else begin
            if (spi_ssel_load) begin
                spi_ssel <= ~spi_ssel;
            end
        end
    end

    // SPI MOSI
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi <= 0;
            spi_mosi_load <= 0;
        end else begin
            if (spi_mosi_load) begin
                spi_mosi <= shift_reg[N-1];
            end
        end
    end

    // Shift Register
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg <= 0;
            shift_reg_load <= 0;
            shift_reg_shift <= 0;
        end else begin
            if (shift_reg_load) begin
                shift_reg <= di_i;
            end else if (shift_reg_shift) begin
                shift_reg <= {shift_reg[N-2:0], 1'b0};
            end
        end
    end

    // RX Register
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            rx_reg <= 0;
            rx_reg_load <= 0;
        end else begin
            if (rx_reg_load) begin
                rx_reg <= {rx_reg[N-2:0], spi_miso_i};
            end
        end
    end

    // DI Request
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req <= 0;
            di_req_load <= 0;
        end else begin
            if (di_req_load) begin
                di_req <= ~di_req;
            end
        end
    end

    // WR Ack
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack <= 0;
            wr_ack_load <= 0;
        end else begin
            if (wr_ack_load) begin
                wr_ack <= 1;
            end else begin
                wr_ack <= 0;
            end
        end
    end

    // DO Valid
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid <= 0;
            do_valid_load <= 0;
        end else begin
            if (do_valid_load) begin
                do_valid <= 1;
            end else begin
                do_valid <= 0;
            end
        end
    end

    // DO Register
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_reg <= 0;
            do_load <= 0;
        end else begin
            if (do_load) begin
                do_reg <= rx_reg;
            end
        end
    end

    // Main State Machine
    reg [2:0] state, next_state;

    parameter IDLE = 3'b000;
    parameter LOAD = 3'b001;
    parameter TRANSFER = 3'b010;
    parameter DONE = 3'b011;

    // State Register
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (wren_i)
                    next_state = LOAD;
                else
                    next_state = IDLE;
            end
            LOAD: begin
                next_state = TRANSFER;
            end
            TRANSFER: begin
                if (bit_cnt == N-1)
                    next_state = DONE;
                else
                    next_state = TRANSFER;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output Logic
    always @(*) begin
        sclk_div_cnt_rst = 0;
        sclk_div_cnt_en = 0;
        bit_cnt_rst = 0;
        bit_cnt_en = 0;
        shift_reg_load = 0;
        shift_reg_shift = 0;
        rx_reg_load = 0;
        spi_sck_load = 0;
        spi_ssel_load = 0;
        spi_mosi_load = 0;
        di_req_load = 0;
        wr_ack_load = 0;
        do_valid_load = 0;
        do_load = 0;

        case (state)
            IDLE: begin
                sclk_div_cnt_rst = 1;
                bit_cnt_rst = 1;
                spi_ssel_load = 1;
                di_req_load = 1;
            end
            LOAD: begin
                shift_reg_load = 1;
                spi_ssel_load = 1;
                wr_ack_load = 1;
            end
            TRANSFER: begin
                if (sclk_div_cnt == SPI_2X_CLK_DIV-1) begin
                    sclk_div_cnt_rst = 1;
                    sclk_div_cnt_en = 0;
                    bit_cnt_en = 1;
                    shift_reg_shift = 1;
                    rx_reg_load = 1;
                    spi_sck_load = 1;
                end else begin
                    sclk_div_cnt_rst = 0;
                    sclk_div_cnt_en = 1;
                    bit_cnt_en = 0;
                    shift_reg_shift = 0;
                    rx_reg_load = 0;
                    spi_sck_load = 0;
                end
            end
            DONE: begin
                do_valid_load = 1;
                do_load = 1;
                spi_ssel_load = 1;
            end
            default: begin
                sclk_div_cnt_rst = 1;
                bit_cnt_rst = 1;
                spi_ssel_load = 1;
            end
        endcase
    end

    // Assign outputs
    assign spi_mosi_o = spi_mosi;
    assign di_req_o = di_req;
    assign wr_ack_o = wr_ack;
    assign do_valid_o = do_valid;
    assign do_o = do_reg;
    assign spi_ssel_o = spi_ssel;
    assign spi_sck_o = spi_sck;

endmodule
