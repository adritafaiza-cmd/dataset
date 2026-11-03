module async_fifo #(
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
    localparam FIFO_HALF = FIFO_SIZE / 2;

    reg [ASIZE-1:0] wr_ptr;
    reg [ASIZE-1:0] rd_ptr;
    reg [DSIZE-1:0] mem [0:FIFO_SIZE-1];
    reg [DSIZE-1:0] q;
    reg wfull_reg;
    reg awfull_reg;
    reg rempty_reg;
    reg arempty_reg;

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wfull_reg <= 1'b0;
            awfull_reg <= 1'b0;
        end else begin
            if (winc && !wfull_reg && (wr_ptr != rd_ptr || winc)) begin
                mem[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == rd_ptr) begin
                    wfull_reg <= 1'b1;
                end else if (wr_ptr == rd_ptr - 1) begin
                    awfull_reg <= 1'b1;
                end
            end
        end
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rempty_reg <= 1'b1;
            arempty_reg <= 1'b1;
        end else begin
            if (rinc && !rempty_reg && (wr_ptr != rd_ptr || rinc)) begin
                q <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == wr_ptr) begin
                    rempty_reg <= 1'b1;
                end else if (rd_ptr == wr_ptr - 1) begin
                    arempty_reg <= 1'b1;
                end
            end
        end
    end

    // Output logic
    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;
    assign rdata = FALLTHROUGH == "TRUE" ? q : mem[rd_ptr];

endmodule
