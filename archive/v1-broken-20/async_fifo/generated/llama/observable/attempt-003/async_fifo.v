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
    reg [ASIZE-1:0] wptr_sync;
    reg [ASIZE-1:0] rptr_sync;
    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [ASIZE-1:0] wcnt;
    reg [ASIZE-1:0] rcnt;

    assign wfull = (wcnt == (1 << ASIZE) - 1);
    assign awfull = (wcnt >= (1 << ASIZE) - 2);
    assign rempty = (rcnt == 0);
    assign arempty = (rcnt <= 1);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
        end else if (winc && !wfull) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wcnt <= wcnt + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
        end else if (rinc && !rempty) begin
            rdata <= mem[rptr];
            rptr <= rptr + 1;
            rcnt <= rcnt - 1;
        end
    end

    always @(posedge wclk) begin
        wptr_sync[0] <= wptr[0];
        for (genvar i = 1; i < ASIZE; i++) begin
            wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        rptr_sync[0] <= rptr[0];
        for (genvar i = 1; i < ASIZE; i++) begin
            rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    always @(posedge wclk) begin
        if (winc && !wfull) begin
            rcnt <= rcnt + 1;
        end
    end

    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            wcnt <= wcnt - 1;
        end
    end

    generate
        if (FALLTHROUGH == "TRUE") begin
            assign rdata = (rempty) ? {DSIZE{1'b0}} : mem[rptr];
        end else begin
            reg [DSIZE-1:0] rdata_reg;
            always @(posedge rclk) begin
                if (rinc && !rempty) begin
                    rdata_reg <= mem[rptr];
                end
            end
            assign rdata = rdata_reg;
        end
    endgenerate

endmodule
