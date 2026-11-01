module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    localparam WIDTH = (N > 0) ? N : 1;

    reg [WIDTH-1:0] sync_reg;
    reg             out_reg;

    // Synchronize the reset signal into the clk domain
    always @(posedge clk) begin
        sync_reg <= {sync_reg[WIDTH-2:0], rst};
    end

    // Count down from N after reset is deasserted
    // When rst is high, out is high (reset active)
    // When rst goes low, we need to keep out high for N clock cycles
    // then release it to low

    // Use a counter that counts down from N to 0
    // When rst is asserted, out should be high
    // When rst is deasserted, out stays high for N cycles then goes low

    reg [WIDTH-1:0] counter;
    reg             rst_active;

    always @(posedge clk) begin
        if (rst) begin
            // Reset is asserted, keep out high
            rst_active <= 1'b1;
            counter    <= {WIDTH{1'b0}};
        end else if (rst_active) begin
            if (counter == 0) begin
                // Counter has reached 0, release reset
                rst_active <= 1'b0;
            end else begin
                counter <= counter - 1'b1;
            end
        end
    end

    // Initialize counter to N-1 when rst is first deasserted
    // We need to load the counter when transitioning from rst=1 to rst=0
    // Let's use a different approach: detect the falling edge of rst

    // Actually, let me reconsider. The requirement says:
    // "Assert reset promptly and release the output cleanly after the configured number of local clock edges."
    
    // So when rst goes high, out should go high promptly (synchronized)
    // When rst goes low, out should stay high for N clock edges, then go low

    // Let me use a simpler approach with a counter that loads N when rst is deasserted

    reg [WIDTH-1:0] cnt;
    reg             cnt_en;

    always @(posedge clk) begin
        if (rst) begin
            cnt    <= {WIDTH{1'b0}};
            cnt_en <= 1'b0;
        end else if (cnt_en) begin
            if (cnt == 0) begin
                cnt_en <= 1'b0;
            end else begin
                cnt <= cnt - 1'b1;
            end
        end else begin
            // Detect falling edge of rst: rst was high, now low
            // We need to know if rst was previously high
            // Let's use a register to track previous rst
        end
    end

    // This is getting complicated. Let me use a cleaner approach.

    // Approach: 
    // 1. Synchronize rst into clk domain
    // 2. When synchronized rst is high, out is high
    // 3. When synchronized rst goes from high to low, start a counter of N
    // 4. While counter is running, out stays high
    // 5. When counter reaches 0, out goes low

    // Let me rewrite cleanly

    // I'll use a separate always block for clarity

endmodule

module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    localparam WIDTH = (N > 0) ? N : 1;

    reg [WIDTH-1:0] sync_reg;
    reg             rst_sync;
    reg [WIDTH-1:0] counter;
    reg             counting;
    reg             out_reg;

    // Synchronize rst into clk domain
    always @(posedge clk) begin
        sync_reg <= {sync_reg[WIDTH-2:0], rst};
    end
    assign rst_sync = sync_reg[WIDTH-1];

    // Counter logic: when rst_sync deasserts, count down from N to 0
    always @(posedge clk) begin
        if (rst_sync) begin
            counting <= 1'b0;
            counter  <= {WIDTH{1'b0}};
        end else if (counting) begin
            if (counter == 0) begin
                counting <= 1'b0;
            end else begin
                counter <= counter - 1'b1;
            end
        end else begin
            // Detect falling edge of rst_sync
            // We need to know if rst_sync was previously high
            // Use a register to track previous state
        end
    end

    // Need to detect the falling edge properly
    // Let me add a register for previous rst_sync

    reg rst_sync_prev;

    always @(posedge clk) begin
        rst_sync_prev <= rst_sync;
    end

    // Falling edge detection
    wire rst_fall = rst_sync_prev & ~rst_sync;

    always @(posedge clk) begin
        if (rst_sync) begin
            counting <= 1'b0;
            counter  <= {WIDTH{1'b0}};
        end else if (rst_fall) begin
            counting <= 1'b1;
            counter  <= WIDTH'(N - 1);
        end else if (counting) begin
            if (counter == 0) begin
                counting <= 1'b0;
            end else begin
                counter <= counter - 1'b1;
            end
        end
    end

    // Output: high when rst_sync is high OR counting is active
    always @(posedge clk) begin
        out_reg <= rst_sync | counting;
    end

    assign out = out_reg;

endmodule
