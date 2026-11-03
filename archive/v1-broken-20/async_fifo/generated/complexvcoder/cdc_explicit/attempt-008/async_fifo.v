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

    localparam FIFO_DEPTH = 1 << ASIZE;
    localparam ADDR_WIDTH = ASIZE;

    wire [ADDR_WIDTH-1:0] wptr_rst_n, rptr_rst_n, wptr, rptr;
    wire [DSIZE-1:0] fifo_mem[FIFO_DEPTH-1:0];
    wire wfull_reg, rempty_reg;
    wire winc_reg, rinc_reg;
    wire [ADDR_WIDTH-1:0] wptr_next, rptr_next;

    // Synchronizers
    sync_reset wrst_sync (
        .clk(wclk),
        .reset(wrst_n),
        .sync_reset(wptr_rst_n)
    );

    sync_reset rrst_sync (
        .clk(rclk),
        .reset(rrst_n),
        .sync_reset(rptr_rst_n)
    );

    // FIFO memory
    fifo_memory fifo_mem_inst (
        .clk(wclk),
        .rst_n(wptr_rst_n),
        .wen(winc_reg),
        .wdata(wdata),
        .rdata(rdata),
        .full(wfull_reg),
        .awfull(awfull),
        .empty(rempty_reg),
        .arempty(arempty)
    );

    // Pointer logic
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc_reg && !wfull_reg) begin
            wptr <= wptr_next;
        end
    end

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc_reg && !rempty_reg) begin
            rptr <= rptr_next;
        end
    end

    assign wptr_next = (wptr + 1) % FIFO_DEPTH;
    assign rptr_next = (rptr + 1) % FIFO_DEPTH;

    // Write increment logic
    assign winc_reg = winc;

    // Read increment logic
    assign rinc_reg = rinc;

    // Full and empty flags
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

endmodule

module fifo_memory
    #(
        parameter DSIZE = 8,
        parameter ADDR_WIDTH = 4
    )(
        input  wire             clk,
        input  wire             rst_n,
        input  wire             wen,
        input  wire [DSIZE-1:0] wdata,
        output wire [DSIZE-1:0] rdata,
        output wire             full,
        output wire             awfull,
        output wire             empty,
        output wire             arempty
    );

    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;
    localparam ADDR_WIDTH = 4;

    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg [DSIZE-1:0] fifo_mem[FIFO_DEPTH-1:0];
    reg full_reg, empty_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0;
            rptr <= 0;
            full_reg <= 0;
            empty_reg <= 1;
        end else begin
            if (wen && !full_reg) begin
                fifo_mem[wptr] <= wdata;
                wptr <= (wptr + 1) % FIFO_DEPTH;
                full_reg <= (wptr == rptr);
                empty_reg <= 0;
            end else if (rinc && !empty_reg) begin
                rptr <= (rptr + 1) % FIFO_DEPTH;
                empty_reg <= (wptr == rptr);
                full_reg <= 0;
            end
        end
    end

    assign awfull = (wptr == (rptr - 1) % FIFO_DEPTH);
    assign arempty = (wptr == rptr);
    assign full = full_reg;
    assign empty = empty_reg;
    assign rdata = fifo_mem[rptr];

endmodule

module sync_reset
    (
        input  wire             clk,
        input  wire             reset,
        output reg              sync_reset
    );

    reg [1:0] sync_reg;

    always_ff @(posedge clk) begin
        sync_reg <= {sync_reg[0], reset};
    end

    assign sync_reset = sync_reg[1];

endmodule
