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
    reg [N-1:0]        rx_data;
    reg [3:0]          bit_cnt;
    reg                tx_start;
    reg                rx_done;
    reg                tx_done;
    reg                sclk_en;
    reg                pclk_en;
    reg                sclk_rst;
    reg                pclk_rst;
    reg                spi_ssel_r;
    reg                spi_sck_r;
    reg                spi_mosi_r;
    reg                di_req_r;
    reg                wr_ack_r;
    reg                do_valid_r;
    reg [N-1:0]        do_o_r;

    // Clock and reset synchronizers
    reg [1:0]          rst_sync_sclk;
    reg [1:0]          rst_sync_pclk;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            rst_sync_sclk <= 2'b11;
        end else begin
            rst_sync_sclk <= {rst_sync_sclk[0], rst_i};
        end
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            rst_sync_pclk <= 2'b11;
        end else begin
            rst_sync_pclk <= {rst_sync_pclk[0], rst_i};
        end
    end

    assign sclk_rst = rst_sync_sclk[1];
    assign pclk_rst = rst_sync_pclk[1];

    // SPI clock enable generation
    reg [1:0]          sclk_div_cnt;

    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            sclk_div_cnt <= 2'b00;
            sclk_en <= 1'b0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 2'b00;
                sclk_en <= ~sclk_en;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // SPI clock generation
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            spi_sck_r <= 1'b0;
        end else if (sclk_en) begin
            spi_sck_r <= ~spi_sck_r;
        end
    end

    assign spi_sck_o = spi_sck_r;

    // SPI master state machine
    typedef enum reg [2:0] {
        IDLE,
        START,
        TRANSFER,
        FINISH
    } state_t;

    state_t state, next_state;

    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (tx_start) begin
                    next_state = START;
                end
            end
            START: begin
                next_state = TRANSFER;
            end
            TRANSFER: begin
                if (bit_cnt == N - 1) begin
                    next_state = FINISH;
                end
            end
            FINISH: begin
                next_state = IDLE;
            end
        endcase
    end

    // SPI master control logic
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            spi_ssel_r <= 1'b1;
            spi_mosi_r <= 1'b0;
            bit_cnt <= 4'b0000;
            tx_start <= 1'b0;
            tx_done <= 1'b0;
            rx_done <= 1'b0;
            shift_reg <= {N{1'b0}};
            rx_data <= {N{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    spi_ssel_r <= 1'b1;
                    if (tx_start) begin
                        spi_ssel_r <= 1'b0;
                        shift_reg <= di_i;
                        bit_cnt <= 4'b0000;
                    end
                end
                START: begin
                    spi_mosi_r <= shift_reg[N-1];
                end
                TRANSFER: begin
                    if (sclk_en) begin
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                        spi_mosi_r <= shift_reg[N-1];
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                FINISH: begin
                    tx_done <= 1'b1;
                    rx_done <= 1'b1;
                end
            endcase
        end
    end

    // Data capture on MISO
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            rx_data <= {N{1'b0}};
        end else if (sclk_en && state == TRANSFER) begin
            rx_data <= {rx_data[N-2:0], spi_miso_i};
        end
    end

    // Output assignments
    assign spi_mosi_o = spi_mosi_r;
    assign spi_ssel_o = spi_ssel_r;

    // Parallel side interface control
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            di_req_r <= 1'b0;
            wr_ack_r <= 1'b0;
            do_valid_r <= 1'b0;
            do_o_r <= {N{1'b0}};
        end else begin
            di_req_r <= 1'b0;
            wr_ack_r <= 1'b0;
            do_valid_r <= 1'b0;

            if (state == IDLE && !tx_start) begin
                if (wren_i) begin
                    tx_start <= 1'b1;
                    wr_ack_r <= 1'b1;
                end else begin
                    di_req_r <= 1'b1;
                end
            end

            if (tx_done) begin
                tx_start <= 1'b0;
                tx_done <= 1'b0;
            end

            if (rx_done) begin
                rx_done <= 1'b0;
                do_o_r <= rx_data;
                do_valid_r <= 1'b1;
            end
        end
    end

    assign di_req_o = di_req_r;
    assign wr_ack_o = wr_ack_r;
    assign do_valid_o = do_valid_r;
    assign do_o = do_o_r;

endmodule
