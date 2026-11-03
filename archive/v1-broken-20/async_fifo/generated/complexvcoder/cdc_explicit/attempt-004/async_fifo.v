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
    reg [ASIZE-1:0] wr_ptr_reg, wr_ptr_sync;
    reg [ASIZE-1:0] rr_ptr_reg, rr_ptr_sync;
    reg [ASIZE-1:0] wr_ptr_ff1, wr_ptr_ff2;
    reg [ASIZE-1:0] rr_ptr_ff1, rr_ptr_ff2;
    reg wfull_reg, wfull_sync;
    reg awfull_reg, awfull_sync;
    reg rempty_reg, rempty_sync;
    reg arempty_reg, arempty_sync;
    reg [DSIZE-1:0] mem [0:(2**ASIZE)-1];
    reg [DSIZE-1:0] rdata_reg;

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr_reg <= 0;
            wfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                mem[wr_ptr_reg] <= wdata;
                wr_ptr_reg <= wr_ptr_reg + 1;
                wfull_reg <= (wr_ptr_reg + 1 == rr_ptr_reg);
            end
        end
    end

    // Write domain clock crossing
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr_ff1 <= 0;
            wr_ptr_ff2 <= 0;
        end else begin
            wr_ptr_ff1 <= wr_ptr_reg;
            wr_ptr_ff2 <= wr_ptr_ff1;
        end
    end

    assign wr_ptr_sync = wr_ptr_ff2;

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rr_ptr_reg <= 0;
            rempty_reg <= 1;
        end else begin
            if (rinc && !rempty_reg) begin
                rr_ptr_reg <= rr_ptr_reg + 1;
                rempty_reg <= (wr_ptr_reg == rr_ptr_reg);
            end
        end
    end

    // Read domain clock crossing
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rr_ptr_ff1 <= 0;
            rr_ptr_ff2 <= 0;
        end else begin
            rr_ptr_ff1 <= rr_ptr_reg;
            rr_ptr_ff2 <= rr_ptr_ff1;
        end
    end

    assign rr_ptr_sync = rr_ptr_ff2;

    // FIFO status
    assign wfull = wfull_reg;
    assign awfull = (wr_ptr_sync == rr_ptr_sync + 2);
    assign rempty = rempty_reg;
    assign arempty = (wr_ptr_sync == rr_ptr_sync + (2**ASIZE - 2));

    // Read data
    assign rdata_reg = mem[rr_ptr_reg];
    assign rdata = FALLTHROUGH == "TRUE" ? rdata_reg : (rempty_reg ? 0 : mem[rr_ptr_sync]);

endmodule
