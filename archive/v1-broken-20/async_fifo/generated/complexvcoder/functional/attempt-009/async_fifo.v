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
    reg [ASIZE:0] wr_ptr;
    reg [ASIZE:0] rd_ptr;
    reg [DSIZE-1:0] mem [0:(1 << ASIZE) - 1];
    reg wfull_reg;
    reg rempty_reg;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                mem[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == (1 << ASIZE) - 1) begin
                    wfull_reg <= 1;
                end
            end else if (wfull_reg && winc) begin
                // No change
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rempty_reg <= 1;
        end else begin
            if (rinc && !rempty_reg) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == (1 << ASIZE) - 1) begin
                    rempty_reg <= 1;
                end
            end else if (rempty_reg && rinc) begin
                // No change
            end
        end
    end

    // FIFO status signals
    assign wfull = wfull_reg;
    assign awfull = (wr_ptr - rd_ptr == (1 << ASIZE) - 2);
    assign rempty = rempty_reg;
    assign arempty = (wr_ptr - rd_ptr == 1);

    // Read data
    reg [DSIZE-1:0] rdata_reg;
    assign rdata = FALLTHROUGH == "TRUE" ? mem[rd_ptr] : rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else begin
            if (rinc && !rempty_reg) begin
                rdata_reg <= mem[rd_ptr];
            end
        end
    end

endmodule
