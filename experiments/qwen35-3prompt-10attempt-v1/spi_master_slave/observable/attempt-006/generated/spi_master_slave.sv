```verilog
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

    localparam WORD_WIDTH = N;
    localparam SPI_CLK_DIV = SPI_2X_CLK_DIV;
    localparam SPI_CLK_DIV_MINUS_1 = SPI_CLK_DIV - 1;

    // State encoding
    localparam IDLE = 2'b00;
    localparam SELECTING = 2'b01;
    localparam TRANSFERRING = 2'b10;
    localparam WAITING_FOR_ACK = 2'b11;

    reg [1:0] state;
    reg [WORD_WIDTH-1:0] tx_data;
    reg [WORD_WIDTH-1:0] rx_data;
    reg [WORD_WIDTH-1:0] last_rx_data;
    reg tx_en;
    reg tx_done;
    reg rx_done;
    reg [3:0] tx_count;
    reg [3:0] rx_count;
    reg ssel_active;
    reg [WORD_WIDTH-1:0] shift_reg_tx;
    reg [WORD_WIDTH-1:0] shift_reg_rx;
    reg [3:0] shift_count;

    // Clock domain crossing registers for state machine output
    reg [1:0] state_ff1;
    reg [1:0] state_ff2;
    reg [WORD_WIDTH-1:0] tx_data_ff1;
    reg [WORD_WIDTH-1:0] tx_data_ff2;
    reg tx_en_ff1;
    reg tx_en_ff2;
    reg tx_done_ff1;
    reg tx_done_ff2;
    reg rx_done_ff1;
    reg rx_done_ff2;
    reg ssel_active_ff1;
    reg ssel_active_ff2;
    reg [3:0] tx_count_ff1;
    reg [3:0] tx_count_ff2;
    reg [3:0] rx_count_ff1;
    reg [3:0] rx_count_ff2;
    reg [WORD_WIDTH-1:0] shift_reg_tx_ff1;
    reg [WORD_WIDTH-1:0] shift_reg_tx_ff2;
    reg [WORD_WIDTH-1:0] shift_reg_rx_ff1;
    reg [WORD_WIDTH-1:0] shift_reg_rx_ff2;
    reg [3:0] shift_count_ff1;
    reg [3:0] shift_count_ff2;

    // Synchronous FIFO for data transfer between clock domains
    // Depth: 4 words (sufficient for typical SPI timing)
    reg [WORD_WIDTH-1:0] fifo_data;
    reg [2:0] fifo_count;
    reg fifo_wr_en;
    reg fifo_rd_en;
    reg fifo_full;
    reg fifo_empty;
    reg [2:0] fifo_count_ff1;
    reg [2:0] fifo_count_ff2;

    // SPI Control Signals
    reg spi_sck_int;
    reg spi_mosi_int;
    reg spi_miso_int;
    reg spi_ssel_int;

    // --- Parallel Interface Logic (PCLK Domain) ---

    // State Machine
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            tx_data <= 0;
            rx_data <= 0;
            last_rx_data <= 0;
            tx_en <= 0;
            tx_done <= 0;
            rx_done <= 0;
            tx_count <= 0;
            rx_count <= 0;
            ssel_active <= 0;
            shift_count <= 0;
            shift_reg_tx <= 0;
            shift_reg_rx <= 0;
        end else begin
            state <= state_ff1;
            tx_data <= tx_data_ff1;
            rx_data <= rx_data_ff2;
            last_rx_data <= rx_data;
            tx_en <= tx_en_ff1;
            tx_done <= tx_done_ff1;
            rx_done <= rx_done_ff1;
            tx_count <= tx_count_ff1;
            rx_count <= rx_count_ff1;
            ssel_active <= ssel_active_ff1;
            shift_count <= shift_count_ff1;
            shift_reg_tx <= shift_reg_tx_ff1;
            shift_reg_rx <= shift_reg_rx_ff1;
        end
    end

    // Data Input Handling
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_en <= 0;
        end else if (state == IDLE && wren_i) begin
            tx_en <= 1;
            tx_data <= di_i;
        end else if (tx_en && tx_done) begin
            tx_en <= 0;
        end
    end

    // Data Output Handling
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_o <= 0;
            do_o <= 0;
            wr_ack_o <= 0;
        end else if (rx_done) begin
            do_valid_o <= 1;
            do_o <= last_rx_data;
            wr_ack_o <= 1;
        end else begin
            do_valid_o <= 0;
            wr_ack_o <= 0;
        end
    end

    // State Machine Logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (tx_en) begin
                    state <= SELECTING;
                    ssel_active <= 1;
                    tx_count <= 0;
                    rx_count <= 0;
                    shift_count <= 0;
                    shift_reg_tx <= tx_data;
                    shift_reg_rx <= 0;
                end else begin
                    state <= IDLE;
                    ssel_active <= 0;
                end
            end

            SELECTING: begin
                if (tx_count == 0) begin
                    state <= TRANSFERRING;
                    tx_count <= 0;
                    rx_count <= 0;
                    shift_count <= 0;
                    shift_reg_tx <= tx_data;
                    shift_reg_rx <= 0;
                end else begin
                    state <= TRANSFERRING;
                end
            end

            TRANSFERRING: begin
                if (tx_count == WORD_WIDTH) begin
                    state <= WAITING_FOR_ACK;
                    tx_done <= 1;
                    rx_done <= 0;
                    last_rx_data <= shift_reg_rx;
                end else begin
                    state <= TRANSFERRING;
                end
            end

            WAITING_FOR_ACK: begin
                if (tx_done) begin
                    state <= IDLE;
                    tx_done <= 0;
                    rx_done <= 1;
                    ssel_active <= 0;
                end else begin
                    state <= WAITING_FOR_ACK;
                end
            end

            default: state <= IDLE;
        endcase
    end

    // --- SPI Interface Logic (SCLK Domain) ---

    // Clock Domain Crossing: Capture state outputs
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state_ff1 <= IDLE;
            state_ff2 <= IDLE;
            tx_data_ff1 <= 0;
            tx_data_ff2 <= 0;
            tx_en_ff1 <= 0;
            tx_en_ff2 <= 0;
            tx_done_ff1 <= 0;
            tx_done_ff2 <= 0;
            rx_done_ff1 <= 0;
            rx_done_ff2 <= 0;
            ssel_active_ff1 <= 0;
            ssel_active_ff2 <= 0;
            tx_count_ff1 <= 0;
            tx_count_ff2 <= 0;
            rx_count_ff1 <= 0;
            rx_count_ff2 <= 0;
            shift_reg_tx_ff1 <= 0;
            shift_reg_tx_ff2 <= 0;
            shift_reg_rx_ff1 <= 0;
            shift_reg_rx_ff2 <= 0;
            shift_count_ff1 <= 0;
            shift_count_ff2 <= 0;
        end else begin
            state_ff1 <= state_ff2;
            state_ff2 <= state;
            tx_data_ff1 <= tx_data_ff2;
            tx_data_ff2 <= tx_data;
            tx_en_ff1 <= tx_en_ff2;
            tx_en_ff2 <= tx_en;
            tx_done_ff1 <= tx_done_ff2;
            tx_done_ff2 <= tx_done;
            rx_done_ff1 <= rx_done_ff2;
            rx_done_ff2 <= rx_done;
            ssel_active_ff1 <= ssel_active_ff2;
            ssel_active_ff2 <= ssel_active;
            tx_count_ff1 <= tx_count_ff2;
            tx_count_ff2 <= tx_count;
            rx_count_ff1 <= rx_count_ff2;
            rx_count_ff2 <= rx_count;
            shift_reg_tx_ff1 <= shift_reg_tx_ff2;
            shift_reg_tx_ff2 <= shift_reg_tx;
            shift_reg_rx_ff1 <= shift_reg_rx_ff2;
            shift_reg_rx_ff2 <= shift_reg_rx;
            shift_count_ff1 <= shift_count_ff2;
            shift_count_ff2 <= shift_count;
        end
    end

    // Clock Domain Crossing: Capture FIFO status
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            fifo_count_ff1 <= 0;
            fifo_count_ff2 <= 0;
        end else begin
            fifo_count_ff1 <= fifo_count_ff2;
            fifo_count_ff2 <= fifo_count;
        end
    end

    // SPI Signal Generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            spi_ssel_o <= 1;
        end else begin
            spi_sck_o <= spi_sck_int;
            spi_mosi_o <= spi_mosi_int;
            spi_ssel_o <= spi_ssel_int;
        end
    end

    // SPI Signal Logic
    always @(*) begin
        spi_sck_int = 0;
        spi_mosi_int = 0;
        spi_mosi_int = spi_mosi_int; // Default
        spi_ssel_int = 1;

        if (state == IDLE) begin
            spi_ssel_int = 1;
        end else if (state == SELECTING || state == TRANSFERRING || state == WAITING_FOR_ACK) begin
            spi_ssel_int = 0;
        end

        if (state == TRANSFERRING) begin
            spi_sck_int = 1;
            if (shift_count < WORD_WIDTH) begin
                spi_mosi_int = shift_reg_tx[shift_count];
                shift_reg_rx[shift_count] = spi_miso_i;
                shift_count = shift_count + 1;
            end else begin
                spi_mosi_int = 0;
                shift_count = 0;
                shift_reg_tx = tx_data;
                shift_reg_rx = 0;
            end
        end else begin
            spi_sck_int = 0;
            shift_count = 0;
            shift_reg_tx = 0;
            shift_reg_rx = 0;
        end
    end

    // --- FIFO Logic (PCLK Domain) ---
    // Note: In this specific design, the FIFO is used to buffer the received data
    // from the SPI domain back to the parallel domain. However, since we are using
    // a simple state machine with cross-domain registers, we can simplify the
    // FIFO logic to just hold the last received word until the transfer is complete.
    // The cross-domain registers (rx_data_ff1, rx_data_ff2) effectively act as a
    // 2-deep FIFO for the received data.

    // We need to ensure that the received data is stable before it is read by the
    // parallel interface. The cross-domain registers handle this.

    // --- SPI Control Signals ---
    // di_req_o: Request to send data
    // wr_ack_o: Acknowledge that data has been received
    // do_valid_o: Valid output data
    // do_o: Output data

    // The logic for these signals is already handled in the Parallel Interface Logic section.
    // di_req_o is driven by tx_en (which is set when wren_i is high and state is IDLE)
    // wr_ack_o is driven by rx_done
    // do_valid_o is driven by rx_done
    // do_o is driven by last_rx_data when rx_done is high

    // Assignments for output registers
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 0;
        end else if (tx_en) begin
            di_req_o <= 1;
        end else begin
            di_req_o <= 0;
        end
    end

    // The wr_ack_o, do_valid_o, and do_o are already assigned in the Data Output Handling block.
    // However, to be explicit and ensure they are driven correctly:
    // wr_ack_o is set when rx_done is high.
    // do_valid_o is set when rx_done is high.
    // do_o is set to last_rx_data when rx_done is high.

    // Re-assigning to ensure clarity and correctness in the always block
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
        end else if (rx_done) begin
            wr_ack_o <= 1;
            do_valid_o <= 1;
            do_o <= last_rx_data;
        end else begin
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
        end
    end

endmodule
```<|im_end|>
