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

    // Internal signals
    reg [ASIZE-1:0] wptr_reg, wptr_sync;
    reg [ASIZE-1:0] rptr_reg, rptr_sync;
    reg [DSIZE-1:0] data_reg [2**ASIZE-1:0];
    reg [ASIZE-1:0] wptr_gray, wptr_gray_sync;
    reg [ASIZE-1:0] rptr_gray, rptr_gray_sync;
    reg full, almost_full, empty, almost_empty;

    // Generate Gray codes for pointers
    wire [ASIZE:0] wptr_gray_code = {wptr_reg[ASIZE-1], wptr_reg[ASIZE-2:0] ^ wptr_reg[ASIZE-1] ^ wptr_reg[ASIZE-3:0] ^ wptr_reg[ASIZE-4:0]};
    wire [ASIZE:0] rptr_gray_code = {rptr_reg[ASIZE-1], rptr_reg[ASIZE-2:0] ^ rptr_reg[ASIZE-1] ^ rptr_reg[ASIZE-3:0] ^ rptr_reg[ASIZE-4:0]};

    // Clock domain crossing for write pointer
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_reg <= 0;
        end else begin
            wptr_reg <= wptr_gray_code[ASIZE-1] ? wptr_gray_code[ASIZE-2:0] : wptr_gray_code[ASIZE-2:0] + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_reg <= 0;
        end else begin
            rptr_reg <= rptr_gray_code[ASIZE-1] ? rptr_gray_code[ASIZE-2:0] : rptr_gray_code[ASIZE-2:0] + 1;
        end
    end

    // Synchronize write pointer to read clock domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync <= 0;
        end else begin
            wptr_sync <= wptr_gray_code[ASIZE-1] ? wptr_gray_code[ASIZE-2:0] : wptr_gray_code[ASIZE-2:0] + 1;
        end
    end

    // Synchronize read pointer to write clock domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync <= 0;
        end else begin
            rptr_sync <= rptr_gray_code[ASIZE-1] ? rptr_gray_code[ASIZE-2:0] : rptr_gray_code[ASIZE-2:0] + 1;
        end
    end

    // FIFO full and empty flags
    assign full = wptr_sync == rptr_gray_code[ASIZE-1] ? wptr_gray_code[ASIZE-2:0] + 1 == rptr_gray_code[ASIZE-2:0] : wptr_sync == rptr_gray_code[ASIZE-2:0] + 1;
    assign empty = wptr_gray_code[ASIZE-1] ? wptr_gray_code[ASIZE-2:0] == rptr_gray_code[ASIZE-2:0] : wptr_gray_code[ASIZE-2:0] == rptr_gray_code[ASIZE-2:0] + 1;

    // Almost full and almost empty flags
    assign almost_full = wptr_sync == rptr_gray_code[ASIZE-1] ? wptr_gray_code[ASIZE-2:0] + 1 == rptr_gray_code[ASIZE-2:0] - 1 : wptr_sync == rptr_gray_code[ASIZE-2:0] + 1 && wptr_gray_code[ASIZE-2:0] + 1 != rptr_gray_code[ASIZE-2:0];
    assign almost_empty = wptr_gray_code[ASIZE-1] ? wptr_gray_code[ASIZE-2:0] == rptr_gray_code[ASIZE-2:0] - 1 : wptr_gray_code[ASIZE-2:0] == rptr_gray_code[ASIZE-2:0] && wptr_gray_code[ASIZE-2:0] != rptr_gray_code[ASIZE-2:0] + 1;

    // Data output
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc && !rempty) begin
            rdata <= data_reg[rptr_gray_code[ASIZE-2:0]];
        end
    end

    // Data input
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            data_reg[wptr_gray_code[ASIZE-2:0]] <= 0;
        end else if (winc && !wfull) begin
            data_reg[wptr_gray_code[ASIZE-2:0]] <= wdata;
        end
    end

    // Output flags
    assign wfull = full;
    assign awfull = almost_full;
    assign rempty = empty;
    assign arempty = almost_empty;

endmodule
