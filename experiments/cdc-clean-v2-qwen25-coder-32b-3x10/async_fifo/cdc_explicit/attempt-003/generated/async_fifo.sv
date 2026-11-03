module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
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

    localparam DEPTH = 1 << ASIZE;
    localparam AWATERMARK = DEPTH - 2;
    localparam EWATERMARK = 1;

    reg [DSIZE-1:0] mem [DEPTH-1:0];

    reg [ASIZE:0] wptr_gray, wptr_gray_nxt, wptr_bin;
    reg [ASIZE:0] rptr_gray, rptr_gray_nxt, rptr_bin;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            wptr_gray <= wptr_gray_nxt;
        end
    end

    always @(*) begin
        wptr_gray_nxt = wptr_gray + 1;
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr_gray <= rptr_gray_nxt;
        end
    end

    always @(*) begin
        rptr_gray_nxt = rptr_gray + 1;
    end

    // Gray to binary conversion
    always @(*) begin
        wptr_bin = wptr_gray ^ (wptr_gray >> 1);
        rptr_bin = rptr_gray ^ (rptr_gray >> 1);
    end

    // Write data to memory
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr_bin[ASIZE-1:0]] <= wdata;
        end
    end

    // Read data from memory
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            rdata_reg <= mem[rptr_bin[ASIZE-1:0]];
        end else if (FALLTHROUGH && !rempty) begin
            rdata_reg <= mem[rptr_bin[ASIZE-1:0]];
        end
    end

    assign rdata = rdata_reg;

    // FIFO status signals
    reg [ASIZE:0] wptr_gray_sync, rptr_gray_sync;

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync <= 0;
        end else begin
            rptr_gray_sync <= rptr_gray;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync <= 0;
        end else begin
            wptr_gray_sync <= wptr_gray;
        end
    end

    // Calculate FIFO status
    reg [ASIZE:0] wptr_sync_bin, rptr_sync_bin;
    always @(*) begin
        wptr_sync_bin = wptr_gray_sync ^ (wptr_gray_sync >> 1);
        rptr_sync_bin = rptr_gray_sync ^ (rptr_gray_sync >> 1);
    end

    assign wfull = (wptr_sync_bin == {1'b1, rptr_sync_bin[ASIZE-1:0]});
    assign awfull = (wptr_sync_bin == {1'b0, rptr_sync_bin[ASIZE-1:0]} + AWATERMARK);
    assign rempty = (wptr_bin == rptr_sync_bin);
    assign arempty = (wptr_bin == rptr_sync_bin + EWATERMARK);

endmodule
