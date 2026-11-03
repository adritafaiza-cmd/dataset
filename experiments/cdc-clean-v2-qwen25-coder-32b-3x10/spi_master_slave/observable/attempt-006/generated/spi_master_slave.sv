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
    reg                spi_start;
    reg                spi_busy;
    reg                spi_done;
    reg [N-1:0]        di_i_sync;
    reg                wren_i_sync;

    // Clock domain crossing for di_i and wren_i
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_i_sync <= 0;
            wren_i_sync <= 0;
        end else begin
            di_i_sync <= di_i;
            wren_i_sync <= wren_i;
        end
    end

    // SPI state machine
    typedef enum reg [2:0] {
        IDLE,
        START,
        TRANSFER,
        DONE
    } spi_state_t;

    spi_state_t state, next_state;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            spi_busy <= 0;
            spi_done <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    spi_ssel_o <= 1;
                    spi_sck_o <= 0;
                    spi_mosi_o <= 0;
                    spi_busy <= 0;
                    spi_done <= 0;
                    if (spi_start) begin
                        spi_ssel_o <= 0;
                        spi_busy <= 1;
                        shift_reg <= di_i_sync;
                        bit_cnt <= N-1;
                        next_state <= START;
                    end else begin
                        next_state <= IDLE;
                    end
                end
                START: begin
                    spi_sck_o <= 0;
                    next_state <= TRANSFER;
                end
                TRANSFER: begin
                    spi_sck_o <= ~spi_sck_o;
                    if (spi_sck_o) begin
                        spi_mosi_o <= shift_reg[bit_cnt];
                        if (bit_cnt == 0) begin
                            next_state <= DONE;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end else begin
                        if (bit_cnt == N-1) begin
                            do_o <= 0;
                        end else begin
                            do_o <= {do_o[N-2:0], spi_miso_i};
                        end
                    end
                end
                DONE: begin
                    spi_ssel_o <= 1;
                    spi_busy <= 0;
                    spi_done <= 1;
                    next_state <= IDLE;
                end
                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end

    // Control signals
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1;
            wr_ack_o <= 0;
            do_valid_o <= 0;
        end else begin
            di_req_o <= ~spi_busy;
            wr_ack_o <= (state == START);
            do_valid_o <= spi_done;
        end
    end

    // SPI start signal generation
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_start <= 0;
        end else begin
            if (wren_i_sync && ~spi_busy) begin
                spi_start <= 1;
            end else begin
                spi_start <= 0;
            end
        end
    end

endmodule
