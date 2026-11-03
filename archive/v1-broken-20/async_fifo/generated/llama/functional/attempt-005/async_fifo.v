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
    reg [ASIZE-1:0] wptr_sync;
    reg [ASIZE-1:0] rptr_sync;
    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [DSIZE-1:0] rdata_reg;

    assign wfull = (wptr_gray == {~rptr_sync[ASIZE-1], rptr_sync[ASIZE-2:0]} && wptr[0] == rptr_sync[0]);
    assign awfull = (wptr_gray == {~rptr_sync[ASIZE-1], rptr_sync[ASIZE-2:0]} && wptr[0] != rptr_sync[0]);
    assign rempty = (rptr_gray == {~wptr_sync[ASIZE-1], wptr_sync[ASIZE-2:0]} && rptr[0] == wptr_sync[0]);
    assign arempty = (rptr_gray == {~wptr_sync[ASIZE-1], wptr_sync[ASIZE-2:0]} && rptr[0] != wptr_sync[0]);

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && ~wfull) begin
            wptr <= wptr + 1;
            wptr_gray <= wptr_gray + 1;
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rdata_reg <= 0;
        end else if (rinc && ~rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= rptr_gray + 1;
            if (FALLTHROUGH == "TRUE") begin
                rdata_reg <= mem[rptr[ASIZE-1:0]];
            end
        end else if (FALLTHROUGH == "TRUE" && ~rempty) begin
            rdata_reg <= mem[rptr[ASIZE-1:0]];
        end
    end

    always @(posedge wclk) begin
        wptr_sync[ASIZE-1:0] <= wptr[ASIZE-1:0];
    end

    always @(posedge rclk) begin
        rptr_sync[ASIZE-1:0] <= rptr[ASIZE-1:0];
    end

    assign rdata = rdata_reg;

endmodule
