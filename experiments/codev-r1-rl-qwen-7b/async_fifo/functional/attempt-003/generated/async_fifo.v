module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "TRUE"
) (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [DSIZE-1:0] wdata,
    output wire             wfull,
    output wire             awfull,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire             rinc,
    output wire [DSIZE-1:0] rdata,
    output wire             rempty,
    output wire             arempty
);

    // Memory
    reg [DSIZE-1:0] mem [0:(1 << ASIZE)-1];

    // Write domain signals
    reg [ASIZE:0] wptr_bin;
    wire [ASIZE:0] wptr_bin_next = wptr_bin + (winc && !wfull);

    // Gray code conversion
    wire [ASIZE:0] wptr_gray = wptr_bin ^ (wptr_bin >> 1);

    // Synchronize read pointer's Gray code into write domain
    reg [ASIZE:0] rptr_gray_sync1, rptr_gray_sync2;

    // Convert synchronized Gray to binary
    function [ASIZE:0] gray2bin;
        input [ASIZE:0] gray;
        integer i;
        begin
            gray2bin[ASIZE] = gray[ASIZE];
            for (i = ASIZE-1; i >=0; i = i-1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    reg [ASIZE:0] rptr_bin_sync;

    // Read domain signals
    reg [ASIZE:0] rptr_bin;
    wire [ASIZE:0] rptr_bin_next = rptr_bin + (rinc && !rempty);

    // Gray code conversion
    wire [ASIZE:0] rptr_gray = rptr_bin ^ (rptr_bin >> 1);

    // Synchronize write pointer's Gray code into read domain
    reg [ASIZE:0] wptr_gray_sync1, wptr_gray_sync2;

    // Convert synchronized Gray to binary
    reg [ASIZE:0] wptr_bin_sync;

    // Full and empty conditions
    wire full;
    wire empty;

    // Almost full and almost empty
    wire [ASIZE:0] count_w = wptr_bin - rptr_bin_sync;
    wire [ASIZE:0] count_r = wptr_bin_sync - rptr_bin;

    // Assign outputs
    assign awfull = (count_w >= ((1 << ASIZE) -1));
    assign arempty = (count_r <= 1);

    // Write pointer update and memory write
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
        end else if (winc && !wfull) begin
            wptr_bin <= wptr_bin_next;
            mem[wptr_bin[ASIZE-1:0]] <= wdata;
        end
    end

    // Synchronize read pointer's Gray code into write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Convert synchronized read pointer to binary
    always @* begin
        rptr_bin_sync = gray2bin(rptr_gray_sync2);
    end

    // Full condition
    assign full = ( (wptr_bin_next - rptr_bin_sync) == (1 << ASIZE) );
    assign wfull = full;

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
        end else if (rinc && !rempty) begin
            rptr_bin <= rptr_bin_next;
        end
    end

    // Synchronize write pointer's Gray code into read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Convert synchronized write pointer to binary
    always @* begin
        wptr_bin_sync = gray2bin(wptr_gray_sync2);
    end

    // Empty condition
    assign empty = (rptr_bin == wptr_bin_sync);
    assign rempty = empty;

    // Read data logic
    generate
        if (FALLTHROUGH == "TRUE") begin
            assign rdata = mem[rptr_bin[ASIZE-1:0]];
        end else begin
            reg [DSIZE-1:0] rdata_reg;
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    rdata_reg <= 0;
                end else if (rinc && !rempty) begin
                    rdata_reg <= mem[rptr_bin[ASIZE-1:0]];
                end
            end
            assign rdata = rdata_reg;
        end
    endgenerate

endmodule
