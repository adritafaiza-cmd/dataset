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

    parameter FIFO_SIZE = 2**ASIZE;
    parameter HALF_FIFO = FIFO_SIZE/2;

    reg [ASIZE-1:0] wrptr;
    reg [ASIZE-1:0] rrptr;
    reg [ASIZE-1:0] count;
    reg [DSIZE-1:0] fifo [0:FIFO_SIZE-1];
    reg [DSIZE-1:0] rdata_reg;

    wire wfull_int;
    wire rempty_int;

    assign wfull = wfull_int;
    assign awfull = (count == (FIFO_SIZE - 1));
    assign rdata = (FALLTHROUGH == "TRUE") ? fifo[rrptr] : rdata_reg;
    assign rempty = rempty_int;
    assign arempty = (count == 1);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wrptr <= 0;
            count <= 0;
        end else begin
            if (winc && !wfull_int) begin
                fifo[wrptr] <= wdata;
                wrptr <= wrptr + 1;
                count <= count + 1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rrptr <= 0;
            rdata_reg <= 0;
            count <= 0;
        end else begin
            if (rinc && !rempty_int) begin
                rrptr <= rrptr + 1;
                count <= count - 1;
            end
        end
    end

    always @(*) begin
        wfull_int = (count == FIFO_SIZE);
        rempty_int = (count == 0);
    end

endmodule
