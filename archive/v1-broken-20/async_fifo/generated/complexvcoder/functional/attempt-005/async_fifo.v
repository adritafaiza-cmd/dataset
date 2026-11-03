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
    reg [DSIZE-1:0] mem [0:2**ASIZE-1];
    reg [ASIZE-1:0] wr_ptr, rd_ptr;
    reg [ASIZE:0] count;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            count <= 0;
            wfull <= 0;
            awfull <= 0;
        end else begin
            if (winc && !wfull) begin
                mem[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
                wfull <= (count == 2**ASIZE - 1);
                awfull <= (count == 2**ASIZE - 2);
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            count <= 0;
            rempty <= 1;
            arempty <= 1;
        end else begin
            if (rinc && !rempty) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
                rempty <= (count == 0);
                arempty <= (count == 1);
            end
        end
    end

    // Read data output
    assign rdata = FALLTHROUGH == "TRUE" ? mem[rd_ptr] : (rempty ? 0 : mem[rd_ptr]);

endmodule
