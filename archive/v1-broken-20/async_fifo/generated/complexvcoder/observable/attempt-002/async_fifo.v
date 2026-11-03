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
    localparam FIFO_SIZE = 2**ASIZE;
    reg [FIFO_SIZE-1:0] mem [0:FIFO_SIZE-1];
    reg [ASIZE:0] wr_ptr, rd_ptr;
    reg [ASIZE:0] wr_count, rd_count;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wr_count <= 0;
        end else if (winc && !wfull) begin
            mem[wr_ptr] <= wdata;
            wr_ptr <= wr_ptr + 1;
            wr_count <= wr_count + 1;
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rd_count <= 0;
        end else if (rinc && !rempty) begin
            rd_ptr <= rd_ptr + 1;
            rd_count <= rd_count - 1;
        end
    end

    // Full and empty flags
    assign wfull = (wr_count == FIFO_SIZE);
    assign rempty = (rd_count == 0);
    assign awfull = (wr_count == FIFO_SIZE - 1);

    // Almost full and almost empty flags
    assign arempty = (rd_count == 1);

    // Output data
    assign rdata = mem[rd_ptr];

endmodule
