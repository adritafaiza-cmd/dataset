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

    // Internal signals
    reg [ASIZE-1:0] wr_ptr;
    reg [ASIZE-1:0] rd_ptr;
    reg [ASIZE-1:0] count;
    reg [DSIZE-1:0] mem [0:FIFO_DEPTH-1];

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            count <= 0;
        end else begin
            if (winc && !wfull) begin
                mem[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
        end
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (rinc && !rempty) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

    // Full and Empty flags
    assign wfull = (count == FIFO_DEPTH);
    assign awfull = (count > (FIFO_DEPTH - 2));
    assign rempty = (count == 0);
    assign arempty = (count < 2);

    // Read data
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else begin
            if (rinc && !rempty) begin
                rdata_reg <= mem[rd_ptr];
            end
        end
    end

    assign rdata = FALLTHROUGH == "TRUE" ? mem[rd_ptr] : rdata_reg;

endmodule
