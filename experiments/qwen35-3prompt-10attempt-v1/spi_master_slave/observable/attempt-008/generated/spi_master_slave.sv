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
    localparam PCLK_DIV = 2; // Assuming 2x division for parallel clock to handle potential frequency mismatch safely
    localparam SPI_DIV  = SPI_2X_CLK_DIV;

    // State encoding
    localparam IDLE = 0;
    localparam DATA_READY = 1;
    localparam SHIFTING = 2;
    localparam DONE = 3;

    // Internal signals
    reg [1:0] state;
    reg [N-1:0] shift_reg;
    reg [N-1:0] rx_data;
    reg [N-1:0] tx_data;
    reg shift_en;
    reg bit_count;
    reg [N-1:0] rx_valid_cnt;
    reg [N-1:0] tx_valid_cnt;
    reg ssel_active;
    reg [PCLK_DIV-1:0] pclk_div_cnt;
    reg [SPI_DIV-1:0] sclk_div_cnt;

    // Synchronous logic for Parallel Clock Domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            shift_reg <= {N{1'b0}};
            rx_data <= {N{1'b0}};
            tx_data <= {N{1'b0}};
            shift_en <= 1'b0;
            bit_count <= 0;
            rx_valid_cnt <= 0;
            tx_valid_cnt <= 0;
            ssel_active <= 0;
            pclk_div_cnt <= 0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
            wr_ack_o <= 1'b0;
            di_req_o <= 1'b0;
        end else begin
            // Parallel Clock Logic
            pclk_div_cnt <= pclk_div_cnt + 1'b1;
            if (pclk_div_cnt == PCLK_DIV - 1) begin
                pclk_div_cnt <= 0;
            end

            // State Machine
            case (state)
                IDLE: begin
                    if (wren_i && !di_req_o) begin
                        // Check if data is valid and ready to be sent
                        if (tx_valid_cnt == 0) begin
                            // Load data into shift register
                            shift_reg <= di_i;
                            tx_valid_cnt <= 1;
                            state <= DATA_READY;
                        end
                    end
                    // Deassert select line if not in transaction
                    if (!ssel_active) begin
                        spi_ssel_o <= 1'b0;
                    end
                end

                DATA_READY: begin
                    if (tx_valid_cnt == 1) begin
                        // Assert Select
                        spi_ssel_o <= 1'b1;
                        ssel_active <= 1;
                        shift_en <= 1'b1;
                        bit_count <= 0;
                        state <= SHIFTING;
                    end
                end

                SHIFTING: begin
                    // Request data if we need more bits
                    if (bit_count < N) begin
                        di_req_o <= 1'b1;
                    end

                    // Shift logic
                    if (bit_count < N) begin
                        shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                        bit_count <= bit_count + 1'b1;
                        
                        // Drive MOSI
                        spi_mosi_o <= shift_reg[N-1];
                        
                        // Drive Clock
                        spi_sck_o <= 1'b1; // Active high assumed for simplicity, can be inverted if needed
                    end

                    // Check if shift complete
                    if (bit_count == N) begin
                        shift_en <= 1'b0;
                        rx_data <= shift_reg;
                        state <= DONE;
                    end
                end

                DONE: begin
                    // Deassert Select
                    spi_ssel_o <= 1'b0;
                    ssel_active <= 0;
                    shift_en <= 1'b0;
                    di_req_o <= 1'b0;
                    
                    // Output data
                    do_valid_o <= 1'b1;
                    do_o <= rx_data;
                    
                    // Acknowledge write
                    wr_ack_o <= 1'b1;
                    
                    // Reset counters
                    tx_valid_cnt <= 0;
                    rx_valid_cnt <= 0;
                    
                    // Return to IDLE after a small delay or immediately if immediate response allowed
                    // Based on "return received words when complete", we stay here briefly or go to IDLE
                    // Let's go to IDLE to allow next transaction immediately
                    state <= IDLE;
                end
            endcase
        end
    end

    // Clock Domain Crossing: Sample Parallel signals on SPI clock (sclk_i)
    // We need to capture wren_i, di_i, and di_req_o changes safely.
    // Since the parallel interface is driven by pclk_i and SPI by sclk_i,
    // we must synchronize the parallel inputs to the SPI clock domain before using them
    // to control the SPI state machine, OR ensure the state machine is driven by pclk_i 
    // and only outputs to SPI domain.
    
    // The current implementation drives SPI outputs from pclk_i domain. This is risky if sclk_i 
    // is much faster than pclk_i. However, the requirement says "Send accepted parallel words".
    // Usually, the parallel interface is the master of the transaction initiation.
    // The SPI clocking is derived from sclk_i.
    // To be safe, we should synchronize the "Start Transaction" signal (wren_i) to the SPI clock domain
    // to ensure we don't start a transaction while the SPI clock is toggling unpredictably relative to pclk.
    // BUT, the state machine above is purely pclk_i driven.
    // The critical path is: pclk_i -> State Machine -> SPI Outputs.
    // If sclk_i is independent and faster, the SPI outputs (spi_sck_o, spi_mosi_o) must be stable 
    // when sclk_i samples them.
    // Since the state machine runs on pclk_i, the outputs are stable between pclk edges.
    // We need to ensure that the SPI clock (sclk_i) does not sample the output during a transition.
    // Given "independent clocks", we rely on the fact that the parallel interface controls the start.
    // We will add synchronization for the parallel inputs (wren_i, di_i) to the SPI clock domain 
    // to ensure we don't miss a start signal or read invalid data if the domains are asynchronous.
    // However, the state machine logic above uses pclk_i to drive the SPI outputs.
    // This creates a potential metastability issue if sclk_i samples spi_sck_o during a pclk transition.
    // Standard practice: The SPI clock domain should drive the SPI outputs if possible, 
    // but here the data loading happens on pclk.
    // Let's restructure slightly to ensure CDC compliance:
    // 1. Synchronize wren_i and di_i to SPI clock domain.
    // 2. Run the state machine on SPI clock domain? No, the requirement implies parallel interface is the trigger.
    // 3. Best approach for independent clocks: 
    //    - The parallel interface (pclk) prepares the data.
    //    - A "Start" signal is synchronized to the SPI clock (sclk) to initiate the shift register loading.
    //    - The shift register and state machine run on the SPI clock domain (sclk_i) to ensure outputs are stable for sclk_i.
    //    - The parallel data is sampled on the rising edge of the synchronized start signal.
    
    // Revised CDC Strategy:
    // The state machine and shift register will run on sclk_i (SPI clock domain) to guarantee 
    // that spi_sck_o and spi_mosi_o are stable relative to sclk_i.
    // The parallel interface (pclk_i) will be used to load data into a FIFO or register that is 
    // read by the SPI domain.
    // Since we need to send "accepted parallel words", we assume the parallel interface asserts wren_i 
    // when data is ready.
    
    // Synchronizers for Parallel Inputs to SPI Domain
    reg wren_sync1, wren_sync2;
    reg di_sync1, di_sync2;
    reg di_req_sync1, di_req_sync2;
    
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_sync1 <= 1'b0;
            wren_sync2 <= 1'b0;
            di_sync1 <= 1'b0;
            di_sync2 <= 1'b0;
            di_req_sync1 <= 1'b0;
            di_req_sync2 <= 1'b0;
        end else begin
            wren_sync1 <= wren_i;
            wren_sync2 <= wren_sync1;
            
            di_sync1 <= di_i;
            di_sync2 <= di_sync1;
            
            di_req_sync1 <= di_req_o; // This is tricky, di_req_o is an output. 
            // Actually, di_req_o is generated by the SPI domain to tell the parallel domain to provide data.
            // So di_req_o is already in SPI domain. We don't need to sync it to SPI domain.
            // We need to sync the parallel request (wren_i) and data (di_i) to SPI domain.
        end
    end
    
    // Wait, the previous logic had di_req_o as an output from pclk domain. 
    // If the state machine is now on sclk_i, di_req_o must be generated on sclk_i.
    // Let's fully migrate the FSM to sclk_i.
    
    // Reset logic for SPI domain
    reg [1:0] state_spi;
    reg [N-1:0] shift_reg_spi;
    reg [N-1:0] rx_data_spi;
    reg shift_en_spi;
    reg bit_count_spi;
    reg [N-1:0] rx_valid_cnt_spi;
    reg [N-1:0] tx_valid_cnt_spi;
    reg ssel_active_spi;
    reg [SPI_DIV-1:0] sclk_div_cnt_spi;
    
    // Synchronizers for wren_i and di_i
    reg wren_d1, wren_d2;
    reg di_d1, di_d2;
    
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_d1 <= 1'b0;
            wren_d2 <= 1'b0;
            di_d1 <= 1'b0;
            di_d2 <= 1'b0;
            state_spi <= IDLE;
            shift_reg_spi <= {N{1'b0}};
            rx_data_spi <= {N{1'b0}};
            shift_en_spi <= 1'b0;
            bit_count_spi <= 0;
            rx_valid_cnt_spi <= 0;
            tx_valid_cnt_spi <= 0;
            ssel_active_spi <= 0;
            sclk_div_cnt_spi <= 0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
            wr_ack_o <= 1'b0;
            di_req_o <= 1'b0;
        end else begin
            wren_d1 <= wren_i;
            wren_d2 <= wren_d1;
            di_d1 <= di_i;
            di_d2 <= di_d1;
            
            // State Machine on SPI Clock
            case (state_spi)
                IDLE: begin
                    // Check for start condition: wren is asserted and we are not currently shifting
                    if (wren_d2 && !di_req_o) begin
                        // Ensure data is stable (sampled on previous cycle)
                        if (tx_valid_cnt_spi == 0) begin
                            shift_reg_spi <= di_d2;
                            tx_valid_cnt_spi <= 1;
                            state_spi <= DATA_READY;
                        end
                    end
                    spi_ssel_o <= 1'b0;
                end

                DATA_READY: begin
                    if (tx_valid_cnt_spi == 1) begin
                        spi_ssel_o <= 1'b1;
                        ssel_active_spi <= 1;
                        shift_en_spi <= 1'b1;
                        bit_count_spi <= 0;
                        state_spi <= SHIFTING;
                    end
                end

                SHIFTING: begin
                    if (bit_count_spi < N) begin
                        di_req_o <= 1'b1;
                    end

                    if (bit_count_spi < N) begin
                        shift_reg_spi <= {shift_reg_spi[N-2:0], spi_miso_i};
                        bit_count_spi <= bit_count_spi + 1'b1;
                        spi_mosi_o <= shift_reg_spi[N-1];
                        spi_sck_o <= 1'b1;
                    end

                    if (bit_count_spi == N) begin
                        shift_en_spi <= 1'b0;
                        rx_data_spi <= shift_reg_spi;
                        state_spi <= DONE;
                    end
                end

                DONE: begin
                    spi_ssel_o <= 1'b0;
                    ssel_active_spi <= 0;
                    shift_en_spi <= 1'b0;
                    di_req_o <= 1'b0;
                    
                    do_valid_o <= 1'b1;
                    do_o <= rx_data_spi;
                    wr_ack_o <= 1'b1;
                    
                    tx_valid_cnt_spi <= 0;
                    rx_valid_cnt_spi <= 0;
                    
                    // Delay before returning to IDLE to allow output to settle? 
                    // Usually immediate is fine if do_valid_o is asserted.
                    state_spi <= IDLE;
                end
            endcase
        end
    end

    // Clock Divider for SPI Clock (if needed for timing, though sclk_i is the source)
    // The requirement mentions SPI_2X_CLK_DIV. This usually implies the internal logic 
    // should run at 2x the SPI clock or the SPI clock is derived from a faster source.
    // Given sclk_i is an input, we assume it is the clock for the SPI interface.
    // If the design requires the internal logic to be faster (e.g., to handle setup/hold),
    // we might need a faster clock. However, without a faster clock input, we assume 
    // sclk_i is sufficient.
    // If the intention is that the parallel interface is faster, we might need to sample 
    // the parallel data multiple times per SPI clock cycle? No, that's complex.
    // Let's assume sclk_i is the master clock for the SPI domain.
    
    // One detail: "SPI_2X_CLK_DIV". If this parameter is meant to divide the SPI clock 
    // for internal processing, we would need a faster clock. Since we only have sclk_i, 
    // we assume the logic runs on sclk_i. 
    // Perhaps the parameter is used to determine how many SPI clocks per bit? 
    // Standard SPI is 1 bit per clock. If 2x div, maybe 2 clocks per bit?
    // Let's implement a counter that increments by 2 per bit if SPI_2X_CLK_DIV > 1.
    
    reg [N-1:0] bit_count_spi_2x;
    reg shift_en_spi_2x;
    
    // Re-implement SHIFTING with 2x clock support if needed
    // Actually, let's keep it simple: 1 bit per clock unless specified otherwise.
    // But the parameter exists. Let's use it to increment the bit counter.
    // If SPI_2X_CLK_DIV = 2, we consume 2 SPI clocks per bit.
    
    // Let's refine the SHIFTING state to use the parameter.
    // We need to track how many SPI clocks have passed for the current bit.
    
    reg [N-1:0] sclk_cycles_per_bit;
    reg [N-1:0] current_bit_cycles;
    
    // This adds complexity. Let's stick to the simplest interpretation:
    // The parameter might be for a specific timing constraint or just a placeholder.
    // However, to be professional, if SPI_2X_CLK_DIV is 2, we should wait 2 cycles per bit.
    
    // Revised SHIFTING logic with parameter support:
    // We need to count sclk cycles.
    // If SPI_2X_CLK_DIV == 1, 1 cycle per bit.
    // If SPI_2X_CLK_DIV == 2, 2 cycles per bit.
    
    // Let's add a cycle counter for the bit shift.
    reg [N-1:0] bit_cycle_cnt;
    reg [N-1:0] cycles_per_bit;
    
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            cycles_per_bit <= SPI_2X_CLK_DIV;
            bit_cycle_cnt <= 0;
        end else begin
            cycles_per_bit <= SPI_2X_CLK_DIV;
            bit_cycle_cnt <= bit_cycle_cnt + 1'b1;
        end
    end
    
    // Integrate into the main FSM
    // We need to duplicate the FSM logic or add a sub-state for bit shifting.
    // To keep the code clean and single-file without complex state encoding changes:
    // We will modify the SHIFTING state to check bit_cycle_cnt.
    
    // Actually, the previous FSM was inside the always block. 
    // We need to restructure the always block to handle the cycle counting.
    
    // Let's rewrite the main always block cleanly.
    
    // Synchronizers for wren_i and di_i
    reg wren_d1, wren_d2;
    reg di_d1, di_d2;
    
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_d1 <= 1'b0;
            wren_d2 <= 1'b0;
            di_d1 <= 1'b0;
            di_d2 <= 1'b0;
            state_spi <= IDLE;
            shift_reg_spi <= {N{1'b0}};
            rx_data_spi <= {N{1'b0}};
            shift_en_spi <= 1'b0;
            bit_count_spi <= 0;
            rx_valid_cnt_spi <= 0;
            tx_valid_cnt_spi <= 0;
            ssel_active_spi <= 0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
            wr_ack_o <= 1'b0;
            di_req_o <= 1'b0;
            bit_cycle_cnt <= 0;
        end else begin
            wren_d1 <= wren_i;
            wren_d2 <= wren_d1;
            di_d1 <= di_i;
            di_d2 <= di_d1;
            
            bit_cycle_cnt <= bit_cycle_cnt + 1'b1;
            
            // State Machine
            case (state_spi)
                IDLE: begin
                    if (wren_d2 && !di_req_o) begin
                        if (tx_valid_cnt_spi == 0) begin
                            shift_reg_spi <= di_d2;
                            tx_valid_cnt_spi <= 1;
                            state_spi <= DATA_READY;
                        end
                    end
                    spi_ssel_o <= 1'b0;
                end

                DATA_READY: begin
                    if (tx_valid_cnt_spi == 1) begin
                        spi_ssel_o <= 1'b1;
                        ssel_active_spi <= 1;
                        shift_en_spi <= 1'b1;
                        bit_count_spi <= 0;
                        state_spi <= SHIFTING;
                    end
                end

                SHIFTING: begin
                    if (bit_count_spi < N) begin
                        di_req_o <= 1'b1;
                    end

                    // Check if we have completed the required cycles for the current bit
                    if (bit_count_spi < N) begin
                        if (bit_cycle_cnt >= cycles_per_bit) begin
                            // Shift bit
                            shift_reg_spi <= {shift_reg_spi[N-2:0], spi_miso_i};
                            bit_count_spi <= bit_count_spi + 1'b1;
                            bit_cycle_cnt <= 0; // Reset cycle counter for next bit
                            
                            spi_mosi_o <= shift_reg_spi[N-1];
                            spi_sck_o <= 1'b1;
                        end
                    end

                    if (bit_count_spi == N) begin
                        shift_en_spi <= 1'b0;
                        rx_data_spi <= shift_reg_spi;
                        state_spi <= DONE;
                    end
                end

                DONE: begin
                    spi_ssel_o <= 1'b0;
                    ssel_active_spi <= 0;
                    shift_en_spi <= 1'b0;
                    di_req_o <= 1'b0;
                    
                    do_valid_o <= 1'b1;
                    do_o <= rx_data_spi;
                    wr_ack_o <= 1'b1;
                    
                    tx_valid_cnt_spi <= 0;
                    rx_valid_cnt_spi <= 0;
                    state_spi <= IDLE;
                end
            endcase
        end
    end

    // Output assignments
    spi_ssel_o <= ssel_active_spi;
    spi_sck_o <= 1'b1; // Assuming active high. If active low required, invert here.
    spi_mosi_o <= 1'b0; // Default low when not shifting

endmodule
```<|im_end|>
