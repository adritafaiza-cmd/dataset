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

    localparam FIFO_DEPTH = 1 << ASIZE;

    reg [ASIZE-1:0] wr_ptr;
    reg [ASIZE-1:0] rd_ptr;
    reg [ASIZE-1:0] wr_count;
    reg [ASIZE-1:0] rd_count;
    reg [DSIZE-1:0] fifo[FIFO_DEPTH-1:0];
    reg wfull_reg;
    reg awfull_reg;
    reg rempty_reg;
    reg arempty_reg;

    wire wfull_wire;
    wire awfull_wire;
    wire rempty_wire;
    wire arempty_wire;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            wr_count <= 0;
            rd_count <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
        end else begin
            if (winc && !wfull_reg) begin
                fifo[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                wr_count <= wr_count + 1;
                if (wr_count + 1 == FIFO_DEPTH) begin
                    wfull_reg <= 1;
                end else begin
                    wfull_reg <= 0;
                end
                if (wr_count + 1 >= FIFO_DEPTH - 1) begin
                    awfull_reg <= 1;
                end else begin
                    awfull_reg <= 0;
                end
            end

            if (wfull_reg && winc) begin
                // Do nothing
            end

            if (rempty_reg && rinc) begin
                // Do nothing
            end

            if (rinc && !rempty_reg) begin
                rd_ptr <= rd_ptr + 1;
                rd_count <= rd_count - 1;
                if (rd_count == 0) begin
                    rempty_reg <= 1;
                end else begin
                    rempty_reg <= 0;
                end
                if (rd_count <= 1) begin
                    arempty_reg <= 1;
                end else begin
                    arempty_reg <= 0;
                end
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            if (FALLTHROUGH == "TRUE") begin
                rdata <= fifo[rd_ptr];
            end else begin
                if (rinc && !rempty_reg) begin
                    rdata <= fifo[rd_ptr];
                end
            end
        end
    end

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

endmodule
