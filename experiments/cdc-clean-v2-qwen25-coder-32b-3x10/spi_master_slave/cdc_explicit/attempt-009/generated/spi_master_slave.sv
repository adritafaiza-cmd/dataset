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

    // Synchronizers for crossing from pclk_i to sclk_i
    reg [1:0] wren_sync;
    reg [1:0] rst_sync;

    // Synchronizers for crossing from sclk_i to pclk_i
    reg [1:0] wr_ack_sync;
    reg [1:0] do_valid_sync;

    // Registers for data transfer
    reg [N-1:0] tx_data;
    reg [N-1:0] rx_data;
    reg [3:0] bit_cnt;

    // State machine states
    typedef enum reg [2:0] {
        IDLE,
        LOAD_DATA,
        TRANSFER,
        WAIT_FOR_NEXT
    } state_t;

    state_t state, next_state;

    // Synchronizers for wren_i and rst_i
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_sync <= 2'b00;
            rst_sync  <= 2'b11;
        end else begin
            wren_sync <= {wren_sync[0], wren_i};
            rst_sync  <= {rst_sync[0], rst_i};
        end
    end

    // Synchronizers for wr_ack_o and do_valid_o
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_sync   <= 2'b00;
            do_valid_sync <= 2'b00;
        end else begin
            wr_ack_sync   <= {wr_ack_sync[0], wr_ack_o};
            do_valid_sync <= {do_valid_sync[0], do_valid_o};
        end
    end

    // State machine for SPI master
    always @(posedge sclk_i or posedge rst_sync[1]) begin
        if (rst_sync[1]) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (wren_sync[1]) begin
                    next_state = LOAD_DATA;
                end
            end
            LOAD_DATA: begin
                next_state = TRANSFER;
            end
            TRANSFER: begin
                if (bit_cnt == N) begin
                    next_state = WAIT_FOR_NEXT;
                end
            end
            WAIT_FOR_NEXT: begin
                if (!wren_sync[1]) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Output logic and data transfer
    always @(posedge sclk_i or posedge rst_sync[1]) begin
        if (rst_sync[1]) begin
            spi_ssel_o   <= 1'b1;
            spi_sck_o    <= 1'b0;
            spi_mosi_o   <= 1'b0;
            di_req_o     <= 1'b0;
            wr_ack_o     <= 1'b0;
            do_valid_o   <= 1'b0;
            do_o         <= {N{1'b0}};
            tx_data      <= {N{1'b0}};
            rx_data      <= {N{1'b0}};
            bit_cnt      <= 4'b0000;
        end else begin
            case (state)
                IDLE: begin
                    di_req_o <= 1'b1;
                end
                LOAD_DATA: begin
                    tx_data  <= di_i;
                    bit_cnt  <= 4'b0000;
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b1;
                    spi_ssel_o <= 1'b0;
                end
                TRANSFER: begin
                    spi_sck_o <= ~spi_sck_o;
                    if (spi_sck_o) begin
                        spi_mosi_o <= tx_data[N-1];
                        tx_data    <= {tx_data[N-2:0], 1'b0};
                        rx_data    <= {rx_data[N-2:0], spi_miso_i};
                        bit_cnt    <= bit_cnt + 1;
                    end
                end
                WAIT_FOR_NEXT: begin
                    spi_ssel_o <= 1'b1;
                    do_o       <= rx_data;
                    do_valid_o <= 1'b1;
                    wr_ack_o   <= 1'b0;
                end
            endcase
        end
    end

endmodule
