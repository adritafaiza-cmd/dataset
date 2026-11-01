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

    // ========================================================================
    // Reset Synchronization
    // ========================================================================
    
    // Sclk domain reset
    reg [1:0] sclk_rst_sync;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sclk_rst_sync <= 2'b11;
        else
            sclk_rst_sync <= {sclk_rst_sync[0], 1'b0};
    end
    wire sclk_rst = sclk_rst_sync[1];

    // Pclk domain reset
    reg [1:0] pclk_rst_sync;
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            pclk_rst_sync <= 2'b11;
        else
            pclk_rst_sync <= {pclk_rst_sync[0], 1'b0};
    end
    wire pclk_rst = pclk_rst_sync[1];

    // ========================================================================
    // Sclk Domain: SPI Master Logic
    // ========================================================================
    
    // State machine states
    localparam S_IDLE    = 2'd0;
    localparam S_ACTIVE  = 2'd1;
    localparam S_DONE    = 2'd2;

    reg [1:0] sclk_state;
    reg [N-1:0] sclk_tx_shift;
    reg [N-1:0] sclk_rx_shift;
    reg [3:0] sclk_bit_count;
    reg [3:0] sclk_div_count;
    reg sclk_sck_phase;
    reg sclk_ssel_int;
    reg sclk_mosi_int;
    reg sclk_tx_valid;
    reg [N-1:0] sclk_tx_data;
    reg sclk_rx_valid;
    reg [N-1:0] sclk_rx_data;
    reg sclk_done_pulse;

    // Handshake signals to pclk domain
    reg sclk_wr_req;
    reg [N-1:0] sclk_wr_data;
    reg sclk_wr_ack;
    reg sclk_rd_req;
    reg [N-1:0] sclk_rd_data;
    reg sclk_rd_valid;

    // Sclk domain: receive data from pclk domain
    reg [N-1:0] sclk_rx_di_data;
    reg sclk_rx_wren;
    reg sclk_rx_wr_ack;

    // Sclk domain: send data to pclk domain
    reg [N-1:0] sclk_tx_do_data;
    reg sclk_tx_do_valid;

    // Sclk domain: SPI clock generation and shifting
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            sclk_state <= S_IDLE;
            sclk_tx_shift <= {N{1'b0}};
            sclk_rx_shift <= {N{1'b0}};
            sclk_bit_count <= 4'd0;
            sclk_div_count <= 4'd0;
            sclk_sck_phase <= 1'b0;
            sclk_ssel_int <= 1'b0;
            sclk_mosi_int <= 1'b0;
            sclk_tx_valid <= 1'b0;
            sclk_tx_data <= {N{1'b0}};
            sclk_rx_valid <= 1'b0;
            sclk_rx_data <= {N{1'b0}};
            sclk_done_pulse <= 1'b0;
            sclk_wr_req <= 1'b0;
            sclk_wr_data <= {N{1'b0}};
            sclk_wr_ack <= 1'b0;
            sclk_rd_req <= 1'b0;
            sclk_rd_data <= {N{1'b0}};
            sclk_rd_valid <= 1'b0;
            sclk_rx_di_data <= {N{1'b0}};
            sclk_rx_wren <= 1'b0;
            sclk_rx_wr_ack <= 1'b0;
            sclk_tx_do_data <= {N{1'b0}};
            sclk_tx_do_valid <= 1'b0;
        end else begin
            // Default: clear pulses
            sclk_done_pulse <= 1'b0;
            sclk_wr_ack <= 1'b0;
            sclk_rd_valid <= 1'b0;

            case (sclk_state)
                S_IDLE: begin
                    sclk_ssel_int <= 1'b0;
                    sclk_sck_phase <= 1'b0;
                    sclk_mosi_int <= 1'b0;
                    sclk_bit_count <= 4'd0;
                    sclk_div_count <= 4'd0;
                    
                    // Check for new write request from pclk domain
                    if (sclk_rx_wren) begin
                        sclk_tx_data <= sclk_rx_di_data;
                        sclk_tx_valid <= 1'b1;
                        sclk_wr_ack <= 1'b1;
                        sclk_state <= S_ACTIVE;
                        sclk_ssel_int <= 1'b1;
                        sclk_tx_shift <= sclk_rx_di_data;
                        sclk_rx_shift <= {N{1'b0}};
                        sclk_bit_count <= 4'd0;
                        sclk_div_count <= 4'd0;
                        sclk_sck_phase <= 1'b0;
                        sclk_mosi_int <= sclk_rx_di_data[N-1];
                    end
                end
                
                S_ACTIVE: begin
                    sclk_ssel_int <= 1'b1;
                    
                    // Clock division
                    if (sclk_div_count == SPI_2X_CLK_DIV - 1) begin
                        sclk_div_count <= 4'd0;
                        // Toggle SCK
                        sclk_sck_phase <= ~sclk_sck_phase;
                        
                        if (sclk_sck_phase) begin
                            // Rising edge of SCK: shift out MSB, capture MISO
                            sclk_mosi_int <= sclk_tx_shift[N-2];
                            sclk_tx_shift <= {sclk_tx_shift[N-2:0], 1'b0};
                            sclk_rx_shift <= {spi_miso_i, sclk_rx_shift[N-1:1]};
                            sclk_bit_count <= sclk_bit_count + 1'b1;
                            
                            if (sclk_bit_count == N - 1) begin
                                // Last bit shifted
                                sclk_state <= S_DONE;
                                sclk_rx_data <= {spi_miso_i, sclk_rx_shift[N-1:1]};
                                sclk_rx_valid <= 1'b1;
                            end
                        end else begin
                            // Falling edge of SCK: no data change
                        end
                    end else begin
                        sclk_div_count <= sclk_div_count + 1'b1;
                    end
                end
                
                S_DONE: begin
                    sclk_ssel_int <= 1'b0;
                    sclk_sck_phase <= 1'b0;
                    sclk_mosi_int <= 1'b0;
                    sclk_done_pulse <= 1'b1;
                    sclk_state <= S_IDLE;
                end
                
                default: begin
                    sclk_state <= S_IDLE;
                end
            endcase
        end
    end

    // Sclk domain: outputs
    assign spi_ssel_o = sclk_ssel_int;
    assign spi_sck_o = sclk_sck_phase;
    assign spi_mosi_o = sclk_mosi_int;

    // ========================================================================
    // Pclk Domain: Parallel Interface Logic
    // ========================================================================
    
    // Pclk domain: send data to sclk domain
    reg pclk_wr_req;
    reg [N-1:0] pclk_wr_data;
    reg pclk_wr_ack;
    reg pclk_rd_req;
    reg [N-1:0] pclk_rd_data;
    reg pclk_rd_valid;

    // Pclk domain: receive data from sclk domain
    reg [N-1:0] pclk_rx_wr_data;
    reg pclk_rx_wr_ack;
    reg [N-1:0] pclk_rx_rd_data;
    reg pclk_rx_rd_valid;

    // Pclk domain: handshake state
    reg pclk_wr_pending;
    reg pclk_rd_pending;

    // Pclk domain: main logic
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
            pclk_wr_req <= 1'b0;
            pclk_wr_data <= {N{1'b0}};
            pclk_wr_ack <= 1'b0;
            pclk_rd_req <= 1'b0;
            pclk_rd_data <= {N{1'b0}};
            pclk_rd_valid <= 1'b0;
            pclk_rx_wr_data <= {N{1'b0}};
            pclk_rx_wr_ack <= 1'b0;
            pclk_rx_rd_data <= {N{1'b0}};
            pclk_rx_rd_valid <= 1'b0;
            pclk_wr_pending <= 1'b0;
            pclk_rd_pending <= 1'b0;
        end else begin
            // Default: clear pulses
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;

            // Handle write request from parallel side
            if (wren_i && !pclk_wr_pending) begin
                pclk_wr_data <= di_i;
                pclk_wr_req <= 1'b1;
                pclk_wr_pending <= 1'b1;
            end

            // Handle write acknowledgment from sclk domain
            if (pclk_rx_wr_ack && pclk_wr_pending) begin
                pclk_wr_pending <= 1'b0;
                pclk_wr_req <= 1'b0;
                wr_ack_o <= 1'b1;
                di_req_o <= 1'b1;
            end else begin
                di_req_o <= 1'b0;
            end

            // Handle read data from sclk domain
            if (pclk_rx_rd_valid) begin
                do_o <= pclk_rx_rd_data;
                do_valid_o <= 1'b1;
            end
        end
    end

    // ========================================================================
    // CDC: Pclk to Sclk (Write Request)
    // ========================================================================
    
    // Synchronize wren and di_i to sclk domain
    // Use a simple handshake: pclk asserts wr_req, sclk acknowledges with wr_ack
    
    // Sclk domain: detect pclk_wr_req
    reg [1:0] sclk_pclk_wr_req_sync;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            sclk_pclk_wr_req_sync <= 2'b00;
        else
            sclk_pclk_wr_req_sync <= {sclk_pclk_wr_req_sync[0], pclk_wr_req};
    end
    wire sclk_pclk_wr_req = sclk_pclk_wr_req_sync[1];

    // Sclk domain: capture di_i when wr_req is detected
    // Since di_i is multi-bit, we need to ensure it's stable
    // Use a simple approach: sample di_i when wr_req transitions
    reg sclk_pclk_wr_req_prev;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            sclk_pclk_wr_req_prev <= 1'b0;
            sclk_rx_di_data <= {N{1'b0}};
            sclk_rx_wren <= 1'b0;
        end else begin
            sclk_pclk_wr_req_prev <= sclk_pclk_wr_req;
            if (sclk_pclk_wr_req && !sclk_pclk_wr_req_prev) begin
                sclk_rx_di_data <= di_i;
                sclk_rx_wren <= 1'b1;
            end else begin
                sclk_rx_wren <= 1'b0;
            end
        end
    end

    // Sclk domain: send wr_ack back to pclk domain
    // Use a toggle-based handshake for reliability
    reg sclk_wr_ack_toggle;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            sclk_wr_ack_toggle <= 1'b0;
        else if (sclk_wr_ack)
            sclk_wr_ack_toggle <= ~sclk_wr_ack_toggle;
    end

    // Pclk domain: synchronize sclk_wr_ack_toggle
    reg [1:0] pclk_sclk_wr_ack_sync;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_sclk_wr_ack_sync <= 2'b00;
        else
            pclk_sclk_wr_ack_sync <= {pclk_sclk_wr_ack_sync[0], sclk_wr_ack_toggle};
    end
    wire pclk_sclk_wr_ack = pclk_sclk_wr_ack_sync[1];

    // Pclk domain: detect toggle change
    reg pclk_sclk_wr_ack_prev;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_sclk_wr_ack_prev <= 1'b0;
        else
            pclk_sclk_wr_ack_prev <= pclk_sclk_wr_ack;
    end
    wire pclk_wr_ack_pulse = pclk_sclk_wr_ack ^ pclk_sclk_wr_ack_prev;

    // Override pclk_rx_wr_ack with the synchronized signal
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_rx_wr_ack <= 1'b0;
        else
            pclk_rx_wr_ack <= pclk_wr_ack_pulse;
    end

    // ========================================================================
    // CDC: Sclk to Pclk (Read Data)
    // ========================================================================
    
    // Sclk domain: send rd_valid and rd_data to pclk domain
    // Use a toggle-based handshake for multi-bit data
    
    reg sclk_rd_valid_toggle;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            sclk_rd_valid_toggle <= 1'b0;
        else if (sclk_rx_valid)
            sclk_rd_valid_toggle <= ~sclk_rd_valid_toggle;
    end

    // Pclk domain: synchronize sclk_rd_valid_toggle
    reg [1:0] pclk_sclk_rd_valid_sync;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_sclk_rd_valid_sync <= 2'b00;
        else
            pclk_sclk_rd_valid_sync <= {pclk_sclk_rd_valid_sync[0], sclk_rd_valid_toggle};
    end
    wire pclk_sclk_rd_valid = pclk_sclk_rd_valid_sync[1];

    // Pclk domain: detect toggle change and capture data
    reg pclk_sclk_rd_valid_prev;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_sclk_rd_valid_prev <= 1'b0;
        else
            pclk_sclk_rd_valid_prev <= pclk_sclk_rd_valid;
    end
    wire pclk_rd_valid_pulse = pclk_sclk_rd_valid ^ pclk_sclk_rd_valid_prev;

    // Pclk domain: capture rd_data when valid pulse detected
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            pclk_rx_rd_data <= {N{1'b0}};
            pclk_rx_rd_valid <= 1'b0;
        end else begin
            pclk_rx_rd_valid <= 1'b0;
            if (pclk_rd_valid_pulse) begin
                pclk_rx_rd_data <= sclk_rx_data;
                pclk_rx_rd_valid <= 1'b1;
            end
        end
    end

endmodule
