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
    reg [ASIZE:0] wrptr;
    reg [ASIZE:0] rrptr;
    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg wfull_reg;
    reg awfull_reg;
    reg rempty_reg;
    reg arempty_reg;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wrptr <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                mem[wrptr] <= wdata;
                wrptr <= wrptr + 1;
                wfull_reg <= (wrptr == rrptr + (1<<ASIZE));
                awfull_reg <= (wrptr == rrptr + (1<<ASIZE) - 1);
            end
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rrptr <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
        end else begin
            if (rinc && !rempty_reg) begin
                rrptr <= rrptr + 1;
                rempty_reg <= (wrptr == rrptr);
                arempty_reg <= (wrptr == rrptr + 1);
            end
        end
    end

    // Output logic
    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rdata = mem[rrptr];
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

endmodule
