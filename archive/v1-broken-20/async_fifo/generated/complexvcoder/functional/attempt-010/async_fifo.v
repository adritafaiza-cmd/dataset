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
    reg [ASIZE-1:0] wrptr;
    reg [ASIZE-1:0] rrptr;
    reg [DSIZE-1:0] fifo [0:2**ASIZE-1];
    reg wfull_int;
    reg awfull_int;
    reg rempty_int;
    reg arempty_int;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wrptr <= 0;
            wfull_int <= 0;
        end else begin
            if (winc && !wfull_int) begin
                fifo[wrptr] <= wdata;
                wrptr <= wrptr + 1;
                if (wrptr == 2**ASIZE - 1) begin
                    wfull_int <= 1;
                end
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rrptr <= 0;
            rempty_int <= 1;
        end else begin
            if (rinc && !rempty_int) begin
                rrptr <= rrptr + 1;
                if (rrptr == 2**ASIZE - 1) begin
                    rempty_int <= 0;
                end
            end
        end
    end

    // Almost full and almost empty logic
    assign awfull_int = (wrptr == rrptr + 1);
    assign arempty_int = (rrptr == wrptr + 1);

    // Full and empty logic
    assign wfull = wfull_int;
    assign rempty = rempty_int;

    // Almost full and almost empty outputs
    assign awfull = awfull_int;
    assign arempty = arempty_int;

    // Read data output
    if (FALLTHROUGH == "TRUE") begin
        assign rdata = fifo[rrptr];
    end else begin
        reg [DSIZE-1:0] rdata_reg;
        always @(posedge rclk or negedge rrst_n) begin
            if (!rrst_n) begin
                rdata_reg <= 0;
            end else begin
                if (rinc && !rempty_int) begin
                    rdata_reg <= fifo[rrptr];
                    rrptr <= rrptr + 1;
                    if (rrptr == 2**ASIZE - 1) begin
                        rempty_int <= 0;
                    end
                end
            end
        end
        assign rdata = rdata_reg;
    end

endmodule
