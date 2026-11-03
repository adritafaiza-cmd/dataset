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
    reg [ASIZE:0] wptr;
    reg [ASIZE:0] rptr;
    reg [ASIZE:0] wcount;
    reg [ASIZE:0] rcount;
    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg wfull_reg;
    reg wempty_reg;
    reg rfull_reg;
    reg rempty_reg;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wcount <= 0;
            wfull_reg <= 0;
            wempty_reg <= 1;
        end else begin
            if (winc && !wfull_reg) begin
                mem[wptr] <= wdata;
                wptr <= (wptr + 1) & ((1<<ASIZE) - 1);
                wcount <= wcount + 1;
            end
            wfull_reg <= (wcount == (1<<ASIZE) - 1);
            wempty_reg <= (wcount == 0);
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcount <= 0;
            rfull_reg <= 0;
            rempty_reg <= 1;
        end else begin
            if (rinc && !rempty_reg) begin
                rptr <= (rptr + 1) & ((1<<ASIZE) - 1);
                rcount <= rcount - 1;
            end
            rfull_reg <= (rcount == (1<<ASIZE) - 1);
            rempty_reg <= (rcount == 0);
        end
    end

    // Full and almost full logic
    assign wfull = wfull_reg;
    assign awfull = (wcount == (1<<ASIZE) - 2);

    // Empty and almost empty logic
    assign rempty = rempty_reg;
    assign arempty = (rcount == 1);

    // Read data logic
    assign rdata = (FALLTHROUGH == "TRUE") ? mem[rptr] : (rempty_reg ? 0 : mem[rptr]);

endmodule
