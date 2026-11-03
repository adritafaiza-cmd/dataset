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
    reg [ASIZE:0] count, count_sync;
    reg full, empty;
    reg full_sync, empty_sync;

    assign wfull = full;
    assign awfull = (count == (2**ASIZE - 2));
    assign rempty = empty;
    assign arempty = (count == 0);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            full <= 0;
            count <= 0;
        end else if (winc && !full) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= {wptr[ASIZE-2:0], wptr[ASIZE-1]};
            count <= count + 1;
            if (count == (2**ASIZE - 1)) begin
                full <= 1;
            end else begin
                full <= 0;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            empty <= 1;
            count_sync <= 0;
        end else if (rinc && !empty) begin
            rptr <= rptr + 1;
            rptr_gray <= {rptr[ASIZE-2:0], rptr[ASIZE-1]};
            count_sync <= count_sync - 1;
            if (count_sync == 1) begin
                empty <= 1;
            end else begin
                empty <= 0;
            end
        end
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr_gray;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr_gray;
        count_sync <= count;
    end

    always @(posedge rclk) begin
        if (FALLTHROUGH == "TRUE") begin
            if (empty) begin
                rdata <= 0;
            end else begin
                rdata <= mem[rptr];
            end
        end else begin
            rdata <= mem[rptr];
        end
    end

endmodule
