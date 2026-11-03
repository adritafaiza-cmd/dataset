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

    localparam FIFO_DEPTH = 2**ASIZE;

    reg [ASIZE-1:0] wptr_reg;
    reg [ASIZE-1:0] rptr_reg;
    reg [ASIZE-1:0] count_reg;
    wire [ASIZE-1:0] wptr;
    wire [ASIZE-1:0] rptr;
    wire [ASIZE-1:0] count;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_reg <= 0;
        end else begin
            if (winc && !wfull) begin
                wptr_reg <= wptr_reg + 1;
            end
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_reg <= 0;
        end else begin
            if (rinc && !rempty) begin
                rptr_reg <= rptr_reg + 1;
            end
        end
    end

    // FIFO count logic
    always @(posedge wclk or negedge wrst_n or posedge rclk or negedge rrst_n) begin
        if (!wrst_n || !rrst_n) begin
            count_reg <= 0;
        end else begin
            if (winc && !wfull) begin
                count_reg <= count_reg + 1;
            end else if (rinc && !rempty) begin
                count_reg <= count_reg - 1;
            end
        end
    end

    // FIFO full and almost full logic
    assign wfull = (count_reg == FIFO_DEPTH - 1);
    assign awfull = (count_reg >= FIFO_DEPTH - 2);

    // FIFO empty and almost empty logic
    assign rempty = (count_reg == 0);
    assign arempty = (count_reg <= 1);

    // Write pointer modulo FIFO depth
    assign wptr = wptr_reg;

    // Read pointer modulo FIFO depth
    assign rptr = rptr_reg;

    // FIFO memory
    reg [DSIZE-1:0] fifo_mem [0:FIFO_DEPTH-1];
    wire [DSIZE-1:0] rd_data;

    assign rd_data = fifo_mem[rptr];

    // First-word fall-through logic
    reg [DSIZE-1:0] fall_through;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            fall_through <= 0;
        end else begin
            if (rinc && !rempty) begin
                fall_through <= rd_data;
            end
        end
    end

    assign rdata = (FALLTHROUGH == "TRUE") ? fall_through : rd_data;

endmodule
