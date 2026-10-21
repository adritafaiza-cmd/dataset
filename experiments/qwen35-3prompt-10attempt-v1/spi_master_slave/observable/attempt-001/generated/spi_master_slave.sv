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

    // Clock domain definitions
    localparam PCLK_DIV = SPI_2X_CLK_DIV;
    
    // State encoding
    localparam IDLE = 2'd0;
    localparam TRANSFER = 2'd1;
    localparam WAIT_ACK = 2'd2;

    // State registers
    reg [1:0] p_state;
    reg [1:0] s_state;
    
    // Data registers
    reg [N-1:0] tx_data;
    reg [N-1:0] rx_data;
    reg tx_valid;
    reg rx_valid;
    
    // SPI shift registers
    reg [N-1:0] shift_reg_tx;
    reg [N-1:0] shift_reg_rx;
    reg shift_cnt;
    
    // Cross-domain signals
    reg p_state_valid;
    reg s_state_valid;
    reg p_state_ready;
    reg s_state_ready;
    
    // Internal clocks for state machines
    reg pclk_en;
    reg sclk_en;
    reg pclk_cnt;
    reg sclk_cnt;

    // ------------------------------------------------------------------
    // Clock Domain Crossing Logic (Async FIFO style for state)
    // ------------------------------------------------------------------
    
    // PCLK domain: Capture SCLK domain state
    reg [1:0] s_state_d1;
    reg [1:0] s_state_d2;
    reg s_state_valid_d1;
    reg s_state_valid_d2;
    
    // SCLK domain: Capture PCLK domain state
    reg [1:0] p_state_d1;
    reg [1:0] p_state_d2;
    reg p_state_valid_d1;
    reg p_state_valid_d2;

    // ------------------------------------------------------------------
    // PCLK Domain Logic
    // ------------------------------------------------------------------
    
    // Clock enable and counter for PCLK domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_cnt <= 0;
            p_state_valid <= 0;
        end else begin
            pclk_cnt <= pclk_cnt + 1;
            p_state_valid <= 1;
        end
    end

    // State Machine in PCLK domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            p_state <= IDLE;
            tx_valid <= 0;
            rx_valid <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
        end else begin
            case (p_state)
                IDLE: begin
                    if (wren_i && di_req_o) begin
                        p_state <= TRANSFER;
                        tx_valid <= 1;
                        rx_valid <= 0;
                        di_req_o <= 0;
                        wr_ack_o <= 0;
                        do_valid_o <= 0;
                        tx_data <= di_i;
                    end
                end
                
                TRANSFER: begin
                    if (s_state_ready) begin
                        p_state <= WAIT_ACK;
                        wr_ack_o <= 1;
                        do_valid_o <= 1;
                        do_o <= rx_data;
                        rx_valid <= 1;
                    end
                end
                
                WAIT_ACK: begin
                    if (!wren_i) begin
                        p_state <= IDLE;
                        tx_valid <= 0;
                        rx_valid <= 0;
                        di_req_o <= 0;
                        wr_ack_o <= 0;
                        do_valid_o <= 0;
                    end
                end
            endcase
        end
    end

    // Cross-domain: Capture SCLK state in PCLK
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            s_state_d1 <= 0;
            s_state_valid_d1 <= 0;
        end else begin
            s_state_d1 <= s_state_valid ? s_state : 0;
            s_state_valid_d1 <= s_state_valid;
        end
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            s_state_d2 <= 0;
            s_state_valid_d2 <= 0;
        end else begin
            s_state_d2 <= s_state_valid_d1 ? s_state_d1 : 0;
            s_state_valid_d2 <= s_state_valid_d1;
        end
    end

    // Cross-domain: Capture PCLK state in SCLK
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            p_state_d1 <= 0;
            p_state_valid_d1 <= 0;
        end else begin
            p_state_d1 <= p_state_valid ? p_state : 0;
            p_state_valid_d1 <= p_state_valid;
        end
    end

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            p_state_d2 <= 0;
            p_state_valid_d2 <= 0;
        end else begin
            p_state_d2 <= p_state_valid_d1 ? p_state_d1 : 0;
            p_state_valid_d2 <= p_state_valid_d1;
        end
    end

    // ------------------------------------------------------------------
    // SCLK Domain Logic
    // ------------------------------------------------------------------
    
    // Clock enable and counter for SCLK domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_cnt <= 0;
            s_state_valid <= 0;
        end else begin
            sclk_cnt <= sclk_cnt + 1;
            s_state_valid <= 1;
        end
    end

    // State Machine in SCLK domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            s_state <= IDLE;
            shift_cnt <= 0;
        end else begin
            case (s_state)
                IDLE: begin
                    if (p_state_ready) begin
                        s_state <= TRANSFER;
                        shift_cnt <= 0;
                    end
                end
                
                TRANSFER: begin
                    if (shift_cnt < N) begin
                        // Shift data
                        shift_reg_tx <= {shift_reg_tx[N-2:0], spi_mosi_o};
                        shift_reg_rx <= {spi_miso_i, shift_reg_rx[N-1:1]};
                        shift_cnt <= shift_cnt + 1;
                        
                        // Generate SPI signals
                        spi_sck_o <= 1'b1;
                        spi_mosi_o <= tx_data[shift_cnt];
                        
                        // Select logic: Deassert after transfer
                        if (shift_cnt == N - 1) begin
                            spi_ssel_o <= 1'b1;
                        end else begin
                            spi_ssel_o <= 1'b0;
                        end
                    end else begin
                        s_state <= WAIT_ACK;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'bz;
                        spi_ssel_o <= 1'b1;
                    end
                end
                
                WAIT_ACK: begin
                    if (p_state_ready) begin
                        s_state <= IDLE;
                        shift_cnt <= 0;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'bz;
                        spi_ssel_o <= 1'b1;
                    end
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Handshake Logic
    // ------------------------------------------------------------------
    
    // PCLK -> SCLK: State Ready
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            p_state_ready <= 0;
        end else begin
            // Ready if SCLK state is IDLE or WAIT_ACK (not transferring)
            p_state_ready <= (s_state == IDLE) || (s_state == WAIT_ACK);
        end
    end

    // SCLK -> PCLK: State Valid
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            s_state_ready <= 0;
        end else begin
            // Ready if PCLK state is IDLE or WAIT_ACK (not transferring)
            s_state_ready <= (p_state == IDLE) || (p_state == WAIT_ACK);
        end
    end

    // ------------------------------------------------------------------
    // Output Logic
    // ------------------------------------------------------------------
    
    // di_req_o is driven by PCLK domain
    // wr_ack_o is driven by PCLK domain
    // do_valid_o and do_o are driven by PCLK domain
    // spi_ssel_o, spi_sck_o, spi_mosi_o are driven by SCLK domain
    
    // Assignments are handled within the state machines above
    // But we need to ensure the outputs are stable when not active
    
    // In SCLK domain, outputs are driven directly
    // In PCLK domain, outputs are driven directly
    
    // Final output assignments (already done in state machines)
    // Just ensuring no glitches on clock edges
    assign spi_ssel_o = (s_state == TRANSFER) ? 1'b0 : 1'b1;
    assign spi_sck_o = (s_state == TRANSFER && shift_cnt < N) ? 1'b1 : 1'b0;
    assign spi_mosi_o = (s_state == TRANSFER && shift_cnt < N) ? tx_data[shift_cnt] : 1'bz;

endmodule
```<|im_end|>
