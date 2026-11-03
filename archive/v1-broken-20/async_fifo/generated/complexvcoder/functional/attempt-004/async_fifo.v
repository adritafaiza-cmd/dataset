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

    localparam FIFO_SIZE = 1 << ASIZE;

    reg [ASIZE-1:0] wr_ptr, rd_ptr;
    reg [ASIZE-1:0] wfull_reg, rempty_reg;
    reg [ASIZE-1:0] awfull_reg, arempty_reg;
    reg [DSIZE-1:0] fifo[FIFO_SIZE-1:0];

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                fifo[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                wfull_reg <= wr_ptr == FIFO_SIZE - 1;
            end
        end
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rempty_reg <= 1;
            rdata <= 0;
        end else begin
            if (rinc && !rempty_reg) begin
                rd_ptr <= rd_ptr + 1;
                rempty_reg <= rd_ptr == wr_ptr;
                rdata <= fifo[rd_ptr];
            end
        end
    end

    // Almost full and almost empty indicators
    assign awfull_reg = wr_ptr == FIFO_SIZE - 2;
    assign arempty_reg = wr_ptr == rd_ptr;

    // Outputs
    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

    // First-word fall-through
    generate
        if (FALLTHROUGH == "TRUE") begin
            assign rdata = fifo[rd_ptr];
        end else begin
            assign rdata = fifo[rd_ptr];
        end
    endgenerate

endmodule
