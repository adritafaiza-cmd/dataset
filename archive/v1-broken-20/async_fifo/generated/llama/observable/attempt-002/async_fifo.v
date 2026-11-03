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

    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [ASIZE-1:0] wptr, rptr, wptr_gray, rptr_gray;
    reg [ASIZE-1:0] wptr_sync, rptr_sync;
    reg [ASIZE-1:0] wptr_bin, rptr_bin;
    reg full, empty;
    reg [ASIZE-1:0] count;

    // Write pointer synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_sync <= 0;
        end else begin
            wptr_sync <= wptr;
        end
    end

    // Read pointer synchronization
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_sync <= 0;
        end else begin
            rptr_sync <= rptr;
        end
    end

    // Write pointer gray encoding
    always @(wptr) begin
        wptr_gray <= {wptr[ASIZE-2:0], wptr[ASIZE-1]};
    end

    // Read pointer gray encoding
    always @(rptr) begin
        rptr_gray <= {rptr[ASIZE-2:0], rptr[ASIZE-1]};
    end

    // Write pointer binary decoding
    always @(wptr_gray) begin
        wptr_bin <= wptr_gray;
    end

    // Read pointer binary decoding
    always @(rptr_gray) begin
        rptr_bin <= rptr_gray;
    end

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            full <= 0;
            count <= 0;
        end else if (winc &&!full) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            if (wptr == 2**ASIZE - 1) begin
                wptr <= 0;
            end
            count <= count + 1;
            if (count == 2**ASIZE - 1) begin
                full <= 1;
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            empty <= 1;
        end else if (rinc &&!empty) begin
            rdata <= mem[rptr];
            rptr <= rptr + 1;
            if (rptr == 2**ASIZE - 1) begin
                rptr <= 0;
            end
            count <= count - 1;
            if (count == 0) begin
                empty <= 1;
            end
        end
    end

    // Full flag
    assign wfull = full;

    // Almost full flag
    always @(count) begin
        if (count >= 2**ASIZE - 2) begin
            awfull <= 1;
        end else begin
            awfull <= 0;
        end
    end

    // Empty flag
    assign rempty = empty;

    // Almost empty flag
    always @(count) begin
        if (count <= 1) begin
            arempty <= 1;
        end else begin
            arempty <= 0;
        end
    end

    // Initialize rdata
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc &&!empty) begin
            rdata <= mem[rptr];
        end
    end

endmodule
