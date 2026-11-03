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

    reg [ASIZE-1:0] wptr, rptr;
    reg [ASIZE-1:0] wptr_gray, rptr_gray;
    reg [ASIZE-1:0] wptr_sync, rptr_sync;
    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [ASIZE-1:0] count;
    reg full, empty;

    assign wfull = full;
    assign awfull = (count == (2**ASIZE - 2));
    assign rempty = empty;
    assign arempty = (count == 1);

    always @(posedge wclk or negedge wrst_n)
    begin
        if (!wrst_n)
        begin
            wptr <= 0;
            wptr_gray <= 0;
            count <= 0;
            full <= 0;
        end
        else if (winc && !full)
        begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= {wptr[ASIZE-2:0], wptr[ASIZE-1]};
            if (wptr == (2**ASIZE - 1))
            begin
                full <= 1;
            end
            else
            begin
                count <= count + 1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n)
    begin
        if (!rrst_n)
        begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_sync <= 0;
            count <= 0;
            empty <= 1;
        end
        else if (rinc && !empty)
        begin
            rdata <= mem[rptr];
            rptr <= rptr + 1;
            rptr_gray <= {rptr[ASIZE-2:0], rptr[ASIZE-1]};
            if (rptr == (2**ASIZE - 1))
            begin
                empty <= 1;
            end
            else
            begin
                count <= count - 1;
            end
        end
    end

    always @(posedge wclk)
    begin
        wptr_sync <= wptr_gray;
    end

    always @(posedge rclk)
    begin
        rptr_sync <= rptr_gray;
    end

    always @(posedge rclk)
    begin
        if (rptr_sync == wptr_sync)
        begin
            empty <= 1;
        end
        else
        begin
            empty <= 0;
        end
    end

    always @(posedge wclk)
    begin
        if (wptr_sync == rptr_sync)
        begin
            full <= 0;
        end
        else
        begin
            full <= 1;
        end
    end

endmodule
