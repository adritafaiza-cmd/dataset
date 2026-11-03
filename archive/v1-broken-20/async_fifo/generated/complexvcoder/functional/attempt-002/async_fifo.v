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
    reg [(ASIZE + 1):0] wr_ptr;
    reg [(ASIZE + 1):0] rd_ptr;
    reg [DSIZE-1:0] fifo [0:(2**ASIZE - 1)];
    reg [(ASIZE + 1):0] full_cnt;
    reg [(ASIZE + 1):0] empty_cnt;

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            full_cnt <= 0;
        end else begin
            if (winc && !wfull) begin
                fifo[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                full_cnt <= full_cnt + 1;
            end
        end
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            empty_cnt <= 2**ASIZE;
        end else begin
            if (rinc && !rempty) begin
                rd_ptr <= rd_ptr + 1;
                empty_cnt <= empty_cnt - 1;
            end
        end
    end

    // Full and empty conditions
    assign wfull = (full_cnt == (2**ASIZE));
    assign rempty = (empty_cnt == 0);

    // Almost full and empty conditions
    assign awfull = (full_cnt >= (2**ASIZE - (2**(ASIZE-2))));
    assign arempty = (empty_cnt <= (2**(ASIZE-2)));

    // Data output
    if (FALLTHROUGH == "TRUE") begin
        assign rdata = fifo[rd_ptr];
    end else begin
        reg [DSIZE-1:0] rdata_reg;
        always @(posedge rclk or negedge rrst_n) begin
            if (!rrst_n) begin
                rdata_reg <= 0;
            end else begin
                if (rinc && !rempty) begin
                    rdata_reg <= fifo[rd_ptr];
                end
            end
        end
        assign rdata = rdata_reg;
    end

endmodule
