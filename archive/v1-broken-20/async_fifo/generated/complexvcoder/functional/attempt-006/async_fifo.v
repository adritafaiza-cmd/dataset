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

    localparam FIFO_SIZE = 2**ASIZE;
    localparam FIFO_HALF = FIFO_SIZE / 2;

    reg [ASIZE:0] wr_ptr;
    reg [ASIZE:0] rd_ptr;
    reg [FIFO_SIZE-1:0][DSIZE-1:0] fifo;
    reg wfull_reg;
    reg rempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                fifo[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == FIFO_SIZE - 1) begin
                    wfull_reg <= 1;
                end
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rempty_reg <= 1;
            rdata <= 0;
        end else begin
            if (rinc && !rempty_reg) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == FIFO_SIZE - 1) begin
                    rempty_reg <= 1;
                end
            end
        end
    end

    assign wfull = wfull_reg;
    assign awfull = (wr_ptr == FIFO_HALF);
    assign rempty = rempty_reg;
    assign arempty = (rd_ptr == FIFO_HALF);

    assign rdata = (FALLTHROUGH == "TRUE") ? fifo[rd_ptr] : (rempty_reg ? 0 : fifo[rd_ptr]);

endmodule
