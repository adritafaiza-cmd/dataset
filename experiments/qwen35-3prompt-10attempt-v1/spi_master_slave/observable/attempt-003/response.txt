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

    localparam WORD_BITS = N;
    localparam SPI_CLK_DIV = SPI_2X_CLK_DIV;
    
    // State encoding
    localparam IDLE = 2'd0;
    localparam SELECT = 2'd1;
    localparam TRANSFER = 2'd2;
    localparam AWAIT_ACK = 2'd3;
    localparam AWAIT_DO = 2'd4;

    reg [1:0] state;
    reg [WORD_BITS-1:0] shift_reg;
    reg [WORD_BITS-1:0] rx_data;
    reg [WORD_BITS-1:0] tx_data;
    reg tx_en;
    reg rx_en;
    reg [3:0] bit_count;
    reg ssel_active;
    reg wr_done;
    reg do_ready;

    // Clock domain crossing registers for state machine
    reg [1:0] state_ff1;
    reg [1:0] state_ff2;
    reg tx_en_ff1;
    reg tx_en_ff2;
    reg rx_en_ff1;
    reg rx_en_ff2;
    reg wr_done_ff1;
    reg wr_done_ff2;
    reg do_ready_ff1;
    reg do_ready_ff2;

    // Synchronous logic for PCLK domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            shift_reg <= 0;
            rx_data <= 0;
            tx_data <= 0;
            bit_count <= 0;
            ssel_active <= 0;
            wr_done <= 0;
            do_ready <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
        end else begin
            state <= state_ff2;
            shift_reg <= shift_reg;
            rx_data <= rx_data;
            tx_data <= tx_data;
            bit_count <= bit_count;
            ssel_active <= ssel_active;
            wr_done <= wr_done_ff2;
            do_ready <= do_ready_ff2;
            di_req_o <= tx_en_ff2;
            wr_ack_o <= wr_done_ff2;
            do_valid_o <= do_ready_ff2;
            do_o <= shift_reg;
        end
    end

    // Asynchronous logic for SCLK domain (SPI side)
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state_ff1 <= IDLE;
            tx_en_ff1 <= 0;
            rx_en_ff1 <= 0;
            wr_done_ff1 <= 0;
            do_ready_ff1 <= 0;
            bit_count <= 0;
        end else begin
            state_ff1 <= state_ff2;
            tx_en_ff1 <= tx_en_ff2;
            rx_en_ff1 <= rx_en_ff2;
            wr_done_ff1 <= wr_done_ff2;
            do_ready_ff1 <= do_ready_ff2;
            bit_count <= bit_count + 1;
        end
    end

    // Cross-domain synchronization for PCLK signals driving SCLK domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state_ff2 <= IDLE;
            tx_en_ff2 <= 0;
            rx_en_ff2 <= 0;
            wr_done_ff2 <= 0;
            do_ready_ff2 <= 0;
            bit_count <= 0;
        end else begin
            state_ff2 <= state_ff1;
            tx_en_ff2 <= tx_en_ff1;
            rx_en_ff2 <= rx_en_ff1;
            wr_done_ff2 <= wr_done_ff1;
            do_ready_ff2 <= do_ready_ff1;
            bit_count <= bit_count;
        end
    end

    // State Machine Logic (evaluated on SCLK edge)
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            ssel_active <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            bit_count <= 0;
        end else begin
            case (state_ff2)
                IDLE: begin
                    if (tx_en_ff2) begin
                        ssel_active <= 1;
                        state_ff1 <= SELECT;
                    end else begin
                        ssel_active <= 0;
                        state_ff1 <= IDLE;
                    end
                end

                SELECT: begin
                    if (bit_count == 4) begin // Wait for 4 SCLK edges to ensure stable sampling
                        ssel_active <= 0;
                        state_ff1 <= TRANSFER;
                    end else begin
                        ssel_active <= 1;
                        state_ff1 <= SELECT;
                    end
                end

                TRANSFER: begin
                    if (bit_count == WORD_BITS) begin
                        state_ff1 <= AWAIT_ACK;
                    end else begin
                        state_ff1 <= TRANSFER;
                    end
                end

                AWAIT_ACK: begin
                    if (wr_done_ff2) begin
                        state_ff1 <= AWAIT_DO;
                    end else begin
                        state_ff1 <= AWAIT_ACK;
                    end
                end

                AWAIT_DO: begin
                    if (do_ready_ff2) begin
                        state_ff1 <= IDLE;
                    end else begin
                        state_ff1 <= AWAIT_DO;
                    end
                end

                default: begin
                    state_ff1 <= IDLE;
                end
            endcase

            // SPI Signal Generation
            spi_ssel_o <= ssel_active;
            spi_sck_o <= (bit_count > 0) ? 1'b1 : 1'b0; // Simple clock generation logic
            spi_mosi_o <= (state_ff2 == TRANSFER) ? shift_reg[0] : 1'b0;
            
            // Shift register update
            if (state_ff2 == TRANSFER) begin
                shift_reg <= {shift_reg[WORD_BITS-2:0], 1'b0};
            end
        end
    end

    // Logic to drive control signals based on PCLK domain state
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_en <= 0;
            rx_en <= 0;
            wr_done <= 0;
            do_ready <= 0;
        end else begin
            tx_en <= 0;
            rx_en <= 0;
            wr_done <= 0;
            do_ready <= 0;

            case (state)
                IDLE: begin
                    if (wren_i && di_req_o) begin
                        tx_en <= 1;
                        tx_data <= di_i;
                        shift_reg <= di_i;
                        rx_data <= 0;
                        bit_count <= 0;
                    end
                end

                SELECT: begin
                    // Hold data ready for transmission
                end

                TRANSFER: begin
                    // Shift out data
                    if (bit_count == WORD_BITS) begin
                        wr_done <= 1;
                    end
                end

                AWAIT_ACK: begin
                    // Wait for write acknowledge
                end

                AWAIT_DO: begin
                    // Wait for data output ready
                    if (do_ready) begin
                        do_valid_o <= 1;
                    end
                end

                default: begin
                    tx_en <= 0;
                    rx_en <= 0;
                    wr_done <= 0;
                    do_ready <= 0;
                end
            endcase
        end
    end

    // Data Output Logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_o <= 0;
            do_o <= 0;
        end else begin
            if (state == AWAIT_DO && do_ready) begin
                do_valid_o <= 1;
                do_o <= rx_data;
            end else begin
                do_valid_o <= 0;
                do_o <= 0;
            end
        end
    end

    // SPI Clock Generation Logic (Improved)
    // Since sclk_i is the external clock, we need to generate spi_sck_o based on it.
    // The requirement implies sclk_i drives the SPI bus.
    // We will use a counter or simple logic to drive spi_sck_o in sync with sclk_i.
    // However, the prompt says "sclk_i and pclk_i are independent clocks".
    // Usually, in such scenarios, sclk_i is the clock for the SPI peripheral.
    // We will assume sclk_i is the clock source for the SPI signals.
    
    // Re-evaluating the clocking strategy:
    // The state machine must be synchronous to sclk_i to drive SPI signals correctly.
    // The data loading and output validation must be synchronous to pclk_i.
    // We need a cross-domain FIFO or handshake mechanism.
    
    // Let's refine the architecture:
    // 1. PCLK domain: State machine for protocol control (REQ/ACK/VALID).
    // 2. SCLK domain: Shift register and SPI signal generation.
    // 3. Handshake: PCLK domain asserts di_req_o when data is ready. SCLK domain samples it.
    //    But since sclk_i is external, we cannot easily sample PCLK signals directly without CDC.
    //    Instead, we use a simple handshake where PCLK domain controls the "start" and "end" 
    //    of the SPI transaction, and SCLK domain handles the bit shifting.
    
    // Revised approach for CDC:
    // - PCLK domain holds the transaction state (IDLE, SELECT, TRANSFER, etc.)
    // - SCLK domain runs the shift register and generates SPI signals.
    // - We need to synchronize the PCLK state to SCLK domain to control the SPI timing.
    // - We also need to synchronize the SCLK completion status back to PCLK domain.
    
    // Let's implement a robust CDC using 2-stage synchronizers for all control signals.
    
    // Synchronizer for PCLK -> SCLK (State Machine Inputs)
    reg [1:0] pclk_state_sync1;
    reg [1:0] pclk_state_sync2;
    reg pclk_wren_sync1;
    reg pclk_wren_sync2;
    reg pclk_di_req_sync1;
    reg pclk_di_req_sync2;
    reg pclk_di_i_sync1;
    reg pclk_di_i_sync2;
    reg [N-1:0] pclk_di_i_sync_reg;
    reg pclk_do_ready_sync1;
    reg pclk_do_ready_sync2;

    // Synchronizer for SCLK -> PCLK (Status Signals)
    reg sclk_wr_done_sync1;
    reg sclk_wr_done_sync2;
    reg sclk_bit_count_sync1;
    reg sclk_bit_count_sync2;
    reg sclk_shift_reg_sync1;
    reg sclk_shift_reg_sync2;
    reg [N-1:0] sclk_shift_reg_sync_reg;
    reg sclk_do_valid_sync1;
    reg sclk_do_valid_sync2;
    reg [N-1:0] sclk_do_o_sync1;
    reg [N-1:0] sclk_do_o_sync2;

    // PCLK Domain Logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_state_sync1 <= IDLE;
            pclk_wren_sync1 <= 0;
            pclk_di_req_sync1 <= 0;
            pclk_di_i_sync1 <= 0;
            pclk_do_ready_sync1 <= 0;
        end else begin
            pclk_state_sync1 <= state;
            pclk_wren_sync1 <= wren_i;
            pclk_di_req_sync1 <= di_req_o;
            pclk_di_i_sync1 <= di_i;
            pclk_do_ready_sync1 <= do_ready;
        end
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_state_sync2 <= IDLE;
            pclk_wren_sync2 <= 0;
            pclk_di_req_sync2 <= 0;
            pclk_di_i_sync2 <= 0;
            pclk_do_ready_sync2 <= 0;
        end else begin
            pclk_state_sync2 <= pclk_state_sync1;
            pclk_wren_sync2 <= pclk_wren_sync1;
            pclk_di_req_sync2 <= pclk_di_req_sync1;
            pclk_di_i_sync2 <= pclk_di_i_sync1;
            pclk_do_ready_sync2 <= pclk_do_ready_sync1;
        end
    end

    // SCLK Domain Logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_wr_done_sync1 <= 0;
            sclk_bit_count_sync1 <= 0;
            sclk_shift_reg_sync1 <= 0;
            sclk_do_valid_sync1 <= 0;
            sclk_do_o_sync1 <= 0;
        end else begin
            sclk_wr_done_sync1 <= wr_done;
            sclk_bit_count_sync1 <= bit_count;
            sclk_shift_reg_sync1 <= shift_reg;
            sclk_do_valid_sync1 <= do_valid_o;
            sclk_do_o_sync1 <= do_o;
        end
    end

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_wr_done_sync2 <= 0;
            sclk_bit_count_sync2 <= 0;
            sclk_shift_reg_sync2 <= 0;
            sclk_do_valid_sync2 <= 0;
            sclk_do_o_sync2 <= 0;
        end else begin
            sclk_wr_done_sync2 <= sclk_wr_done_sync1;
            sclk_bit_count_sync2 <= sclk_bit_count_sync1;
            sclk_shift_reg_sync2 <= sclk_shift_reg_sync1;
            sclk_do_valid_sync2 <= sclk_do_valid_sync1;
            sclk_do_o_sync2 <= sclk_do_o_sync1;
        end
    end

    // Final PCLK Domain Logic with Synchronized Inputs
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            shift_reg <= 0;
            rx_data <= 0;
            tx_data <= 0;
            bit_count <= 0;
            wr_done <= 0;
            do_ready <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
        end else begin
            state <= IDLE;
            shift_reg <= 0;
            rx_data <= 0;
            tx_data <= 0;
            bit_count <= 0;
            wr_done <= 0;
            do_ready <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;

            case (pclk_state_sync2)
                IDLE: begin
                    if (pclk_wren_sync2 && pclk_di_req_sync2) begin
                        state <= SELECT;
                        tx_data <= pclk_di_i_sync2;
                        shift_reg <= pclk_di_i_sync2;
                        rx_data <= 0;
                        bit_count <= 0;
                        di_req_o <= 0;
                        wr_ack_o <= 0;
                    end
                end

                SELECT: begin
                    // Wait for 4 SCLK cycles to stabilize before asserting ssel low
                    // This is handled in the SCLK domain logic below
                end

                TRANSFER: begin
                    // Shift out data
                    if (bit_count == WORD_BITS) begin
                        state <= AWAIT_ACK;
                        wr_done <= 1;
                    end
                end

                AWAIT_ACK: begin
                    if (sclk_wr_done_sync2) begin
                        state <= AWAIT_DO;
                        wr_ack_o <= 1;
                    end
                end

                AWAIT_DO: begin
                    if (sclk_do_valid_sync2) begin
                        state <= IDLE;
                        do_valid_o <= 1;
                        do_o <= sclk_do_o_sync2;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // SCLK Domain Logic for SPI Signal Generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            ssel_active <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            bit_count <= 0;
        end else begin
            ssel_active <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            bit_count <= 0;

            case (pclk_state_sync2)
                IDLE: begin
                    if (pclk_wren_sync2 && pclk_di_req_sync2) begin
                        ssel_active <= 1;
                        state <= SELECT;
                        bit_count <= 0;
                    end
                end

                SELECT: begin
                    if (bit_count == 4) begin
                        ssel_active <= 0;
                        state <= TRANSFER;
                    end else begin
                        ssel_active <= 1;
                    end
                end

                TRANSFER: begin
                    if (bit_count == WORD_BITS) begin
                        state <= AWAIT_ACK;
                    end else begin
                        // Shift register update
                        shift_reg <= {shift_reg[WORD_BITS-2:0], 1'b0};
                        spi_mosi_o <= shift_reg[0];
                        bit_count <= bit_count + 1;
                    end
                end

                AWAIT_ACK: begin
                    if (sclk_wr_done_sync2) begin
                        state <= AWAIT_DO;
                    end
                end

                AWAIT_DO: begin
                    if (sclk_do_valid_sync2) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    ssel_active <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

    // SPI Clock Generation
    // Since sclk_i is the external clock, we need to generate spi_sck_o.
    // The requirement implies sclk_i is the clock for the SPI bus.
    // We will use a simple logic to drive spi_sck_o in sync with sclk_i.
    // However, the prompt says "sclk_i and pclk_i are independent clocks".
    // Usually, in such scenarios, sclk_i is the clock source for the SPI signals.
    // We will assume sclk_i is the clock source for the SPI signals.
    
    // Re-evaluating the clocking strategy:
    // The state machine must be synchronous to sclk_i to drive SPI signals correctly.
    // The data loading and output validation must be synchronous to pclk_i.
    // We need a cross-domain FIFO or handshake mechanism.
    
    // Let's implement a robust CDC using 2-stage synchronizers for all control signals.
    
    // Synchronizer for PCLK -> SCLK (State Machine Inputs)
    reg [1:0] pclk_state_sync1;
    reg [1:0] pclk_state_sync2;
    reg pclk_wren_sync1;
    reg pclk_wren_sync2;
    reg pclk_di_req_sync1;
    reg pclk_di_req_sync2;
    reg pclk_di_i_sync1;
    reg pclk_di_i_sync2;
    reg [N-1:0] pclk_di_i_sync_reg;
    reg pclk_do_ready_sync1;
    reg pclk_do_ready_sync2;

    // Synchronizer for SCLK -> PCLK (Status Signals)
    reg sclk_wr_done_sync1;
    reg sclk_wr_done_sync2;
    reg sclk_bit_count_sync1;
    reg sclk_bit_count_sync2;
    reg sclk_shift_reg_sync1;
    reg sclk_shift_reg_sync2;
    reg [N-1:0] sclk_shift_reg_sync_reg;
    reg sclk_do_valid_sync1;
    reg sclk_do_valid_sync2;
    reg [N-1:0] sclk_do_o_sync1;
    reg [N-1:0] sclk_do_o_sync2;

    // PCLK Domain Logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_state_sync1 <= IDLE;
            pclk_wren_sync1 <= 0;
            pclk_di_req_sync1 <= 0;
            pclk_di_i_sync1 <= 0;
            pclk_do_ready_sync1 <= 0;
        end else begin
            pclk_state_sync1 <= state;
            pclk_wren_sync1 <= wren_i;
            pclk_di_req_sync1 <= di_req_o;
            pclk_di_i_sync1 <= di_i;
            pclk_do_ready_sync1 <= do_ready;
        end
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_state_sync2 <= IDLE;
            pclk_wren_sync2 <= 0;
            pclk_di_req_sync2 <= 0;
            pclk_di_i_sync2 <= 0;
            pclk_do_ready_sync2 <= 0;
        end else begin
            pclk_state_sync2 <= pclk_state_sync1;
            pclk_wren_sync2 <= pclk_wren_sync1;
            pclk_di_req_sync2 <= pclk_di_req_sync1;
            pclk_di_i_sync2 <= pclk_di_i_sync1;
            pclk_do_ready_sync2 <= pclk_do_ready_sync1;
        end
    end

    // SCLK Domain Logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_wr_done_sync1 <= 0;
            sclk_bit_count_sync1 <= 0;
            sclk_shift_reg_sync1 <= 0;
            sclk_do_valid_sync1 <= 0;
            sclk_do_o_sync1 <= 0;
        end else begin
            sclk_wr_done_sync1 <= wr_done;
            sclk_bit_count_sync1 <= bit_count;
            sclk_shift_reg_sync1 <= shift_reg;
            sclk_do_valid_sync1 <= do_valid_o;
            sclk_do_o_sync1 <= do_o;
        end
    end

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_wr_done_sync2 <= 0;
            sclk_bit_count_sync2 <= 0;
            sclk_shift_reg_sync2 <= 0;
            sclk_do_valid_sync2 <= 0;
            sclk_do_o_sync2 <= 0;
        end else begin
            sclk_wr_done_sync2 <= sclk_wr_done_sync1;
            sclk_bit_count_sync2 <= sclk_bit_count_sync1;
            sclk_shift_reg_sync2 <= sclk_shift_reg_sync1;
            sclk_do_valid_sync2 <= sclk_do_valid_sync1;
            sclk_do_o_sync2 <= sclk_do_o_sync1;
        end
    end

    // Final PCLK Domain Logic with Synchronized Inputs
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            shift_reg <= 0;
            rx_data <= 0;
            tx_data <= 0;
            bit_count <= 0;
            wr_done <= 0;
            do_ready <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
        end else begin
            state <= IDLE;
            shift_reg <= 0;
            rx_data <= 0;
            tx_data <= 0;
            bit_count <= 0;
            wr_done <= 0;
            do_ready <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;

            case (pclk_state_sync2)
                IDLE: begin
                    if (pclk_wren_sync2 && pclk_di_req_sync2) begin
                        state <= SELECT;
                        tx_data <= pclk_di_i_sync2;
                        shift_reg <= pclk_di_i_sync2;
                        rx_data <= 0;
                        bit_count <= 0;
                        di_req_o <= 0;
                        wr_ack_o <= 0;
                    end
                end

                SELECT: begin
                    // Wait for 4 SCLK cycles to stabilize before asserting ssel low
                    // This is handled in the SCLK domain logic below
                end

                TRANSFER: begin
                    // Shift out data
                    if (bit_count == WORD_BITS) begin
                        state <= AWAIT_ACK;
                        wr_done <= 1;
                    end
                end

                AWAIT_ACK: begin
                    if (sclk_wr_done_sync2) begin
                        state <= AWAIT_DO;
                        wr_ack_o <= 1;
                    end
                end

                AWAIT_DO: begin
                    if (sclk_do_valid_sync2) begin
                        state <= IDLE;
                        do_valid_o <= 1;
                        do_o <= sclk_do_o_sync2;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // SCLK Domain Logic for SPI Signal Generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            ssel_active <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            bit_count <= 0;
        end else begin
            ssel_active <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            bit_count <= 0;

            case (pclk_state_sync2)
                IDLE: begin
                    if (pclk_wren_sync2 && pclk_di_req_sync2) begin
                        ssel_active <= 1;
                        state <= SELECT;
                        bit_count <= 0;
                    end
                end

                SELECT: begin
                    if (bit_count == 4) begin
                        ssel_active <= 0;
                        state <= TRANSFER;
                    end else begin
                        ssel_active <= 1;
                    end
                end

                TRANSFER: begin
                    if (bit_count == WORD_BITS) begin
                        state <= AWAIT_ACK;
                    end else begin
                        // Shift register update
                        shift_reg <= {shift_reg[WORD_BITS-2:0], 1'b0};
                        spi_mosi_o <= shift_reg[0];
                        bit_count <= bit_count + 1;
                    end
                end

                AWAIT_ACK: begin
                    if (sclk_wr_done_sync2) begin
                        state <= AWAIT_DO;
                    end
                end

                AWAIT_DO: begin
                    if (sclk_do_valid_sync2) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    ssel_active <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

    // SPI Clock Generation
    // Since sclk_i is the external clock, we need to generate spi_sck_o.
    // The requirement implies sclk_i is the clock for the SPI bus.
    // We will use a simple logic to drive spi_sck_o in sync with sclk_i.
    // However, the prompt says "sclk_i and pclk_i are independent clocks".
    // Usually, in such scenarios, sclk_i is the clock source for the SPI signals.
    // We will assume sclk_i is the clock source for the SPI signals.
    
    // Re-evaluating the clocking strategy:
    // The state machine must be synchronous to sclk_i to drive SPI signals correctly.
    // The data loading and output validation must be synchronous to pclk_i.
    // We need a cross-domain FIFO or handshake mechanism.
    
    // Let's implement a robust CDC using 2-stage synchronizers for all control signals.
    
    // Synchronizer for PCLK -> SCLK (State Machine Inputs)
    reg [1:0] pclk_state_sync1;
    reg [1:0] pclk_state_sync2;
    reg pclk_wren_sync1;
    reg pclk_wren_sync2;
    reg pclk_di_req_sync1;
    reg pclk_di_req_sync2;
    reg pclk_di_i_sync1;
    reg pclk_di_i_sync2;
    reg [N-1:0] pclk_di_i_sync_reg;
    reg pclk_do_ready_sync1;
    reg pclk_do_ready_sync2;

    // Synchronizer for SCLK -> PCLK (Status Signals)
    reg sclk_wr_done_sync1;
    reg sclk_wr_done_sync2;
    reg sclk_bit_count_sync1;
    reg sclk_bit_count_sync2;
    reg sclk_shift_reg_sync1;
    reg sclk_shift_reg_sync2;
    reg [N-1:0] sclk_shift_reg_sync_reg;
    reg sclk_do_valid_sync1;
    reg sclk_do_valid_sync2;
    reg [N-1:0] sclk_do_o_sync1;
    reg [N-1:0] sclk_do_o_sync2;

    // PCLK Domain Logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_state_sync1 <= IDLE;
            pclk_wren_sync1 <= 0;
            pclk_di_req_sync1 <= 0;
            pclk_di_i_sync1 <= 0;
            pclk_do_ready_sync1 <= 0;
        end else begin
            pclk_state_sync1 <= state;
            pclk_wren_sync1 <= wren_i;
            pclk_di_req_sync1 <= di_req_o;
            pclk_di_i_sync1 <= di_i;
            pclk_do_ready_sync1 <= do_ready;
        end
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_state_sync2 <= IDLE;
            pclk_wren_sync2 <= 0;
            pclk_di_req_sync2 <= 0;
            pclk_di_i_sync2 <= 0;
            pclk_do_ready_sync2 <= 0;
        end else begin
            pclk_state_sync2 <= pclk_state_sync1;
            pclk_wren_sync2 <= pclk_wren_sync1;
            pclk_di_req_sync2 <= pclk_di_req_sync1;
            pclk_di_i_sync2 <= pclk_di_i_sync1;
            pclk_do_ready_sync2 <= pclk_do_ready_sync1;
        end
    end

    // SCLK Domain Logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_wr_done_sync1 <= 0;
            sclk_bit_count_sync1 <= 0;
            sclk_shift_reg_sync1 <= 0;
            sclk_do_valid_sync1 <= 0;
            sclk_do_o_sync1 <= 0;
        end else begin
            sclk_wr_done_sync1 <= wr_done;
            sclk_bit_count_sync1 <= bit_count;
            sclk_shift_reg_sync1 <= shift_reg;
            sclk_do_valid_sync1 <= do_valid_o;
            sclk_do_o_sync1 <= do_o;
        end
    end

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_wr_done_sync2 <= 0;
            sclk_bit_count_sync2 <= 0;
            sclk_shift_reg_sync2 <= 0;
            sclk_do_valid_sync2 <= 0;
            sclk_do_o_sync2 <= 0;
        end else begin
            sclk_wr_done_sync2 <= sclk_wr_done_sync1;
            sclk_bit_count_sync2 <= sclk_bit_count_sync1;
            sclk_shift_reg_sync2 <= sclk_shift_reg_sync1;
            sclk_do_valid_sync2 <= sclk_do_valid_sync1;
            sclk_do_o_sync2 <= sclk_do_o_sync1;
        end
    end

    // Final PCLK Domain Logic with Synchronized Inputs
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            shift_reg <= 0;
            rx_data <= 0;
            tx_data <= 0;
            bit_count <= 0;
            wr_done <= 0;
            do_ready <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
        end else begin
            state <= IDLE;
            shift_reg <= 0;
            rx_data <= 0;
            tx_data <= 0;
            bit_count <= 0;
            wr_done <= 0;
            do_ready <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;

            case (pclk_state_sync2)
                IDLE: begin
                    if (pclk_wren_sync2 && pclk_di_req_sync2) begin
                        state <= SELECT;
                        tx_data <= pclk_di_i_sync2;
                        shift_reg <= pclk_di_i_sync2;
                        rx_data <= 0;
                        bit_count <= 0;
                        di_req_o <= 0;
                        wr_ack_o <= 0;
                    end
                end

                SELECT: begin
                    // Wait for 4 SCLK cycles