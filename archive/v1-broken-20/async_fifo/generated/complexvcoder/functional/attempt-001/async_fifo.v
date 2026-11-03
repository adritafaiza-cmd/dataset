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
    reg [ASIZE:0] wptr, rptr;
    reg [ASIZE:0] wcount, rcount;
    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg [ASIZE:0] wcount_next, rcount_next;
    reg [ASIZE:0] wptr_next, rptr_next;
    reg [DSIZE-1:0] rdata_next;
    reg wfull_reg, rempty_reg;

    // Write control logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wcount <= 0;
        end else begin
            if (winc && !wfull) begin
                wptr_next <= wptr + 1;
                wcount_next <= wcount + 1;
            end else begin
                wptr_next <= wptr;
                wcount_next <= wcount;
            end
        end
    end

    // Read control logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcount <= 0;
        end else begin
            if (rinc && !rempty) begin
                rptr_next <= rptr + 1;
                rcount_next <= rcount + 1;
            end else begin
                rptr_next <= rptr;
                rcount_next <= rcount;
            end
        end
    end

    // FIFO full and empty flags
    assign wfull = (wcount == (1 << ASIZE));
    assign rempty = (wcount == 0);

    // Almost full and almost empty flags
    assign awfull = (wcount == ((1 << ASIZE) - 1));
    assign arempty = (wcount == 1);

    // Data output logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            if (FALLTHROUGH == "TRUE") begin
                rdata_next <= mem[rptr];
            end else begin
                if (rinc && !rempty) begin
                    rdata_next <= mem[rptr_next];
                end else begin
                    rdata_next <= mem[rptr];
                end
            end
        end
    end

    // Register outputs
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_reg <= 0;
            wcount_reg <= 0;
        end else begin
            wptr_reg <= wptr_next;
            wcount_reg <= wcount_next;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_reg <= 0;
            rcount_reg <= 0;
        end else begin
            rptr_reg <= rptr_next;
            rcount_reg <= rcount_next;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            rdata <= rdata_next;
        end
    end

    // Output assignments
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;
    assign rdata = rdata_reg;

endmodule
