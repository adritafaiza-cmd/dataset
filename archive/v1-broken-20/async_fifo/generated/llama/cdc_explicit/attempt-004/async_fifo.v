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

    reg [ASIZE-1:0] wptr;
    reg [ASIZE-1:0] rptr;
    reg [ASIZE-1:0] wptr_gray;
    reg [ASIZE-1:0] rptr_gray;
    reg [ASIZE-1:0] wptr_gray_sync;
    reg [ASIZE-1:0] rptr_gray_sync;
    reg [DSIZE-1:0] fifo [2**ASIZE-1:0];
    reg [ASIZE-1:0] wptr_bin;
    reg [ASIZE-1:0] rptr_bin;
    reg [ASIZE-1:0] wptr_bin_sync;
    reg [ASIZE-1:0] rptr_bin_sync;
    reg [ASIZE:0] wcnt;
    reg [ASIZE:0] rcnt;
    reg [ASIZE:0] wcnt_sync;
    reg [ASIZE:0] rcnt_sync;
    reg wfull_reg;
    reg awfull_reg;
    reg rempty_reg;
    reg arempty_reg;
    reg [DSIZE-1:0] rdata_reg;

    // Gray counter
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull_reg) begin
            wptr <= wptr + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty_reg) begin
            rptr <= rptr + 1;
        end
    end

    // Binary counter
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wcnt <= 0;
        end else if (winc && !wfull_reg) begin
            wcnt <= wcnt + 1;
        end else if (!winc && wcnt > 0) begin
            wcnt <= wcnt - 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rcnt <= 0;
        end else if (rinc && !rempty_reg) begin
            rcnt <= rcnt - 1;
        end else if (!rinc && rcnt < 2**ASIZE) begin
            rcnt <= rcnt + 1;
        end
    end

    // Gray to binary conversion
    always @(wptr) begin
        wptr_gray = wptr;
        wptr_bin = 0;
        for (int i = 0; i < ASIZE; i++) begin
            wptr_bin[i] = wptr_gray[i] ^ (wptr_gray[i+1] ? 1 : 0);
        end
    end

    always @(rptr) begin
        rptr_gray = rptr;
        rptr_bin = 0;
        for (int i = 0; i < ASIZE; i++) begin
            rptr_bin[i] = rptr_gray[i] ^ (rptr_gray[i+1] ? 1 : 0);
        end
    end

    // Synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray_sync <= 0;
        end else begin
            wptr_gray_sync <= wptr_gray;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray_sync <= 0;
        end else begin
            rptr_gray_sync <= rptr_gray;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin_sync <= 0;
        end else begin
            wptr_bin_sync <= wptr_bin;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin_sync <= 0;
        end else begin
            rptr_bin_sync <= rptr_bin;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wcnt_sync <= 0;
        end else begin
            wcnt_sync <= wcnt;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rcnt_sync <= 0;
        end else begin
            rcnt_sync <= rcnt;
        end
    end

    // FIFO write
    always @(posedge wclk) begin
        if (winc && !wfull_reg) begin
            fifo[wptr_bin] <= wdata;
        end
    end

    // FIFO read
    always @(posedge rclk) begin
        if (rinc && !rempty_reg) begin
            rdata_reg <= fifo[rptr_bin];
        end else if (FALLTHROUGH == "TRUE" && !rempty_reg) begin
            rdata_reg <= fifo[rptr_bin];
        end
    end

    // Status flags
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull_reg <= 0;
        end else begin
            wfull_reg <= (wcnt == 2**ASIZE);
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty_reg <= 1;
        end else begin
            rempty_reg <= (rcnt == 0);
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            awfull_reg <= 0;
        end else begin
            awfull_reg <= (wcnt >= 2**ASIZE - 2);
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            arempty_reg <= 1;
        end else begin
            arempty_reg <= (rcnt <= 2);
        end
    end

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rdata = rdata_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

endmodule
